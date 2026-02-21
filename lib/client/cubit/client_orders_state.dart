import 'package:equatable/equatable.dart';
import 'package:sevenouti/client/models/models.dart';

/// États de la page d'historique des commandes
abstract class ClientOrdersState extends Equatable {
  const ClientOrdersState();

  @override
  List<Object?> get props => [];
}

enum ClientOrdersFilter {
  all,
  inProgress,
}

/// État initial
class ClientOrdersInitial extends ClientOrdersState {
  const ClientOrdersInitial();
}

/// État de chargement
class ClientOrdersLoading extends ClientOrdersState {
  const ClientOrdersLoading();
}

/// État chargé avec les commandes
class ClientOrdersLoaded extends ClientOrdersState {
  const ClientOrdersLoaded({
    required this.orders,
    required this.gasRequests,
    this.selectedStatus,
    this.filter = ClientOrdersFilter.inProgress,
  });

  final List<OrderModel> orders;
  final List<GasServiceOrder> gasRequests;
  final OrderStatus? selectedStatus;
  final ClientOrdersFilter filter;

  @override
  List<Object?> get props => [orders, gasRequests, selectedStatus, filter];

  /// Filtre les commandes par statut
  List<OrderModel> get filteredOrders {
    if (selectedStatus == null) return orders;
    return orders.where((order) => order.status == selectedStatus).toList();
  }

  /// Compte les commandes par statut
  Map<OrderStatus, int> get statusCounts {
    final counts = <OrderStatus, int>{};
    for (final order in orders) {
      counts[order.status] = (counts[order.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Copie avec modifications
  ClientOrdersLoaded copyWith({
    List<OrderModel>? orders,
    List<GasServiceOrder>? gasRequests,
    OrderStatus? selectedStatus,
    ClientOrdersFilter? filter,
    bool clearStatus = false,
  }) {
    return ClientOrdersLoaded(
      orders: orders ?? this.orders,
      gasRequests: gasRequests ?? this.gasRequests,
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      filter: filter ?? this.filter,
    );
  }
}

/// État vide - pas de commandes
class ClientOrdersEmpty extends ClientOrdersState {
  const ClientOrdersEmpty();
}

/// État d'erreur
class ClientOrdersError extends ClientOrdersState {
  const ClientOrdersError({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [message];
}
