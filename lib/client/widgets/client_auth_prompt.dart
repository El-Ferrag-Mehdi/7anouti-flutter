import 'package:flutter/material.dart';
import 'package:sevenouti/auth/view/login_page.dart';
import 'package:sevenouti/auth/view/register_page.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/buttons.dart' as app_buttons;
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/l10n/l10n.dart';

Future<bool> showClientAuthPrompt({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    child: _ClientAuthPromptContent(
      title: title,
      message: message,
    ),
  );

  return result ?? false;
}

class _ClientAuthPromptContent extends StatelessWidget {
  const _ClientAuthPromptContent({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHandle(),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.16),
                AppColors.secondary.withOpacity(0.12),
              ],
            ),
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.large,
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text(message, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        app_buttons.PrimaryButton(
          label: context.l10n.authLoginButton,
          icon: Icons.login,
          fullWidth: true,
          onPressed: () => _openLogin(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        app_buttons.SecondaryButton(
          label: context.l10n.authCreateAccount,
          icon: Icons.person_add_alt_1_rounded,
          fullWidth: true,
          onPressed: () => _openRegister(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: app_buttons.TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: context.l10n.clientCommonCancel,
          ),
        ),
      ],
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const LoginPage(closeOnAuthenticated: true),
      ),
    );
    if (!context.mounted || result != true) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _openRegister(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const RegisterPage(closeOnAuthenticated: true),
      ),
    );
    if (!context.mounted || result != true) return;
    Navigator.of(context).pop(true);
  }
}
