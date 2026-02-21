import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/client_orders_cubit.dart';
import 'package:sevenouti/client/cubit/client_orders_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/models.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/client/view/pages/gas_service_tracking_page.dart';
import 'package:sevenouti/client/view/pages/order_tracking_page.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/date_utils.dart' as app_date;

/// Page d'historique des commandes du client
class ClientOrdersPage extends StatelessWidget {
  const ClientOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientOrdersCubit(
        orderRepository: OrderRepository(ApiService()),
        gasServiceRepository: GasServiceRepository(ApiService()),
      )..loadOrders(), // Mode MOCK
      child: const ClientOrdersView(),
    );
  }
}

class ClientOrdersView extends StatelessWidget {
  const ClientOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: BlocBuilder<ClientOrdersCubit, ClientOrdersState>(
        builder: (context, state) {
          // Loading
          if (state is ClientOrdersInitial || state is ClientOrdersLoading) {
            return AppBackground(
              child: LoadingView(message: l10n.clientOrdersLoading),
            );
          }

          // Empty
          if (state is ClientOrdersEmpty) {
            return AppBackground(
              child: EmptyView(
                message: l10n.clientOrdersEmptyMessage,
                icon: Icons.shopping_bag_outlined,
                action: () {
                  // TODO: Navigate to home
                },
                actionLabel: l10n.clientOrdersSeeHanouts,
              ),
            );
          }

          // Error
          if (state is ClientOrdersError) {
            return AppBackground(
              child: ErrorView(
                message: state.message,
                onRetry: () => context.read<ClientOrdersCubit>().loadOrders(),
              ),
            );
          }

          // Loaded
          if (state is ClientOrdersLoaded) {
            return _buildLoadedView(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, ClientOrdersLoaded state) {
    final filteredGas = _filterGasRequests(state.gasRequests, state.filter);
    final filteredOrders = _filterOrders(
      state.orders,
      state.filter,
    );
    final combinedItems = <_UnifiedOrderItem>[
      ...filteredOrders.map(_UnifiedOrderItem.order),
      ...filteredGas.map(_UnifiedOrderItem.gas),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<ClientOrdersCubit>().refresh(),
        child: CustomScrollView(
          slivers: [
            // Header moderne
            SliverToBoxAdapter(
              child: _buildOrdersHeader(context, state),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _buildTypeFilters(context, state),
              ),
            ),

            // Liste unifiee des commandes (normales + gaz)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = combinedItems[index];
                    return item.order != null
                        ? _buildOrderCard(context, item.order!)
                        : _buildGasRequestCard(context, item.gasRequest!);
                  },
                  childCount: combinedItems.length,
                ),
              ),
            ),

            // Padding bottom
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilters(BuildContext context, ClientOrdersLoaded state) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            context: context,
            label: context.l10n.clientOrdersFilterAll,
            isSelected: state.filter == ClientOrdersFilter.all,
            count: state.orders.length + state.gasRequests.length,
            onTap: () {
              context.read<ClientOrdersCubit>().filterByType(
                ClientOrdersFilter.all,
              );
            },
          ),
          _buildFilterChip(
            context: context,
            label: context.l10n.clientOrdersFilterInProgress,
            isSelected: state.filter == ClientOrdersFilter.inProgress,
            count: _countInProgress(state),
            color: AppColors.warning,
            onTap: () {
              context.read<ClientOrdersCubit>().filterByType(
                ClientOrdersFilter.inProgress,
              );
            },
          ),
        ],
      ),
    );
  }

  int _countInProgress(ClientOrdersLoaded state) {
    final orders = _filterOrders(state.orders, ClientOrdersFilter.inProgress);
    final gas = _filterGasRequests(
      state.gasRequests,
      ClientOrdersFilter.inProgress,
    );
    return orders.length + gas.length;
  }

  List<OrderModel> _filterOrders(
    List<OrderModel> orders,
    ClientOrdersFilter filter,
  ) {
    if (filter == ClientOrdersFilter.all) return orders;
    return orders.where((order) {
      return order.status == OrderStatus.pending ||
          order.status == OrderStatus.accepted ||
          order.status == OrderStatus.preparing ||
          order.status == OrderStatus.ready ||
          order.status == OrderStatus.pickedUp ||
          order.status == OrderStatus.delivering;
    }).toList();
  }

  List<GasServiceOrder> _filterGasRequests(
    List<GasServiceOrder> requests,
    ClientOrdersFilter filter,
  ) {
    if (filter == ClientOrdersFilter.all) return requests;
    return requests.where((request) {
      return request.status == GasServiceStatus.pending ||
          request.status == GasServiceStatus.enRoute ||
          request.status == GasServiceStatus.arrive ||
          request.status == GasServiceStatus.recupereVide ||
          request.status == GasServiceStatus.vaAuHanout ||
          request.status == GasServiceStatus.retourMaison;
    }).toList();
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: chipColor.withOpacity(0.15),
        checkmarkColor: chipColor,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: isSelected ? chipColor : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? chipColor : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.round),
      ),
    );
  }

  /// Card d'une commande
  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: () => _navigateToTracking(context, order),
          borderRadius: AppRadius.large,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: NumÃ©ro + Statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // NumÃ©ro commande
                    Text(
                      context.l10n.clientOrdersOrderNumber(
                        _shortOrderId(order.id),
                      ),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Badge statut
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: AppRadius.round,
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        context.orderStatusLabel(order.status),
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Contenu de la commande
                Text(
                  order.freeTextOrder,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),

                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                // Infos: Date, Type, Montant
                Row(
                  children: [
                    // Date
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.access_time,
                        text: app_date.DateUtils.formatRelativeDate(
                          order.createdAt,
                        ),
                      ),
                    ),

                    // Type livraison
                    Expanded(
                      child: _buildInfoItem(
                        icon: order.deliveryType == DeliveryType.delivery
                            ? Icons.delivery_dining
                            : Icons.shopping_bag,
                        text: context.deliveryTypeLabel(order.deliveryType),
                      ),
                    ),

                    // Montant
                    if (order.totalAmount != null)
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.payments,
                          text: '${order.totalAmount!.toStringAsFixed(2)} DH',
                        ),
                      ),
                  ],
                ),

                // Actions rapides selon le statut
                if (_hasQuickActions(order)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildQuickActions(context, order),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersHeader(BuildContext context, ClientOrdersLoaded state) {
    final total = state.orders.length + state.gasRequests.length;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.card,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: AppRadius.large,
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.clientOrdersHeaderTitle,
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.clientOrdersHeaderCount(total),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGasRequestCard(
    BuildContext context,
    GasServiceOrder request,
  ) {
    final statusColor = request.status.color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: () => _navigateToGasTracking(context, request),
          borderRadius: AppRadius.large,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.clientGasBottleTitle,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: AppRadius.round,
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        context.gasStatusLabel(request.status),
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  request.clientAddress ??
                      context.l10n.clientOrdersClientAddressFallback,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.access_time,
                        text: app_date.DateUtils.formatRelativeDate(
                          request.createdAt,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.payments,
                        text: '${request.total.toStringAsFixed(0)} DH',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.track_changes,
                        text: context.l10n.clientOrdersTrack,
                      ),
                    ),
                  ],
                ),
                if (request.status == GasServiceStatus.livre) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _rateGasRequest(context, request),
                      icon: const Icon(Icons.star, size: 18),
                      label: Text(context.l10n.clientOrdersRateDriver),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  bool _hasQuickActions(OrderModel order) {
    // Actions disponibles pour: en cours ou livrÃ©es
    return order.status == OrderStatus.delivering ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.delivered;
  }

  Widget _buildQuickActions(BuildContext context, OrderModel order) {
    if (order.status == OrderStatus.delivered) {
      // Si livrÃ©e: Re-commander + Ã‰valuer
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _reorder(context, order),
              icon: const Icon(Icons.replay, size: 18),
              label: Text(context.l10n.clientOrdersReorder),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextButton.icon(
              onPressed: () => _rateOrder(context, order),
              icon: const Icon(Icons.star, size: 18),
              label: Text(context.l10n.clientOrdersRate),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.warning,
              ),
            ),
          ),
        ],
      );
    }

    // Si en cours: Suivre
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _navigateToTracking(context, order),
        icon: const Icon(Icons.track_changes, size: 18),
        label: Text(context.l10n.clientOrdersTrackOrder),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }

  // === Helper Methods ===

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return AppColors.info;
      case OrderStatus.preparing:
      case OrderStatus.ready:
      case OrderStatus.pickedUp:
      case OrderStatus.delivering:
        return AppColors.warning;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  void _navigateToTracking(BuildContext context, OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderTrackingPage(order: order),
      ),
    );
  }

  void _navigateToGasTracking(
    BuildContext context,
    GasServiceOrder request,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GasServiceTrackingPage(order: request),
      ),
    );
  }

  void _reorder(BuildContext context, OrderModel order) {
    // TODO: Navigate to hanout details with pre-filled order
    AppSnackBar.show(
      context,
      message: context.l10n.clientOrdersReorderSoon(order.freeTextOrder),
      type: SnackBarType.info,
    );
  }

  void _rateOrder(BuildContext context, OrderModel order) {
    var hanoutRating = 5;
    var livreurRating = 5;
    final hanoutCommentController = TextEditingController();
    final livreurCommentController = TextEditingController();
    final hasLivreur = order.livreurId != null;
    final repository = OrderRepository(ApiService());

    showAppBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            SheetTitle(context.l10n.clientOrdersRateOrderTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.clientOrdersHanoutRating,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  icon: Icon(
                    star <= hanoutRating ? Icons.star : Icons.star_border,
                  ),
                  color: AppColors.warning,
                  onPressed: () {
                    setSheetState(() {
                      hanoutRating = star;
                    });
                  },
                );
              }),
            ),
            TextField(
              controller: hanoutCommentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: context.l10n.clientOrdersHanoutCommentHint,
              ),
            ),
            if (hasLivreur) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.clientOrdersDriverRating,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: Icon(
                      star <= livreurRating ? Icons.star : Icons.star_border,
                    ),
                    color: AppColors.warning,
                    onPressed: () {
                      setSheetState(() {
                        livreurRating = star;
                      });
                    },
                  );
                }),
              ),
              TextField(
                controller: livreurCommentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: context.l10n.clientOrdersDriverCommentHint,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                try {
                  await repository.upsertOrderReview(
                    orderId: order.id,
                    hanoutRating: hanoutRating,
                    hanoutComment: hanoutCommentController.text.trim(),
                    livreurRating: hasLivreur ? livreurRating : null,
                    livreurComment: hasLivreur
                        ? livreurCommentController.text.trim()
                        : null,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    AppSnackBar.show(
                      context,
                      message: context.l10n.clientOrdersThanksReview,
                      type: SnackBarType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.show(
                      context,
                      message: context.l10n.clientCommonErrorWithMessage(
                        e.toString(),
                      ),
                      type: SnackBarType.error,
                    );
                  }
                }
              },
              child: Text(context.l10n.clientCommonSend),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.clientCommonClose),
            ),
          ],
        ),
      ),
    );
  }

  void _rateGasRequest(BuildContext context, GasServiceOrder request) {
    var livreurRating = 5;
    final commentController = TextEditingController();
    final repository = GasServiceRepository(ApiService());

    showAppBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            SheetTitle(context.l10n.clientOrdersRateDriverTitle),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  icon: Icon(
                    star <= livreurRating ? Icons.star : Icons.star_border,
                  ),
                  color: AppColors.warning,
                  onPressed: () {
                    setSheetState(() {
                      livreurRating = star;
                    });
                  },
                );
              }),
            ),
            TextField(
              controller: commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: context.l10n.clientOrdersDriverCommentHint,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () async {
                try {
                  await repository.upsertRequestReview(
                    requestId: request.id,
                    livreurRating: livreurRating,
                    livreurComment: commentController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    AppSnackBar.show(
                      context,
                      message: context.l10n.clientOrdersThanksReview,
                      type: SnackBarType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.show(
                      context,
                      message: context.l10n.clientCommonErrorWithMessage(
                        e.toString(),
                      ),
                      type: SnackBarType.error,
                    );
                  }
                }
              },
              child: Text(context.l10n.clientCommonSend),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.clientCommonClose),
            ),
          ],
        ),
      ),
    );
  }

  String _shortOrderId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }
}

class _UnifiedOrderItem {
  _UnifiedOrderItem.order(this.order)
    : gasRequest = null,
      createdAt = order!.createdAt;

  _UnifiedOrderItem.gas(this.gasRequest)
    : order = null,
      createdAt = gasRequest!.createdAt;

  final OrderModel? order;
  final GasServiceOrder? gasRequest;
  final DateTime createdAt;
}
