import 'dart:async';

import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';
import 'package:sevenouti/livreur/models/delivery_request_model.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';

class ClientOrderStatusChangedEvent {
  const ClientOrderStatusChangedEvent({
    required this.orderId,
    required this.oldStatus,
    required this.newStatus,
  });

  final String orderId;
  final OrderStatus oldStatus;
  final OrderStatus newStatus;
}

class ClientOrderStatusWatcher {
  ClientOrderStatusWatcher({
    required OrderRepository repository,
    this.interval = const Duration(seconds: 12),
  }) : _repository = repository;

  final OrderRepository _repository;
  final Duration interval;

  Timer? _timer;
  bool _isPolling = false;
  bool _initialized = false;
  Map<String, OrderStatus> _known = <String, OrderStatus>{};
  void Function(ClientOrderStatusChangedEvent event)? _onEvent;

  Future<void> start(
    void Function(ClientOrderStatusChangedEvent event) onEvent,
  ) async {
    _onEvent = onEvent;
    await _poll();
    _timer ??= Timer.periodic(interval, (_) {
      unawaited(_poll());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final orders = await _repository.getClientOrders(limit: 100);
      final next = <String, OrderStatus>{
        for (final order in orders) order.id: order.status,
      };

      if (_initialized) {
        for (final entry in next.entries) {
          final previous = _known[entry.key];
          if (previous != null && previous != entry.value) {
            _onEvent?.call(
              ClientOrderStatusChangedEvent(
                orderId: entry.key,
                oldStatus: previous,
                newStatus: entry.value,
              ),
            );
          }
        }
      }

      _known = next;
      _initialized = true;
    } on Object {
      // Polling errors are ignored; next tick will retry.
    } finally {
      _isPolling = false;
    }
  }
}

class HanoutNewOrderEvent {
  const HanoutNewOrderEvent({
    required this.orderId,
  });

  final String orderId;
}

class HanoutDeliveryRequestUpdatedEvent {
  const HanoutDeliveryRequestUpdatedEvent({
    required this.orderId,
    required this.status,
  });

  final String orderId;
  final String status;
}

class HanoutNotificationsWatcher {
  HanoutNotificationsWatcher({
    required HanoutOrdersRepository repository,
    this.interval = const Duration(seconds: 12),
  }) : _repository = repository;

  final HanoutOrdersRepository _repository;
  final Duration interval;

  Timer? _timer;
  bool _isPolling = false;
  bool _initialized = false;
  Set<String> _knownOrderIds = <String>{};
  Map<String, String?> _knownDeliveryRequestStatuses = <String, String?>{};
  void Function(HanoutNewOrderEvent event)? _onNewOrder;
  void Function(HanoutDeliveryRequestUpdatedEvent event)?
      _onDeliveryRequestUpdated;

  Future<void> start({
    required void Function(HanoutNewOrderEvent event) onNewOrder,
    required void Function(HanoutDeliveryRequestUpdatedEvent event)
        onDeliveryRequestUpdated,
  }) async {
    _onNewOrder = onNewOrder;
    _onDeliveryRequestUpdated = onDeliveryRequestUpdated;
    await _poll();
    _timer ??= Timer.periodic(interval, (_) {
      unawaited(_poll());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final orders = await _repository.getHanoutOrders(limit: 100);
      final nextIds = <String>{for (final order in orders) order.id};
      final nextRequestStatuses = <String, String?>{
        for (final order in orders) order.id: order.latestDeliveryRequestStatus,
      };

      if (_initialized) {
        for (final order in orders) {
          if (!_knownOrderIds.contains(order.id)) {
            _onNewOrder?.call(HanoutNewOrderEvent(orderId: order.id));
          }
        }

        for (final order in orders) {
          final previous = _knownDeliveryRequestStatuses[order.id];
          final current = order.latestDeliveryRequestStatus;
          if (current == null || current == previous) {
            continue;
          }

          if (current == 'ACCEPTED' ||
              current == 'REJECTED' ||
              current == 'CANCELLED') {
            _onDeliveryRequestUpdated?.call(
              HanoutDeliveryRequestUpdatedEvent(
                orderId: order.id,
                status: current,
              ),
            );
          }
        }
      }

      _knownOrderIds = nextIds;
      _knownDeliveryRequestStatuses = nextRequestStatuses;
      _initialized = true;
    } on Object {
      // Polling errors are ignored; next tick will retry.
    } finally {
      _isPolling = false;
    }
  }
}

class LivreurNewRequestEvent {
  const LivreurNewRequestEvent({
    required this.request,
  });

  final LivreurDeliveryRequestModel request;
}

class LivreurRequestsWatcher {
  LivreurRequestsWatcher({
    required LivreurRequestsRepository repository,
    this.interval = const Duration(seconds: 12),
  }) : _repository = repository;

  final LivreurRequestsRepository _repository;
  final Duration interval;

  Timer? _timer;
  bool _isPolling = false;
  bool _initialized = false;
  Set<String> _knownRequestIds = <String>{};
  void Function(LivreurNewRequestEvent event)? _onNewRequest;

  Future<void> start(
    void Function(LivreurNewRequestEvent event) onNewRequest,
  ) async {
    _onNewRequest = onNewRequest;
    await _poll();
    _timer ??= Timer.periodic(interval, (_) {
      unawaited(_poll());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final requests = await _repository.getAvailableRequests();
      final pendingRequests = requests
          .where((request) => request.status.toUpperCase() == 'PENDING')
          .toList();
      final nextIds = <String>{
        for (final request in pendingRequests) request.id,
      };

      if (_initialized) {
        for (final request in pendingRequests) {
          if (!_knownRequestIds.contains(request.id)) {
            _onNewRequest?.call(LivreurNewRequestEvent(request: request));
          }
        }
      }

      _knownRequestIds = nextIds;
      _initialized = true;
    } on Object {
      // Polling errors are ignored; next tick will retry.
    } finally {
      _isPolling = false;
    }
  }
}
