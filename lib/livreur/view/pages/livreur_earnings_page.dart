import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';
import 'package:sevenouti/utils/localized_formatters.dart';

class LivreurEarningsPage extends StatelessWidget {
  const LivreurEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LivreurEarningsCubit(
        repository: LivreurEarningsRepository(ApiService()),
      ),
      child: const LivreurEarningsView(),
    );
  }
}

class LivreurEarningsCubit extends Cubit<LivreurEarningsState> {
  LivreurEarningsCubit({required LivreurEarningsRepository repository})
    : _repository = repository,
      super(const LivreurEarningsInitial());

  final LivreurEarningsRepository _repository;

  Future<void> load({String? month}) async {
    emit(const LivreurEarningsLoading());
    try {
      final data = await _repository.getEarnings(month: month);
      emit(LivreurEarningsLoaded(data: data));
    } on ApiException catch (e) {
      emit(LivreurEarningsError(message: e.message));
    } catch (e) {
      emit(LivreurEarningsError(message: e.toString()));
    }
  }
}

abstract class LivreurEarningsState extends Equatable {
  const LivreurEarningsState();

  @override
  List<Object?> get props => [];
}

class LivreurEarningsInitial extends LivreurEarningsState {
  const LivreurEarningsInitial();
}

class LivreurEarningsLoading extends LivreurEarningsState {
  const LivreurEarningsLoading();
}

class LivreurEarningsLoaded extends LivreurEarningsState {
  const LivreurEarningsLoaded({required this.data});

  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [data];
}

class LivreurEarningsError extends LivreurEarningsState {
  const LivreurEarningsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class LivreurEarningsView extends StatefulWidget {
  const LivreurEarningsView({super.key});

  @override
  State<LivreurEarningsView> createState() => _LivreurEarningsViewState();
}

class _LivreurEarningsViewState extends State<LivreurEarningsView> {
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = _currentMonthKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LivreurEarningsCubit>().load(month: _selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LivreurEarningsCubit, LivreurEarningsState>(
      builder: (context, state) {
        if (state is LivreurEarningsInitial ||
            state is LivreurEarningsLoading) {
          return AppBackground(
            child: LoadingView(message: l10n.livreurEarningsLoading),
          );
        }

        if (state is LivreurEarningsError) {
          return AppBackground(
            child: ErrorView(
              message: state.message,
              onRetry: () => context.read<LivreurEarningsCubit>().load(
                month: _selectedMonth,
              ),
            ),
          );
        }

        if (state is LivreurEarningsLoaded) {
          final serverMonth =
              state.data['selectedMonth'] as String? ?? _selectedMonth;
          if (serverMonth != _selectedMonth) {
            _selectedMonth = serverMonth;
          }
          return _buildContent(context, state.data);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final l10n = context.l10n;
    final totalCollected =
        (data['totalCollected'] as num?)?.toDouble() ??
        (data['total'] as num?)?.toDouble() ??
        0;
    final ordersCollectedTotal =
        (data['ordersCollectedTotal'] as num?)?.toDouble() ?? 0;
    final gasCollectedTotal =
        (data['gasCollectedTotal'] as num?)?.toDouble() ??
        (data['gasTotal'] as num?)?.toDouble() ??
        0;
    final amountToTransfer =
        (data['amountToTransfer'] as num?)?.toDouble() ?? totalCollected;
    final hanoutDeliveryCount =
        (data['hanoutDeliveryCount'] as num?)?.toInt() ?? 0;
    final freeDeliveryPromoCompletedCount =
        (data['freeDeliveryPromoCompletedCount'] as num?)?.toInt() ?? 0;
    final freeDeliveryPromoPotentialReimbursementTotal =
        (data['freeDeliveryPromoPotentialReimbursementTotal'] as num?)
            ?.toDouble() ??
        0;
    final gasDeliveryCount =
        (data['gasDeliveryCount'] as num?)?.toInt() ??
        (data['gasCount'] as num?)?.toInt() ??
        0;
    final perOrder = (data['perOrder'] as List<dynamic>? ?? []);

    return AppBackground(
      child: RefreshIndicator(
        onRefresh: () =>
            context.read<LivreurEarningsCubit>().load(month: _selectedMonth),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.lg),
            _buildMonthPicker(context),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryCard(
              context,
              totalCollected: totalCollected,
              ordersCollectedTotal: ordersCollectedTotal,
              gasCollectedTotal: gasCollectedTotal,
              amountToTransfer: amountToTransfer,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: l10n.livreurEarningsHanoutDeliveries,
                    value: '$hanoutDeliveryCount',
                    icon: Icons.local_shipping,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatCard(
                    title: l10n.livreurEarningsGasServices,
                    value: '$gasDeliveryCount',
                    icon: Icons.local_fire_department,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: l10n.livreurEarningsOrdersCollected,
                    value: formatDh(context, ordersCollectedTotal),
                    icon: Icons.storefront,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatCard(
                    title: l10n.livreurEarningsGasCollected,
                    value: formatDh(context, gasCollectedTotal),
                    icon: Icons.payments,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: _promoDeliveriesTitle(context),
                    value: '$freeDeliveryPromoCompletedCount',
                    icon: Icons.card_giftcard,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatCard(
                    title: _promoReimbursementTitle(context),
                    value: formatDh(
                      context,
                      freeDeliveryPromoPotentialReimbursementTotal,
                    ),
                    icon: Icons.account_balance_wallet,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.livreurEarningsHistory, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            if (perOrder.isEmpty)
              EmptyView(
                message: l10n.livreurEarningsNoIncome,
                icon: Icons.monetization_on_outlined,
              )
            else
              ...perOrder.map((row) {
                final item = row as Map<String, dynamic>;
                final amount = (item['amount'] as num?)?.toDouble() ?? 0;
                final deliveredAt = item['deliveredAt'] != null
                    ? DateTime.parse(item['deliveredAt'] as String)
                    : null;
                final type = item['type'] as String? ?? 'ORDER';
                final hanout = item['hanout'] as Map<String, dynamic>?;
                final hanoutName =
                    hanout?['name'] as String? ??
                    l10n.clientOrderTrackingHanout;
                final hanoutAddress = hanout?['address'] as String? ?? '-';
                final clientAddress =
                    item['clientAddress'] as String? ??
                    l10n.livreurClientAddressFallback;
                final title = type == 'GAS'
                    ? l10n.livreurGasServiceTitle
                    : hanoutName;
                final subtitle = type == 'GAS' ? clientAddress : hanoutAddress;
                final badgeColor = type == 'GAS'
                    ? AppColors.warning
                    : AppColors.info;
                final freeDeliveryPromoApplied =
                    item['freeDeliveryPromoApplied'] as bool? ?? false;
                final freeDeliveryPromoReimbursementAmount =
                    (item['freeDeliveryPromoReimbursementAmount'] as num?)
                        ?.toDouble() ??
                    0;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.large,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: AppRadius.medium,
                        ),
                        child: Icon(
                          type == 'GAS'
                              ? Icons.local_fire_department
                              : Icons.receipt_long,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AppTextStyles.bodyMedium),
                            const SizedBox(height: 2),
                            Text(
                              formatAddressLocalized(context, subtitle),
                              style: AppTextStyles.caption,
                            ),
                            if (deliveredAt != null)
                              Text(
                                formatRelativeDateLocalized(
                                  context,
                                  deliveredAt,
                                ),
                                style: AppTextStyles.caption,
                              ),
                            if (freeDeliveryPromoApplied)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.14),
                                    borderRadius: AppRadius.round,
                                  ),
                                  child: Text(
                                    '${_promoChipLabel(context)} ${formatDh(context, freeDeliveryPromoReimbursementAmount)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        formatDh(context, amount),
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: AppRadius.large,
          ),
          child: Image.asset(
            'assets/logo/logo_icon.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.livreurEarningsTitle, style: AppTextStyles.h3),
              const SizedBox(height: 2),
              Text(
                l10n.livreurEarningsSubtitle,
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

  Widget _buildMonthPicker(BuildContext context) {
    final l10n = context.l10n;
    final options = _monthOptions(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedMonth,
        decoration: InputDecoration(
          labelText: l10n.livreurEarningsMonthLabel,
        ),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.key,
                child: Text(option.label),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null || value == _selectedMonth) return;
          setState(() {
            _selectedMonth = value;
          });
          context.read<LivreurEarningsCubit>().load(month: value);
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required double totalCollected,
    required double ordersCollectedTotal,
    required double gasCollectedTotal,
    required double amountToTransfer,
  }) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.livreurEarningsTotalCollected,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatDh(context, totalCollected),
            style: AppTextStyles.h2.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.livreurEarningsOrdersCollectedValue(
              ordersCollectedTotal.toStringAsFixed(2),
            ),
            style: AppTextStyles.bodySmall,
          ),
          Text(
            l10n.livreurEarningsGasCollectedValue(
              gasCollectedTotal.toStringAsFixed(2),
            ),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.livreurEarningsAmountToTransferValue(
              amountToTransfer.toStringAsFixed(2),
            ),
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: AppRadius.medium,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _promoDeliveriesTitle(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'توصيلات مجانية' : 'Livraisons gratuites';
  }

  String _promoReimbursementTitle(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'تعويض متوقع' : 'Remboursement potentiel';
  }

  String _promoChipLabel(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'توصيل مجاني' : 'Livraison gratuite';
  }

  List<_MonthOption> _monthOptions(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final monthFormatter = DateFormat('MMMM', localeCode);
    final now = DateTime.now();
    return List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      final monthName = monthFormatter.format(date);
      return _MonthOption(
        key: '${date.year}-${date.month.toString().padLeft(2, '0')}',
        label: '$monthName ${date.year}',
      );
    });
  }

  String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}

class _MonthOption {
  const _MonthOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}
