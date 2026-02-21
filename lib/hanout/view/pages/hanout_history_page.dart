import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/hanout/cubbit/hanout_orders_cubit.dart';
import 'package:sevenouti/hanout/cubbit/hanout_orders_state.dart';
import 'package:sevenouti/hanout/l10n/hanout_l10n.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/localized_formatters.dart';

class HanoutHistoryPage extends StatelessWidget {
  const HanoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HanoutOrdersCubit(
        ordersRepository: HanoutOrdersRepository(ApiService()),
      )..loadOrders(),
      child: const HanoutHistoryView(),
    );
  }
}

class HanoutHistoryView extends StatelessWidget {
  const HanoutHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HanoutOrdersCubit, HanoutOrdersState>(
      builder: (context, state) {
        if (state is HanoutOrdersInitial || state is HanoutOrdersLoading) {
          return AppBackground(
            child: LoadingView(message: l10n.hanoutHistoryLoading),
          );
        }

        if (state is HanoutOrdersEmpty) {
          return AppBackground(
            child: EmptyView(
              message: l10n.hanoutHistoryEmpty,
              icon: Icons.history,
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
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: _buildHeader(context, state),
              ),
            ),
            if (state.historyOrders.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(l10n.hanoutHistoryNoData),
                  ),
                ),
              ),
            if (state.historyOrders.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = state.historyOrders[index];
                      return _buildHistoryOrderCard(context, order);
                    },
                    childCount: state.historyOrders.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HanoutOrdersLoaded state) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: AppRadius.medium,
              ),
              child: const Icon(
                Icons.history,
                color: AppColors.secondary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.hanoutHistoryTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    l10n.hanoutHistoryCount(state.historyOrders.length),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: l10n.hanoutHistoryStatTotal,
                value: '${state.orders.length}',
                icon: Icons.receipt_long,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                label: l10n.hanoutHistoryStatDelivered,
                value: '${state.deliveredCount}',
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: l10n.hanoutHistoryStatCancelled,
                value: '${state.cancelledCount}',
                icon: Icons.cancel,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                label: l10n.hanoutHistoryStatRevenue,
                value: formatDh(context, state.deliveredRevenue),
                icon: Icons.payments,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: AppRadius.medium,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOrderCard(BuildContext context, HanoutOrderModel order) {
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
                    text: formatRelativeDateLocalized(context, order.createdAt),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: order.deliveryType == DeliveryType.delivery
                        ? Icons.delivery_dining
                        : Icons.shopping_bag,
                    text: context.hanoutDeliveryTypeLabel(order.deliveryType),
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
          ],
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
