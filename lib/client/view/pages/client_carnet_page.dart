import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/client_carnet_cubit.dart';
import 'package:sevenouti/client/cubit/client_carnet_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/carnet_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/client/view/pages/carnet_details_page.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/date_utils.dart' as app_date;

/// Page Carnet du client - Gestion du crédit
class ClientCarnetPage extends StatelessWidget {
  const ClientCarnetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ClientCarnetCubit(
        carnetRepository: CarnetRepository(ApiService()),
      )..loadCarnets(), // Mode MOCK
      child: const ClientCarnetView(),
    );
  }
}

class ClientCarnetView extends StatelessWidget {
  const ClientCarnetView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: BlocBuilder<ClientCarnetCubit, ClientCarnetState>(
        builder: (context, state) {
          // Loading
          if (state is ClientCarnetInitial || state is ClientCarnetLoading) {
            return AppBackground(
              child: LoadingView(message: l10n.clientCarnetLoading),
            );
          }

          // Empty
          if (state is ClientCarnetEmpty) {
            return AppBackground(
              child: EmptyView(
                message: l10n.clientCarnetEmptyMessage,
                icon: Icons.book_outlined,
                action: () {
                  // TODO: Navigate to hanouts list to request carnet
                },
                actionLabel: l10n.clientCarnetSeeHanouts,
              ),
            );
          }

          // Error
          if (state is ClientCarnetError) {
            return AppBackground(
              child: ErrorView(
                message: state.message,
                onRetry: () => context.read<ClientCarnetCubit>().loadCarnets(),
              ),
            );
          }

          // Loaded
          if (state is ClientCarnetLoaded) {
            return _buildLoadedView(context, state, l10n);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    ClientCarnetLoaded state,
    AppLocalizations l10n,
  ) {
    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () => context.read<ClientCarnetCubit>().refresh(),
        child: CustomScrollView(
          slivers: [
          // Header avec solde total
          SliverToBoxAdapter(
            child: _buildTotalBalanceHeader(state, l10n),
          ),

          // Info explicative
          SliverToBoxAdapter(
            child: _buildInfoBanner(l10n),
          ),

          // Liste des carnets
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final carnet = state.carnets[index];
                  return _buildCarnetCard(context, carnet, l10n);
                },
                childCount: state.carnets.length,
              ),
            ),
          ),

          // Padding bottom
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
          ],
        ),
      ),
    );
  }

  /// Header avec le solde total
  Widget _buildTotalBalanceHeader(ClientCarnetLoaded state, AppLocalizations l10n) {
    final totalBalance = state.totalBalance;
    final hasDebt = totalBalance > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasDebt
              ? [
                  AppColors.accent.withOpacity(0.95),
                  AppColors.primary,
                ]
              : [
                  AppColors.secondary,
                  AppColors.success,
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.clientCarnetTitle,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Solde total
            Text(
              l10n.clientCarnetTotalBalance,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDebt ? '-' : '',
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                  ),
                ),
                Text(
                  totalBalance.abs().toStringAsFixed(2),
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'DH',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Statut
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: AppRadius.round,
              ),
              child: Text(
                hasDebt
                    ? l10n.clientCarnetToRepay
                    : l10n.clientCarnetNoDebt,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Nombre de carnets actifs
            Row(
              children: [
                const Icon(Icons.book, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  l10n.clientCarnetActiveCount(state.activeCarnetCount),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Banner d'information
  Widget _buildInfoBanner(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.2),
          borderRadius: AppRadius.large,
          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppColors.brown,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.clientCarnetInfoBanner,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card d'un carnet
  Widget _buildCarnetCard(
    BuildContext context,
    CarnetModel carnet,
    AppLocalizations l10n,
  ) {
    final hasDebt = carnet.hasDebt;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: hasDebt
              ? AppColors.error.withOpacity(0.3)
              : AppColors.success.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: () => _navigateToDetails(context, carnet),
          borderRadius: AppRadius.large,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec hanout
                Row(
                  children: [
                    // Icône
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasDebt
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: AppRadius.medium,
                      ),
                      child: Icon(
                        Icons.store,
                        color: hasDebt ? AppColors.error : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Nom du hanout
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getHanoutName(carnet.hanoutId),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.clientCarnetActiveSince(
                              _formatActivationDate(context, carnet.activatedAt),
                            ),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),

                    // Flèche
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // Solde
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.clientCarnetCurrentBalance,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDebt)
                          Text(
                            '-',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          carnet.balance.abs().toStringAsFixed(2),
                          style: AppTextStyles.h3.copyWith(
                            color: hasDebt
                                ? AppColors.error
                                : AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'DH',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: hasDebt
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Dernière mise à jour
                Text(
                  l10n.clientCarnetLastActivity(
                    app_date.DateUtils.formatRelativeDate(carnet.updatedAt),
                  ),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === Helper Methods ===

  String _getHanoutName(String hanoutId) {
    // TODO: Récupérer le vrai nom depuis une map ou API
    final names = {
      'hanout1': 'Hanout Hassan',
      'hanout2': 'Épicerie Fatima',
      'hanout3': 'Hanout Al Baraka',
    };
    return names[hanoutId] ?? 'Hanout';
  }

  String _formatActivationDate(BuildContext context, DateTime? date) {
    final l10n = context.l10n;
    if (date == null) return l10n.clientCommonRecently;
    final diff = DateTime.now().difference(date).inDays;
    
    if (diff < 7) return l10n.clientCommonDays(diff);
    if (diff < 30) return l10n.clientCommonWeeks((diff / 7).floor());
    return l10n.clientCommonMonths((diff / 30).floor());
  }

  void _navigateToDetails(BuildContext context, CarnetModel carnet) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CarnetDetailsPage(carnet: carnet),
      ),
    );
  }
}








