import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/client/view/pages/client_carnet_page.dart';
import 'package:sevenouti/client/view/pages/client_home_page.dart';
import 'package:sevenouti/client/view/pages/client_orders_page.dart';
import 'package:sevenouti/client/view/pages/client_settings_page.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/realtime/realtime_event_service.dart';
import 'package:sevenouti/core/widgets/app_logo_header.dart';
import 'package:sevenouti/l10n/l10n.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;
  int _ordersRefreshSeed = 0;
  late final RealtimeEventService _realtimeService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  List<Widget> get _pages => [
    const ClientHomePage(),
    ClientOrdersPage(key: ValueKey(_ordersRefreshSeed)),
    const ClientCarnetPage(),
  ];

  @override
  void initState() {
    super.initState();
    _realtimeService = RealtimeEventService();
    _realtimeSubscription = _realtimeService.events.listen(_onRealtimeEvent);
    unawaited(_realtimeService.start());
  }

  @override
  void dispose() {
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_realtimeService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: -15,
        title: const AppLogoHeader(height: 44, width: 156),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                unawaited(
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const ClientSettingsPage(),
                    ),
                  ),
                );
                return;
              }

              if (value == 'logout') {
                unawaited(context.read<AuthCubit>().logout());
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text(l10n.clientMenuSettings),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.clientMenuLogout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.clientHomeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_bag_outlined),
            selectedIcon: const Icon(Icons.shopping_bag),
            label: l10n.clientOrdersTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: l10n.clientCarnetTab,
          ),
        ],
      ),
    );
  }

  String _shortOrderId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!mounted) return;
    if (!_isClientRelevantEvent(event.type)) return;

    final shortId = _shortOrderId(
      event.payload['orderId']?.toString() ??
          event.payload['gasRequestId']?.toString() ??
          '',
    );
    final body = _buildRealtimeMessage(event, shortId);
    if (body == null) return;

    setState(() {
      _ordersRefreshSeed++;
    });

    unawaited(
      LocalNotificationService.instance.show(
        title: '7anouti',
        body: body,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(body),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _isClientRelevantEvent(String type) {
    return type == 'ORDER_STATUS_CHANGED' ||
        type == 'ORDER_DRIVER_ASSIGNED' ||
        type == 'DELIVERY_REQUEST_UPDATED' ||
        type == 'GAS_REQUEST_CREATED' ||
        type == 'GAS_REQUEST_STATUS_CHANGED';
  }

  String? _buildRealtimeMessage(RealtimeEvent event, String shortId) {
    switch (event.type) {
      case 'ORDER_STATUS_CHANGED':
        final status = event.payload['status']?.toString();
        if (status == null) return null;
        if (shortId.isEmpty) {
          return '${context.l10n.clientOrdersTab}: ${_statusLabel(status)}';
        }
        return '${context.l10n.clientOrdersOrderNumber(shortId)}: '
            '${_statusLabel(status)}';
      case 'ORDER_DRIVER_ASSIGNED':
        final label = context.l10n.hanoutOrdersDriverAssigned;
        if (shortId.isEmpty) return label;
        return '${context.l10n.clientOrdersOrderNumber(shortId)}: $label';
      case 'GAS_REQUEST_STATUS_CHANGED':
        final status = event.payload['status']?.toString() ?? '';
        final statusLabel = _gasStatusLabel(status);
        if (shortId.isEmpty) {
          return '${context.l10n.clientGasServiceTitle}: $statusLabel';
        }
        return '${context.l10n.clientGasBottleTitle} #$shortId: $statusLabel';
      case 'DELIVERY_REQUEST_UPDATED':
        final status = event.payload['status']?.toString();
        if (status == null || status.isEmpty) return null;
        final statusLabel = _deliveryRequestStatusLabel(status);
        return shortId.isEmpty
            ? '${context.l10n.livreurAvailableTitle}: $statusLabel'
            : '${context.l10n.livreurAvailableTitle} #$shortId: $statusLabel';
      case 'GAS_REQUEST_CREATED':
        return shortId.isEmpty
            ? context.l10n.clientGasServiceTitle
            : '${context.l10n.clientGasServiceTitle} #$shortId';
      default:
        return null;
    }
  }

  String _statusLabel(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'PENDING':
        return context.orderStatusLabel(OrderStatus.pending);
      case 'ACCEPTED':
        return context.orderStatusLabel(OrderStatus.accepted);
      case 'READY':
        return context.orderStatusLabel(OrderStatus.ready);
      case 'PICKED_UP':
        return context.orderStatusLabel(OrderStatus.pickedUp);
      case 'DELIVERING':
        return context.orderStatusLabel(OrderStatus.delivering);
      case 'DELIVERED':
        return context.orderStatusLabel(OrderStatus.delivered);
      case 'CANCELLED':
        return context.orderStatusLabel(OrderStatus.cancelled);
      default:
        return rawStatus;
    }
  }

  String _deliveryRequestStatusLabel(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'ACCEPTED':
        return context.l10n.livreurRequestStatusAccepted;
      case 'REJECTED':
        return context.l10n.livreurRequestStatusRejected;
      case 'PENDING':
      default:
        return context.l10n.livreurRequestStatusPending;
    }
  }

  String _gasStatusLabel(String rawStatus) {
    final status = GasServiceStatusX.fromString(rawStatus);
    return context.gasStatusLabel(status);
  }
}
