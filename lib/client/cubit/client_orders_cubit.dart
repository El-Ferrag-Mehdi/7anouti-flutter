import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/client_orders_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';

/// Cubit pour gérer la page d'historique des commandes
class ClientOrdersCubit extends Cubit<ClientOrdersState> {
  ClientOrdersCubit({
    required OrderRepository orderRepository,
    required GasServiceRepository gasServiceRepository,
  }) : _orderRepository = orderRepository,
       _gasServiceRepository = gasServiceRepository,
       super(const ClientOrdersInitial());

  final OrderRepository _orderRepository;
  final GasServiceRepository _gasServiceRepository;

  /// Charge toutes les commandes du client
  Future<void> loadOrders({
    OrderStatus? status,
    ClientOrdersFilter filter = ClientOrdersFilter.inProgress,
  }) async {
    emit(const ClientOrdersLoading());

    try {
      final orders = await _orderRepository.getClientOrders(
        status: status?.value,
        limit: 100,
      );
      final gasRequests = await _gasServiceRepository.getMyRequests();

      if (orders.isEmpty && gasRequests.isEmpty) {
        emit(const ClientOrdersEmpty());
      } else {
        emit(
          ClientOrdersLoaded(
            orders: orders,
            gasRequests: gasRequests,
            selectedStatus: status,
            filter: filter,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(ClientOrdersError(message: e.message));
    } catch (e) {
      emit(
        ClientOrdersError(
          message: e.toString(),
        ),
      );
    }
  }

  /// Filtre par statut
  void filterByStatus(OrderStatus? status) {
    final currentState = state;
    if (currentState is ClientOrdersLoaded) {
      emit(
        currentState.copyWith(
          selectedStatus: status,
          clearStatus: status == null,
        ),
      );
    }
  }

  void filterByType(ClientOrdersFilter filter) {
    final currentState = state;
    if (currentState is ClientOrdersLoaded) {
      emit(currentState.copyWith(filter: filter));
    }
  }

  /// Rafraîchit la liste
  Future<void> refresh() async {
    final currentState = state;
    OrderStatus? currentStatus;
    var currentFilter = ClientOrdersFilter.inProgress;

    if (currentState is ClientOrdersLoaded) {
      currentStatus = currentState.selectedStatus;
      currentFilter = currentState.filter;
    }

    await loadOrders(status: currentStatus, filter: currentFilter);
  }

  /// VERSION MOCK pour tester sans API
  Future<void> loadOrdersMock() async {
    emit(const ClientOrdersLoading());

    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Commandes fictives
    final mockOrders = [
      OrderModel(
        id: 'order1',
        clientId: 'client1',
        hanoutId: 'hanout1',
        freeTextOrder: '2 painssss, 1 lait, 1 eau',
        status: OrderStatus.delivered,
        deliveryType: DeliveryType.delivery,
        paymentMethod: PaymentMethod.cash,
        deliveryFee: 7.0,
        totalAmount: 35.0,
        clientAddress: '123 Rue Test',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        deliveredAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      ),
      OrderModel(
        id: 'order2',
        clientId: 'client1',
        hanoutId: 'hanout1',
        freeTextOrder: '1 pain, fromage, olives',
        status: OrderStatus.delivering,
        deliveryType: DeliveryType.delivery,
        paymentMethod: PaymentMethod.cash,
        deliveryFee: 7.0,
        totalAmount: 28.0,
        clientAddress: '123 Rue Test',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        acceptedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 10)),
        pickedUpAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      OrderModel(
        id: 'order3',
        clientId: 'client1',
        hanoutId: 'hanout2',
        freeTextOrder: 'Légumes frais, tomates, oignons',
        status: OrderStatus.ready,
        deliveryType: DeliveryType.pickup,
        paymentMethod: PaymentMethod.cash,
        totalAmount: 45.0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        acceptedAt: DateTime.now().subtract(
          const Duration(hours: 1, minutes: 55),
        ),
        readyAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      OrderModel(
        id: 'order4',
        clientId: 'client1',
        hanoutId: 'hanout1',
        freeTextOrder: '3 pains, confiture',
        status: OrderStatus.preparing,
        deliveryType: DeliveryType.delivery,
        paymentMethod: PaymentMethod.carnet,
        deliveryFee: 7.0,
        totalAmount: 22.0,
        clientAddress: '123 Rue Test',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        acceptedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      OrderModel(
        id: 'order5',
        clientId: 'client1',
        hanoutId: 'hanout3',
        freeTextOrder: 'Eau minérale pack de 6',
        status: OrderStatus.cancelled,
        deliveryType: DeliveryType.delivery,
        paymentMethod: PaymentMethod.cash,
        deliveryFee: 7.0,
        clientAddress: '123 Rue Test',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        cancelledAt: DateTime.now().subtract(const Duration(days: 5)),
        cancellationReason: 'Hanout fermé',
      ),
      OrderModel(
        id: 'order6',
        clientId: 'client1',
        hanoutId: 'hanout1',
        freeTextOrder: '2 pains, 1 lait',
        status: OrderStatus.delivered,
        deliveryType: DeliveryType.pickup,
        paymentMethod: PaymentMethod.cash,
        totalAmount: 15.0,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        deliveredAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    emit(ClientOrdersLoaded(orders: mockOrders, gasRequests: const []));
  }
}
