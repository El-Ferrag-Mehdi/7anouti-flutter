import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/free_delivery_promo_badge.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/cubbit/livreur_inprogress_cubit.dart';
import 'package:sevenouti/livreur/l10n/livreur_l10n.dart';
import 'package:sevenouti/livreur/models/livreur_order_model.dart';
import 'package:sevenouti/utils/localized_formatters.dart';
import 'package:sevenouti/utils/map_launcher.dart';
import 'package:sevenouti/utils/phone_launcher.dart';

class LivreurInProgressOrderDetailsPage extends StatefulWidget {
  const LivreurInProgressOrderDetailsPage({
    required this.order,
    super.key,
  });

  final LivreurOrderModel order;

  @override
  State<LivreurInProgressOrderDetailsPage> createState() =>
      _LivreurInProgressOrderDetailsPageState();
}

class _LivreurInProgressOrderDetailsPageState
    extends State<LivreurInProgressOrderDetailsPage> {
  bool _isSubmitting = false;
  late LivreurOrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clientName =
        _order.client?.displayName(preferArabic: preferArabic) ??
        l10n.livreurClientFallback;
    final clientAddress = _order.displayClientAddress(
      preferArabic: preferArabic,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hanoutOrderNumber(_shortId(_order.id))),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (_order.freeDeliveryPromoApplied) ...[
                const SizedBox(height: AppSpacing.md),
                const FreeDeliveryPromoBadge(),
              ],
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.hanoutOrderDetailsClientSection,
                children: [
                  _infoRow(context, l10n.hanoutCommonName, clientName),
                  _buildPhoneRow(
                    context,
                    l10n.hanoutCommonPhone,
                    _order.client?.phone,
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutCommonAddress,
                    formatAddressLocalized(
                      context,
                      clientAddress ?? l10n.livreurClientAddressFallback,
                    ),
                  ),
                  if (_hasClientLocation())
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => launchMaps(
                          latitude: _order.clientLatitude,
                          longitude: _order.clientLongitude,
                          address: clientAddress,
                        ),
                        icon: const Icon(Icons.map),
                        label: Text(l10n.livreurOrderDetailsOpenClientMaps),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.livreurOrderDetailsHanoutSection,
                children: [
                  _infoRow(
                    context,
                    l10n.clientOrderTrackingHanout,
                    _order.hanout?.name ?? '-',
                  ),
                  _buildPhoneRow(
                    context,
                    l10n.hanoutCommonPhone,
                    _order.hanout?.phone,
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutCommonAddress,
                    formatAddressLocalized(context, _order.hanout?.address),
                  ),
                  if (_order.hanout?.latitude != null &&
                      _order.hanout?.longitude != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => launchMaps(
                          latitude: _order.hanout?.latitude,
                          longitude: _order.hanout?.longitude,
                          address: _order.hanout?.address,
                        ),
                        icon: const Icon(Icons.store_mall_directory),
                        label: Text(l10n.livreurOrderDetailsOpenHanoutMaps),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.hanoutOrderDetailsOrderSection,
                children: [
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsContent,
                    _order.freeTextOrder,
                  ),
                  if (_order.notes != null && _order.notes!.isNotEmpty)
                    _infoRow(
                      context,
                      l10n.hanoutOrderDetailsDeliveryNotes,
                      _order.notes!,
                    ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsCreatedAt,
                    formatRelativeDateLocalized(context, _order.createdAt),
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsDeliveryType,
                    context.livreurDeliveryTypeLabel(_order.deliveryType),
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsPaymentMethod,
                    context.paymentMethodLabel(_order.paymentMethod),
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsAmountSection,
                    _order.totalAmount != null
                        ? formatDh(context, _order.totalAmount!)
                        : l10n.clientOrderTrackingAmountPending,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.livreurOrderDetailsRouteSection,
                children: [
                  _infoRow(
                    context,
                    l10n.livreurOrderDetailsFlow,
                    _order.isDirectLivreurFlow
                        ? l10n.livreurAvailableDirectHint
                        : l10n.livreurAvailableHanoutHint,
                  ),
                  _infoRow(
                    context,
                    l10n.livreurAvailableHanoutDistanceLabel,
                    _formatDistance(_order.hanoutDistance),
                  ),
                  _infoRow(
                    context,
                    l10n.livreurAvailableClientDistanceLabel,
                    _formatDistance(_order.clientDistance),
                  ),
                  _infoRow(
                    context,
                    l10n.commonStatusLabel,
                    context.livreurOrderStatusLabel(
                      _order.status,
                      processingMode: _order.processingMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = context.l10n;
    final isDirect = _order.isDirectLivreurFlow;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDirect
              ? [AppColors.secondary, AppColors.secondary.withOpacity(0.8)]
              : [AppColors.info, AppColors.info.withOpacity(0.8)],
        ),
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isDirect
                      ? l10n.livreurAvailableDirectBadge
                      : l10n.livreurAvailableHanoutBadge,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusChip(
                label: context.livreurOrderStatusLabel(
                  _order.status,
                  processingMode: _order.processingMode,
                ),
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isDirect
                ? l10n.livreurAvailableDirectHint
                : l10n.livreurAvailableHanoutHint,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Text(title, style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(BuildContext context, String label, String? phone) {
    final value = phone ?? '-';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodyMedium),
        ),
        if (phone != null && phone.isNotEmpty)
          IconButton(
            onPressed: () => launchPhoneCall(phone),
            icon: const Icon(Icons.phone),
            color: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final l10n = context.l10n;
    final action = _currentAction(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSubmitting || action == null ? null : action.onPressed,
          icon: Icon(action?.icon ?? Icons.check_circle),
          label: Text(action?.label ?? l10n.clientCommonConfirm),
        ),
      ),
    );
  }

  _OrderAction? _currentAction(BuildContext context) {
    final l10n = context.l10n;
    if (_order.isDirectLivreurFlow && _order.status == OrderStatus.accepted) {
      return _OrderAction(
        icon: Icons.delivery_dining,
        label: l10n.livreurActionOnWay,
        onPressed: () => _handleStatusUpdate(context, OrderStatus.ready),
      );
    }

    if (_order.isDirectLivreurFlow && _order.status == OrderStatus.ready) {
      return _OrderAction(
        icon: Icons.inventory_2,
        label: l10n.livreurActionPickedUp,
        onPressed: () => _handlePickupWithAmount(context),
      );
    }

    if (_order.status == OrderStatus.ready) {
      return _OrderAction(
        icon: Icons.inventory_2,
        label: l10n.livreurActionPickedUp,
        onPressed: () => _handleStatusUpdate(context, OrderStatus.pickedUp),
      );
    }

    if (_order.status == OrderStatus.pickedUp) {
      return _OrderAction(
        icon: Icons.delivery_dining,
        label: l10n.livreurActionDelivering,
        onPressed: () => _handleStatusUpdate(context, OrderStatus.delivering),
      );
    }

    if (_order.status == OrderStatus.delivering) {
      return _OrderAction(
        icon: Icons.check_circle,
        label: l10n.livreurActionDelivered,
        onPressed: () => _handleStatusUpdate(context, OrderStatus.delivered),
      );
    }

    return null;
  }

  Future<void> _handlePickupWithAmount(BuildContext context) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DirectPickupAmountSheet(
        initialAmount: _order.totalAmount,
      ),
    );

    if (amount == null || amount <= 0) return;
    if (!context.mounted) return;

    await _handleStatusUpdate(
      context,
      OrderStatus.pickedUp,
      totalAmount: amount,
    );
  }

  Future<void> _handleStatusUpdate(
    BuildContext context,
    OrderStatus status, {
    double? totalAmount,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<LivreurInProgressCubit>().updateStatus(
        _order.id,
        status,
        totalAmount: totalAmount,
      );
      if (!mounted) return;
      setState(() {
        _order = _order.copyWith(
          status: status,
          totalAmount: totalAmount ?? _order.totalAmount,
        );
      });
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: AppRadius.round,
        border: Border.all(color: color.withOpacity(0.35)),
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

  bool _hasClientLocation() {
    return _order.clientLatitude != null && _order.clientLongitude != null;
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  String _formatDistance(double? distance) {
    if (distance == null) return '-';
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }
}

class _OrderAction {
  const _OrderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
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
