import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/language_selector_tile.dart';
import 'package:sevenouti/core/widgets/privacy_policy_button.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/livreur/repository/livreur_profile_repository.dart';
import 'package:sevenouti/utils/location_service.dart';

class LivreurSettingsPage extends StatefulWidget {
  const LivreurSettingsPage({super.key});

  @override
  State<LivreurSettingsPage> createState() => _LivreurSettingsPageState();
}

class _LivreurSettingsPageState extends State<LivreurSettingsPage> {
  final _repository = LivreurProfileRepository(ApiService());
  final _locationService = LocationService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  bool _changingPassword = false;
  bool _updatingZone = false;
  bool _zoneActive = false;
  double? _zoneLatitude;
  double? _zoneLongitude;
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
      _zoneActive = user.isLivreurZoneActive;
      _zoneLatitude = user.latitude;
      _zoneLongitude = user.longitude;
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

  Future<void> _showChangePasswordDialog() async {
    if (_saving || _deleting || _updatingZone || _changingPassword) return;

    final currentController = TextEditingController();
    final nextController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Changer mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: nextController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer nouveau mot de passe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.clientCommonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.clientCommonConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      currentController.dispose();
      nextController.dispose();
      confirmController.dispose();
      return;
    }

    final currentPassword = currentController.text.trim();
    final newPassword = nextController.text.trim();
    final confirmPassword = confirmController.text.trim();

    currentController.dispose();
    nextController.dispose();
    confirmController.dispose();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Tous les champs sont obligatoires',
        type: SnackBarType.error,
      );
      return;
    }

    if (newPassword.length < 6) {
      AppSnackBar.show(
        context,
        message: 'Le nouveau mot de passe doit contenir au moins 6 caracteres',
        type: SnackBarType.error,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppSnackBar.show(
        context,
        message: 'La confirmation ne correspond pas',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _changingPassword = true;
    });
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Mot de passe modifie avec succes',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingPassword = false;
        });
      }
    }
  }

  Future<void> _activateZone() async {
    if (_saving || _deleting || _updatingZone) return;
    setState(() {
      _updatingZone = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          message:
              'Position indisponible. Active la localisation puis reessaie.',
          type: SnackBarType.warning,
        );
        return;
      }

      final updated = await _repository.updateMyProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        isLivreurZoneActive: true,
      );

      if (!mounted) return;
      setState(() {
        _zoneActive = updated.isLivreurZoneActive;
        _zoneLatitude = updated.latitude;
        _zoneLongitude = updated.longitude;
      });
      AppSnackBar.show(
        context,
        message:
            'Zone activee. Vous recevrez les demandes dans un rayon de 5 km.',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Erreur activation zone: $e',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingZone = false;
        });
      }
    }
  }

  Future<void> _deactivateZone() async {
    if (_saving || _deleting || _updatingZone) return;
    setState(() {
      _updatingZone = true;
    });
    try {
      final updated = await _repository.updateMyProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        isLivreurZoneActive: false,
      );
      if (!mounted) return;
      setState(() {
        _zoneActive = updated.isLivreurZoneActive;
        _zoneLatitude = updated.latitude;
        _zoneLongitude = updated.longitude;
      });
      AppSnackBar.show(
        context,
        message: 'Zone desactivee.',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Erreur desactivation zone: $e',
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingZone = false;
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
            l10n.commonLegalSectionTitle,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          const PrivacyPolicyButton(),
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Zone de travail',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _zoneActive,
            onChanged: _updatingZone
                ? null
                : (value) {
                    if (value) {
                      unawaited(_activateZone());
                      return;
                    }
                    unawaited(_deactivateZone());
                  },
            title: const Text('Je suis actif sur cette zone'),
            subtitle: Text(
              _zoneActive
                  ? 'Actif dans un rayon de 5 km'
                  : 'Inactif: aucune nouvelle demande',
            ),
          ),
          if (_zoneLatitude != null && _zoneLongitude != null)
            Text(
              'Position: ${_zoneLatitude!.toStringAsFixed(6)}, ${_zoneLongitude!.toStringAsFixed(6)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: _updatingZone ? null : _activateZone,
            icon: _updatingZone
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Actualiser ma position et activer'),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _changingPassword ? null : _showChangePasswordDialog,
            icon: _changingPassword
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(
              _changingPassword ? 'Modification...' : 'Changer mot de passe',
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
