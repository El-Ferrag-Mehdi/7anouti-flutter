import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/hanout/cubbit/hanout_orders_cubit.dart';
import 'package:sevenouti/hanout/l10n/hanout_l10n.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/localized_formatters.dart';
import 'package:sevenouti/utils/map_launcher.dart';
import 'package:sevenouti/utils/phone_launcher.dart';

class HanoutOrderDetailsPage extends StatelessWidget {
  const HanoutOrderDetailsPage({
    required this.order,
    super.key,
  });

  final HanoutOrderModel order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColor = _getStatusColor(order.status);
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final localizedAddress = order.displayClientAddress(
      preferArabic: preferArabic,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hanoutOrderNumber(_shortOrderId(order.id))),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(context, statusColor),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.hanoutOrderDetailsClientSection,
                children: [
                  _infoRow(
                    context,
                    l10n.hanoutCommonName,
                    order.client?.displayName(preferArabic: preferArabic) ??
                        l10n.hanoutCommonClient,
                  ),
                  _buildPhoneRow(context, order.client?.phone),
                  _infoRow(
                    context,
                    l10n.hanoutCommonAddress,
                    formatAddressLocalized(context, localizedAddress),
                  ),
                  if (_hasClientLocation())
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => launchMaps(
                          latitude: order.clientLatitude,
                          longitude: order.clientLongitude,
                          address: localizedAddress,
                        ),
                        icon: const Icon(Icons.map),
                        label: Text(l10n.hanoutOrderDetailsOpenMaps),
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
                    order.freeTextOrder,
                  ),
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _infoRow(
                      context,
                      l10n.hanoutOrderDetailsDeliveryNotes,
                      order.notes!,
                    ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsCreatedAt,
                    formatRelativeDateLocalized(context, order.createdAt),
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsDeliveryType,
                    context.hanoutDeliveryTypeLabel(order.deliveryType),
                  ),
                  _infoRow(
                    context,
                    l10n.hanoutOrderDetailsPaymentMethod,
                    context.hanoutPaymentMethodLabel(order.paymentMethod),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                title: l10n.hanoutOrderDetailsAmountSection,
                children: [
                  _infoRow(
                    context,
                    l10n.clientCommonTotal,
                    order.totalAmount != null
                        ? formatDh(context, order.totalAmount!)
                        : '-',
                  ),
                  if (order.deliveryFee != null)
                    _infoRow(
                      context,
                      l10n.clientConfirmDeliveryFee,
                      formatDh(context, order.deliveryFee!),
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

  Widget _buildStatusHeader(BuildContext context, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.9),
            statusColor,
          ],
        ),
        borderRadius: AppRadius.large,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.hanoutOrderStatusLabel(order.status),
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            formatRelativeDateLocalized(context, order.createdAt),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(BuildContext context, String? phone) {
    final value = phone ?? '-';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            context.l10n.hanoutCommonPhone,
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
            width: 110,
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

  Widget _buildActions(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<HanoutOrdersCubit>();

    if (order.status == OrderStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showAcceptDialog(context, cubit),
          icon: const Icon(Icons.check),
          label: Text(l10n.hanoutOrdersActionAccept),
        ),
      );
    }

    if (order.status == OrderStatus.accepted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _setOrderReadyWithRequiredTotal(context, cubit),
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
                onPressed: () => _confirmRequestLivreur(context, cubit),
                icon: const Icon(Icons.delivery_dining),
                label: Text(l10n.hanoutOrdersActionAskDriver),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await cubit.updateStatus(
                    order.id,
                    status: OrderStatus.delivering,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
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
          onPressed: () async {
            await cubit.updateStatus(order.id, status: OrderStatus.delivered);
            if (context.mounted) Navigator.of(context).pop();
          },
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
          onPressed: () async {
            await cubit.updateStatus(order.id, status: OrderStatus.delivered);
            if (context.mounted) Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check_circle),
          label: Text(l10n.hanoutOrdersActionDeliveredInternal),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool _hasClientLocation() {
    final hasCoords =
        order.clientLatitude != null && order.clientLongitude != null;
    final address =
        order.displayClientAddress(preferArabic: true) ??
        order.displayClientAddress(preferArabic: false) ??
        '';
    final hasAddress = address.trim().isNotEmpty;
    return hasCoords || hasAddress;
  }

  Future<void> _showAcceptDialog(
    BuildContext context,
    HanoutOrdersCubit cubit,
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
    await cubit.acceptOrder(
      order.id,
      totalAmount: result['amount'] as double?,
    );
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _setOrderReadyWithRequiredTotal(
    BuildContext context,
    HanoutOrdersCubit cubit,
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
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmRequestLivreur(
    BuildContext context,
    HanoutOrdersCubit cubit,
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
      if (context.mounted) Navigator.of(context).pop();
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
