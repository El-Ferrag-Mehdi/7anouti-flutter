import 'package:flutter/material.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/join_application_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';

class JoinUsApplicationPage extends StatefulWidget {
  const JoinUsApplicationPage({super.key});

  @override
  State<JoinUsApplicationPage> createState() => _JoinUsApplicationPageState();
}

class _JoinUsApplicationPageState extends State<JoinUsApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _zoneController = TextEditingController();
  final _addressController = TextEditingController();

  late final JoinApplicationRepository _repository;
  JoinApplicationType _type = JoinApplicationType.livreur;
  bool _submitting = false;

  bool get _preferArabic =>
      Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _repository = JoinApplicationRepository(ApiService());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessTypeController.dispose();
    _zoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _submitting = true);
    try {
      await _repository.submitApplication(
        type: _type,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        businessCategory: _type == JoinApplicationType.hanout
            ? _businessTypeController.text.trim()
            : null,
        deliveryZone: _type == JoinApplicationType.livreur
            ? _zoneController.text.trim()
            : null,
        address: _type == JoinApplicationType.hanout
            ? _addressController.text.trim()
            : null,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: _tr(
          fr: 'Votre demande a été envoyée avec succés',
          ar: 'تم إرسال طلبك بنجاح',
        ),
        type: SnackBarType.success,
      );
      Navigator.of(context).pop();
    } on Object catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _type == JoinApplicationType.hanout
        ? _tr(fr: 'Postuler comme commercant', ar: 'التقديم كتاجر')
        : _tr(fr: 'Postuler comme livreur', ar: 'التقديم كعامل توصيل');
    final subtitle = _type == JoinApplicationType.hanout
        ? _tr(
            fr: 'Laissez les informations de votre commerce et nous vous contacterons.',
            ar: 'اترك معلومات متجرك وسنتواصل معك.',
          )
        : _tr(
            fr: 'Laissez votre zone de livraison et nous vous contacterons.',
            ar: 'اترك منطقة التوصيل الخاصة بك وسنتواصل معك.',
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_tr(fr: 'Nous rejoindre ?', ar: 'انضم إلينا')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
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
                      Text(title, style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _typeChoice(
                      label: _tr(fr: 'Livreur', ar: 'عامل توصيل'),
                      icon: Icons.delivery_dining,
                      value: JoinApplicationType.livreur,
                    ),
                    _typeChoice(
                      label: _tr(fr: 'Commercant', ar: 'تاجر'),
                      icon: Icons.storefront,
                      value: JoinApplicationType.hanout,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(_tr(fr: 'Informations', ar: 'المعلومات')),
                const SizedBox(height: AppSpacing.sm),
                _field(
                  controller: _nameController,
                  label: _type == JoinApplicationType.hanout
                      ? _tr(fr: 'Nom du commerce', ar: 'اسم المتجر')
                      : _tr(fr: 'Nom complet', ar: 'الاسم الكامل'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                _field(
                  controller: _phoneController,
                  label: _tr(fr: 'Numero de telephone', ar: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                if (_type == JoinApplicationType.hanout) ...[
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    controller: _businessTypeController,
                    label: _tr(fr: 'Type de commerce', ar: 'نوع التجارة'),
                    hint: _tr(
                      fr: 'Ex: hanout, boucherie, patisserie...',
                      ar: 'مثال: حانوت، جزارة، حلويات...',
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    controller: _addressController,
                    label: _tr(fr: 'Adresse', ar: 'العنوان'),
                    validator: _requiredValidator,
                    maxLines: 2,
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    controller: _zoneController,
                    label: _tr(fr: 'Zone de livraison', ar: 'منطقة التوصيل'),
                    hint: _tr(
                      fr: 'Ex: Hay Salam, Casablanca...',
                      ar: 'مثال: حي السلام، الدار البيضاء...',
                    ),
                    validator: _requiredValidator,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _tr(fr: 'Envoyer ma demande', ar: 'إرسال طلبي'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChoice({
    required String label,
    required IconData icon,
    required JoinApplicationType value,
  }) {
    final selected = _type == value;
    return InkWell(
      borderRadius: AppRadius.large,
      onTap: () => setState(() => _type = value),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: AppRadius.large,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String value) {
    return Text(
      value,
      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _tr(fr: 'Champ obligatoire', ar: 'هذا الحقل مطلوب');
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _tr(fr: 'Numero obligatoire', ar: 'رقم الهاتف مطلوب');
    }
    if (value.trim().length < 8) {
      return _tr(fr: 'Numero invalide', ar: 'رقم غير صالح');
    }
    return null;
  }

  String _tr({required String fr, required String ar}) {
    return _preferArabic ? ar : fr;
  }
}
