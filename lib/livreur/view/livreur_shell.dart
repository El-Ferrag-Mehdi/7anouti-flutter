import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/realtime/realtime_event_service.dart';
import 'package:sevenouti/core/utils/legal_links.dart';
import 'package:sevenouti/core/widgets/app_logo_header.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/l10n/livreur_l10n.dart';
import 'package:sevenouti/livreur/view/pages/livreur_available_page.dart';
import 'package:sevenouti/livreur/view/pages/livreur_earnings_page.dart';
import 'package:sevenouti/livreur/view/pages/livreur_inprogress_page.dart';
import 'package:sevenouti/livreur/view/pages/livreur_settings_page.dart';

class LivreurShell extends StatefulWidget {
  const LivreurShell({super.key});

  @override
  State<LivreurShell> createState() => _LivreurShellState();
}

class _LivreurShellState extends State<LivreurShell> {
  int _currentIndex = 0;
  int _availableRefreshSeed = 0;
  int _inProgressRefreshSeed = 0;
  late final RealtimeEventService _realtimeService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

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
    final pages = <Widget>[
      LivreurAvailablePage(
        key: ValueKey(_availableRefreshSeed),
        onAccepted: _switchToInProgress,
      ),
      LivreurInProgressPage(key: ValueKey(_inProgressRefreshSeed)),
      const LivreurEarningsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: -15,
        title: const AppLogoHeader(height: 44, width: 136),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                unawaited(
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const LivreurSettingsPage(),
                    ),
                  ),
                );
                return;
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
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text(l10n.livreurMenuSettings),
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
                    Text(l10n.livreurMenuLogout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: l10n.livreurNavAvailable,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.delivery_dining),
            label: l10n.livreurNavInProgress,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.monetization_on),
            label: l10n.livreurNavEarnings,
          ),
        ],
      ),
    );
  }

  void _switchToInProgress() {
    if (!mounted) return;
    setState(() {
      _currentIndex = 1;
      _availableRefreshSeed++;
      _inProgressRefreshSeed++;
    });
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!mounted) return;
    if (!_isLivreurRelevantEvent(event.type)) return;

    final shouldSwitchToInProgress =
        event.type == 'ORDER_ASSIGNED' ||
        (event.type == 'DELIVERY_REQUEST_UPDATED' &&
            (event.payload['status']?.toString().toUpperCase() ==
                'ACCEPTED')) ||
        (event.type == 'GAS_REQUEST_STATUS_CHANGED' &&
            event.payload['status']?.toString().toUpperCase() == 'EN_ROUTE');

    setState(() {
      if (shouldSwitchToInProgress) {
        _currentIndex = 1;
      }
      _availableRefreshSeed++;
      _inProgressRefreshSeed++;
    });

    final message = _buildRealtimeMessage(event);
    if (message == null) return;

    unawaited(
      LocalNotificationService.instance.show(
        title: '7anouti Livreur',
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

  bool _isLivreurRelevantEvent(String type) {
    return type == 'DELIVERY_REQUEST_CREATED' ||
        type == 'DELIVERY_REQUEST_UPDATED' ||
        type == 'ORDER_ASSIGNED' ||
        type == 'ORDER_STATUS_CHANGED' ||
        type == 'GAS_REQUEST_CREATED' ||
        type == 'GAS_REQUEST_STATUS_CHANGED';
  }

  String? _buildRealtimeMessage(RealtimeEvent event) {
    final orderId = event.payload['orderId']?.toString() ?? '';
    final gasId = event.payload['gasRequestId']?.toString() ?? '';
    final shortId = _shortId(orderId.isNotEmpty ? orderId : gasId);

    switch (event.type) {
      case 'DELIVERY_REQUEST_CREATED':
        return shortId.isEmpty
            ? context.l10n.livreurAvailableTitle
            : '${context.l10n.livreurAvailableTitle}: #$shortId';
      case 'ORDER_ASSIGNED':
        return shortId.isEmpty
            ? context.l10n.livreurInProgressTitle
            : '${context.l10n.clientOrdersOrderNumber(shortId)}: '
                  '${context.l10n.livreurInProgressTitle}';
      case 'GAS_REQUEST_CREATED':
        return shortId.isEmpty
            ? context.l10n.livreurGasServiceTitle
            : '${context.l10n.clientGasBottleTitle} #$shortId: '
                  '${context.l10n.livreurGasServiceTitle}';
      case 'GAS_REQUEST_STATUS_CHANGED':
        final gasStatus = event.payload['status']?.toString();
        if (gasStatus == null || gasStatus.isEmpty) return null;
        final label = _gasStatusLabel(gasStatus);
        return shortId.isEmpty
            ? '${context.l10n.clientGasServiceTitle}: $label'
            : '${context.l10n.clientGasBottleTitle} #$shortId: $label';
      case 'ORDER_STATUS_CHANGED':
        final orderStatus = event.payload['status']?.toString();
        if (orderStatus == null || orderStatus.isEmpty) return null;
        final processingMode = OrderProcessingMode.fromString(
          event.payload['processingMode']?.toString(),
        );
        final label = _orderStatusLabel(orderStatus, processingMode);
        return shortId.isEmpty
            ? '${context.l10n.livreurHanoutOrdersTitle}: $label'
            : '${context.l10n.clientOrdersOrderNumber(shortId)}: $label';
      case 'DELIVERY_REQUEST_UPDATED':
        final requestStatus = event.payload['status']?.toString();
        if (requestStatus == null || requestStatus.isEmpty) return null;
        final label = context.livreurRequestStatusLabel(requestStatus);
        return shortId.isEmpty
            ? '${context.l10n.livreurAvailableTitle}: $label'
            : '${context.l10n.livreurAvailableTitle} #$shortId: $label';
      default:
        return null;
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await openPrivacyPolicy();
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonLinkOpenError)),
    );
  }

  String _shortId(String value) {
    if (value.length <= 8) return value;
    return value.substring(0, 8);
  }

  String _orderStatusLabel(
    String rawStatus,
    OrderProcessingMode processingMode,
  ) {
    final status = OrderStatus.fromString(rawStatus);
    return context.livreurOrderStatusLabel(
      status,
      processingMode: processingMode,
    );
  }

  String _gasStatusLabel(String rawStatus) {
    final status = GasServiceStatusX.fromString(rawStatus);
    return context.livreurGasStatusLabel(status);
  }
}
