import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/client_home_cubit.dart';
import 'package:sevenouti/client/cubit/client_home_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/hanout_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/client/view/pages/gas_service_tracking_page.dart';
import 'package:sevenouti/client/view/pages/hanout_details_page.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/buttons.dart'
    hide IconButton, TextButton;
import 'package:sevenouti/core/widgets/cards.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/location_service.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';

/// Page d'accueil du client - Liste des hanouts à proximité
enum ClientHomeVariant { standard, aggressive }

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({
    super.key,
    this.variant = ClientHomeVariant.standard,
  });

  final ClientHomeVariant variant;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientHomeCubit(
        hanoutRepository: HanoutRepository(ApiService()),
      )..loadNearbyHanouts(), // Pour l'instant on utilise les données mock
      child: ClientHomeView(variant: variant),
    );
  }
}

class ClientHomeAggressivePage extends ClientHomePage {
  const ClientHomeAggressivePage({super.key})
    : super(variant: ClientHomeVariant.aggressive);
}

/// Vue de la page home (séparée pour faciliter les tests)
class ClientHomeView extends StatelessWidget {
  const ClientHomeView({
    super.key,
    this.variant = ClientHomeVariant.standard,
  });

  final ClientHomeVariant variant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: BlocBuilder<ClientHomeCubit, ClientHomeState>(
        builder: (context, state) {
          // État initial ou chargement
          if (state is ClientHomeInitial ||
              state is ClientHomeLoading ||
              state is ClientHomeLoadingLocation) {
            return AppBackground(
              child: LoadingView(
                message: l10n.clientHomeLoadingNearby,
              ),
            );
          }

          // État de succès - affiche les hanouts
          if (state is ClientHomeLoaded) {
            return _buildLoadedView(context, state);
          }

          // État vide - pas de hanouts trouvés
          if (state is ClientHomeEmpty) {
            return AppBackground(
              child: EmptyView(
                message: l10n.clientHomeNoHanoutNearby,
                icon: Icons.store_outlined,
                action: () => context.read<ClientHomeCubit>().refresh(),
                actionLabel: l10n.clientCommonRefresh,
              ),
            );
          }

          // État d'erreur de permission
          if (state is ClientHomeLocationPermissionDenied) {
            return AppBackground(
              child: ErrorView(
                message: l10n.clientHomeLocationPermissionDenied,
                onRetry: () => context.read<ClientHomeCubit>().refresh(),
              ),
            );
          }

          // État d'erreur
          if (state is ClientHomeError) {
            return AppBackground(
              child: ErrorView(
                message: state.message,
                onRetry: state.canRetry
                    ? () => context.read<ClientHomeCubit>().loadNearbyHanouts()
                    : null,
              ),
            );
          }

          // État par défaut (ne devrait jamais arriver)
          return Center(child: Text(l10n.clientCommonUnknownState));
        },
      ),
    );
  }

  /// Construit la vue quand les données sont chargées
  Widget _buildLoadedView(BuildContext context, ClientHomeLoaded state) {
    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<ClientHomeCubit>().refresh(),
        child: CustomScrollView(
          slivers: [
            // Header moderne
            SliverToBoxAdapter(
              child: _buildHeroHeader(context),
            ),

            // Actions rapides: commandes + service bouteille à gaz
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _buildQuickActions(context),
              ),
            ),

            // Section title + info carnet
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      title: context.l10n.clientHomeNearbyHanoutsTitle,
                      subtitle: context.l10n.clientHomeHanoutsFound(
                        state.hanouts.length,
                      ),
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // _buildCarnetInfoBanner(context),
                  ],
                ),
              ),
            ),

            // Liste des hanouts
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final hanout = state.hanouts[index];
                    return HanoutCard(
                      name: hanout.name,
                      address: hanout.address,
                      distance: hanout.formattedDistance,
                      imageUrl: hanout.image,
                      rating: hanout.rating,
                      isOpen: hanout.isOpen,
                      hasCarnet: hanout.hasCarnet,
                      onTap: () => _navigateToHanoutDetails(context, hanout),
                    );
                  },
                  childCount: state.hanouts.length,
                ),
              ),
            ),

            // Padding bottom pour ne pas être caché par la bottom nav
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return _buildAggressiveQuickActions(context);
  }

  Widget _buildAggressiveQuickActions(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.clientHomeQuickActionsTitle,
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildAggressiveCtaCard(
          title: l10n.clientHomeQuickActionsCoursesTitle,
          subtitle: l10n.clientHomeQuickActionsCoursesSubtitle,
          icon: Icons.storefront,
          color: AppColors.primary,
          onTap: () {
            AppSnackBar.show(
              context,
              message: context.l10n.clientHomeScrollForHanouts,
              type: SnackBarType.info,
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildAggressiveCtaCard(
          title: l10n.clientHomeQuickActionsGasTitle,
          subtitle: l10n.clientHomeQuickActionsGasSubtitle,
          icon: Icons.local_fire_department,
          color: AppColors.secondary,
          onTap: () => _showGasServiceSheet(context),
          badge: l10n.clientHomeQuickActionsGasBadge,
        ),
      ],
    );
  }

  Widget _buildAggressiveCtaCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.95),
                color.withOpacity(0.78),
              ],
            ),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: AppRadius.medium,
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.round,
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Banner d'information sur le carnet
  // Widget _buildCarnetInfoBanner(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.all(AppSpacing.md),
  //     decoration: BoxDecoration(
  //       color: AppColors.gold.withOpacity(0.2),
  //       borderRadius: AppRadius.large,
  //       border: Border.all(color: AppColors.gold.withOpacity(0.5)),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           Icons.auto_awesome,
  //           color: AppColors.brown,
  //           size: 20,
  //         ),
  //         const SizedBox(width: AppSpacing.sm),
  //         Expanded(
  //           child: Text(
  //             context.l10n.clientHomeCarnetInfoBanner,
  //             style: AppTextStyles.bodySmall.copyWith(
  //               color: AppColors.brown,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildHeroHeader(BuildContext context) {
    if (variant == ClientHomeVariant.aggressive) {
      return _buildAggressiveHeroHeader(context);
    }

    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.95),
            AppColors.accent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clientHomeHeroWelcome,
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.clientHomeHeroSubtitleCustom,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: AppRadius.large,
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAggressiveHeroHeader(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clientHomeAggressiveTitle,
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.clientHomeAggressiveSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: AppRadius.large,
              ),
              child: const Icon(
                Icons.flash_on_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGasServiceSheet(BuildContext context) {
    final parentContext = context;
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;
    bool isLocating = false;
    double? clientLatitude;
    double? clientLongitude;

    showAppBottomSheet<void>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(context.l10n.clientGasServiceTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.clientGasServiceDescription,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: isLocating
                          ? null
                          : () async {
                              setState(() => isLocating = true);
                              try {
                                final location = await LocationService()
                                    .fetchAndCacheCurrentLocation(
                                      languageCode: Localizations.localeOf(
                                        context,
                                      ).languageCode,
                                    );
                                if (location != null) {
                                  clientLatitude = location.latitude;
                                  clientLongitude = location.longitude;
                                  if (location.address != null &&
                                      location.address!.isNotEmpty) {
                                    addressController.text = location.address!;
                                  }
                                }
                              } finally {
                                if (context.mounted) {
                                  setState(() => isLocating = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(
                        isLocating
                            ? context.l10n.clientCommonLocating
                            : context.l10n.clientCommonUseMyLocation,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.clientCommonDeliveryAddress,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: addressController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: context.l10n.clientCommonDeliveryAddressHint,
                      prefixIcon: Icon(Icons.place),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.clientCommonDriverNotesOptional,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: context.l10n.clientCommonDriverNotesHint,
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.large,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _priceRow(
                          context.l10n.clientGasPromoPriceAllInclusive,
                          context.l10n.clientGasPromoPriceValue,
                          isTotal: true,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.clientGasPromoNormalPrice,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: isSubmitting
                        ? context.l10n.clientCommonSending
                        : context.l10n.clientGasRequestDriver,
                    icon: Icons.delivery_dining,
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final address = addressController.text.trim();
                            final notes = notesController.text.trim();
                            if (address.isEmpty) {
                              AppSnackBar.show(
                                context,
                                message: context.l10n.clientGasEnterAddress,
                                type: SnackBarType.error,
                              );
                              return;
                            }
                            setState(() => isSubmitting = true);
                            GasServiceOrder? order;
                            try {
                              order = await _startGasServiceOrder(
                                parentContext,
                                address: address,
                                notes: notes.isEmpty ? null : notes,
                                clientLatitude: clientLatitude,
                                clientLongitude: clientLongitude,
                              );
                            } finally {
                              if (context.mounted) {
                                setState(() => isSubmitting = false);
                              }
                            }
                            if (!context.mounted) return;
                            if (order == null) return;
                            Navigator.of(context).pop();
                            if (!parentContext.mounted) return;
                            AppSnackBar.show(
                              parentContext,
                              message: context.l10n.clientGasRequestSent,
                              type: SnackBarType.success,
                            );
                            Navigator.of(parentContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    GasServiceTrackingPage(order: order!),
                              ),
                            );
                          },
                    fullWidth: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.clientCommonCancel),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<GasServiceOrder?> _startGasServiceOrder(
    BuildContext context, {
    required String address,
    String? notes,
    double? clientLatitude,
    double? clientLongitude,
  }) async {
    try {
      final repo = GasServiceRepository(ApiService());
      return await repo.createRequest(
        price: 13,
        serviceFee: 2,
        clientAddress: address,
        clientLatitude: clientLatitude,
        clientLongitude: clientLongitude,
        notes: notes,
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: context.l10n.clientCommonErrorWithMessage(e.toString()),
          type: SnackBarType.error,
        );
      }
      return null;
    }
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: AppRadius.medium,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h3),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Navigation vers la page de détails du hanout
  void _navigateToHanoutDetails(
    BuildContext context,
    HanoutWithDistance hanout,
  ) {
    // Sélectionne le hanout dans le cubit
    context.read<ClientHomeCubit>().selectHanout(hanout);

    // ✅ Navigation vers la page de détails
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HanoutDetailsPage(hanout: hanout),
      ),
    );
  }
}
