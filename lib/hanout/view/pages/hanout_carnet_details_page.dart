import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/carnet_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_cubit.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_transactions_cubit.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_transactions_state.dart';
import 'package:sevenouti/hanout/cubbit/hanout_orders_cubit.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';
import 'package:sevenouti/hanout/view/pages/hanout_order_details_page.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/localized_formatters.dart';

class HanoutCarnetDetailsPage extends StatelessWidget {
  const HanoutCarnetDetailsPage({
    required this.carnet,
    super.key,
  });

  final HanoutCarnetModel carnet;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HanoutCarnetTransactionsCubit(
        carnetRepository: HanoutCarnetRepository(ApiService()),
      )..loadTransactions(carnet),
      child: HanoutCarnetDetailsView(carnet: carnet),
    );
  }
}

class HanoutCarnetDetailsView extends StatelessWidget {
  const HanoutCarnetDetailsView({
    required this.carnet,
    super.key,
  });

  final HanoutCarnetModel carnet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasDebt = carnet.hasDebt;
    final client = carnet.client;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hanoutCarnetClientBookTitle),
      ),
      body: AppBackground(
        child: Column(
          children: [
            _buildHeader(context, hasDebt, client),
            Expanded(
              child:
                  BlocBuilder<
                    HanoutCarnetTransactionsCubit,
                    HanoutCarnetTransactionsState
                  >(
                    builder: (context, state) {
                      if (state is HanoutCarnetTransactionsLoading) {
                        return LoadingView(
                          message: l10n.hanoutCarnetTransactionsLoading,
                        );
                      }

                      if (state is HanoutCarnetTransactionsEmpty) {
                        return EmptyView(
                          message: l10n.hanoutCarnetTransactionsEmpty,
                          icon: Icons.receipt_long_outlined,
                        );
                      }

                      if (state is HanoutCarnetTransactionsError) {
                        return ErrorView(
                          message: state.message,
                          onRetry: () => context
                              .read<HanoutCarnetTransactionsCubit>()
                              .loadTransactions(carnet),
                        );
                      }

                      if (state is HanoutCarnetTransactionsLoaded) {
                        return _buildTransactionsList(context, state);
                      }

                      return const SizedBox.shrink();
                    },
                  ),
            ),
            _buildActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool hasDebt,
    HanoutClientSummary? client,
  ) {
    final l10n = context.l10n;
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final color = hasDebt ? AppColors.error : AppColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.9),
            color,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              client?.displayName(preferArabic: preferArabic) ??
                  l10n.hanoutCommonClient,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              client?.phone ?? '-',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.hanoutCarnetCurrentDebt,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (hasDebt)
                  Text(
                    '-',
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                Text(
                  formatDh(context, carnet.balance.abs()).split(' ').first,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    isArabicLocale(context) ? 'د.م' : 'DH',
                    style: AppTextStyles.h3.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _buildInfoChip(
                  label: l10n.hanoutCarnetLimit,
                  value: carnet.creditLimit != null
                      ? formatDh(context, carnet.creditLimit!)
                      : l10n.hanoutCarnetUndefined,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (carnet.isLimitReached || carnet.isLimitNear)
                  _buildLimitBadge(context, carnet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    HanoutCarnetTransactionsLoaded state,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildStats(context, state),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.l10n.hanoutCarnetTransactionsHistory,
              style: AppTextStyles.h3,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final transaction = state.transactions[index];
                final showDate =
                    index == 0 ||
                    !_isSameDay(
                      transaction.createdAt,
                      state.transactions[index - 1].createdAt,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDate)
                      _buildDateHeader(context, transaction.createdAt),
                    _buildTransactionCard(context, transaction),
                  ],
                );
              },
              childCount: state.transactions.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildStats(
    BuildContext context,
    HanoutCarnetTransactionsLoaded state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context: context,
              icon: Icons.shopping_cart,
              label: context.l10n.hanoutCarnetCreditPurchases,
              value: state.totalCredit,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              context: context,
              icon: Icons.payments,
              label: context.l10n.hanoutCarnetPayments,
              value: state.totalPayments,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: AppShadows.card,
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
            formatDh(context, value),
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        formatRelativeDateLocalized(context, date),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    CarnetTransactionModel transaction,
  ) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          borderRadius: AppRadius.large,
          onTap: () => _handleTransactionTap(context, transaction),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
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
                        formatRelativeDateLocalized(
                          context,
                          transaction.createdAt,
                        ),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
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
                      context.l10n.hanoutCarnetBalanceAfter(
                        formatDh(
                          context,
                          transaction.balanceAfter,
                        ).split(' ').first,
                      ),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.round,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitBadge(BuildContext context, HanoutCarnetModel carnet) {
    final isReached = carnet.isLimitReached;
    final color = isReached ? AppColors.error : AppColors.warning;
    final label = isReached
        ? context.l10n.hanoutCarnetLimitReached
        : context.l10n.hanoutCarnetLimitNear;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.round,
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildActionBar(BuildContext context) {
    final l10n = context.l10n;
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showLimitDialog(context),
                icon: const Icon(Icons.tune),
                label: Text(l10n.hanoutCarnetLimit),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(context),
                icon: const Icon(Icons.payments),
                label: Text(l10n.hanoutCarnetPayment),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showPhysicalOrderDialog(context),
                icon: const Icon(Icons.storefront),
                label: Text(l10n.hanoutCarnetPhysicalOrderShort),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLimitDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: carnet.creditLimit?.toStringAsFixed(2) ?? '',
    );

    final value = await showAppBottomSheet<double>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(l10n.hanoutCarnetSetLimitTitle),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.hanoutCarnetLimitDh),
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
                    final parsed = double.tryParse(controller.text.trim());
                    Navigator.of(context).pop(parsed);
                  },
                  child: Text(l10n.hanoutCommonSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (value != null && context.mounted) {
      await context.read<HanoutCarnetCubit>().updateCreditLimit(
        carnet.id,
        value,
      );
      if (!context.mounted) return;
      await context.read<HanoutCarnetTransactionsCubit>().loadTransactions(
        carnet,
      );
    }
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final l10n = context.l10n;
    final amountController = TextEditingController();
    final descController = TextEditingController();

    final result = await showAppBottomSheet<Map<String, dynamic>>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(l10n.hanoutCarnetRecordPaymentTitle),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.hanoutCarnetAmountDh),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: descController,
            decoration: InputDecoration(
              labelText: l10n.hanoutCommonDescription,
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
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null) {
                      AppSnackBar.show(
                        context,
                        message: l10n.hanoutCarnetInvalidAmount,
                        type: SnackBarType.error,
                      );
                      return;
                    }
                    Navigator.of(context).pop({
                      'amount': amount,
                      'description': descController.text.trim(),
                    });
                  },
                  child: Text(l10n.hanoutCommonSave),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await context.read<HanoutCarnetCubit>().recordPayment(
        carnet.id,
        result['amount'] as double,
        description: (result['description'] as String).isEmpty
            ? null
            : result['description'] as String,
      );
      if (!context.mounted) return;
      await context.read<HanoutCarnetTransactionsCubit>().loadTransactions(
        carnet,
      );
    }
  }

  Future<void> _showPhysicalOrderDialog(BuildContext context) async {
    final l10n = context.l10n;
    final amountController = TextEditingController();
    final descController = TextEditingController();

    final result = await showAppBottomSheet<Map<String, dynamic>>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(l10n.hanoutCarnetAddPhysicalOrderTitle),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.hanoutCarnetAmountDh),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: descController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.hanoutCarnetOrderDescription,
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
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    final description = descController.text.trim();
                    if (amount == null || amount <= 0) {
                      AppSnackBar.show(
                        context,
                        message: l10n.hanoutCarnetInvalidAmount,
                        type: SnackBarType.error,
                      );
                      return;
                    }
                    if (description.isEmpty) {
                      AppSnackBar.show(
                        context,
                        message: l10n.hanoutCarnetDescriptionRequired,
                        type: SnackBarType.error,
                      );
                      return;
                    }
                    Navigator.of(context).pop({
                      'amount': amount,
                      'description': description,
                    });
                  },
                  child: Text(l10n.hanoutCarnetAdd),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await context.read<HanoutCarnetCubit>().addDebt(
        carnet.id,
        result['amount'] as double,
        description: result['description'] as String,
      );
      if (!context.mounted) return;
      await context.read<HanoutCarnetTransactionsCubit>().loadTransactions(
        carnet,
      );
    }
  }

  Future<void> _handleTransactionTap(
    BuildContext context,
    CarnetTransactionModel transaction,
  ) async {
    if (transaction.orderId != null) {
      await _openOrderDetails(context, transaction.orderId!);
      return;
    }

    await _showPhysicalOrderDescription(context, transaction);
  }

  Future<void> _openOrderDetails(BuildContext context, String orderId) async {
    try {
      final ordersRepository = HanoutOrdersRepository(ApiService());
      final orders = await ordersRepository.getHanoutOrders(limit: 500);

      HanoutOrderModel? order;
      for (final candidate in orders) {
        if (candidate.id == orderId) {
          order = candidate;
          break;
        }
      }

      if (order == null) {
        if (!context.mounted) return;
        AppSnackBar.show(
          context,
          message: context.l10n.hanoutOrderNotFound,
          type: SnackBarType.error,
        );
        return;
      }
      final resolvedOrder = order;
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider(
            create: (_) => HanoutOrdersCubit(
              ordersRepository: HanoutOrdersRepository(ApiService()),
            ),
            child: HanoutOrderDetailsPage(order: resolvedOrder),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: e.message,
        type: SnackBarType.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: context.l10n.hanoutOrderLoadError,
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _showPhysicalOrderDescription(
    BuildContext context,
    CarnetTransactionModel transaction,
  ) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.hanoutCarnetPhysicalOrderTitle),
          content: Text(
            (transaction.description ?? '').trim().isNotEmpty
                ? transaction.description!
                : l10n.hanoutCarnetNoDescription,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.clientCommonClose),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
