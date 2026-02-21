import 'package:equatable/equatable.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';

abstract class HanoutOrdersState extends Equatable {
  const HanoutOrdersState();

  @override
  List<Object?> get props => [];
}

class HanoutOrdersInitial extends HanoutOrdersState {
  const HanoutOrdersInitial();
}

class HanoutOrdersLoading extends HanoutOrdersState {
  const HanoutOrdersLoading();
}

class HanoutOrdersLoaded extends HanoutOrdersState {
  const HanoutOrdersLoaded({
    required this.orders,
    this.selectedStatus,
  });

  final List<HanoutOrderModel> orders;
  final OrderStatus? selectedStatus;

  @override
  List<Object?> get props => [orders, selectedStatus];

  List<HanoutOrderModel> get filteredOrders {
    if (selectedStatus == null) return orders;
    return orders.where((order) => order.status == selectedStatus).toList();
  }

  List<HanoutOrderModel> get activeOrders {
    return orders.where((order) {
      return order.status != OrderStatus.delivered &&
          order.status != OrderStatus.cancelled;
    }).toList();
  }

  List<HanoutOrderModel> get historyOrders {
    return orders.where((order) {
      return order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled;
    }).toList();
  }

  List<HanoutOrderModel> get activeFilteredOrders {
    if (selectedStatus == null) return activeOrders;
    return activeOrders
        .where((order) => order.status == selectedStatus)
        .toList();
  }

  Map<OrderStatus, int> get statusCounts {
    final counts = <OrderStatus, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return counts;
  }

  Map<OrderStatus, int> get activeStatusCounts {
    final counts = <OrderStatus, int>{};
    for (final order in activeOrders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return counts;
  }

  int get deliveredCount {
    return orders.where((o) => o.status == OrderStatus.delivered).length;
  }

  int get cancelledCount {
    return orders.where((o) => o.status == OrderStatus.cancelled).length;
  }

  double get deliveredRevenue {
    double total = 0;
    for (final order in orders) {
      if (order.status == OrderStatus.delivered && order.totalAmount != null) {
        total += order.totalAmount!;
      }
    }
    return total;
  }

  HanoutOrdersLoaded copyWith({
    List<HanoutOrderModel>? orders,
    OrderStatus? selectedStatus,
    bool clearStatus = false,
  }) {
    return HanoutOrdersLoaded(
      orders: orders ?? this.orders,
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
  }
}

class HanoutOrdersEmpty extends HanoutOrdersState {
  const HanoutOrdersEmpty();
}

class HanoutOrdersError extends HanoutOrdersState {
  const HanoutOrdersError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
