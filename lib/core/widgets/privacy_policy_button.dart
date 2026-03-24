import 'package:flutter/material.dart';
import 'package:sevenouti/core/utils/legal_links.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/l10n/l10n.dart';

class PrivacyPolicyButton extends StatelessWidget {
  const PrivacyPolicyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _openPrivacyPolicy(context),
      icon: const Icon(Icons.privacy_tip_outlined),
      label: Text(context.l10n.commonPrivacyPolicy),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await openPrivacyPolicy();
    if (!context.mounted || opened) return;

    AppSnackBar.show(
      context,
      message: context.l10n.commonLinkOpenError,
      type: SnackBarType.error,
    );
  }
}
