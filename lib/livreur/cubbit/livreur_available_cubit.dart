import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/livreur/cubbit/livreur_available_state.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';

class LivreurAvailableCubit extends Cubit<LivreurAvailableState> {
  LivreurAvailableCubit({
    required LivreurRequestsRepository repository,
  })  : _repository = repository,
        super(const LivreurAvailableInitial());

  final LivreurRequestsRepository _repository;

  Future<void> loadRequests() async {
    emit(const LivreurAvailableLoading());
    try {
      final requests = await _repository.getAvailableRequests();
      if (requests.isEmpty) {
        emit(const LivreurAvailableEmpty());
      } else {
        emit(LivreurAvailableLoaded(requests: requests));
      }
    } on ApiException catch (e) {
      emit(LivreurAvailableError(message: e.message));
    } catch (e) {
      emit(LivreurAvailableError(
        message: e.toString(),
      ));
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _repository.acceptRequest(requestId);
      await loadRequests();
    } on ApiException catch (e) {
      emit(LivreurAvailableError(message: e.message));
    } catch (e) {
      emit(LivreurAvailableError(
        message: e.toString(),
      ));
    }
  }

  Future<void> acceptGasRequest(String requestId) async {
    try {
      await _repository.acceptGasRequest(requestId);
      await loadRequests();
    } on ApiException catch (e) {
      emit(LivreurAvailableError(message: e.message));
    } catch (e) {
      emit(LivreurAvailableError(
        message: e.toString(),
      ));
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _repository.rejectRequest(requestId);
      await loadRequests();
    } on ApiException catch (e) {
      emit(LivreurAvailableError(message: e.message));
    } catch (e) {
      emit(LivreurAvailableError(
        message: e.toString(),
      ));
    }
  }

  Future<void> rejectGasRequest(String requestId) async {
    try {
      await _repository.rejectGasRequest(requestId);
      await loadRequests();
    } on ApiException catch (e) {
      emit(LivreurAvailableError(message: e.message));
    } catch (e) {
      emit(LivreurAvailableError(
        message: e.toString(),
      ));
    }
  }
}

