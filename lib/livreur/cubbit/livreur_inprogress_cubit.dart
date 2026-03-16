import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/livreur/cubbit/livreur_inprogress_state.dart';
import 'package:sevenouti/livreur/models/livreur_order_model.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';

class LivreurInProgressCubit extends Cubit<LivreurInProgressState> {
  LivreurInProgressCubit({
    required LivreurOrdersRepository repository,
    required GasServiceLivreurRepository gasRepository,
  }) : _repository = repository,
       _gasRepository = gasRepository,
       super(const LivreurInProgressInitial()) {
    _startAutoRefresh();
  }

  final LivreurOrdersRepository _repository;
  final GasServiceLivreurRepository _gasRepository;
  Timer? _autoRefreshTimer;
  bool _isRefreshing = false;

  Future<void> loadOrders() async {
    await _fetchOrders(showLoading: true);
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      await _repository.updateOrderStatus(orderId, status);
      await loadOrders();
    } on ApiException catch (e) {
      emit(LivreurInProgressError(message: e.message));
    } catch (e) {
      emit(
        LivreurInProgressError(
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> updateGasStatus(
    String requestId,
    GasServiceStatus status,
  ) async {
    try {
      await _gasRepository.updateGasStatus(requestId, status);
      await loadOrders();
    } on ApiException catch (e) {
      emit(LivreurInProgressError(message: e.message));
    } catch (e) {
      emit(
        LivreurInProgressError(
          message: e.toString(),
        ),
      );
    }
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
      await _fetchOrders(showLoading: false);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _fetchOrders({required bool showLoading}) async {
    if (showLoading) {
      emit(const LivreurInProgressLoading());
    }
    try {
      final results = await Future.wait<dynamic>([
        _repository.getLivreurOrders(
          status: 'READY,PICKED_UP,DELIVERING',
          limit: 40,
        ),
        _gasRepository.getLivreurGasRequests(
          status: 'EN_ROUTE,ARRIVE,RECUPERE_VIDE,VA_AU_HANOUT,RETOUR_MAISON',
        ),
      ]);

      final active = results[0] as List<LivreurOrderModel>;
      final gasActive = results[1] as List<GasServiceOrder>;

      if (active.isEmpty && gasActive.isEmpty) {
        emit(const LivreurInProgressEmpty());
      } else {
        emit(LivreurInProgressLoaded(orders: active, gasRequests: gasActive));
      }
    } on ApiException catch (e) {
      if (showLoading) {
        emit(LivreurInProgressError(message: e.message));
      }
    } catch (e) {
      if (showLoading) {
        emit(
          LivreurInProgressError(
            message: e.toString(),
          ),
        );
      }
    }
  }
}
