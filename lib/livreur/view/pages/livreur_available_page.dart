import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/cubbit/livreur_available_cubit.dart';
import 'package:sevenouti/livreur/cubbit/livreur_available_state.dart';
import 'package:sevenouti/livreur/models/delivery_request_model.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';
import 'package:sevenouti/livreur/view/pages/livreur_available_order_details_page.dart';
import 'package:sevenouti/utils/localized_formatters.dart';
import 'package:sevenouti/utils/phone_launcher.dart';

class LivreurAvailablePage extends StatelessWidget {
  const LivreurAvailablePage({
    super.key,
    this.onAccepted,
  });

  final VoidCallback? onAccepted;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LivreurAvailableCubit(
        repository: LivreurRequestsRepository(ApiService()),
      )..loadRequests(),
      child: LivreurAvailableView(onAccepted: onAccepted),
    );
  }
}

class LivreurAvailableView extends StatelessWidget {
  const LivreurAvailableView({
    super.key,
    this.onAccepted,
  });

  final VoidCallback? onAccepted;

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
    final directOrders = requests.where(_isDirectOrder).toList();
    final hanoutOrders = requests.where(_isHanoutRequest).toList();
    final gasRequests = requests.where(_isGasServiceRequest).toList();

    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<LivreurAvailableCubit>().loadRequests(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, requests.length),
            ),
            if (directOrders.isNotEmpty)
              _buildSection(
                context,
                title: context.l10n.livreurAvailableDirectSection,
                requests: directOrders,
                sectionColor: AppColors.secondary,
              ),
            if (hanoutOrders.isNotEmpty)
              _buildSection(
                context,
                title: context.l10n.livreurAvailableHanoutSection,
                requests: hanoutOrders,
                sectionColor: AppColors.info,
              ),
            if (gasRequests.isNotEmpty)
              _buildSection(
                context,
                title: context.l10n.livreurAvailableGasSection,
                requests: gasRequests,
                sectionColor: AppColors.warning,
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<LivreurDeliveryRequestModel> requests,
    required Color sectionColor,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: sectionColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTextStyles.h3),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final request = requests[index];
                if (_isGasServiceRequest(request)) {
                  return _buildGasCard(context, request);
                }
                return _buildOrderCard(context, request);
              },
              childCount: requests.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    LivreurDeliveryRequestModel request,
  ) {
    final l10n = context.l10n;
    final order = request.order;
    final hanout = request.hanout;
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clientName =
        order?.client?.displayName(preferArabic: preferArabic) ??
        l10n.livreurClientFallback;
    final clientAddress = order?.displayClientAddress(
      preferArabic: preferArabic,
    );
    final isDirect = order?.isDirectLivreurFlow ?? false;

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
              _typeChip(
                label: isDirect
                    ? l10n.livreurAvailableDirectBadge
                    : l10n.livreurAvailableHanoutBadge,
                color: isDirect ? AppColors.secondary : AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isDirect
                ? l10n.livreurAvailableDirectHint
                : l10n.livreurAvailableHanoutHint,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
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
                icon: Icons.person,
                text: clientName,
              ),
              _infoPill(
                icon: Icons.access_time,
                text: formatRelativeDateLocalized(context, request.createdAt),
              ),
              _infoPill(
                icon: Icons.storefront,
                text: formatAddressLocalized(context, hanout?.address),
              ),
              _infoPill(
                icon: Icons.place,
                text: formatAddressLocalized(
                  context,
                  clientAddress ?? l10n.livreurClientAddressFallback,
                ),
              ),
              _infoPill(
                icon: Icons.near_me,
                text:
                    '${l10n.livreurAvailableHanoutDistanceLabel}: ${_formatDistance(request.hanoutDistance)}',
              ),
              _infoPill(
                icon: Icons.home_work_outlined,
                text:
                    '${l10n.livreurAvailableClientDistanceLabel}: ${_formatDistance(request.clientDistance)}',
              ),
              if (order?.notes != null && order!.notes!.isNotEmpty)
                _infoPill(
                  icon: Icons.notes,
                  text: order.notes!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openOrderDetails(context, request),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.livreurAvailableViewDetails),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectOrderRequest(context, request.id),
                  icon: const Icon(Icons.close),
                  label: Text(l10n.livreurReject),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptOrderRequest(context, request.id),
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

  Widget _buildGasCard(
    BuildContext context,
    LivreurDeliveryRequestModel request,
  ) {
    final l10n = context.l10n;
    final order = request.order;
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clientAddress = order?.displayClientAddress(
      preferArabic: preferArabic,
    );
    final clientName =
        order?.client?.displayName(preferArabic: preferArabic) ??
        l10n.livreurClientFallback;
    final clientPhone = order?.client?.phone;

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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _typeChip(
                label: l10n.clientGasBottleTitle,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.livreurGasServiceDirect,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _infoPill(
                icon: Icons.person,
                text: clientName,
              ),
              _infoPill(
                icon: Icons.access_time,
                text: formatRelativeDateLocalized(context, request.createdAt),
              ),
              _infoPill(
                icon: Icons.place,
                text: formatAddressLocalized(
                  context,
                  clientAddress ?? l10n.livreurClientAddressFallback,
                ),
              ),
              _infoPill(
                icon: Icons.near_me,
                text:
                    '${l10n.livreurAvailableClientDistanceLabel}: ${_formatDistance(request.clientDistance ?? request.distance)}',
              ),
              if (order?.notes != null && order!.notes!.isNotEmpty)
                _infoPill(
                  icon: Icons.notes,
                  text: order.notes!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (clientPhone != null && clientPhone.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => launchPhoneCall(clientPhone),
                icon: const Icon(Icons.phone),
                label: Text(l10n.livreurCallClient),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectGasRequest(context, request.id),
                  icon: const Icon(Icons.close),
                  label: Text(l10n.livreurReject),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptGasRequest(context, request.id),
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

  Future<void> _openOrderDetails(
    BuildContext context,
    LivreurDeliveryRequestModel request,
  ) async {
    final cubit = context.read<LivreurAvailableCubit>();
    final result = await Navigator.of(context)
        .push<LivreurAvailableOrderAction>(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: LivreurAvailableOrderDetailsPage(request: request),
            ),
          ),
        );

    if (result == LivreurAvailableOrderAction.accepted) {
      onAccepted?.call();
    }
  }

  Future<void> _acceptOrderRequest(
    BuildContext context,
    String requestId,
  ) async {
    try {
      final accepted = await context
          .read<LivreurAvailableCubit>()
          .acceptRequest(
            requestId,
          );
      if (accepted) {
        onAccepted?.call();
      }
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

  Future<void> _rejectOrderRequest(
    BuildContext context,
    String requestId,
  ) async {
    try {
      await context.read<LivreurAvailableCubit>().rejectRequest(requestId);
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

  Future<void> _acceptGasRequest(BuildContext context, String requestId) async {
    try {
      final accepted = await context
          .read<LivreurAvailableCubit>()
          .acceptGasRequest(
            requestId,
          );
      if (accepted) {
        onAccepted?.call();
      }
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

  Future<void> _rejectGasRequest(BuildContext context, String requestId) async {
    try {
      await context.read<LivreurAvailableCubit>().rejectGasRequest(requestId);
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

  Widget _typeChip({required String label, required Color color}) {
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
            constraints: const BoxConstraints(maxWidth: 220),
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

  bool _isGasServiceRequest(LivreurDeliveryRequestModel request) {
    final order = request.order;
    final hanout = request.hanout;
    if (order == null) return false;
    final text = order.freeTextOrder.toLowerCase();
    final hasGasKeyword = text.contains('gaz') || text.contains('bouteille');
    final noHanout = hanout == null || hanout.id.isEmpty;
    return hasGasKeyword || noHanout;
  }

  bool _isDirectOrder(LivreurDeliveryRequestModel request) {
    return !_isGasServiceRequest(request) &&
        (request.order?.isDirectLivreurFlow ?? false);
  }

  bool _isHanoutRequest(LivreurDeliveryRequestModel request) {
    return !_isGasServiceRequest(request) &&
        !(request.order?.isDirectLivreurFlow ?? false);
  }

  String _formatDistance(double? distance) {
    if (distance == null) return '-';
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }
}
