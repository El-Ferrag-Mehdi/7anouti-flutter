import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/livreur/cubbit/livreur_available_state.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';

class LivreurAvailableCubit extends Cubit<LivreurAvailableState> {
  LivreurAvailableCubit({
    required LivreurRequestsRepository repository,
  }) : _repository = repository,
       super(const LivreurAvailableInitial()) {
    _startAutoRefresh();
  }

  final LivreurRequestsRepository _repository;
  Timer? _autoRefreshTimer;
  bool _isRefreshing = false;

  Future<void> loadRequests() async {
    await _fetchRequests(showLoading: true);
  }

  Future<bool> acceptRequest(String requestId) async {
    await _repository.acceptRequest(requestId);
    await _fetchRequests(showLoading: false);
    return true;
  }

  Future<bool> acceptGasRequest(String requestId) async {
    await _repository.acceptGasRequest(requestId);
    await _fetchRequests(showLoading: false);
    return true;
  }

  Future<void> rejectRequest(String requestId) async {
    await _repository.rejectRequest(requestId);
    await _fetchRequests(showLoading: false);
  }

  Future<void> rejectGasRequest(String requestId) async {
    await _repository.rejectGasRequest(requestId);
    await _fetchRequests(showLoading: false);
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    return super.close();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_refreshSilently());
    });
  }

  Future<void> _refreshSilently() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await _fetchRequests(showLoading: false);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _fetchRequests({required bool showLoading}) async {
    if (showLoading) {
      emit(const LivreurAvailableLoading());
    }
    try {
      final requests = await _repository.getAvailableRequests();
      if (requests.isEmpty) {
        emit(const LivreurAvailableEmpty());
      } else {
        emit(LivreurAvailableLoaded(requests: requests));
      }
    } on ApiException catch (e) {
      if (showLoading) {
        emit(LivreurAvailableError(message: e.message));
      }
    } catch (e) {
      if (showLoading) {
        emit(
          LivreurAvailableError(
            message: e.toString(),
          ),
        );
      }
    }
  }
}
