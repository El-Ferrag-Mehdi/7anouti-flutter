import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_cubit.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_state.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';
import 'package:sevenouti/hanout/view/pages/hanout_carnet_details_page.dart';
import 'package:sevenouti/l10n/l10n.dart';

class HanoutClientsPage extends StatelessWidget {
  const HanoutClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HanoutCarnetCubit(
        carnetRepository: HanoutCarnetRepository(ApiService()),
      )..loadCarnetsOnly(),
      child: const HanoutClientsView(),
    );
  }
}

class HanoutClientsView extends StatelessWidget {
  const HanoutClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HanoutCarnetCubit, HanoutCarnetState>(
      builder: (context, state) {
        if (state is HanoutCarnetInitial || state is HanoutCarnetLoading) {
          return AppBackground(
            child: LoadingView(message: l10n.hanoutClientsLoading),
          );
        }

        if (state is HanoutCarnetEmpty) {
          return AppBackground(
            child: EmptyView(
              message: l10n.hanoutClientsEmpty,
              icon: Icons.people_outline,
            ),
          );
        }

        if (state is HanoutCarnetError) {
          return AppBackground(
            child: ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<HanoutCarnetCubit>().loadCarnetsOnly(),
            ),
          );
        }

        if (state is HanoutCarnetLoaded) {
          return _buildList(context, state.carnets);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildList(BuildContext context, List<HanoutCarnetModel> carnets) {
    final l10n = context.l10n;
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    return AppBackground(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: carnets.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final carnet = carnets[index];
          final client = carnet.client;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.large,
              onTap: () => _openDetails(context, carnet),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.large,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client?.displayName(preferArabic: preferArabic) ??
                                l10n.hanoutCommonClient,
                            style: AppTextStyles.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            client?.phone ?? '-',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.hanoutClientsDebt(carnet.formattedBalance),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: carnet.hasDebt
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (carnet.isLimitReached || carnet.isLimitNear)
                      _buildLimitBadge(context, carnet),
                  ],
                ),
              ),
            ),
          );
        },
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

  void _openDetails(BuildContext context, HanoutCarnetModel carnet) {
    final cubit = context.read<HanoutCarnetCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: HanoutCarnetDetailsPage(carnet: carnet),
        ),
      ),
    );
  }
}
