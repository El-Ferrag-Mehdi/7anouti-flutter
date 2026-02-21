import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/language_selector_tile.dart';
import 'package:sevenouti/hanout/repository/hanout_profile_repository.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/location_service.dart';

class HanoutSettingsPage extends StatefulWidget {
  const HanoutSettingsPage({super.key});

  @override
  State<HanoutSettingsPage> createState() => _HanoutSettingsPageState();
}

class _HanoutSettingsPageState extends State<HanoutSettingsPage> {
  final _repository = HanoutProfileRepository(ApiService());
  final _locationService = LocationService();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _deliveryFeeController = TextEditingController();

  XFile? _pickedImage;
  bool _loading = true;
  bool _saving = false;
  bool _deleting = false;
  bool _locating = false;
  bool _hasCarnet = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _imageController.addListener(_onImageChanged);
    _load();
  }

  @override
  void dispose() {
    _imageController.removeListener(_onImageChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _imageController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  void _onImageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;
      setState(() {
        _pickedImage = file;
      });
    } catch (e) {
      AppSnackBar.show(
        context,
        message: context.l10n.hanoutSettingsImageSelectError(e.toString()),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hanout = await _repository.getMyHanout();
      _nameController.text = hanout.name;
      _descriptionController.text = hanout.description ?? '';
      _addressController.text = hanout.address;
      _phoneController.text = hanout.phone;
      _imageController.text = hanout.image ?? '';
      _latitudeController.text = hanout.latitude.toStringAsFixed(6);
      _longitudeController.text = hanout.longitude.toStringAsFixed(6);
      _deliveryFeeController.text =
          (hanout.deliveryFee ?? AppConstants.defaultDeliveryFee)
              .toStringAsFixed(2);
      _hasCarnet = hanout.hasCarnet;
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

  Future<void> _useCurrentPosition() async {
    setState(() {
      _locating = true;
    });
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        AppSnackBar.show(
          context,
          message: context.l10n.hanoutSettingsPositionUnavailable,
          type: SnackBarType.warning,
        );
        return;
      }

      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);

      final address = await _locationService.reverseGeocode(
        position.latitude,
        position.longitude,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (address != null && address.trim().isNotEmpty) {
        _addressController.text = address.trim();
      }

      AppSnackBar.show(
        context,
        message: context.l10n.hanoutSettingsPositionUpdated,
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: context.l10n.hanoutSettingsPositionError(e.toString()),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (name.isEmpty ||
        address.isEmpty ||
        phone.isEmpty ||
        latitude == null ||
        longitude == null) {
      AppSnackBar.show(
        context,
        message: l10n.hanoutSettingsRequiredFields,
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        imageUrl = await _repository.uploadHanoutImage(
          bytes: bytes,
          filename: _pickedImage!.name,
        );
        _imageController.text = imageUrl;
      }
      await _repository.updateMyHanout(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        address: address,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        image:
            imageUrl ??
            (_imageController.text.trim().isEmpty
                ? null
                : _imageController.text.trim()),
        hasCarnet: _hasCarnet,
      );
      _pickedImage = null;
      AppSnackBar.show(
        context,
        message: l10n.hanoutSettingsSaved,
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: l10n.hanoutSettingsSaveError(e.toString()),
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
        body: LoadingView(message: l10n.hanoutSettingsLoading),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.hanoutSettingsTitle)),
        body: ErrorView(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hanoutSettingsTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.hanoutCommonSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.settingsLanguageSectionTitle, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.sm),
          const LanguageSelectorTile(),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.hanoutSettingsGeneralInfo, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.hanoutSettingsNameLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.hanoutCommonDescription,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: l10n.hanoutCommonPhone),
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: _saving ? null : _pickImage,
            icon: const Icon(Icons.photo_library),
            label: Text(l10n.hanoutSettingsUploadImage),
          ),
          if (_pickedImage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.medium,
              child: Image.file(
                File(_pickedImage!.path),
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.border,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ],
          if (_pickedImage == null &&
              _imageController.text.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.medium,
              child: Image.network(
                _imageController.text.trim(),
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.border,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.hanoutSettingsLocationTitle, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(labelText: l10n.hanoutCommonAddress),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.hanoutSettingsLatitude,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.hanoutSettingsLongitude,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: _locating ? null : _useCurrentPosition,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(l10n.hanoutSettingsUseCurrentPosition),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.hanoutSettingsServicesTitle, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _hasCarnet,
            title: Text(l10n.hanoutSettingsEnableCarnet),
            subtitle: Text(l10n.hanoutSettingsEnableCarnetHelp),
            onChanged: (value) => setState(() => _hasCarnet = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _deliveryFeeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: false,
            readOnly: true,
            decoration: InputDecoration(
              labelText: l10n.hanoutSettingsDeliveryFeeDh,
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
