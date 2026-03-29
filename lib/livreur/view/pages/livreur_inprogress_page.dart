import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/distance_pill.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/cubbit/livreur_inprogress_cubit.dart';
import 'package:sevenouti/livreur/cubbit/livreur_inprogress_state.dart';
import 'package:sevenouti/livreur/l10n/livreur_l10n.dart';
import 'package:sevenouti/livreur/models/livreur_order_model.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';
import 'package:sevenouti/livreur/view/pages/livreur_inprogress_gas_details_page.dart';
import 'package:sevenouti/livreur/view/pages/livreur_inprogress_order_details_page.dart';
import 'package:sevenouti/utils/localized_formatters.dart';
import 'package:sevenouti/utils/map_launcher.dart';
import 'package:sevenouti/utils/phone_launcher.dart';

class LivreurInProgressPage extends StatelessWidget {
  const LivreurInProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LivreurInProgressCubit(
        repository: LivreurOrdersRepository(ApiService()),
        gasRepository: GasServiceLivreurRepository(ApiService()),
      )..loadOrders(),
      child: const LivreurInProgressView(),
    );
  }
}

class LivreurInProgressView extends StatelessWidget {
  const LivreurInProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LivreurInProgressCubit, LivreurInProgressState>(
      builder: (context, state) {
        if (state is LivreurInProgressInitial ||
            state is LivreurInProgressLoading) {
          return AppBackground(
            child: LoadingView(message: l10n.livreurInProgressLoading),
          );
        }

        if (state is LivreurInProgressEmpty) {
          return AppBackground(
            child: EmptyView(
              message: l10n.livreurInProgressEmpty,
              icon: Icons.delivery_dining,
            ),
          );
        }

        if (state is LivreurInProgressError) {
          return AppBackground(
            child: ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<LivreurInProgressCubit>().loadOrders(),
            ),
          );
        }

        if (state is LivreurInProgressLoaded) {
          return _buildLoaded(context, state.orders, state.gasRequests);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    List<LivreurOrderModel> orders,
    List<GasServiceOrder> gasRequests,
  ) {
    final l10n = context.l10n;
    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<LivreurInProgressCubit>().loadOrders(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, orders.length, gasRequests.length),
            ),
            if (gasRequests.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Text(
                    l10n.livreurGasServiceTitle,
                    style: AppTextStyles.h3,
                  ),
                ),
              ),
            if (gasRequests.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final request = gasRequests[index];
                      return _buildGasCard(context, request);
                    },
                    childCount: gasRequests.length,
                  ),
                ),
              ),
            if (gasRequests.isNotEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.lg),
              ),
            if (orders.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Text(
                    l10n.livreurHanoutOrdersTitle,
                    style: AppTextStyles.h3,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order);
                  },
                  childCount: orders.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, LivreurOrderModel order) {
    final l10n = context.l10n;
    final cubit = context.read<LivreurInProgressCubit>();

    if (order.isDirectLivreurFlow && order.status == OrderStatus.accepted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(
            context,
            cubit,
            order.id,
            OrderStatus.ready,
          ),
          icon: const Icon(Icons.delivery_dining),
          label: Text(l10n.livreurActionOnWay),
        ),
      );
    }

    if (order.isDirectLivreurFlow && order.status == OrderStatus.ready) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showPickupAmountSheet(context, order, cubit),
          icon: const Icon(Icons.inventory_2),
          label: Text(l10n.livreurActionPickedUp),
        ),
      );
    }

    if (order.status == OrderStatus.ready) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(
            context,
            cubit,
            order.id,
            OrderStatus.pickedUp,
          ),
          icon: const Icon(Icons.inventory_2),
          label: Text(l10n.livreurActionPickedUp),
        ),
      );
    }

    if (order.status == OrderStatus.pickedUp) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(
            context,
            cubit,
            order.id,
            OrderStatus.delivering,
          ),
          icon: const Icon(Icons.delivery_dining),
          label: Text(l10n.livreurActionDelivering),
        ),
      );
    }

    if (order.status == OrderStatus.delivering) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(
            context,
            cubit,
            order.id,
            OrderStatus.delivered,
          ),
          icon: const Icon(Icons.check_circle),
          label: Text(l10n.livreurActionDelivered),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _showPickupAmountSheet(
    BuildContext context,
    LivreurOrderModel order,
    LivreurInProgressCubit cubit,
  ) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DirectPickupAmountSheet(
        initialAmount: order.totalAmount,
      ),
    );

    if (amount == null || amount <= 0) return;
    if (!context.mounted) return;

    await _updateOrderStatus(
      context,
      cubit,
      order.id,
      OrderStatus.pickedUp,
      totalAmount: amount,
    );
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    LivreurInProgressCubit cubit,
    String orderId,
    OrderStatus status, {
    double? totalAmount,
  }) async {
    try {
      await cubit.updateStatus(orderId, status, totalAmount: totalAmount);
    } on ApiException catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: error.message,
        type: SnackBarType.error,
      );
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: error.toString(),
        type: SnackBarType.error,
      );
    }
  }

  Widget _buildHeader(BuildContext context, int orderCount, int gasCount) {
    final l10n = context.l10n;
    final total = orderCount + gasCount;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
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
                Icons.delivery_dining,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.livreurInProgressTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    l10n.livreurInProgressCount(total),
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

  Widget _buildOrderCard(BuildContext context, LivreurOrderModel order) {
    final l10n = context.l10n;
    final hanout = order.hanout;
    final client = order.client;
    final statusColor = _statusColor(order.status);
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final localizedClientAddress = order.displayClientAddress(
      preferArabic: preferArabic,
    );
    final missionColor = order.isDirectLivreurFlow
        ? AppColors.secondary
        : AppColors.info;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hanout?.name ?? l10n.clientOrderTrackingHanout,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusChip(
                    label: context.livreurOrderStatusLabel(
                      order.status,
                      processingMode: order.processingMode,
                    ),
                    color: statusColor,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _statusChip(
                    label: order.isDirectLivreurFlow
                        ? l10n.livreurAvailableDirectBadge
                        : l10n.livreurAvailableHanoutBadge,
                    color: missionColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order.isDirectLivreurFlow
                ? l10n.livreurAvailableDirectHint
                : l10n.livreurAvailableHanoutHint,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            order.freeTextOrder,
            style: AppTextStyles.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _infoPill(
                icon: Icons.person,
                text:
                    client?.displayName(preferArabic: preferArabic) ??
                    l10n.livreurClientFallback,
              ),
              _infoPill(
                icon: Icons.storefront,
                text: formatAddressLocalized(context, hanout?.address),
              ),
              _infoPill(
                icon: Icons.place,
                text: formatAddressLocalized(
                  context,
                  localizedClientAddress ?? l10n.livreurClientAddressFallback,
                ),
              ),
              _infoPill(
                icon: Icons.local_shipping,
                text: context.livreurDeliveryTypeLabel(order.deliveryType),
              ),
              _infoPill(
                icon: Icons.credit_card,
                text: context.paymentMethodLabel(order.paymentMethod),
              ),
              _infoPill(
                icon: Icons.access_time,
                text: formatRelativeDateLocalized(context, order.createdAt),
              ),
              if (order.hanoutDistance != null)
                _infoPill(
                  icon: Icons.near_me,
                  text:
                      '${l10n.livreurAvailableHanoutDistanceLabel}: ${_formatDistance(order.hanoutDistance)}',
                ),
              if (order.clientDistance != null)
                _infoPill(
                  icon: Icons.home_work_outlined,
                  text:
                      '${l10n.livreurAvailableClientDistanceLabel}: ${_formatDistance(order.clientDistance)}',
                ),
              CurrentDistancePill(
                targetLatitude: order.clientLatitude,
                targetLongitude: order.clientLongitude,
              ),
              if (order.notes != null && order.notes!.isNotEmpty)
                _infoPill(
                  icon: Icons.home,
                  text: order.notes!,
                ),
              if (order.totalAmount != null)
                _infoPill(
                  icon: Icons.payments,
                  text: formatDh(context, order.totalAmount!),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openOrderDetails(context, order),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.livreurAvailableViewDetails),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (client?.phone != null && client!.phone.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchPhoneCall(client.phone),
                icon: const Icon(Icons.phone),
                label: Text(l10n.livreurCallClient),
              ),
            ),
          ],
          _buildActions(context, order),
        ],
      ),
    );
  }

  Future<void> _openOrderDetails(
    BuildContext context,
    LivreurOrderModel order,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<LivreurInProgressCubit>(),
          child: LivreurInProgressOrderDetailsPage(order: order),
        ),
      ),
    );
  }

  Widget _buildGasCard(BuildContext context, GasServiceOrder request) {
    final l10n = context.l10n;
    final cubit = context.read<LivreurInProgressCubit>();
    final statusColor = request.status.color;
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clientName = request.displayClientName(preferArabic: preferArabic);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.livreurGasServiceTitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _statusChip(
                label: context.livreurGasStatusLabel(request.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatAddressLocalized(
              context,
              request.clientAddress ?? l10n.livreurClientAddressFallback,
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_hasGasLocation(request))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => launchMaps(
                  latitude: request.clientLatitude,
                  longitude: request.clientLongitude,
                  address: request.clientAddress,
                ),
                icon: const Icon(Icons.map),
                label: Text(l10n.livreurOpenMaps),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _infoPill(
                icon: Icons.person,
                text: clientName.isEmpty
                    ? l10n.livreurClientFallback
                    : clientName,
              ),
              _infoPill(
                icon: Icons.local_fire_department,
                text: l10n.clientGasBottleTitle,
              ),
              _infoPill(
                icon: Icons.access_time,
                text: formatRelativeDateLocalized(context, request.createdAt),
              ),
              _infoPill(
                icon: Icons.payments,
                text: formatDh(context, request.total, decimals: 0),
              ),
              CurrentDistancePill(
                targetLatitude: request.clientLatitude,
                targetLongitude: request.clientLongitude,
              ),
              if (request.notes != null && request.notes!.isNotEmpty)
                _infoPill(
                  icon: Icons.home,
                  text: request.notes!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (request.clientPhone != null &&
              request.clientPhone!.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchPhoneCall(request.clientPhone!),
                icon: const Icon(Icons.phone),
                label: Text(l10n.livreurCallClient),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openGasDetails(context, request),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.livreurAvailableViewDetails),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGasActions(context, cubit, request),
        ],
      ),
    );
  }

  Future<void> _openGasDetails(
    BuildContext context,
    GasServiceOrder request,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<LivreurInProgressCubit>(),
          child: LivreurInProgressGasDetailsPage(request: request),
        ),
      ),
    );
  }

  Widget _buildGasActions(
    BuildContext context,
    LivreurInProgressCubit cubit,
    GasServiceOrder request,
  ) {
    final next = _nextGasStatus(request.status);
    if (next == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _updateGasStatus(context, cubit, request.id, next),
        icon: const Icon(Icons.check_circle),
        label: Text(context.livreurGasActionLabel(next)),
      ),
    );
  }

  Future<void> _updateGasStatus(
    BuildContext context,
    LivreurInProgressCubit cubit,
    String requestId,
    GasServiceStatus status,
  ) async {
    try {
      await cubit.updateGasStatus(requestId, status);
    } on ApiException catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: error.message,
        type: SnackBarType.error,
      );
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: error.toString(),
        type: SnackBarType.error,
      );
    }
  }

  bool _hasGasLocation(GasServiceOrder request) {
    final hasCoords =
        request.clientLatitude != null && request.clientLongitude != null;
    final hasAddress =
        request.clientAddress != null &&
        request.clientAddress!.trim().isNotEmpty;
    return hasCoords || hasAddress;
  }

  GasServiceStatus? _nextGasStatus(GasServiceStatus status) {
    switch (status) {
      case GasServiceStatus.enRoute:
        return GasServiceStatus.arrive;
      case GasServiceStatus.arrive:
        return GasServiceStatus.recupereVide;
      case GasServiceStatus.recupereVide:
        return GasServiceStatus.vaAuHanout;
      case GasServiceStatus.vaAuHanout:
        return GasServiceStatus.retourMaison;
      case GasServiceStatus.retourMaison:
        return GasServiceStatus.livre;
      case GasServiceStatus.pending:
      case GasServiceStatus.livre:
      case GasServiceStatus.cancelled:
      case GasServiceStatus.rejected:
        return null;
    }
  }

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.round,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDistance(double? distance) {
    if (distance == null) return '-';
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }

  Widget _infoPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.round,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              text,
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
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
}

class _DirectPickupAmountSheet extends StatefulWidget {
  const _DirectPickupAmountSheet({this.initialAmount});

  final double? initialAmount;

  @override
  State<_DirectPickupAmountSheet> createState() =>
      _DirectPickupAmountSheetState();
}

class _DirectPickupAmountSheetState extends State<_DirectPickupAmountSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    final canSubmit = parsed != null && parsed > 0;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.livreurDirectPickupAmountTitle,
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.livreurDirectPickupAmountMessage,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.hanoutOrdersTotalRequired,
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
                      onPressed: canSubmit
                          ? () {
                              FocusScope.of(context).unfocus();
                              Navigator.of(context).pop(parsed);
                            }
                          : null,
                      child: Text(l10n.clientCommonConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
