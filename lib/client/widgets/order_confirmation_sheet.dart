import 'package:flutter/material.dart';
import 'package:sevenouti/client/models/hanout_model.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/models.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/buttons.dart';
import 'package:sevenouti/core/widgets/distance_pill.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/location_service.dart';

/// Bottom Sheet de confirmation de commande
class OrderConfirmationSheet extends StatefulWidget {
  const OrderConfirmationSheet({
    required this.hanout,
    required this.freeTextOrder,
    required this.deliveryType,
    required this.paymentMethod,
    required this.onConfirm,
    super.key,
  });

  final HanoutWithDistance hanout;
  final String freeTextOrder;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final void Function({
    required String address,
    required String? addressFr,
    required String? addressAr,
    required double? latitude,
    required double? longitude,
    required String? notes,
  })
  onConfirm;

  @override
  State<OrderConfirmationSheet> createState() => _OrderConfirmationSheetState();
}

class _OrderConfirmationSheetState extends State<OrderConfirmationSheet> {
  final _addressController = TextEditingController();
  final _detailsController = TextEditingController();
  final _locationService = LocationService();

  double? _userLat;
  double? _userLon;
  bool _usingCurrentLocation = false;
  bool _isLocating = false;
  static const String _defaultAddress = 'Mon adresse';

  @override
  void initState() {
    super.initState();
    // Pré-rempli avec une adresse par défaut
    _addressController.text =
        _defaultAddress; // Tu peux récupérer depuis le profil
    _loadCachedLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: Image.asset(
                  'assets/logo/logo_full.png',
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Titre
              Text(
                l10n.clientConfirmOrderTitle,
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Résumé de la commande
              _buildSection(
                title: l10n.clientConfirmYourOrder,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.large,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Text(
                    widget.freeTextOrder,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Adresse de livraison (si livraison)
              if (widget.deliveryType == DeliveryType.delivery) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  title: l10n.clientCommonDeliveryAddress,
                  child: Column(
                    children: [
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: l10n.clientConfirmAddressHint,
                          prefixIcon: const Icon(Icons.location_on),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        maxLines: 2,
                        onChanged: (_) {
                          if (_usingCurrentLocation) {
                            setState(() => _usingCurrentLocation = false);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _detailsController,
                        decoration: InputDecoration(
                          hintText: l10n.clientConfirmAddressDetailsHint,
                          prefixIcon: const Icon(Icons.home),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Option: Utiliser ma position actuelle
                      InkWell(
                        onTap: _isLocating ? null : _useCurrentLocation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.my_location,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                l10n.clientCommonUseMyLocation,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_isLocating) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Point de collecte (si collecte)
              if (widget.deliveryType == DeliveryType.pickup) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  title: l10n.clientConfirmPickupPoint,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: AppRadius.large,
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: AppColors.brown),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.hanout.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.hanout.address,
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              CurrentDistancePill(
                                targetLatitude: widget.hanout.latitude,
                                targetLongitude: widget.hanout.longitude,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Mode de livraison
              _buildInfoRow(
                icon: widget.deliveryType == DeliveryType.delivery
                    ? Icons.delivery_dining
                    : Icons.shopping_bag,
                label: l10n.clientConfirmTypeLabel,
                value: context.deliveryTypeLabel(widget.deliveryType),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Mode de paiement
              _buildInfoRow(
                icon: widget.paymentMethod == PaymentMethod.cash
                    ? Icons.payments
                    : Icons.book,
                label: l10n.clientConfirmPaymentLabel,
                value: context.paymentMethodLabel(widget.paymentMethod),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Résumé des frais
              _buildPriceSummary(),

              const SizedBox(height: AppSpacing.xl),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: l10n.clientCommonEdit,
                      onPressed: () => Navigator.of(context).pop(),
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: l10n.clientCommonConfirm,
                      icon: Icons.check,
                      onPressed: _confirmOrder,
                      fullWidth: true,
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

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    final deliveryFee = widget.deliveryType == DeliveryType.delivery
        ? (widget.hanout.deliveryFee ?? AppConstants.defaultDeliveryFee)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          // Frais de livraison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.clientConfirmDeliveryFee,
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                deliveryFee > 0
                    ? '${deliveryFee.toStringAsFixed(2)} DH'
                    : context.l10n.clientConfirmFree,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Note: Le montant total sera calculé par le hanout
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.clientConfirmTotalToPay,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                context.l10n.clientConfirmToBeConfirmed,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.clientConfirmFinalAmountMessage,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _useCurrentLocation() {
    _fetchAndUseCurrentLocation();
  }

  Future<void> _confirmOrder() async {
    // Validation
    if (widget.deliveryType == DeliveryType.delivery &&
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.clientConfirmEnterAddress),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final localeCode = Localizations.localeOf(context).languageCode;
    final primaryAddress = widget.deliveryType == DeliveryType.delivery
        ? _addressController.text.trim()
        : widget.hanout.address;
    String? addressFr;
    String? addressAr;

    if (widget.deliveryType == DeliveryType.delivery) {
      if (localeCode == 'ar') {
        addressAr = primaryAddress;
      } else {
        addressFr = primaryAddress;
      }

      // If GPS is used, generate the alternate locale address automatically.
      if (_usingCurrentLocation && _userLat != null && _userLon != null) {
        if (localeCode == 'ar') {
          final resolvedFr = await _locationService.reverseGeocode(
            _userLat!,
            _userLon!,
            languageCode: 'fr',
          );
          if (resolvedFr != null && resolvedFr.trim().isNotEmpty) {
            addressFr = resolvedFr.trim();
          }
        } else {
          final resolvedAr = await _locationService.reverseGeocode(
            _userLat!,
            _userLon!,
            languageCode: 'ar',
          );
          if (resolvedAr != null && resolvedAr.trim().isNotEmpty) {
            addressAr = resolvedAr.trim();
          }
        }
      }
    }

    if (!mounted) return;

    // Ferme le bottom sheet et appelle le callback
    Navigator.of(context).pop();

    widget.onConfirm(
      address: primaryAddress,
      addressFr: addressFr,
      addressAr: addressAr,
      latitude: _usingCurrentLocation ? _userLat : null,
      longitude: _usingCurrentLocation ? _userLon : null,
      notes: widget.deliveryType == DeliveryType.delivery
          ? _detailsController.text.trim().isEmpty
                ? null
                : _detailsController.text.trim()
          : null,
    );
  }

  Future<void> _loadCachedLocation() async {
    final cached = await _locationService.getCachedLocation();
    if (!mounted || cached == null) return;
    setState(() {
      _userLat = cached.latitude;
      _userLon = cached.longitude;
      _usingCurrentLocation = true;
      if (cached.address != null &&
          cached.address!.isNotEmpty &&
          _addressController.text == _defaultAddress) {
        _addressController.text = cached.address!;
      }
    });
  }

  Future<void> _fetchAndUseCurrentLocation() async {
    setState(() => _isLocating = true);
    final cached = await _locationService.fetchAndCacheCurrentLocation(
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;

    if (cached == null) {
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.clientConfirmLocationError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _userLat = cached.latitude;
      _userLon = cached.longitude;
      _usingCurrentLocation = true;
      _isLocating = false;
      _addressController.text =
          (cached.address != null && cached.address!.isNotEmpty)
          ? cached.address!
          : context.l10n.clientConfirmMyCurrentGps;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.clientConfirmLocationUsed),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Fonction helper pour afficher le bottom sheet
void showOrderConfirmationSheet({
  required BuildContext context,
  required HanoutWithDistance hanout,
  required String freeTextOrder,
  required DeliveryType deliveryType,
  required PaymentMethod paymentMethod,
  required void Function({
    required String address,
    required String? addressFr,
    required String? addressAr,
    required double? latitude,
    required double? longitude,
    required String? notes,
  })
  onConfirm,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: OrderConfirmationSheet(
        hanout: hanout,
        freeTextOrder: freeTextOrder,
        deliveryType: deliveryType,
        paymentMethod: paymentMethod,
        onConfirm: onConfirm,
      ),
    ),
  );
}
