import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/hanout/cubbit/hanout_orders_cubit.dart';
import 'package:sevenouti/hanout/cubbit/hanout_orders_state.dart';
import 'package:sevenouti/hanout/l10n/hanout_l10n.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';
import 'package:sevenouti/hanout/view/pages/hanout_order_details_page.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/localized_formatters.dart';

class HanoutOrdersPage extends StatelessWidget {
  const HanoutOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HanoutOrdersCubit(
        ordersRepository: HanoutOrdersRepository(ApiService()),
      )..loadOrders(),
      child: const HanoutOrdersView(),
    );
  }
}

class HanoutOrdersView extends StatelessWidget {
  const HanoutOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HanoutOrdersCubit, HanoutOrdersState>(
      builder: (context, state) {
        if (state is HanoutOrdersInitial || state is HanoutOrdersLoading) {
          return AppBackground(
            child: LoadingView(message: l10n.hanoutOrdersLoading),
          );
        }

        if (state is HanoutOrdersEmpty) {
          return AppBackground(
            child: EmptyView(
              message: l10n.hanoutOrdersEmpty,
              icon: Icons.receipt_long,
            ),
          );
        }

        if (state is HanoutOrdersError) {
          return AppBackground(
            child: ErrorView(
              message: state.message,
              onRetry: () => context.read<HanoutOrdersCubit>().loadOrders(),
            ),
          );
        }

        if (state is HanoutOrdersLoaded) {
          return _buildLoaded(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoaded(BuildContext context, HanoutOrdersLoaded state) {
    final l10n = context.l10n;
    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<HanoutOrdersCubit>().refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildOrdersHeader(context, state),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: _buildStatusFilters(context, state),
              ),
            ),
            if (state.activeFilteredOrders.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: EmptyView(
                    message: l10n.hanoutOrdersNoActive,
                    icon: Icons.hourglass_empty,
                  ),
                ),
              ),
            if (state.activeFilteredOrders.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = state.activeFilteredOrders[index];
                      return _buildOrderCard(context, order);
                    },
                    childCount: state.activeFilteredOrders.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersHeader(BuildContext context, HanoutOrdersLoaded state) {
    final l10n = context.l10n;
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
                Icons.receipt_long,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.hanoutOrdersTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    l10n.hanoutOrdersTotalCount(state.orders.length),
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

  Widget _buildStatusFilters(BuildContext context, HanoutOrdersLoaded state) {
    final l10n = context.l10n;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            context: context,
            label: l10n.hanoutOrdersFilterAll,
            isSelected: state.selectedStatus == null,
            count: state.activeOrders.length,
            onTap: () => context.read<HanoutOrdersCubit>().filterByStatus(null),
          ),
          _buildFilterChip(
            context: context,
            label: l10n.hanoutOrdersFilterPending,
            isSelected: state.selectedStatus == OrderStatus.pending,
            count: state.activeStatusCounts[OrderStatus.pending] ?? 0,
            color: AppColors.info,
            onTap: () => context.read<HanoutOrdersCubit>().filterByStatus(
              OrderStatus.pending,
            ),
          ),
          _buildFilterChip(
            context: context,
            label: l10n.hanoutOrdersFilterAccepted,
            isSelected: state.selectedStatus == OrderStatus.accepted,
            count: state.activeStatusCounts[OrderStatus.accepted] ?? 0,
            color: AppColors.primary,
            onTap: () => context.read<HanoutOrdersCubit>().filterByStatus(
              OrderStatus.accepted,
            ),
          ),
          _buildFilterChip(
            context: context,
            label: l10n.hanoutOrdersFilterReady,
            isSelected: state.selectedStatus == OrderStatus.ready,
            count: state.activeStatusCounts[OrderStatus.ready] ?? 0,
            color: AppColors.warning,
            onTap: () => context.read<HanoutOrdersCubit>().filterByStatus(
              OrderStatus.ready,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildOrderCard(BuildContext context, HanoutOrderModel order) {
    final l10n = context.l10n;
    final statusColor = _getStatusColor(order.status);
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clientName =
        order.client?.displayName(preferArabic: preferArabic) ??
        l10n.hanoutCommonClient;

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
          onTap: () => _openDetails(context, order),
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
                      l10n.hanoutOrderNumber(_shortOrderId(order.id)),
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
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        context.hanoutOrderStatusLabel(order.status),
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
                  clientName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if ((order.client?.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    order.client!.phone,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  order.freeTextOrder,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.access_time,
                        text: formatRelativeDateLocalized(
                          context,
                          order.createdAt,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: order.deliveryType == DeliveryType.delivery
                            ? Icons.delivery_dining
                            : Icons.shopping_bag,
                        text: context.hanoutDeliveryTypeLabel(
                          order.deliveryType,
                        ),
                      ),
                    ),
                    if (order.totalAmount != null)
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.payments,
                          text: formatDh(context, order.totalAmount!),
                        ),
                      ),
                  ],
                ),
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

  bool _hasQuickActions(HanoutOrderModel order) {
    return order.status == OrderStatus.pending ||
        order.status == OrderStatus.accepted ||
        order.status == OrderStatus.ready ||
        (order.status == OrderStatus.delivering &&
            order.deliveryType == DeliveryType.delivery &&
            order.livreurId == null);
  }

  Widget _buildQuickActions(BuildContext context, HanoutOrderModel order) {
    final l10n = context.l10n;
    final cubit = context.read<HanoutOrdersCubit>();

    if (order.status == OrderStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showAcceptDialog(context, cubit, order),
          icon: const Icon(Icons.check),
          label: Text(l10n.hanoutOrdersActionAccept),
        ),
      );
    }

    if (order.status == OrderStatus.accepted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _setOrderReadyWithRequiredTotal(
            context,
            cubit,
            order,
          ),
          icon: const Icon(Icons.inventory_2),
          label: Text(l10n.hanoutOrdersActionReady),
        ),
      );
    }

    if (order.status == OrderStatus.ready) {
      if (order.deliveryType == DeliveryType.delivery) {
        if (order.livreurId != null) {
          return Row(
            children: [
              const Icon(Icons.delivery_dining, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.hanoutOrdersDriverAssigned,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }
        if (order.latestDeliveryRequestStatus == 'PENDING') {
          return Row(
            children: [
              const Icon(Icons.hourglass_top, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.hanoutOrdersDeliveryRequestSent,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmRequestLivreur(context, cubit, order),
                icon: const Icon(Icons.delivery_dining),
                label: Text(l10n.hanoutOrdersActionAskDriver),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => cubit.updateStatus(
                  order.id,
                  status: OrderStatus.delivering,
                ),
                icon: const Icon(Icons.local_shipping),
                label: Text(l10n.hanoutOrdersActionStartInternal),
              ),
            ),
          ],
        );
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => cubit.updateStatus(
            order.id,
            status: OrderStatus.delivered,
          ),
          icon: const Icon(Icons.check_circle),
          label: Text(l10n.hanoutOrdersActionMarkDelivered),
        ),
      );
    }

    if (order.status == OrderStatus.delivering &&
        order.deliveryType == DeliveryType.delivery &&
        order.livreurId == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => cubit.updateStatus(
            order.id,
            status: OrderStatus.delivered,
          ),
          icon: const Icon(Icons.check_circle),
          label: Text(l10n.hanoutOrdersActionDeliveredInternal),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _openDetails(BuildContext context, HanoutOrderModel order) {
    final cubit = context.read<HanoutOrdersCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: HanoutOrderDetailsPage(order: order),
        ),
      ),
    );
  }

  Future<void> _showAcceptDialog(
    BuildContext context,
    HanoutOrdersCubit cubit,
    HanoutOrderModel order,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showAppBottomSheet<Map<String, dynamic>>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(l10n.hanoutOrdersAcceptDialogTitle),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.hanoutOrdersTotalOptional,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.clientCommonCancel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    final parsed = value.isEmpty
                        ? null
                        : double.tryParse(value);
                    Navigator.of(context).pop({'amount': parsed});
                  },
                  child: Text(l10n.hanoutCommonValidate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (result == null) return;
    await cubit.acceptOrder(order.id, totalAmount: result['amount'] as double?);
  }

  Future<void> _setOrderReadyWithRequiredTotal(
    BuildContext context,
    HanoutOrdersCubit cubit,
    HanoutOrderModel order,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: order.totalAmount?.toStringAsFixed(2) ?? '',
    );
    final amount = await showAppBottomSheet<double>(
      context: context,
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final parsed = double.tryParse(
            controller.text.trim().replaceAll(',', '.'),
          );
          final canSubmit = parsed != null && parsed > 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpacing.lg),
              SheetTitle(l10n.hanoutOrdersEditTotalDialogTitle),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: (_) => setSheetState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.hanoutOrdersTotalRequired,
                  helperText: l10n.hanoutOrdersReadyRequiresTotal,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(l10n.clientCommonCancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canSubmit
                          ? () => Navigator.of(sheetContext).pop(parsed)
                          : null,
                      child: Text(l10n.hanoutCommonValidate),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (amount != null && amount > 0) {
      await cubit.updateStatus(
        order.id,
        status: OrderStatus.ready,
        totalAmount: amount,
      );
    }
  }

  Future<void> _confirmRequestLivreur(
    BuildContext context,
    HanoutOrdersCubit cubit,
    HanoutOrderModel order,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(l10n.hanoutOrdersRequestDriverDialogTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.hanoutOrdersRequestDriverDialogBody,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.clientCommonCancel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.clientCommonConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.requestLivreur(order.id);
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return AppColors.info;
      case OrderStatus.ready:
      case OrderStatus.pickedUp:
      case OrderStatus.delivering:
      case OrderStatus.preparing:
        return AppColors.warning;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _shortOrderId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }
}
