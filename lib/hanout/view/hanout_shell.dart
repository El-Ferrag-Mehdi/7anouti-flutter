import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/notifications/polling_notification_watchers.dart';
import 'package:sevenouti/core/widgets/app_logo_header.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';
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
  late final HanoutNotificationsWatcher _notificationsWatcher;

  final List<Widget> _pages = const [
    HanoutOrdersPage(),
    HanoutHistoryPage(),
    HanoutClientsPage(),
    HanoutCarnetPage(),
  ];

  @override
  void initState() {
    super.initState();
    _notificationsWatcher = HanoutNotificationsWatcher(
      repository: HanoutOrdersRepository(ApiService()),
    );
    unawaited(
      _notificationsWatcher.start(
        onNewOrder: (event) {
          if (!mounted) return;
          final shortId = _shortOrderId(event.orderId);
          final message =
              '${context.l10n.hanoutOrdersTitle}: '
              '${context.l10n.hanoutOrderNumber(shortId)}';
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
        },
        onDeliveryRequestUpdated: (event) {
          if (!mounted) return;
          final shortId = _shortOrderId(event.orderId);
          final statusLabel = context.livreurRequestStatusLabel(event.status);
          final message = 'Demande livreur #$shortId: $statusLabel';
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
        },
      ),
    );
  }

  @override
  void dispose() {
    _notificationsWatcher.stop();
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
      body: _pages[_currentIndex],
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
}
