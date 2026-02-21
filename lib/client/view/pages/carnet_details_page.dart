import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/carnet_transactions_cubit.dart';
import 'package:sevenouti/client/cubit/carnet_transactions_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/models.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/core/widgets/buttons.dart' hide TextButton;
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/date_utils.dart' as app_date;

/// Page de dÃ©tails d'un carnet avec historique des transactions
class CarnetDetailsPage extends StatelessWidget {
  const CarnetDetailsPage({
    required this.carnet,
    super.key,
  });

  final CarnetModel carnet;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CarnetTransactionsCubit(
        carnetRepository: CarnetRepository(ApiService()),
      )..loadTransactions(carnet), // Mode MOCK
      child: CarnetDetailsView(carnet: carnet),
    );
  }
}

class CarnetDetailsView extends StatelessWidget {
  const CarnetDetailsView({
    required this.carnet,
    super.key,
  });

  final CarnetModel carnet;

  @override
  Widget build(BuildContext context) {
    final hasDebt = carnet.hasDebt;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clientCarnetDetailsTitle),
        actions: [
          // Menu avec options
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.phone),
                    SizedBox(width: 8),
                    Text(l10n.clientCommonContactHanout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec solde
          _buildBalanceHeader(context, hasDebt),

          // Liste des transactions
          Expanded(
            child: BlocBuilder<CarnetTransactionsCubit, CarnetTransactionsState>(
              builder: (context, state) {
                if (state is CarnetTransactionsLoading) {
                  return LoadingView(
                    message: l10n.clientCarnetTransactionsLoading,
                  );
                }

                if (state is CarnetTransactionsEmpty) {
                  return EmptyView(
                    message: l10n.clientCarnetNoTransactions,
                    icon: Icons.receipt_long_outlined,
                  );
                }

                if (state is CarnetTransactionsError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<CarnetTransactionsCubit>()
                        .loadTransactions(carnet),
                  );
                }

                if (state is CarnetTransactionsLoaded) {
                  return _buildTransactionsList(context, state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Bouton de paiement (si dette)
          if (hasDebt) _buildPaymentButton(context),
        ],
      ),
    );
  }

  /// Header avec le solde du carnet
  Widget _buildBalanceHeader(BuildContext context, bool hasDebt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: hasDebt
            ? AppColors.error.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: hasDebt
                ? AppColors.error.withOpacity(0.3)
                : AppColors.success.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          // Hanout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store,
                color: hasDebt ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _getHanoutName(carnet.hanoutId),
                style: AppTextStyles.h3.copyWith(
                  color: hasDebt ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Solde
          Text(
            context.l10n.clientCarnetCurrentBalance,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDebt)
                Text(
                  '-',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.error,
                    fontSize: 36,
                  ),
                ),
              Text(
                carnet.balance.abs().toStringAsFixed(2),
                style: AppTextStyles.h1.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: hasDebt ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'DH',
                  style: AppTextStyles.h3.copyWith(
                    color: hasDebt ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Liste des transactions
  Widget _buildTransactionsList(
    BuildContext context,
    CarnetTransactionsLoaded state,
  ) {
    return CustomScrollView(
      slivers: [
        // Stats rÃ©sumÃ©
        SliverToBoxAdapter(
          child: _buildStats(context, state),
        ),

        // Titre section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.l10n.clientCarnetTransactionHistory,
              style: AppTextStyles.h3,
            ),
          ),
        ),

        // Liste groupÃ©e par date
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final transaction = state.transactions[index];
                final showDate = index == 0 ||
                    !_isSameDay(
                      transaction.createdAt,
                      state.transactions[index - 1].createdAt,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    if (showDate) _buildDateHeader(transaction.createdAt),

                    // Transaction card
                    _buildTransactionCard(context, transaction),
                  ],
                );
              },
              childCount: state.transactions.length,
            ),
          ),
        ),

        // Padding bottom
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  /// Stats rÃ©sumÃ© (total achats, total paiements)
  Widget _buildStats(BuildContext context, CarnetTransactionsLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.shopping_cart,
              label: context.l10n.clientCarnetCreditPurchases,
              value: state.totalCredit,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              icon: Icons.payments,
              label: context.l10n.clientCarnetPayments,
              value: state.totalPayments,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${value.toStringAsFixed(2)} DH',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Header de date
  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        app_date.DateUtils.formatDate(date),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Card d'une transaction
  Widget _buildTransactionCard(
    BuildContext context,
    CarnetTransactionModel transaction,
  ) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // IcÃ´ne
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  app_date.DateUtils.formatTime(transaction.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Montant
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmount,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.clientCarnetBalanceAfter(
                  transaction.balanceAfter.toStringAsFixed(2),
                ),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bouton de paiement
  Widget _buildPaymentButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.elevated,
      ),
      child: SafeArea(
        child: PrimaryButton(
          label: context.l10n.clientCarnetMakePayment,
          icon: Icons.payments,
          onPressed: () => _showPaymentDialog(context),
          fullWidth: true,
        ),
      ),
    );
  }

  // === Helper Methods ===

  String _getHanoutName(String hanoutId) {
    final names = {
      'hanout1': 'Hanout Hassan',
      'hanout2': 'Ã‰picerie Fatima',
      'hanout3': 'Hanout Al Baraka',
    };
    return names[hanoutId] ?? 'Hanout';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'contact':
        _contactHanout(context);
        break;
    }
  }

  void _contactHanout(BuildContext context) {
    // TODO: Lancer l'appel tÃ©lÃ©phonique
    AppSnackBar.show(
      context,
      message: context.l10n.clientCarnetCallingHanout,
      type: SnackBarType.info,
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(context.l10n.clientCarnetPaymentTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.clientCarnetPaymentMessage,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              borderRadius: AppRadius.large,
              border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.brown),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.clientCarnetOnlineSoon,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.brown,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.clientCommonClose),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _contactHanout(context);
                  },
                  child: Text(context.l10n.clientCarnetCallHanout),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


