import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/hanout/cubbit/hanout_orders_state.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';

class HanoutOrdersCubit extends Cubit<HanoutOrdersState> {
  HanoutOrdersCubit({
    required HanoutOrdersRepository ordersRepository,
  })  : _ordersRepository = ordersRepository,
        super(const HanoutOrdersInitial());

  final HanoutOrdersRepository _ordersRepository;

  Future<void> loadOrders({OrderStatus? status}) async {
    emit(const HanoutOrdersLoading());
    try {
      final orders = await _ordersRepository.getHanoutOrders(
        status: status?.value,
        limit: 100,
      );
      if (orders.isEmpty) {
        emit(const HanoutOrdersEmpty());
      } else {
        emit(HanoutOrdersLoaded(
          orders: orders,
          selectedStatus: status,
        ));
      }
    } on ApiException catch (e) {
      emit(HanoutOrdersError(message: e.message));
    } catch (e) {
      emit(HanoutOrdersError(
        message: e.toString(),
      ));
    }
  }

  void filterByStatus(OrderStatus? status) {
    final currentState = state;
    if (currentState is HanoutOrdersLoaded) {
      emit(currentState.copyWith(
        selectedStatus: status,
        clearStatus: status == null,
      ));
    }
  }

  Future<void> refresh() async {
    final currentState = state;
    OrderStatus? currentStatus;

    if (currentState is HanoutOrdersLoaded) {
      currentStatus = currentState.selectedStatus;
    }

    await loadOrders(status: currentStatus);
  }

  Future<void> acceptOrder(String orderId, {double? totalAmount}) async {
    try {
      await _ordersRepository.acceptOrder(
        orderId,
        totalAmount: totalAmount,
      );
      await refresh();
    } on ApiException catch (e) {
      emit(HanoutOrdersError(message: e.message));
    } catch (e) {
      emit(HanoutOrdersError(
        message: e.toString(),
      ));
    }
  }

  Future<void> updateStatus(
    String orderId, {
    OrderStatus? status,
    double? totalAmount,
  }) async {
    try {
      await _ordersRepository.updateOrderStatus(
        orderId,
        status: status,
        totalAmount: totalAmount,
      );
      await refresh();
    } on ApiException catch (e) {
      emit(HanoutOrdersError(message: e.message));
    } catch (e) {
      emit(HanoutOrdersError(
        message: e.toString(),
      ));
    }
  }

  Future<void> assignLivreur(String orderId, String livreurId) async {
    try {
      await _ordersRepository.assignLivreur(orderId, livreurId);
      await refresh();
    } on ApiException catch (e) {
      emit(HanoutOrdersError(message: e.message));
    } catch (e) {
      emit(HanoutOrdersError(
        message: e.toString(),
      ));
    }
  }

  Future<void> requestLivreur(String orderId) async {
    try {
      await _ordersRepository.requestLivreur(orderId);
      await refresh();
    } on ApiException catch (e) {
      emit(HanoutOrdersError(message: e.message));
    } catch (e) {
      emit(HanoutOrdersError(
        message: e.toString(),
      ));
    }
  }
}

