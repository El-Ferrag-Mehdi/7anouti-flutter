import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_cubit.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_state.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';
import 'package:sevenouti/hanout/view/pages/hanout_carnet_details_page.dart';
import 'package:sevenouti/l10n/l10n.dart';

class HanoutCarnetPage extends StatelessWidget {
  const HanoutCarnetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HanoutCarnetCubit(
        carnetRepository: HanoutCarnetRepository(ApiService()),
      )..loadAll(),
      child: const HanoutCarnetView(),
    );
  }
}

class HanoutCarnetView extends StatelessWidget {
  const HanoutCarnetView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: AppBackground(
        child: Column(
          children: [
            Material(
              color: AppColors.surface,
              child: TabBar(
                tabs: [
                  Tab(text: l10n.hanoutCarnetTabCarnets),
                  Tab(text: l10n.hanoutCarnetTabRequests),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<HanoutCarnetCubit, HanoutCarnetState>(
                builder: (context, state) {
                  if (state is HanoutCarnetInitial ||
                      state is HanoutCarnetLoading) {
                    return LoadingView(
                      message: l10n.hanoutCarnetLoading,
                    );
                  }

                  if (state is HanoutCarnetEmpty) {
                    return EmptyView(
                      message: l10n.hanoutCarnetEmptyAll,
                      icon: Icons.book_outlined,
                    );
                  }

                  if (state is HanoutCarnetError) {
                    return ErrorView(
                      message: state.message,
                      onRetry: () => context.read<HanoutCarnetCubit>().loadAll(),
                    );
                  }

                  if (state is HanoutCarnetLoaded) {
                    return TabBarView(
                      children: [
                        _buildCarnets(context, state.carnets),
                        _buildRequests(context, state.requests),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarnets(
    BuildContext context,
    List<HanoutCarnetModel> carnets,
  ) {
    final l10n = context.l10n;
    if (carnets.isEmpty) {
      return EmptyView(
        message: l10n.hanoutCarnetEmptyActive,
        icon: Icons.people_outline,
      );
    }

    return ListView.separated(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child:
                            const Icon(Icons.person, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client?.name ?? l10n.hanoutCommonClient,
                              style: AppTextStyles.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              client?.phone ?? '-',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (carnet.isLimitReached || carnet.isLimitNear)
                        _buildLimitBadge(context, carnet),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          label: l10n.hanoutCarnetDebt,
                          value: carnet.formattedBalance,
                          color: carnet.hasDebt
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildInfoChip(
                          label: l10n.hanoutCarnetLimit,
                          value: carnet.creditLimit != null
                              ? '${carnet.creditLimit!.toStringAsFixed(2)} DH'
                              : l10n.hanoutCarnetUndefined,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showLimitDialog(context, carnet),
                          icon: const Icon(Icons.tune),
                          label: Text(l10n.hanoutCarnetLimit),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(context, carnet),
                          icon: const Icon(Icons.payments),
                          label: Text(l10n.hanoutCarnetPayment),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequests(
    BuildContext context,
    List<HanoutCarnetRequestModel> requests,
  ) {
    final l10n = context.l10n;
    if (requests.isEmpty) {
      return EmptyView(
        message: l10n.hanoutCarnetNoRequests,
        icon: Icons.mail_outline,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final request = requests[index];
        final client = request.client;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client?.name ?? l10n.hanoutCommonClient,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                client?.phone ?? '-',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.read<HanoutCarnetCubit>().rejectRequest(
                                request.id,
                                l10n.hanoutCarnetRejectReason,
                              ),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.hanoutCarnetReject),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.read<HanoutCarnetCubit>().approveRequest(
                                request.id,
                              ),
                      icon: const Icon(Icons.check),
                      label: Text(l10n.hanoutCarnetApprove),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Future<void> _showLimitDialog(
    BuildContext context,
    HanoutCarnetModel carnet,
  ) async {
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

    if (value != null) {
      await context.read<HanoutCarnetCubit>().updateCreditLimit(
            carnet.id,
            value,
          );
    }
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    HanoutCarnetModel carnet,
  ) async {
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
            decoration: InputDecoration(labelText: l10n.hanoutCommonDescription),
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
                    final amount = double.tryParse(amountController.text.trim());
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

    if (result != null) {
      await context.read<HanoutCarnetCubit>().recordPayment(
            carnet.id,
            result['amount'] as double,
            description: (result['description'] as String).isEmpty
                ? null
                : result['description'] as String,
          );
    }
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
