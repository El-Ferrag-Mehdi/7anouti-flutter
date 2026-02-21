import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/language_selector_tile.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/repository/livreur_profile_repository.dart';

class LivreurSettingsPage extends StatefulWidget {
  const LivreurSettingsPage({super.key});

  @override
  State<LivreurSettingsPage> createState() => _LivreurSettingsPageState();
}

class _LivreurSettingsPageState extends State<LivreurSettingsPage> {
  final _repository = LivreurProfileRepository(ApiService());

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _repository.getMyProfile();
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _emailController.text = user.email ?? '';
      _addressController.text = user.address ?? '';
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      AppSnackBar.show(
        context,
        message: l10n.livreurSettingsRequiredFields,
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _saving = true;
    });
    try {
      final updated = await _repository.updateMyProfile(
        name: name,
        phone: phone,
        address: address.isEmpty ? null : address,
      );
      if (!mounted) return;
      _nameController.text = updated.name;
      _phoneController.text = updated.phone;
      _emailController.text = updated.email ?? '';
      _addressController.text = updated.address ?? '';
      AppSnackBar.show(
        context,
        message: l10n.livreurSettingsSaved,
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.livreurSettingsSaveError(e.toString()),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_saving || _deleting) return;
    final l10n = context.l10n;

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountDialogTitle),
        content: Text(l10n.settingsDeleteAccountDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.clientCommonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsDeleteAccountDialogConfirm),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted) return;

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountFinalTitle),
        content: Text(l10n.settingsDeleteAccountFinalMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.clientCommonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsDeleteAccountFinalConfirm),
          ),
        ],
      ),
    );

    if (finalConfirm != true || !mounted) return;

    setState(() {
      _deleting = true;
    });

    try {
      await _repository.deleteMyAccount();
      if (!mounted) return;
      await context.read<AuthCubit>().logout();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.settingsDeleteAccountError(e.toString()),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.livreurSettingsTitle)),
        body: LoadingView(message: l10n.livreurSettingsLoading),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.livreurSettingsTitle)),
        body: ErrorView(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.livreurSettingsTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.livreurSettingsSaveButton),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.settingsLanguageSectionTitle,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const LanguageSelectorTile(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.livreurSettingsAccountSectionTitle,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.livreurSettingsNameLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.livreurSettingsPhoneLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _emailController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: l10n.livreurSettingsEmailLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.livreurSettingsAddressLabel,
              hintText: l10n.clientCommonDeliveryAddressHint,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.settingsDeleteAccountSectionTitle,
            style: AppTextStyles.h3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.settingsDeleteAccountDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _deleting ? null : _deleteAccount,
            icon: _deleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            label: Text(
              _deleting
                  ? l10n.settingsDeleteAccountInProgress
                  : l10n.settingsDeleteAccountButton,
            ),
          ),
        ],
      ),
    );
  }
}
