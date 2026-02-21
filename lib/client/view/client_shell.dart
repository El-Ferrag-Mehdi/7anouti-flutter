import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/client/view/pages/client_carnet_page.dart';
import 'package:sevenouti/client/view/pages/client_home_page.dart';
import 'package:sevenouti/client/view/pages/client_orders_page.dart';
import 'package:sevenouti/client/view/pages/client_settings_page.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/notifications/polling_notification_watchers.dart';
import 'package:sevenouti/core/widgets/app_logo_header.dart';
import 'package:sevenouti/l10n/l10n.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;
  late final ClientOrderStatusWatcher _orderStatusWatcher;

  List<Widget> get _pages => [
    const ClientHomePage(),
    const ClientOrdersPage(),
    const ClientCarnetPage(),
  ];

  @override
  void initState() {
    super.initState();
    _orderStatusWatcher = ClientOrderStatusWatcher(
      repository: OrderRepository(ApiService()),
    );
    unawaited(
      _orderStatusWatcher.start((event) {
        if (!mounted) return;
        final shortId = _shortOrderId(event.orderId);
        final statusLabel = context.orderStatusLabel(event.newStatus);
        unawaited(
          LocalNotificationService.instance.show(
            title: '7anouti',
            body: 'Commande #$shortId: $statusLabel',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande #$shortId: $statusLabel'),
            duration: const Duration(seconds: 3),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _orderStatusWatcher.stop();
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

      body: _pages[_currentIndex],

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
}
