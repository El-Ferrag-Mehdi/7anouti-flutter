import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/client_carnet_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/carnet_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';

/// Cubit pour gérer la page Carnet du client
class ClientCarnetCubit extends Cubit<ClientCarnetState> {
  ClientCarnetCubit({
    required CarnetRepository carnetRepository,
  })  : _carnetRepository = carnetRepository,
        super(const ClientCarnetInitial());

  final CarnetRepository _carnetRepository;

  /// Charge tous les carnets du client
  Future<void> loadCarnets() async {
    emit(const ClientCarnetLoading());

    try {
      final carnets = await _carnetRepository.getAllCarnets();

      if (carnets.isEmpty) {
        emit(const ClientCarnetEmpty());
      } else {
        emit(ClientCarnetLoaded(carnets: carnets));
      }
    } on ApiException catch (e) {
      emit(ClientCarnetError(message: e.message));
    } catch (e) {
      emit(ClientCarnetError(
        message: e.toString(),
      ));
    }
  }

  /// Sélectionne un carnet pour voir les détails
  void selectCarnet(CarnetModel carnet) {
    final currentState = state;
    if (currentState is ClientCarnetLoaded) {
      emit(currentState.copyWith(selectedCarnet: carnet));
    }
  }

  /// Désélectionne le carnet
  void deselectCarnet() {
    final currentState = state;
    if (currentState is ClientCarnetLoaded) {
      emit(currentState.copyWith(selectedCarnet: null));
    }
  }

  /// Rafraîchit les données
  Future<void> refresh() async {
    await loadCarnets();
  }

  /// VERSION MOCK pour tester sans API
  Future<void> loadCarnetsMock() async {
    emit(const ClientCarnetLoading());

    // Simule un délai réseau
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Carnets fictifs
    final mockCarnets = [
      CarnetModel(
        id: 'carnet1',
        clientId: 'client1',
        hanoutId: 'hanout1',
        balance: 120.50, // Dette de 120.50 DH
        isActive: true,
        activatedAt: DateTime.now().subtract(const Duration(days: 60)),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CarnetModel(
        id: 'carnet2',
        clientId: 'client1',
        hanoutId: 'hanout2',
        balance: 45.00, // Dette de 45 DH
        isActive: true,
        activatedAt: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      CarnetModel(
        id: 'carnet3',
        clientId: 'client1',
        hanoutId: 'hanout3',
        balance: 0.0, // Pas de dette
        isActive: true,
        activatedAt: DateTime.now().subtract(const Duration(days: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    emit(ClientCarnetLoaded(carnets: mockCarnets));
  }
}
