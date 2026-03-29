import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/cubbit/livreur_available_cubit.dart';
import 'package:sevenouti/livreur/l10n/livreur_l10n.dart';
import 'package:sevenouti/livreur/models/delivery_request_model.dart';
import 'package:sevenouti/utils/localized_formatters.dart';
import 'package:sevenouti/utils/map_launcher.dart';
import 'package:sevenouti/utils/phone_launcher.dart';

enum LivreurAvailableOrderAction { accepted, rejected }

class LivreurAvailableOrderDetailsPage extends StatefulWidget {
  const LivreurAvailableOrderDetailsPage({
    required this.request,
    super.key,
  });

  final LivreurDeliveryRequestModel request;

  @override
  State<LivreurAvailableOrderDetailsPage> createState() =>
      _LivreurAvailableOrderDetailsPageState();
}

class _LivreurAvailableOrderDetailsPageState
    extends State<LivreurAvailableOrderDetailsPage> {
  bool _isSubmitting = false;

  LivreurDeliveryRequestModel get request => widget.request;
  LivreurDeliveryOrderInfo? get order => request.order;
  LivreurHanoutInfo? get hanout => request.hanout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clientName =
        order?.client?.displayName(preferArabic: preferArabic) ??
        l10n.livreurClientFallback;
    final clientAddress = order?.displayClientAddress(
      preferArabic: preferArabic,
    );
    final isDirect = order?.isDirectLivreurFlow ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hanoutOrderNumber(_shortId(request.orderId))),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDirect),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.hanoutOrderDetailsClientSection,
                children: [
                  _infoRow(context, l10n.hanoutCommonName, clientName),
                  _buildPhoneRow(
                    context,
                    l10n.hanoutCommonPhone,
                    order?.client?.phone,
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
                          latitude: order?.clientLatitude,
                          longitude: order?.clientLongitude,
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
                    hanout?.name ?? '-',
                  ),
                  _buildPhoneRow(
                    context,
                    l10n.hanoutCommonPhone,
                    hanout?.phone,
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutCommonAddress,
                    formatAddressLocalized(context, hanout?.address),
                  ),
                  if (_hasHanoutLocation())
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => launchMaps(
                          latitude: hanout?.latitude,
                          longitude: hanout?.longitude,
                          address: hanout?.address,
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
                    order?.freeTextOrder ?? l10n.livreurOrderFallback,
                  ),
                  if (order?.notes != null && order!.notes!.isNotEmpty)
                    _infoRow(
                      context,
                      l10n.hanoutOrderDetailsDeliveryNotes,
                      order!.notes!,
                    ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsCreatedAt,
                    formatRelativeDateLocalized(
                      context,
                      order?.createdAt ?? request.createdAt,
                    ),
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsDeliveryType,
                    context.livreurDeliveryTypeLabel(
                      order?.deliveryType ?? request.order!.deliveryType,
                    ),
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsPaymentMethod,
                    context.paymentMethodLabel(
                      order?.paymentMethod ?? request.order!.paymentMethod,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.livreurOrderDetailsRouteSection,
                children: [
                  _infoRow(
                    context,
                    l10n.livreurAvailableHanoutDistanceLabel,
                    _formatDistance(context, request.hanoutDistance),
                  ),
                  _infoRow(
                    context,
                    l10n.livreurAvailableClientDistanceLabel,
                    _formatDistance(context, request.clientDistance),
                  ),
                  _infoRow(
                    context,
                    l10n.livreurOrderDetailsFlow,
                    isDirect
                        ? l10n.livreurAvailableDirectHint
                        : l10n.livreurAvailableHanoutHint,
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

  Widget _buildHeader(BuildContext context, bool isDirect) {
    final l10n = context.l10n;
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
          Text(
            isDirect
                ? l10n.livreurAvailableDirectBadge
                : l10n.livreurAvailableHanoutBadge,
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isDirect
                ? l10n.livreurAvailableDirectHint
                : l10n.livreurAvailableHanoutHint,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : () => _reject(context),
              icon: const Icon(Icons.close),
              label: Text(l10n.livreurReject),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : () => _accept(context),
              icon: const Icon(Icons.check),
              label: Text(l10n.livreurAccept),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<LivreurAvailableCubit>().acceptRequest(request.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(LivreurAvailableOrderAction.accepted);
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

  Future<void> _reject(BuildContext context) async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<LivreurAvailableCubit>().rejectRequest(request.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(LivreurAvailableOrderAction.rejected);
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

  bool _hasClientLocation() {
    return order?.clientLatitude != null && order?.clientLongitude != null;
  }

  bool _hasHanoutLocation() {
    return hanout?.latitude != null && hanout?.longitude != null;
  }

  String _formatDistance(BuildContext context, double? distance) {
    if (distance == null) return '-';
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }
}
