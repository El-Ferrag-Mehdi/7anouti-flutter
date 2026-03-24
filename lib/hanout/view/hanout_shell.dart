import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/realtime/realtime_event_service.dart';
import 'package:sevenouti/core/utils/legal_links.dart';
import 'package:sevenouti/core/widgets/app_logo_header.dart';
import 'package:sevenouti/hanout/l10n/hanout_l10n.dart';
import 'package:sevenouti/hanout/view/pages/hanout_carnet_page.dart';
import 'package:sevenouti/hanout/view/pages/hanout_clients_page.dart';
import 'package:sevenouti/hanout/view/pages/hanout_history_page.dart';
import 'package:sevenouti/hanout/view/pages/hanout_orders_page.dart';
import 'package:sevenouti/hanout/view/pages/hanout_settings_page.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/l10n/livreur_l10n.dart';

class HanoutShell extends StatefulWidget {
  const HanoutShell({super.key});

  @override
  State<HanoutShell> createState() => _HanoutShellState();
}

class _HanoutShellState extends State<HanoutShell> {
  int _currentIndex = 0;
  int _ordersRefreshSeed = 0;
  late final RealtimeEventService _realtimeService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  List<Widget> get _pages => [
    HanoutOrdersPage(key: ValueKey(_ordersRefreshSeed)),
    const HanoutHistoryPage(),
    const HanoutClientsPage(),
    const HanoutCarnetPage(),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(LocalNotificationService.instance.requestPermissionsIfNeeded());
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
        title: const AppLogoHeader(height: 44, width: 136),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HanoutSettingsPage(),
                    ),
                  ),
                );
              }
              if (value == 'logout') {
                unawaited(context.read<AuthCubit>().logout());
                return;
              }
              if (value == 'privacy') {
                unawaited(_openPrivacyPolicy(context));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text(l10n.hanoutMenuSettings),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined),
                    const SizedBox(width: 8),
                    Text(l10n.commonPrivacyPolicy),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.hanoutMenuLogout),
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
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.hanoutNavOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.hanoutNavHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.hanoutNavClients,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: l10n.hanoutNavCarnet,
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
    if (!_isHanoutRelevantEvent(event.type)) return;

    setState(() {
      _ordersRefreshSeed++;
    });

    final shortId = _shortOrderId(event.payload['orderId']?.toString() ?? '');
    final message = _buildRealtimeMessage(event, shortId);
    if (message == null) return;

    unawaited(
      LocalNotificationService.instance.show(
        title: '7anouti Hanout',
        body: message,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _isHanoutRelevantEvent(String type) {
    return type == 'NEW_ORDER' ||
        type == 'ORDER_STATUS_CHANGED' ||
        type == 'ORDER_DRIVER_ASSIGNED' ||
        type == 'DELIVERY_REQUEST_CREATED' ||
        type == 'DELIVERY_REQUEST_UPDATED';
  }

  String? _buildRealtimeMessage(RealtimeEvent event, String shortId) {
    switch (event.type) {
      case 'NEW_ORDER':
        final title = context.l10n.hanoutOrdersTitle;
        final orderLabel = context.l10n.hanoutOrderNumber(shortId);
        return '$title: $orderLabel';
      case 'DELIVERY_REQUEST_UPDATED':
        final status = event.payload['status']?.toString() ?? '';
        final statusLabel = context.livreurRequestStatusLabel(status);
        return shortId.isEmpty
            ? '${context.l10n.livreurAvailableTitle}: $statusLabel'
            : '${context.l10n.livreurAvailableTitle} #$shortId: $statusLabel';
      case 'ORDER_STATUS_CHANGED':
        final status = event.payload['status']?.toString();
        if (status == null || status.isEmpty) return null;
        final orderLabel = _orderStatusLabel(status);
        if (shortId.isEmpty) {
          return '${context.l10n.hanoutNavOrders}: $orderLabel';
        }
        return '${context.l10n.hanoutOrderNumber(shortId)}: $orderLabel';
      case 'ORDER_DRIVER_ASSIGNED':
        final label = context.l10n.hanoutOrdersDriverAssigned;
        if (shortId.isEmpty) return label;
        return '${context.l10n.hanoutOrderNumber(shortId)}: $label';
      case 'DELIVERY_REQUEST_CREATED':
        return shortId.isEmpty
            ? context.l10n.livreurAvailableTitle
            : '${context.l10n.livreurAvailableTitle} #$shortId';
      default:
        return null;
    }
  }

  String _orderStatusLabel(String rawStatus) {
    final status = OrderStatus.fromString(rawStatus);
    return context.hanoutOrderStatusLabel(status);
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await openPrivacyPolicy();
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonLinkOpenError)),
    );
  }
}
