import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/auth/cubbit/auth_state.dart';
import 'package:sevenouti/auth/models/user_role.dart';
import 'package:sevenouti/client/cubit/client_home_cubit.dart';
import 'package:sevenouti/client/cubit/client_home_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/business_category_model.dart';
import 'package:sevenouti/client/models/first_delivery_promo_config_model.dart';
import 'package:sevenouti/client/models/first_delivery_promo_status_model.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/hanout_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/client/view/pages/gas_service_tracking_page.dart';
import 'package:sevenouti/client/view/pages/hanout_details_page.dart';
import 'package:sevenouti/client/widgets/client_auth_prompt.dart';
import 'package:sevenouti/client/widgets/first_delivery_promo_banner.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/notifications/local_notification_service.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/buttons.dart'
    hide IconButton, TextButton;
import 'package:sevenouti/core/widgets/cards.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/location_service.dart';

/// Page d'accueil du client - Liste des hanouts à proximité
enum ClientHomeVariant { standard, aggressive }

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({
    super.key,
    this.variant = ClientHomeVariant.standard,
    this.scrollRequestToken = 0,
  });

  final ClientHomeVariant variant;
  final int scrollRequestToken;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientHomeCubit(
        hanoutRepository: HanoutRepository(ApiService()),
      )..loadNearbyHanouts(),
      child: ClientHomeView(
        variant: variant,
        scrollRequestToken: scrollRequestToken,
      ),
    );
  }
}

class ClientHomeAggressivePage extends ClientHomePage {
  const ClientHomeAggressivePage({super.key})
    : super(variant: ClientHomeVariant.aggressive);
}

/// Vue de la page home (séparée pour faciliter les tests)
class ClientHomeView extends StatefulWidget {
  const ClientHomeView({
    super.key,
    this.variant = ClientHomeVariant.standard,
    this.scrollRequestToken = 0,
  });

  final ClientHomeVariant variant;
  final int scrollRequestToken;

  @override
  State<ClientHomeView> createState() => _ClientHomeViewState();
}

class _ClientHomeViewState extends State<ClientHomeView> {
  final GlobalKey _hanoutsSectionKey = const GlobalObjectKey(
    'client-home-hanouts-section',
  );
  final PromotionRepository _promotionRepository = PromotionRepository(
    ApiService(),
  );
  String? _selectedBusinessCategoryKey;
  Future<FirstDeliveryPromoStatusModel?>? _promoStatusFuture;
  Future<FirstDeliveryPromoConfigModel?>? _publicPromoConfigFuture;

  @override
  void didUpdateWidget(covariant ClientHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollRequestToken == oldWidget.scrollRequestToken) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToHanouts(context, hasHanouts: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticatedClient =
        authState is Authenticated && authState.role == UserRole.client;
    final promoStatusFuture = _resolvePromoStatusFuture(isAuthenticatedClient);
    final publicPromoConfigFuture = _resolvePublicPromoConfigFuture(
      isAuthenticatedClient,
    );
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
            return _buildLoadedView(
              context,
              state,
              isAuthenticatedClient: isAuthenticatedClient,
              promoStatusFuture: promoStatusFuture,
              publicPromoConfigFuture: publicPromoConfigFuture,
            );
          }

          // État vide - pas de hanouts trouvés
          if (state is ClientHomeEmpty) {
            if (state.isUsingFallbackLocation) {
              return _buildLocationPermissionDeniedView(
                context,
                isAuthenticatedClient: isAuthenticatedClient,
                promoStatusFuture: promoStatusFuture,
                publicPromoConfigFuture: publicPromoConfigFuture,
              );
            }
            return _buildNoHanoutAvailableView(
              context,
              isAuthenticatedClient: isAuthenticatedClient,
              promoStatusFuture: promoStatusFuture,
              publicPromoConfigFuture: publicPromoConfigFuture,
            );
          }

          // État d'erreur de permission
          if (state is ClientHomeLocationPermissionDenied) {
            return _buildLocationPermissionDeniedView(
              context,
              isAuthenticatedClient: isAuthenticatedClient,
              promoStatusFuture: promoStatusFuture,
              publicPromoConfigFuture: publicPromoConfigFuture,
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
  Widget _buildLoadedView(
    BuildContext context,
    ClientHomeLoaded state, {
    required bool isAuthenticatedClient,
    required Future<FirstDeliveryPromoStatusModel?>? promoStatusFuture,
    required Future<FirstDeliveryPromoConfigModel?>? publicPromoConfigFuture,
  }) {
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final availableCategories = _extractAvailableCategories(state.hanouts);
    final selectedCategoryKey =
        availableCategories.any(
          (category) =>
              _businessCategoryKey(category) == _selectedBusinessCategoryKey,
        )
        ? _selectedBusinessCategoryKey
        : null;
    final visibleHanouts = _filterHanoutsByCategory(
      state.hanouts,
      selectedCategoryKey,
    );

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
                child: _buildQuickActions(
                  context,
                  hasHanouts: state.hanouts.isNotEmpty,
                  isUsingFallbackLocation: state.isUsingFallbackLocation,
                  isAuthenticatedClient: isAuthenticatedClient,
                ),
              ),
            ),
            if (promoStatusFuture != null || publicPromoConfigFuture != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _buildPromoBanner(
                    promoStatusFuture: promoStatusFuture,
                    publicPromoConfigFuture: publicPromoConfigFuture,
                    compact: false,
                  ),
                ),
              ),
            if (state.isUsingFallbackLocation)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _buildLocationPermissionCard(context),
                ),
              ),

            // Section title + info carnet
            SliverToBoxAdapter(
              child: Padding(
                key: _hanoutsSectionKey,
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
                      subtitle: state.isUsingFallbackLocation
                          ? context.l10n.clientHomeFallbackHanoutsSubtitle
                          : context.l10n.clientHomeHanoutsFound(
                              visibleHanouts.length,
                            ),
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // _buildCarnetInfoBanner(context),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _buildBusinessCategoryFilters(
                  context,
                  categories: availableCategories,
                  hanouts: state.hanouts,
                  selectedCategoryKey: selectedCategoryKey,
                ),
              ),
            ),

            // Liste des hanouts
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final hanout = visibleHanouts[index];
                    return HanoutCard(
                      name: hanout.name,
                      address: hanout.address,
                      distance: hanout.formattedDistance,
                      categoryName: hanout.businessCategory?.displayName(
                        preferArabic: preferArabic,
                      ),
                      categoryIcon: hanout.businessCategory?.icon,
                      imageUrl: hanout.image,
                      rating: hanout.rating,
                      isOpen: hanout.isOpen,
                      hasCarnet: hanout.hasCarnet,
                      isEnabled: !state.isUsingFallbackLocation,
                      imageHeroTag: 'client-home-hanout-image-${hanout.id}',
                      onTap: () => state.isUsingFallbackLocation
                          ? _showLocationRequiredSnack(context)
                          : _navigateToHanoutDetails(context, hanout),
                    );
                  },
                  childCount: visibleHanouts.length,
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

  Widget _buildBusinessCategoryFilters(
    BuildContext context, {
    required List<BusinessCategoryModel> categories,
    required List<HanoutWithDistance> hanouts,
    required String? selectedCategoryKey,
  }) {
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final allCount = hanouts.length;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(
            label: context.l10n.clientOrdersFilterAll,
            icon: '🏪',
            count: allCount,
            isSelected: selectedCategoryKey == null,
            onTap: () {
              setState(() => _selectedBusinessCategoryKey = null);
            },
          ),
          ...categories.map((category) {
            final count = hanouts
                .where(
                  (hanout) =>
                      _hanoutBusinessCategoryKey(hanout) ==
                      _businessCategoryKey(category),
                )
                .length;

            return _buildCategoryChip(
              label: category.displayName(preferArabic: preferArabic),
              icon: category.displayIcon,
              count: count,
              isSelected: selectedCategoryKey == _businessCategoryKey(category),
              onTap: () {
                setState(
                  () => _selectedBusinessCategoryKey = _businessCategoryKey(
                    category,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: FilterChip(
        label: Text('$icon $label ($count)'),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.round),
      ),
    );
  }

  List<BusinessCategoryModel> _extractAvailableCategories(
    List<HanoutWithDistance> hanouts,
  ) {
    final map = <String, BusinessCategoryModel>{
      for (final category in _defaultBusinessCategories())
        _businessCategoryKey(category): category,
    };
    for (final hanout in hanouts) {
      final category = hanout.businessCategory;
      final key = _hanoutBusinessCategoryKey(hanout);
      if (category == null || key == null) continue;
      map[key] = category;
    }

    final categories = map.values.toList();
    categories.sort((a, b) {
      final orderComparison = (a.order ?? 0).compareTo(b.order ?? 0);
      if (orderComparison != 0) return orderComparison;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  List<HanoutWithDistance> _filterHanoutsByCategory(
    List<HanoutWithDistance> hanouts,
    String? businessCategoryKey,
  ) {
    if (businessCategoryKey == null) return hanouts;
    return hanouts
        .where(
          (hanout) => _hanoutBusinessCategoryKey(hanout) == businessCategoryKey,
        )
        .toList();
  }

  List<BusinessCategoryModel> _defaultBusinessCategories() {
    return const [
      BusinessCategoryModel(
        id: 'default-hanout',
        name: 'Hanout',
        nameAr: 'الحانوت',
        slug: 'hanout',
        icon: '🛒',
        order: 1,
        isDefault: true,
      ),
      BusinessCategoryModel(
        id: 'default-boucherie',
        name: 'Boucherie',
        nameAr: 'الجزار',
        slug: 'boucherie',
        icon: '🥩',
        order: 2,
        isDefault: true,
      ),
      BusinessCategoryModel(
        id: 'default-snack',
        name: 'Snack',
        nameAr: 'سناك',
        slug: 'snack',
        icon: '🍔',
        order: 3,
        isDefault: true,
      ),
      BusinessCategoryModel(
        id: 'default-legumes-et-fruits',
        name: 'Legumes et fruits',
        nameAr: 'الخضر والفواكه',
        slug: 'legumes-et-fruits',
        icon: '🍎',
        order: 4,
        isDefault: true,
      ),
      BusinessCategoryModel(
        id: 'default-patisserie',
        name: 'Patisserie',
        nameAr: 'الحلويات',
        slug: 'patisserie',
        icon: '🥐',
        order: 5,
        isDefault: true,
      ),
    ];
  }

  String _businessCategoryKey(BusinessCategoryModel category) {
    final slug = category.slug?.trim();
    if (slug != null && slug.isNotEmpty) {
      return slug;
    }
    return category.id;
  }

  String? _hanoutBusinessCategoryKey(HanoutWithDistance hanout) {
    final slug = hanout.businessCategory?.slug?.trim();
    if (slug != null && slug.isNotEmpty) {
      return slug;
    }
    final businessCategoryId = hanout.businessCategoryId?.trim();
    if (businessCategoryId != null && businessCategoryId.isNotEmpty) {
      return businessCategoryId;
    }
    return null;
  }

  Widget _buildQuickActions(
    BuildContext context, {
    required bool hasHanouts,
    required bool isUsingFallbackLocation,
    required bool isAuthenticatedClient,
  }) {
    return _buildAggressiveQuickActions(
      context,
      hasHanouts: hasHanouts,
      isUsingFallbackLocation: isUsingFallbackLocation,
      isAuthenticatedClient: isAuthenticatedClient,
    );
  }

  Widget _buildAggressiveQuickActions(
    BuildContext context, {
    required bool hasHanouts,
    required bool isUsingFallbackLocation,
    required bool isAuthenticatedClient,
  }) {
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
          onTap: () => _scrollToHanouts(context, hasHanouts: hasHanouts),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildAggressiveCtaCard(
          title: l10n.clientHomeQuickActionsGasTitle,
          subtitle: l10n.clientHomeQuickActionsGasSubtitle,
          icon: Icons.local_fire_department,
          color: AppColors.secondary,
          onTap: () => unawaited(
            _handleGasAction(
              context,
              hasHanouts: hasHanouts,
              isUsingFallbackLocation: isUsingFallbackLocation,
              isAuthenticatedClient: isAuthenticatedClient,
            ),
          ),
          badge: l10n.clientHomeQuickActionsGasBadge,
        ),
      ],
    );
  }

  Widget _buildLocationPermissionDeniedView(
    BuildContext context, {
    required bool isAuthenticatedClient,
    required Future<FirstDeliveryPromoStatusModel?>? promoStatusFuture,
    required Future<FirstDeliveryPromoConfigModel?>? publicPromoConfigFuture,
  }) {
    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<ClientHomeCubit>().refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroHeader(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _buildQuickActions(
                  context,
                  hasHanouts: true,
                  isUsingFallbackLocation: true,
                  isAuthenticatedClient: isAuthenticatedClient,
                ),
              ),
            ),
            if (promoStatusFuture != null || publicPromoConfigFuture != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _buildPromoBanner(
                    promoStatusFuture: promoStatusFuture,
                    publicPromoConfigFuture: publicPromoConfigFuture,
                    compact: true,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                key: _hanoutsSectionKey,
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
                      subtitle: context.l10n.clientHomeFallbackHanoutsSubtitle,
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildLocationPermissionCard(context),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHanoutAvailableView(
    BuildContext context, {
    required bool isAuthenticatedClient,
    required Future<FirstDeliveryPromoStatusModel?>? promoStatusFuture,
    required Future<FirstDeliveryPromoConfigModel?>? publicPromoConfigFuture,
  }) {
    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<ClientHomeCubit>().refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroHeader(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _buildQuickActions(
                  context,
                  hasHanouts: false,
                  isUsingFallbackLocation: false,
                  isAuthenticatedClient: isAuthenticatedClient,
                ),
              ),
            ),
            if (promoStatusFuture != null || publicPromoConfigFuture != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _buildPromoBanner(
                    promoStatusFuture: promoStatusFuture,
                    publicPromoConfigFuture: publicPromoConfigFuture,
                    compact: true,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                key: _hanoutsSectionKey,
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
                      subtitle: context.l10n.clientHomeNoHanoutNearby,
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildBusinessCategoryFilters(
                      context,
                      categories: _extractAvailableCategories(const []),
                      hanouts: const [],
                      selectedCategoryKey: _selectedBusinessCategoryKey,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildNoHanoutCard(context),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  Future<FirstDeliveryPromoStatusModel?>? _resolvePromoStatusFuture(
    bool isAuthenticatedClient,
  ) {
    if (!isAuthenticatedClient) {
      _promoStatusFuture = null;
      return null;
    }

    _promoStatusFuture ??= _promotionRepository
        .getFirstDeliveryPromoStatus()
        .then<FirstDeliveryPromoStatusModel?>((value) => value)
        .onError((_, __) => null);
    return _promoStatusFuture;
  }

  Future<FirstDeliveryPromoConfigModel?>? _resolvePublicPromoConfigFuture(
    bool isAuthenticatedClient,
  ) {
    if (isAuthenticatedClient) {
      _publicPromoConfigFuture = null;
      return null;
    }

    _publicPromoConfigFuture ??= _promotionRepository
        .getFirstDeliveryPromoPublicConfig()
        .then<FirstDeliveryPromoConfigModel?>((value) => value)
        .onError((_, __) => null);
    return _publicPromoConfigFuture;
  }

  Widget _buildPromoBanner({
    Future<FirstDeliveryPromoStatusModel?>? promoStatusFuture,
    Future<FirstDeliveryPromoConfigModel?>? publicPromoConfigFuture,
    required bool compact,
  }) {
    if (promoStatusFuture != null) {
      return FutureBuilder<FirstDeliveryPromoStatusModel?>(
        future: promoStatusFuture,
        builder: (context, snapshot) {
          final status = snapshot.data;
          if (status == null || !status.canShowMarketingBanner) {
            return const SizedBox.shrink();
          }

          return FirstDeliveryPromoBanner(
            status: status,
            compact: compact,
          );
        },
      );
    }

    if (publicPromoConfigFuture != null) {
      return FutureBuilder<FirstDeliveryPromoConfigModel?>(
        future: publicPromoConfigFuture,
        builder: (context, snapshot) {
          final config = snapshot.data;
          if (config == null || !config.firstDeliveryFreeEnabled) {
            return const SizedBox.shrink();
          }

          return FirstDeliveryPromoBanner(
            config: config,
            compact: compact,
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNoHanoutCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: AppRadius.large,
            ),
            child: const Icon(
              Icons.store_mall_directory_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.clientHomeNoHanoutNearby,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPermissionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.12),
              borderRadius: AppRadius.large,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.clientHomeLocationPermissionDenied,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: context.l10n.clientHomeLocationPermissionAction,
            icon: Icons.my_location_rounded,
            fullWidth: true,
            onPressed: () => unawaited(_requestLocationAccess(context)),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: context.l10n.clientHomeLocationPermissionRetry,
            icon: Icons.refresh_rounded,
            fullWidth: true,
            onPressed: () => unawaited(
              context.read<ClientHomeCubit>().refresh(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLocationAccess(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    if (permission == LocationPermission.denied) {
      return;
    }

    if (!context.mounted) return;
    await context.read<ClientHomeCubit>().loadNearbyHanouts();
  }

  void _scrollToHanouts(
    BuildContext context, {
    required bool hasHanouts,
  }) {
    final targetContext = _hanoutsSectionKey.currentContext;
    if (targetContext == null) {
      AppSnackBar.show(
        context,
        message: hasHanouts
            ? context.l10n.clientHomeScrollForHanouts
            : context.l10n.clientHomeNoHanoutNearby,
        type: hasHanouts ? SnackBarType.info : SnackBarType.warning,
      );
      return;
    }

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
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
    if (widget.variant == ClientHomeVariant.aggressive) {
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

  void _showGasServiceSheet(
    BuildContext context, {
    required bool isAuthenticatedClient,
    _GasRequestDraft? initialDraft,
  }) {
    final parentContext = context;
    final addressController = TextEditingController(
      text: initialDraft?.address ?? '',
    );
    final notesController = TextEditingController(
      text: initialDraft?.notes ?? '',
    );
    bool isSubmitting = false;
    bool isLocating = false;
    var canSubmitWithoutPrompt = isAuthenticatedClient;
    double? clientLatitude = initialDraft?.clientLatitude;
    double? clientLongitude = initialDraft?.clientLongitude;

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
                            if (!canSubmitWithoutPrompt) {
                              final draft = _GasRequestDraft(
                                address: address,
                                notes: notes,
                                clientLatitude: clientLatitude,
                                clientLongitude: clientLongitude,
                              );
                              Navigator.of(context).pop();
                              final authenticated = await showClientAuthPrompt(
                                context: parentContext,
                                title: context.l10n.clientGuestGasPromptTitle,
                                message:
                                    context.l10n.clientGuestGasPromptMessage,
                              );
                              if (!parentContext.mounted || !authenticated) {
                                return;
                              }
                              _showGasServiceSheet(
                                parentContext,
                                isAuthenticatedClient: true,
                                initialDraft: draft,
                              );
                              return;
                            }
                            await LocalNotificationService.instance
                                .requestPermissionsIfNeeded();
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

  Future<void> _handleGasAction(
    BuildContext context, {
    required bool hasHanouts,
    required bool isUsingFallbackLocation,
    required bool isAuthenticatedClient,
  }) async {
    if (isUsingFallbackLocation) {
      AppSnackBar.show(
        context,
        message: context.l10n.clientGasRequiresLocationForAvailability,
        type: SnackBarType.info,
      );
      return;
    }

    if (!hasHanouts) {
      AppSnackBar.show(
        context,
        message: context.l10n.clientGasUnavailableInZone,
        type: SnackBarType.warning,
      );
      return;
    }

    _showGasServiceSheet(
      context,
      isAuthenticatedClient: isAuthenticatedClient,
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
        price: 15,
        serviceFee: 0,
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

  void _showLocationRequiredSnack(BuildContext context) {
    AppSnackBar.show(
      context,
      message: context.l10n.clientHomeFallbackHanoutTapMessage,
      type: SnackBarType.info,
    );
  }
}

class _GasRequestDraft {
  const _GasRequestDraft({
    required this.address,
    required this.notes,
    required this.clientLatitude,
    required this.clientLongitude,
  });

  final String address;
  final String notes;
  final double? clientLatitude;
  final double? clientLongitude;
}
