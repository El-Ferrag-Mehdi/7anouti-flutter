import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sevenouti/client/cubit/client_home_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/hanout_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/utils/hanout_cache.dart';
import 'package:sevenouti/utils/location_cache.dart';
import 'package:sevenouti/utils/location_utils.dart';

/// Cubit pour gérer la page Home du client
class ClientHomeCubit extends Cubit<ClientHomeState> {
  ClientHomeCubit({
    required HanoutRepository hanoutRepository,
  }) : _hanoutRepository = hanoutRepository,
       super(const ClientHomeInitial());

  final HanoutRepository _hanoutRepository;

  /// Charge les hanouts proches de l'utilisateur
  Future<void> loadNearbyHanouts() async {
    debugPrint('🟦 [ClientHomeCubit] loadNearbyHanouts() called');
    var emittedCache = false;
    final cachedLocation = await LocationCache().getLastKnown();
    final cachedHanouts = await HanoutCache().getCachedHanouts();
    if (cachedLocation != null &&
        cachedHanouts != null &&
        cachedHanouts.isNotEmpty) {
      final cachedWithDistance = _withDistance(
        cachedHanouts,
        cachedLocation.latitude,
        cachedLocation.longitude,
      );
      emit(
        ClientHomeLoaded(
          hanouts: cachedWithDistance,
          userLatitude: cachedLocation.latitude,
          userLongitude: cachedLocation.longitude,
        ),
      );
      emittedCache = true;
    } else {
      emit(const ClientHomeLoading());
    }

    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        // 1. Récupère la position de l'utilisateur
        final position = await _getUserPosition(
          emitLoadingState: !emittedCache && attempt == 1,
          // Évite le faux message d'erreur au 1er essai (erreurs transitoires)
          emitErrors: !emittedCache && attempt == 2,
        );
        if (position == null) {
          if (attempt < 2) {
            await Future<void>.delayed(const Duration(milliseconds: 400));
            continue;
          }
          debugPrint(
            '🟨 [ClientHomeCubit] Position is null -> aborting API call',
          );
          return;
        }
        debugPrint(
          '🟦 [ClientHomeCubit] Position: lat=${position.latitude}, lon=${position.longitude}',
        );
        await LocationCache().save(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        // 2. Récupère les hanouts proches depuis l'API
        final hanouts = await _hanoutRepository.getNearbyHanouts(
          latitude: position.latitude,
          longitude: position.longitude,
          radius: 100000, // 500m par défaut
        );
        debugPrint(
          '🟦 [ClientHomeCubit] API returned ${hanouts.length} hanouts',
        );

        // 3. Calcule les distances et trie
        final hanoutsWithDistance = _withDistance(
          hanouts,
          position.latitude,
          position.longitude,
        );

        await HanoutCache().saveHanouts(hanouts);

        // 4. Émet le bon état
        if (hanoutsWithDistance.isEmpty) {
          emit(
            ClientHomeEmpty(
              userLatitude: position.latitude,
              userLongitude: position.longitude,
            ),
          );
        } else {
          final currentState = state;
          if (currentState is ClientHomeLoaded &&
              _sameHanouts(currentState.hanouts, hanoutsWithDistance) &&
              currentState.userLatitude == position.latitude &&
              currentState.userLongitude == position.longitude) {
            return;
          }
          emit(
            ClientHomeLoaded(
              hanouts: hanoutsWithDistance,
              userLatitude: position.latitude,
              userLongitude: position.longitude,
            ),
          );
        }
        return;
      } on ApiException catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        if (!emittedCache) {
          emit(
            ClientHomeError(
              message: e.message,
              canRetry: true,
            ),
          );
        }
      } catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        if (!emittedCache) {
          emit(
            ClientHomeError(
              message: 'Une erreur est survenue: ${e.toString()}',
              canRetry: true,
            ),
          );
        }
      }
    }
    if (lastError != null) {
      debugPrint('🟥 [ClientHomeCubit] loadNearbyHanouts failed: $lastError');
    }
  }

  /// Sélectionne un hanout (pour le marquer comme favoris ou habituel)
  void selectHanout(HanoutWithDistance hanout) {
    final currentState = state;
    if (currentState is ClientHomeLoaded) {
      emit(currentState.copyWith(selectedHanout: hanout));
    }
  }

  /// Rafraîchit la liste des hanouts
  Future<void> refresh() async {
    debugPrint('🟦 [ClientHomeCubit] refresh() called');
    await loadNearbyHanouts();
  }

  /// Récupère la position GPS de l'utilisateur
  Future<Position?> _getUserPosition({
    bool emitLoadingState = true,
    bool emitErrors = true,
  }) async {
    try {
      // Vérifie si le service de localisation est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('🟥 [ClientHomeCubit] Location service disabled');
        if (emitErrors) {
          emit(
            const ClientHomeError(
              message:
                  'Le service de localisation est désactivé. '
                  'Veuillez l\'activer dans les paramètres.',
              canRetry: true,
            ),
          );
        }
        return null;
      }

      // Vérifie les permissions
      var permission = await Geolocator.checkPermission();
      debugPrint('🟦 [ClientHomeCubit] Location permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint(
          '🟦 [ClientHomeCubit] Permission after request: $permission',
        );
        if (permission == LocationPermission.denied) {
          debugPrint('🟥 [ClientHomeCubit] Permission denied (user)');
          if (emitErrors) {
            emit(const ClientHomeLocationPermissionDenied());
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('🟥 [ClientHomeCubit] Permission denied forever');
        if (emitErrors) {
          emit(const ClientHomeLocationPermissionDenied());
        }
        return null;
      }

      // Récupère la position
      if (emitLoadingState) {
        emit(const ClientHomeLoadingLocation());
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('🟦 [ClientHomeCubit] Got position from Geolocator');

      return position;
    } catch (e) {
      debugPrint('🟥 [ClientHomeCubit] getUserPosition error: $e');
      if (emitErrors) {
        emit(
          ClientHomeError(
            message: 'Impossible de récupérer votre position: ${e.toString()}',
            canRetry: true,
          ),
        );
      }
      return null;
    }
  }

  List<HanoutWithDistance> _withDistance(
    List<HanoutModel> hanouts,
    double userLat,
    double userLon,
  ) {
    final hanoutsWithDistance = hanouts.map((hanout) {
      final distance = LocationUtils.calculateDistance(
        userLat,
        userLon,
        hanout.latitude,
        hanout.longitude,
      );
      return HanoutWithDistance.fromHanout(hanout, distance);
    }).toList();

    hanoutsWithDistance.sort(
      (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters),
    );
    return hanoutsWithDistance;
  }

  bool _sameHanouts(
    List<HanoutWithDistance> a,
    List<HanoutWithDistance> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// VERSION MOCK - Pour tester sans API ni GPS
  /// À utiliser pendant le développement
  Future<void> loadNearbyHanoutsMock() async {
    emit(const ClientHomeLoading());

    // Simule un délai réseau
    await Future<void>.delayed(const Duration(seconds: 1));

    // Position fictive (Casablanca centre)
    const userLat = 33.5731;
    const userLon = -7.5898;

    // Données fictives
    final mockHanouts = [
      HanoutModel(
        id: '1',
        name: 'Hanout Hassan',
        description: 'Épicerie de quartier',
        address: '12 Rue Mohammed V, Casablanca',
        latitude: 33.5735,
        longitude: -7.5895,
        phone: '+212 6 12 34 56 78',
        image: null,
        isOpen: true,
        hasCarnet: true,
        deliveryFee: 7.0,
        estimatedDeliveryTime: 10,
        rating: 4.5,
        totalOrders: 234,
        ownerId: 'owner1',
        createdAt: DateTime.now(),
      ),
      HanoutModel(
        id: '2',
        name: 'Épicerie Fatima',
        description: 'Produits frais tous les jours',
        address: '45 Boulevard Zerktouni, Casablanca',
        latitude: 33.5720,
        longitude: -7.5910,
        phone: '+212 6 98 76 54 32',
        image: null,
        isOpen: true,
        hasCarnet: false,
        deliveryFee: 7.0,
        estimatedDeliveryTime: 15,
        rating: 4.2,
        totalOrders: 156,
        ownerId: 'owner2',
        createdAt: DateTime.now(),
      ),
      HanoutModel(
        id: '3',
        name: 'Hanout Al Baraka',
        description: 'Ouvert 24h/24',
        address: '78 Rue Allal Ben Abdellah, Casablanca',
        latitude: 33.5745,
        longitude: -7.5880,
        phone: '+212 6 11 22 33 44',
        image: null,
        isOpen: true,
        hasCarnet: true,
        deliveryFee: 7.0,
        estimatedDeliveryTime: 8,
        rating: 4.8,
        totalOrders: 445,
        ownerId: 'owner3',
        createdAt: DateTime.now(),
      ),
      HanoutModel(
        id: '4',
        name: 'Épicerie du Coin',
        description: 'Fermé actuellement',
        address: '23 Rue Ibn Batouta, Casablanca',
        latitude: 33.5750,
        longitude: -7.5920,
        phone: '+212 6 55 44 33 22',
        image: null,
        isOpen: false,
        hasCarnet: false,
        deliveryFee: 7.0,
        estimatedDeliveryTime: 12,
        rating: 3.9,
        totalOrders: 89,
        ownerId: 'owner4',
        createdAt: DateTime.now(),
      ),
    ];

    // Calcule les distances
    final hanoutsWithDistance = mockHanouts.map((hanout) {
      final distance = LocationUtils.calculateDistance(
        userLat,
        userLon,
        hanout.latitude,
        hanout.longitude,
      );
      return HanoutWithDistance.fromHanout(hanout, distance);
    }).toList();

    // Trie par distance
    hanoutsWithDistance.sort(
      (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters),
    );

    emit(
      ClientHomeLoaded(
        hanouts: hanoutsWithDistance,
        userLatitude: userLat,
        userLongitude: userLon,
      ),
    );
  }
}
