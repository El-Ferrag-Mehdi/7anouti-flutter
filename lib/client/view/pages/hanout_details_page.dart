import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/hanout_details_cubit.dart';
import 'package:sevenouti/client/cubit/hanout_details_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/models.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/client/view/pages/order_tracking_page.dart';
import 'package:sevenouti/client/widgets/order_confirmation_sheet.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/core/widgets/buttons.dart'
    hide IconButton, TextButton;

/// Page de dÃƒÆ’Ã‚Â©tails d'un hanout avec commande
class HanoutDetailsPage extends StatelessWidget {
  const HanoutDetailsPage({
    required this.hanout,
    super.key,
  });

  final HanoutWithDistance hanout;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HanoutDetailsCubit(
        hanout: hanout,
        hanoutRepository: HanoutRepository(ApiService()),
        orderRepository: OrderRepository(ApiService()),
        carnetRepository: CarnetRepository(ApiService()),
      )..initialize(), // Mode MOCK pour l'instant
      child: const HanoutDetailsView(),
    );
  }
}

/// Vue de la page (sÃƒÆ’Ã‚Â©parÃƒÆ’Ã‚Â©e pour les tests)
class HanoutDetailsView extends StatelessWidget {
  const HanoutDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HanoutDetailsCubit, HanoutDetailsState>(
      listener: (context, state) {
        // Gere les erreurs
        if (state is HanoutDetailsError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          AppSnackBar.show(
            context,
            message: state.message,
            type: SnackBarType.error,
          );
          // Retourne a l'etat precedent apres 2 secondes
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              context.read<HanoutDetailsCubit>().clearError();
            }
          });
        }

        // Gere le succes de commande -> Navigation vers OrderTracking
        if (state is HanoutDetailsOrderSuccess) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          AppSnackBar.show(
            context,
            message: context.l10n.clientHanoutOrderSentSuccess,
            type: SnackBarType.success,
          );

          // Navigation directe vers la page de suivi sans passer par l'ecran precedent
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => OrderTrackingPage(
                    order: state.order,
                    hanoutPhone: state.hanoutPhone,
                  ),
                ),
              );
            }
          });
        }
      },
      builder: (context, state) {
        // Loading
        if (state is HanoutDetailsInitial || state is HanoutDetailsLoading) {
          return Scaffold(
            body: LoadingView(message: context.l10n.clientCommonLoading),
          );
        }

        // Submitting order
        if (state is HanoutDetailsSubmitting) {
          return Scaffold(
            body: LoadingView(message: context.l10n.clientHanoutSendingOrder),
          );
        }

        // Success: keep a neutral loading screen while listener redirects.
        if (state is HanoutDetailsOrderSuccess) {
          return Scaffold(
            body: LoadingView(
              message: context.l10n.clientHanoutRedirectTracking,
            ),
          );
        }

        // Loaded state
        if (state is HanoutDetailsLoaded) {
          return _buildLoadedView(context, state);
        }

        // Error with previous loaded state: keep UI visible (snackbar is shown by listener).
        if (state is HanoutDetailsError &&
            state.previousState is HanoutDetailsLoaded) {
          return _buildLoadedView(
            context,
            state.previousState! as HanoutDetailsLoaded,
          );
        }

        // Error (sera gÃƒÆ’Ã‚Â©rÃƒÆ’Ã‚Â© par le listener, mais au cas oÃƒÆ’Ã‚Â¹)
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.clientCommonError)),
          body: ErrorView(message: context.l10n.clientHanoutGenericError),
        );
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, HanoutDetailsLoaded state) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.hanout.name),
        actions: [
          // Info du hanout
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHanoutInfo(context, state.hanout),
          ),
        ],
      ),
      body: AppBackground(
        child: Column(
          children: [
            // Corps de la page avec scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header du hanout
                    _buildHanoutHeader(context, state.hanout),
                    const SizedBox(height: AppSpacing.lg),

                    // Info carnet
                    if (state.hanout.hasCarnet)
                      _buildCarnetInfo(context, state),
                    if (state.hanout.hasCarnet)
                      const SizedBox(height: AppSpacing.lg),

                    // Section commande libre
                    _buildOrderSection(context, state),
                    const SizedBox(height: AppSpacing.lg),
                    // Produits suggeres et categories masques temporairement

                    // Options de livraison
                    _buildDeliveryOptions(context, state),
                    const SizedBox(height: AppSpacing.lg),

                    // Options de paiement
                    _buildPaymentOptions(context, state),
                    const SizedBox(height: 100), // Espace pour le bouton fixe
                  ],
                ),
              ),
            ),

            // Bouton de validation fixe en bas
            _buildSubmitButton(context, state),
          ],
        ),
      ),
    );
  }

  /// Header avec infos du hanout
  Widget _buildHanoutHeader(BuildContext context, HanoutWithDistance hanout) {
    final hasImage = hanout.image != null && hanout.image!.trim().isNotEmpty;
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
          // Image ou icone
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              gradient: hasImage
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.accent.withOpacity(0.2),
                      ],
                    ),
              borderRadius: AppRadius.medium,
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: AppRadius.medium,
                    child: Image.network(
                      hanout.image!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.store,
                    size: 30,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hanout.name, style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hanout.formattedDistance,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Badge ouvert/ferme
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: hanout.isOpen
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.error.withOpacity(0.15),
              borderRadius: AppRadius.round,
              border: Border.all(
                color: hanout.isOpen ? AppColors.success : AppColors.error,
              ),
            ),
            child: Text(
              hanout.isOpen
                  ? context.l10n.clientHanoutOpen
                  : context.l10n.clientHanoutClosed,
              style: AppTextStyles.caption.copyWith(
                color: hanout.isOpen ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Info sur le carnet
  Widget _buildCarnetInfo(BuildContext context, HanoutDetailsLoaded state) {
    if (state.canUseCarnet && state.carnet != null) {
      // Client a dÃƒÆ’Ã‚Â©jÃƒÆ’Ã‚Â  un carnet actif
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: AppRadius.large,
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.clientHanoutCarnetActive,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    context.l10n.clientHanoutCurrentBalance(
                      state.carnet!.formattedBalance,
                    ),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (state.hanout.hasCarnet) {
      // Hanout accepte le carnet mais client n'en a pas
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.2),
          borderRadius: AppRadius.large,
          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book, color: AppColors.brown),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.clientHanoutCarnetAvailable,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.brown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.clientHanoutCarnetExplain,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.brown,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: context.l10n.clientHanoutRequestActivation,
              icon: Icons.send,
              onPressed: () {
                context.read<HanoutDetailsCubit>().requestCarnetActivation();
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Section commande libre (TextArea principale)
  Widget _buildOrderSection(BuildContext context, HanoutDetailsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.clientHanoutYourOrder, style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.clientHanoutOrderHint,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        // TextArea
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: TextField(
            maxLines: 6,
            maxLength: AppConstants.maxOrderTextLength,
            decoration: InputDecoration(
              hintText: context.l10n.clientHanoutOrderExampleHint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              counterText: '',
            ),
            style: AppTextStyles.bodyLarge,
            onChanged: (text) {
              context.read<HanoutDetailsCubit>().updateOrderText(text);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.clientHanoutCharactersCount(
            state.freeTextOrder.length,
            AppConstants.maxOrderTextLength,
          ),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  /// Section produits suggÃƒÆ’Ã‚Â©rÃƒÆ’Ã‚Â©s

  /// Options de livraison
  Widget _buildDeliveryOptions(
    BuildContext context,
    HanoutDetailsLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.clientHanoutPickupType, style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),

        // Livraison
        _buildOptionTile(
          title: context.l10n.clientDeliveryDelivery,
          subtitle: context.l10n.clientHanoutDeliveryFee(
            '${(state.hanout.deliveryFee ?? AppConstants.defaultDeliveryFee).toStringAsFixed(0)} DH',
          ),
          icon: Icons.delivery_dining,
          isSelected: state.deliveryType == DeliveryType.delivery,
          onTap: () {
            context.read<HanoutDetailsCubit>().changeDeliveryType(
              DeliveryType.delivery,
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),

        // Collecte
        _buildOptionTile(
          title: context.l10n.clientDeliveryPickup,
          subtitle: context.l10n.clientHanoutPickupFree,
          icon: Icons.shopping_bag,
          isSelected: state.deliveryType == DeliveryType.pickup,
          onTap: () {
            context.read<HanoutDetailsCubit>().changeDeliveryType(
              DeliveryType.pickup,
            );
          },
        ),
      ],
    );
  }

  /// Options de paiement
  Widget _buildPaymentOptions(
    BuildContext context,
    HanoutDetailsLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.clientConfirmPaymentLabel, style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),

        // EspÃƒÆ’Ã‚Â¨ces
        _buildOptionTile(
          title: context.l10n.clientPaymentCash,
          subtitle: context.l10n.clientHanoutPayOnDelivery,
          icon: Icons.payments,
          isSelected: state.paymentMethod == PaymentMethod.cash,
          onTap: () {
            context.read<HanoutDetailsCubit>().changePaymentMethod(
              PaymentMethod.cash,
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),

        // Carnet (uniquement si disponible)
        if (state.hanout.hasCarnet)
          _buildOptionTile(
            title: context.l10n.clientHanoutCarnetCredit,
            subtitle: state.canUseCarnet
                ? context.l10n.clientHanoutAddedToCarnet
                : context.l10n.clientHanoutCarnetUnavailable,
            icon: Icons.book,
            isSelected: state.paymentMethod == PaymentMethod.carnet,
            isEnabled: state.canUseCarnet,
            onTap: () {
              context.read<HanoutDetailsCubit>().changePaymentMethod(
                PaymentMethod.carnet,
              );
            },
          ),
      ],
    );
  }

  /// Tile d'option (livraison ou paiement)
  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: AppRadius.large,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: AppRadius.large,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // IcÃƒÆ’Ã‚Â´ne
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                borderRadius: AppRadius.medium,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isEnabled
                          ? AppColors.textSecondary
                          : AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),

            // Radio button
            if (isEnabled)
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  /// Bouton de soumission fixe en bas
  Widget _buildSubmitButton(BuildContext context, HanoutDetailsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.elevated,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: PrimaryButton(
          label: context.l10n.clientCommonConfirmOrder,
          icon: Icons.check,
          onPressed: state.canSubmitOrder
              ? () => _showOrderConfirmation(context, state)
              : null,
          fullWidth: true,
        ),
      ),
    );
  }

  /// Affiche le bottom sheet de confirmation
  void _showOrderConfirmation(
    BuildContext context,
    HanoutDetailsLoaded state,
  ) {
    showOrderConfirmationSheet(
      context: context,
      hanout: state.hanout,
      freeTextOrder: state.freeTextOrder,
      deliveryType: state.deliveryType,
      paymentMethod: state.paymentMethod,
      onConfirm:
          ({
            required String address,
            required String? addressFr,
            required String? addressAr,
            required double? latitude,
            required double? longitude,
            required String? notes,
          }) {
            // Soumet la commande avec les infos confirmÃƒÆ’Ã‚Â©es
            context.read<HanoutDetailsCubit>().submitOrder(
              clientAddress: address,
              clientAddressFr: addressFr,
              clientAddressAr: addressAr,
              clientLatitude: latitude,
              clientLongitude: longitude,
              notes: notes,
            );
          },
    );
  }

  /// Dialog d'info du hanout
  void _showHanoutInfo(BuildContext context, HanoutWithDistance hanout) {
    showAppBottomSheet<void>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(hanout.name),
          const SizedBox(height: AppSpacing.md),
          _infoRow(Icons.location_on, hanout.address),
          const SizedBox(height: AppSpacing.sm),
          _infoRow(Icons.phone, hanout.phone),
          const SizedBox(height: AppSpacing.sm),
          _infoRow(
            Icons.directions,
            context.l10n.clientHanoutDistance(hanout.formattedDistance),
          ),
          if (hanout.rating != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _infoRow(
              Icons.star,
              context.l10n.clientHanoutRating('${hanout.rating}/5'),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.clientCommonClose),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}
