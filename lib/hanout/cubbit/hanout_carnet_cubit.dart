import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_state.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';

class HanoutCarnetCubit extends Cubit<HanoutCarnetState> {
  HanoutCarnetCubit({
    required HanoutCarnetRepository carnetRepository,
  })  : _carnetRepository = carnetRepository,
        super(const HanoutCarnetInitial());

  final HanoutCarnetRepository _carnetRepository;

  Future<void> loadAll() async {
    emit(const HanoutCarnetLoading());
    try {
      final carnets = await _carnetRepository.getHanoutCarnets();
      final requests = await _carnetRepository.getHanoutRequests(
        status: 'PENDING',
      );

      if (carnets.isEmpty && requests.isEmpty) {
        emit(const HanoutCarnetEmpty());
      } else {
        emit(HanoutCarnetLoaded(carnets: carnets, requests: requests));
      }
    } on ApiException catch (e) {
      emit(HanoutCarnetError(message: e.message));
    } catch (e) {
      emit(HanoutCarnetError(
        message: e.toString(),
      ));
    }
  }

  Future<void> loadCarnetsOnly() async {
    emit(const HanoutCarnetLoading());
    try {
      final carnets = await _carnetRepository.getHanoutCarnets();
      if (carnets.isEmpty) {
        emit(const HanoutCarnetEmpty());
      } else {
        emit(HanoutCarnetLoaded(carnets: carnets, requests: const []));
      }
    } on ApiException catch (e) {
      emit(HanoutCarnetError(message: e.message));
    } catch (e) {
      emit(HanoutCarnetError(
        message: e.toString(),
      ));
    }
  }

  Future<void> updateCreditLimit(String carnetId, double creditLimit) async {
    try {
      await _carnetRepository.updateCreditLimit(carnetId, creditLimit);
      await loadAll();
    } on ApiException catch (e) {
      emit(HanoutCarnetError(message: e.message));
    } catch (e) {
      emit(HanoutCarnetError(
        message: e.toString(),
      ));
    }
  }

  Future<void> recordPayment(
    String carnetId,
    double amount, {
    String? description,
  }) async {
    try {
      await _carnetRepository.recordPayment(
        carnetId: carnetId,
        amount: amount,
        description: description,
      );
      await loadAll();
    } on ApiException catch (e) {
      emit(HanoutCarnetError(message: e.message));
    } catch (e) {
      emit(HanoutCarnetError(
        message: e.toString(),
      ));
    }
  }

  Future<void> addDebt(
    String carnetId,
    double amount, {
    required String description,
  }) async {
    try {
      await _carnetRepository.addDebt(
        carnetId: carnetId,
        amount: amount,
        description: description,
      );
      await loadAll();
    } on ApiException catch (e) {
      emit(HanoutCarnetError(message: e.message));
    } catch (e) {
      emit(HanoutCarnetError(
        message: e.toString(),
      ));
    }
  }

  Future<void> approveRequest(String requestId) async {
    try {
      await _carnetRepository.approveRequest(requestId);
      await loadAll();
    } on ApiException catch (e) {
      emit(HanoutCarnetError(message: e.message));
    } catch (e) {
      emit(HanoutCarnetError(
        message: e.toString(),
      ));
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    try {
      await _carnetRepository.rejectRequest(requestId, reason);
      await loadAll();
    } on ApiException catch (e) {
      emit(HanoutCarnetError(message: e.message));
    } catch (e) {
      emit(HanoutCarnetError(
        message: e.toString(),
      ));
    }
  }
}

