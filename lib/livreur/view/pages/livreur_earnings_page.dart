import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      )..load(),
      child: const LivreurEarningsView(),
    );
  }
}

class LivreurEarningsCubit extends Cubit<LivreurEarningsState> {
  LivreurEarningsCubit({required LivreurEarningsRepository repository})
    : _repository = repository,
      super(const LivreurEarningsInitial());

  final LivreurEarningsRepository _repository;

  Future<void> load() async {
    emit(const LivreurEarningsLoading());
    try {
      final data = await _repository.getEarnings();
      emit(LivreurEarningsLoaded(data: data));
    } on ApiException catch (e) {
      emit(LivreurEarningsError(message: e.message));
    } catch (e) {
      emit(
        LivreurEarningsError(
          message: e.toString(),
        ),
      );
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

class LivreurEarningsView extends StatelessWidget {
  const LivreurEarningsView({super.key});

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
              onRetry: () => context.read<LivreurEarningsCubit>().load(),
            ),
          );
        }

        if (state is LivreurEarningsLoaded) {
          return _buildContent(context, state.data);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final l10n = context.l10n;
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final deliveryFee = (data['deliveryFee'] as num?)?.toDouble() ?? 0;
    final serviceFee = (data['serviceFee'] as num?)?.toDouble() ?? 0;
    final gasTotal = (data['gasTotal'] as num?)?.toDouble() ?? 0;
    final gasCount = (data['gasCount'] as num?)?.toInt() ?? 0;
    final List<dynamic> perOrder = (data['perOrder'] as List<dynamic>? ?? []);

    return AppBackground(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.lg),
          _buildTotalCard(context, total, deliveryFee, serviceFee),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: l10n.livreurEarningsDeliveries,
                  value: '${perOrder.length}',
                  icon: Icons.local_shipping,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  title: l10n.livreurEarningsServiceFees,
                  value: formatDh(context, serviceFee),
                  icon: Icons.receipt_long,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          if (gasCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: l10n.livreurEarningsGasServices,
                    value: '$gasCount',
                    icon: Icons.local_fire_department,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatCard(
                    title: l10n.livreurEarningsGasGain,
                    value: formatDh(context, gasTotal),
                    icon: Icons.payments,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
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
              final Map<String, dynamic> item = row as Map<String, dynamic>;
              final amount = (item['amount'] as num?)?.toDouble() ?? 0;
              final deliveredAt = item['deliveredAt'] != null
                  ? DateTime.parse(item['deliveredAt'] as String)
                  : null;
              final type = item['type'] as String? ?? 'ORDER';
              final hanout = item['hanout'] as Map<String, dynamic>?;
              final hanoutName =
                  hanout?['name'] as String? ?? l10n.clientOrderTrackingHanout;
              final hanoutAddress = hanout?['address'] as String? ?? '-';
              final clientAddress =
                  item['clientAddress'] as String? ??
                  l10n.livreurClientAddressFallback;
              final title = type == 'GAS'
                  ? l10n.livreurGasServiceTitle
                  : hanoutName;
              final subtitle = type == 'GAS' ? clientAddress : hanoutAddress;

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
                        color: AppColors.info.withOpacity(0.12),
                        borderRadius: AppRadius.medium,
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatAddressLocalized(context, subtitle),
                            style: AppTextStyles.caption,
                          ),
                          if (deliveredAt != null)
                            Text(
                              formatRelativeDateLocalized(context, deliveredAt),
                              style: AppTextStyles.caption,
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

  Widget _buildTotalCard(
    BuildContext context,
    double total,
    double deliveryFee,
    double serviceFee,
  ) {
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
          Text(l10n.clientCommonTotal, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatDh(context, total),
            style: AppTextStyles.h2.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.livreurEarningsDeliveryFees(deliveryFee.toStringAsFixed(2)),
            style: AppTextStyles.bodySmall,
          ),
          Text(
            l10n.livreurEarningsServiceFeesValue(serviceFee.toStringAsFixed(2)),
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
}
