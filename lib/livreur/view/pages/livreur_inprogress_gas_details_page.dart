import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/cubbit/livreur_inprogress_cubit.dart';
import 'package:sevenouti/livreur/l10n/livreur_l10n.dart';
import 'package:sevenouti/utils/localized_formatters.dart';
import 'package:sevenouti/utils/map_launcher.dart';
import 'package:sevenouti/utils/phone_launcher.dart';

class LivreurInProgressGasDetailsPage extends StatefulWidget {
  const LivreurInProgressGasDetailsPage({
    required this.request,
    super.key,
  });

  final GasServiceOrder request;

  @override
  State<LivreurInProgressGasDetailsPage> createState() =>
      _LivreurInProgressGasDetailsPageState();
}

class _LivreurInProgressGasDetailsPageState
    extends State<LivreurInProgressGasDetailsPage> {
  bool _isSubmitting = false;
  late GasServiceOrder _request;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clientName = _request.displayClientName(preferArabic: preferArabic);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientGasDetailsTitle),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.hanoutOrderDetailsClientSection,
                children: [
                  _infoRow(
                    context,
                    l10n.hanoutCommonName,
                    clientName.isEmpty
                        ? l10n.livreurClientFallback
                        : clientName,
                  ),
                  _buildPhoneRow(
                    context,
                    l10n.hanoutCommonPhone,
                    _request.clientPhone,
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutCommonAddress,
                    formatAddressLocalized(
                      context,
                      _request.clientAddress ??
                          l10n.livreurClientAddressFallback,
                    ),
                  ),
                  if (_hasLocation())
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => launchMaps(
                          latitude: _request.clientLatitude,
                          longitude: _request.clientLongitude,
                          address: _request.clientAddress,
                        ),
                        icon: const Icon(Icons.map),
                        label: Text(l10n.livreurOrderDetailsOpenClientMaps),
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
                    l10n.clientGasServiceLabel,
                    l10n.clientGasServiceTitle,
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsCreatedAt,
                    formatRelativeDateLocalized(context, _request.createdAt),
                  ),
                  if (_request.notes != null && _request.notes!.isNotEmpty)
                    _infoRow(
                      context,
                      l10n.hanoutOrderDetailsDeliveryNotes,
                      _request.notes!,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.hanoutOrderDetailsAmountSection,
                children: [
                  _infoRow(
                    context,
                    l10n.clientGasPromoNormalPrice,
                    formatDh(context, _request.price, decimals: 0),
                  ),
                  _infoRow(
                    context,
                    l10n.livreurGasServiceTitle,
                    formatDh(context, _request.serviceFee, decimals: 0),
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsAmountSection,
                    formatDh(context, _request.total, decimals: 0),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.livreurOrderDetailsRouteSection,
                children: [
                  _infoRow(
                    context,
                    l10n.commonStatusLabel,
                    context.livreurGasStatusLabel(_request.status),
                  ),
                  if (_hasLocation())
                    _infoRow(
                      context,
                      l10n.livreurAvailableClientDistanceLabel,
                      l10n.livreurOpenMaps,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)],
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
                  l10n.clientGasBottleTitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusChip(
                label: context.livreurGasStatusLabel(_request.status),
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.livreurGasServiceDirect,
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
    final next = _nextGasStatus(_request.status);
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
          onPressed: _isSubmitting || next == null
              ? null
              : () => _updateGasStatus(context, next),
          icon: const Icon(Icons.check_circle),
          label: Text(
            next == null
                ? context.l10n.clientCommonConfirm
                : context.livreurGasActionLabel(next),
          ),
        ),
      ),
    );
  }

  Future<void> _updateGasStatus(
    BuildContext context,
    GasServiceStatus status,
  ) async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<LivreurInProgressCubit>().updateGasStatus(
        _request.id,
        status,
      );
      if (!mounted) return;
      setState(() {
        _request = _request.copyWith(status: status);
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

  bool _hasLocation() {
    return _request.clientLatitude != null && _request.clientLongitude != null;
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
}
