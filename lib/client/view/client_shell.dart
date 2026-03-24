import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/app/cubbit/app_cubbit.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/auth/cubbit/auth_state.dart';
import 'package:sevenouti/auth/models/user_role.dart';
import 'package:sevenouti/auth/view/login_page.dart';
import 'package:sevenouti/auth/view/register_page.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/client/view/pages/client_carnet_page.dart';
import 'package:sevenouti/client/view/pages/client_home_page.dart';
import 'package:sevenouti/client/view/pages/client_orders_page.dart';
import 'package:sevenouti/client/view/pages/client_settings_page.dart';
import 'package:sevenouti/client/widgets/client_feature_lock_view.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/realtime/realtime_event_service.dart';
import 'package:sevenouti/core/utils/legal_links.dart';
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
  RealtimeEventService? _realtimeService;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  bool _realtimeRunning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_syncRealtime());
  }

  @override
  void dispose() {
    unawaited(_stopRealtime());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticatedClient = _isAuthenticatedClient(authState);
    final l10n = context.l10n;
    final pages = _buildPages(context, isAuthenticatedClient);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: -15,
        title: const AppLogoHeader(height: 44, width: 156),
        actions: [
          if (!isAuthenticatedClient)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: TextButton(
                onPressed: _openLoginPage,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.18),
                    ),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                ),
                child: Text(
                  l10n.authLoginButton,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuSelection(value),
            itemBuilder: (context) {
              if (isAuthenticatedClient) {
                return [
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
                        Text(l10n.clientMenuLogout),
                      ],
                    ),
                  ),
                ];
              }

              return [
                PopupMenuItem(
                  value: 'switch_language',
                  child: Row(
                    children: [
                      const Icon(Icons.language),
                      const SizedBox(width: 8),
                      Text(_guestLanguageLabel(context)),
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
                  value: 'login',
                  child: Row(
                    children: [
                      const Icon(Icons.login),
                      const SizedBox(width: 8),
                      Text(l10n.clientGuestMenuLogin),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'register',
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded),
                      const SizedBox(width: 8),
                      Text(l10n.clientGuestMenuRegister),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
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
            icon: _navigationIcon(
              Icons.shopping_bag_outlined,
              isLocked: !isAuthenticatedClient,
            ),
            selectedIcon: _navigationIcon(
              Icons.shopping_bag,
              isLocked: !isAuthenticatedClient,
            ),
            label: l10n.clientOrdersTab,
          ),
          NavigationDestination(
            icon: _navigationIcon(
              Icons.book_outlined,
              isLocked: !isAuthenticatedClient,
            ),
            selectedIcon: _navigationIcon(
              Icons.book,
              isLocked: !isAuthenticatedClient,
            ),
            label: l10n.clientCarnetTab,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages(BuildContext context, bool isAuthenticatedClient) {
    final l10n = context.l10n;
    return [
      const ClientHomePage(),
      isAuthenticatedClient
          ? ClientOrdersPage(key: ValueKey(_ordersRefreshSeed))
          : ClientFeatureLockView(
              icon: Icons.shopping_bag_rounded,
              title: l10n.clientGuestOrdersLockedTitle,
              message: l10n.clientGuestOrdersLockedMessage,
              promptTitle: l10n.clientGuestOrdersPromptTitle,
              promptMessage: l10n.clientGuestOrdersPromptMessage,
              highlights: [
                l10n.clientGuestOrdersHighlightTrack,
                l10n.clientGuestOrdersHighlightReorder,
                l10n.clientGuestOrdersHighlightReviews,
              ],
            ),
      isAuthenticatedClient
          ? const ClientCarnetPage()
          : ClientFeatureLockView(
              icon: Icons.menu_book_rounded,
              title: l10n.clientGuestCarnetLockedTitle,
              message: l10n.clientGuestCarnetLockedMessage,
              promptTitle: l10n.clientGuestCarnetPromptTitle,
              promptMessage: l10n.clientGuestCarnetPromptMessage,
              highlights: [
                l10n.clientGuestCarnetHighlightBalances,
                l10n.clientGuestCarnetHighlightRequests,
                l10n.clientGuestCarnetHighlightTransactions,
              ],
            ),
    ];
  }

  Widget _navigationIcon(
    IconData icon, {
    required bool isLocked,
  }) {
    if (!isLocked) {
      return Icon(icon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        PositionedDirectional(
          end: -5,
          bottom: -3,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 12,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }

  bool _isAuthenticatedClient(AuthState state) {
    return state is Authenticated && state.role == UserRole.client;
  }

  Future<void> _handleMenuSelection(String value) async {
    if (value == 'settings') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const ClientSettingsPage(),
        ),
      );
      return;
    }

    if (value == 'logout') {
      await context.read<AuthCubit>().logout();
      return;
    }

    if (value == 'privacy') {
      final opened = await openPrivacyPolicy();
      if (!mounted || opened) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.commonLinkOpenError)),
      );
      return;
    }

    if (value == 'switch_language') {
      await _toggleGuestLanguage();
      return;
    }

    if (value == 'login') {
      await _openLoginPage();
      return;
    }

    if (value == 'register') {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const RegisterPage(closeOnAuthenticated: true),
        ),
      );
    }
  }

  Future<void> _syncRealtime() async {
    final shouldRun = _isAuthenticatedClient(context.read<AuthCubit>().state);
    if (shouldRun && !_realtimeRunning) {
      await _startRealtime();
      return;
    }

    if (!shouldRun && _realtimeRunning) {
      await _stopRealtime();
    }
  }

  Future<void> _startRealtime() async {
    _realtimeService = RealtimeEventService();
    _realtimeSubscription = _realtimeService!.events.listen(_onRealtimeEvent);
    _realtimeRunning = true;
    await _realtimeService!.start();
  }

  Future<void> _stopRealtime() async {
    _realtimeRunning = false;
    await _realtimeSubscription?.cancel();
    await _realtimeService?.dispose();
    _realtimeSubscription = null;
    _realtimeService = null;
  }

  String _shortOrderId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (!mounted || !_realtimeRunning) return;
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

  Future<void> _openLoginPage() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const LoginPage(closeOnAuthenticated: true),
      ),
    );
  }

  String _guestLanguageLabel(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'ar' ? 'Francais' : 'العربية';
  }

  Future<void> _toggleGuestLanguage() async {
    final appCubit = context.read<AppCubit>();
    final currentCode = appCubit.state.locale.languageCode;
    await appCubit.setLocale(
      Locale(currentCode == 'ar' ? 'fr' : 'ar'),
    );
  }
}
