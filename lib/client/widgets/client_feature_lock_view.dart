import 'package:flutter/material.dart';
import 'package:sevenouti/client/widgets/client_auth_prompt.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/buttons.dart';
import 'package:sevenouti/l10n/l10n.dart';

class ClientFeatureLockView extends StatelessWidget {
  const ClientFeatureLockView({
    required this.icon,
    required this.title,
    required this.message,
    required this.promptTitle,
    required this.promptMessage,
    required this.highlights,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String promptTitle;
  final String promptMessage;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.extraLarge,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.95),
                        AppColors.accent.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: AppRadius.large,
                  ),
                  child: Icon(icon, color: Colors.white, size: 34),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.sm),
                Text(message, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                ...highlights.map(
                  (highlight) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppRadius.large,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.14),
                              borderRadius: AppRadius.round,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              highlight,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: context.l10n.authLoginButton,
                  icon: Icons.login,
                  fullWidth: true,
                  onPressed: () => _openPrompt(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: context.l10n.authCreateAccount,
                  icon: Icons.person_add_alt_1_rounded,
                  fullWidth: true,
                  onPressed: () => _openPrompt(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPrompt(BuildContext context) async {
    await showClientAuthPrompt(
      context: context,
      title: promptTitle,
      message: promptMessage,
    );
  }
}
