import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sevenouti/client/cubit/client_home_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/hanout_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/utils/location_cache.dart';
import 'package:sevenouti/utils/location_utils.dart';

class ClientHomeCubit extends Cubit<ClientHomeState> {
  ClientHomeCubit({
    required HanoutRepository hanoutRepository,
  }) : _hanoutRepository = hanoutRepository,
       super(const ClientHomeInitial());

  final HanoutRepository _hanoutRepository;

  Future<void> loadNearbyHanouts({
    bool requestPermission = false,
  }) async {
    debugPrint('[ClientHomeCubit] loadNearbyHanouts() called');
    emit(const ClientHomeLoading());

    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final position = await _getUserPosition(
          emitLoadingState: requestPermission && attempt == 1,
          requestPermission: requestPermission,
        );
        if (position == null) {
          await _loadPublicHanouts();
          return;
        }

        debugPrint(
          '[ClientHomeCubit] Position: lat=${position.latitude}, '
          'lon=${position.longitude}',
        );
        await LocationCache().save(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        final hanouts = await _hanoutRepository.getNearbyHanouts(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        debugPrint(
          '[ClientHomeCubit] API returned ${hanouts.length} hanouts',
        );

        final hanoutsWithDistance = _withDistance(
          hanouts,
          position.latitude,
          position.longitude,
        );

        if (hanoutsWithDistance.isEmpty) {
          emit(
            ClientHomeEmpty(
              userLatitude: position.latitude,
              userLongitude: position.longitude,
              isUsingFallbackLocation: false,
            ),
          );
        } else {
          final currentState = state;
          if (currentState is ClientHomeLoaded &&
              _sameHanouts(currentState.hanouts, hanoutsWithDistance) &&
              currentState.userLatitude == position.latitude &&
              currentState.userLongitude == position.longitude &&
              !currentState.isUsingFallbackLocation) {
            return;
          }
          emit(
            ClientHomeLoaded(
              hanouts: hanoutsWithDistance,
              userLatitude: position.latitude,
              userLongitude: position.longitude,
              isUsingFallbackLocation: false,
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
        emit(
          ClientHomeError(
            message: e.message,
            canRetry: true,
          ),
        );
      } catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        emit(
          ClientHomeError(
            message: 'Une erreur est survenue: ${e.toString()}',
            canRetry: true,
          ),
        );
      }
    }

    if (lastError != null) {
      debugPrint('[ClientHomeCubit] loadNearbyHanouts failed: $lastError');
    }
  }

  void selectHanout(HanoutWithDistance hanout) {
    final currentState = state;
    if (currentState is ClientHomeLoaded) {
      emit(currentState.copyWith(selectedHanout: hanout));
    }
  }

  Future<void> refresh() async {
    debugPrint('[ClientHomeCubit] refresh() called');
    await loadNearbyHanouts();
  }

  Future<Position?> _getUserPosition({
    bool emitLoadingState = true,
    bool requestPermission = false,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[ClientHomeCubit] Location service disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      debugPrint('[ClientHomeCubit] Location permission: $permission');
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
        debugPrint(
          '[ClientHomeCubit] Permission after request: $permission',
        );
      }

      if (permission == LocationPermission.denied) {
        debugPrint('[ClientHomeCubit] Permission denied by user');
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[ClientHomeCubit] Permission denied forever');
        return null;
      }

      if (emitLoadingState) {
        emit(const ClientHomeLoadingLocation());
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('[ClientHomeCubit] Got position from Geolocator');
      return position;
    } catch (e) {
      debugPrint('[ClientHomeCubit] getUserPosition error: $e');
      return null;
    }
  }

  Future<void> _loadPublicHanouts() async {
    final hanouts = await _hanoutRepository.getNearbyHanouts(
      limit: 5,
    );

    if (hanouts.isEmpty) {
      emit(
        const ClientHomeEmpty(
          userLatitude: 0,
          userLongitude: 0,
          isUsingFallbackLocation: true,
        ),
      );
      return;
    }

    emit(
      ClientHomeLoaded(
        hanouts: hanouts,
        userLatitude: 0,
        userLongitude: 0,
        isUsingFallbackLocation: true,
      ),
    );
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

  Future<void> loadNearbyHanoutsMock() async {
    emit(const ClientHomeLoading());

    await Future<void>.delayed(const Duration(seconds: 1));

    const userLat = 33.5731;
    const userLon = -7.5898;

    final mockHanouts = [
      HanoutModel(
        id: '1',
        name: 'Hanout Hassan',
        description: 'Epicerie de quartier',
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
        name: 'Epicerie Fatima',
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
        name: 'Epicerie du Coin',
        description: 'Ferme actuellement',
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

    final hanoutsWithDistance = mockHanouts.map((hanout) {
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

    emit(
      ClientHomeLoaded(
        hanouts: hanoutsWithDistance,
        userLatitude: userLat,
        userLongitude: userLon,
      ),
    );
  }
}
