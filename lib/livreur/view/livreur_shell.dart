import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/notifications/polling_notification_watchers.dart';
import 'package:sevenouti/core/widgets/app_logo_header.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';
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
  late final LivreurRequestsWatcher _requestsWatcher;

  final List<Widget> _pages = const [
    LivreurAvailablePage(),
    LivreurInProgressPage(),
    LivreurEarningsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _requestsWatcher = LivreurRequestsWatcher(
      repository: LivreurRequestsRepository(ApiService()),
    );
    unawaited(
      _requestsWatcher.start((event) {
        if (!mounted) return;
        final request = event.request;
        final title =
            request.hanout?.name ?? context.l10n.clientGasServiceTitle;
        final message = '${context.l10n.livreurAvailableTitle}: $title';
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
      }),
    );
  }

  @override
  void dispose() {
    _requestsWatcher.stop();
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
      body: _pages[_currentIndex],
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
}
