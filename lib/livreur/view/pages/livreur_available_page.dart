import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/distance_pill.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/cubbit/livreur_available_cubit.dart';
import 'package:sevenouti/livreur/cubbit/livreur_available_state.dart';
import 'package:sevenouti/livreur/l10n/livreur_l10n.dart';
import 'package:sevenouti/livreur/models/delivery_request_model.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';
import 'package:sevenouti/utils/localized_formatters.dart';
import 'package:sevenouti/utils/map_launcher.dart';

class LivreurAvailablePage extends StatelessWidget {
  const LivreurAvailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LivreurAvailableCubit(
        repository: LivreurRequestsRepository(ApiService()),
      )..loadRequests(),
      child: const LivreurAvailableView(),
    );
  }
}

class LivreurAvailableView extends StatelessWidget {
  const LivreurAvailableView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LivreurAvailableCubit, LivreurAvailableState>(
      builder: (context, state) {
        if (state is LivreurAvailableInitial ||
            state is LivreurAvailableLoading) {
          return AppBackground(
            child: LoadingView(message: l10n.livreurAvailableLoading),
          );
        }

        if (state is LivreurAvailableEmpty) {
          return AppBackground(
            child: EmptyView(
              message: l10n.livreurAvailableEmpty,
              icon: Icons.inbox_outlined,
            ),
          );
        }

        if (state is LivreurAvailableError) {
          return AppBackground(
            child: ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<LivreurAvailableCubit>().loadRequests(),
            ),
          );
        }

        if (state is LivreurAvailableLoaded) {
          return _buildLoaded(context, state.requests);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    List<LivreurDeliveryRequestModel> requests,
  ) {
    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<LivreurAvailableCubit>().loadRequests(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, requests.length),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final request = requests[index];
                    return _buildRequestCard(context, request);
                  },
                  childCount: requests.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final l10n = context.l10n;
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
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: AppRadius.large,
              ),
              child: const Icon(
                Icons.campaign,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.livreurAvailableTitle, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    l10n.livreurAvailableCount(count),
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

  Widget _buildRequestCard(
    BuildContext context,
    LivreurDeliveryRequestModel request,
  ) {
    final l10n = context.l10n;
    final order = request.order;
    final hanout = request.hanout;
    final isGasService = _isGasServiceRequest(order, hanout);
    final statusColor = _requestStatusColor(request.status);
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final localizedClientAddress = order?.displayClientAddress(
      preferArabic: preferArabic,
    );

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
                  isGasService
                      ? l10n.livreurGasServiceTitle
                      : (hanout?.name ?? l10n.clientOrderTrackingHanout),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _statusChip(
                label: context.livreurRequestStatusLabel(request.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isGasService
                ? l10n.livreurGasServiceDirect
                : formatAddressLocalized(context, hanout?.address),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_hasClientLocation(order))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => launchMaps(
                  latitude: order?.clientLatitude,
                  longitude: order?.clientLongitude,
                  address: localizedClientAddress,
                ),
                icon: const Icon(Icons.map),
                label: Text(l10n.livreurOpenMaps),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            order?.freeTextOrder ?? l10n.livreurOrderFallback,
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
                icon: Icons.access_time,
                text: formatRelativeDateLocalized(context, request.createdAt),
              ),
              _infoPill(
                icon: Icons.place,
                text: formatAddressLocalized(
                  context,
                  localizedClientAddress ?? l10n.livreurClientAddressFallback,
                ),
              ),
              if (isGasService)
                _infoPill(
                  icon: Icons.payments,
                  text: l10n.livreurGasServicePriceBadge,
                ),
              if (order?.notes != null && order!.notes!.isNotEmpty)
                _infoPill(
                  icon: Icons.home,
                  text: order.notes!,
                ),
              if (request.distance != null)
                _infoPill(
                  icon: Icons.near_me,
                  text: '${(request.distance! / 1000).toStringAsFixed(1)} km',
                ),
              if (request.distance == null)
                CurrentDistancePill(
                  targetLatitude: order?.clientLatitude,
                  targetLongitude: order?.clientLongitude,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final cubit = context.read<LivreurAvailableCubit>();
                    if (isGasService) {
                      cubit.rejectGasRequest(request.id);
                      return;
                    }
                    cubit.rejectRequest(request.id);
                  },
                  icon: const Icon(Icons.close),
                  label: Text(l10n.livreurReject),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final cubit = context.read<LivreurAvailableCubit>();
                    if (isGasService) {
                      cubit.acceptGasRequest(request.id);
                      return;
                    }
                    cubit.acceptRequest(request.id);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(l10n.livreurAccept),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  bool _isGasServiceRequest(
    LivreurDeliveryOrderInfo? order,
    LivreurHanoutInfo? hanout,
  ) {
    if (order == null) return false;
    final text = order.freeTextOrder.toLowerCase();
    final hasGasKeyword = text.contains('gaz') || text.contains('bouteille');
    final noHanout = hanout == null || hanout.id.isEmpty;
    return hasGasKeyword || noHanout;
  }

  bool _hasClientLocation(LivreurDeliveryOrderInfo? order) {
    if (order == null) return false;
    final hasCoords =
        order.clientLatitude != null && order.clientLongitude != null;
    final address =
        order.displayClientAddress(preferArabic: true) ??
        order.displayClientAddress(preferArabic: false);
    final hasAddress = address != null && address.trim().isNotEmpty;
    return hasCoords || hasAddress;
  }

  Color _requestStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'PENDING':
      default:
        return AppColors.info;
    }
  }
}
