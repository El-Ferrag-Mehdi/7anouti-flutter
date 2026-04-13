import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/admin/cubbit/admin_accounts_cubit.dart';
import 'package:sevenouti/admin/cubbit/admin_accounts_state.dart';
import 'package:sevenouti/admin/models/admin_hanout_model.dart';
import 'package:sevenouti/admin/view/widgets/admin_entity_insights_dialog.dart';
import 'package:sevenouti/client/models/business_category_model.dart';
import 'package:sevenouti/client/models/join_application_model.dart';
import 'package:sevenouti/client/models/user_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';

import 'package:sevenouti/utils/location_service.dart';
import 'package:sevenouti/utils/phone_launcher.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminAccountsCubit, AdminAccountsState>(
      builder: (context, state) {
        if (state.loading) {
          return const LoadingView(message: 'Chargement des comptes...');
        }

        if (state.error != null) {
          return ErrorView(
            message: state.error!,
            onRetry: () => context.read<AdminAccountsCubit>().loadAll(),
          );
        }

        return DefaultTabController(
          length: 6,
          child: Column(
            children: [
              _buildSearch(context, state),
              const TabBar(
                tabs: [
                  Tab(text: 'Stats'),
                  Tab(text: 'Clients'),
                  Tab(text: 'Candidatures'),
                  Tab(text: 'Catégories'),
                  Tab(text: 'Hanouts'),
                  Tab(text: 'Livreurs'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildStatsView(context, state),
                    _AccountsList(
                      title: 'Clients',
                      users: _filter(state.clients, state.query),
                      canCreate: false,
                      onEdit: (user) => _showEditDialog(context, user),
                      onToggleActive: (user) => _toggleActive(context, user),
                    ),
                    _JoinApplicationsList(
                      applications: _filterJoinApplications(
                        state.joinApplications,
                        state.query,
                      ),
                    ),
                    _BusinessCategoryList(
                      categories: _filterBusinessCategories(
                        state.businessCategories,
                        state.query,
                      ),
                      onCreate: () => _showCreateCategoryDialog(context),
                    ),
                    _HanoutSettingsList(
                      hanouts: _filterHanouts(
                        state.hanoutProfiles,
                        state.query,
                      ),
                      onCreate: () => _showCreateDialog(
                        context,
                        role: UserRole.hanout,
                      ),
                      onToggleShowRating: (hanout, value) async {
                        try {
                          await context
                              .read<AdminAccountsCubit>()
                              .setHanoutShowRating(
                                hanoutId: hanout.id,
                                showRating: value,
                              );
                          if (context.mounted) {
                            AppSnackBar.show(
                              context,
                              message: value
                                  ? 'Affichage des notes activé'
                                  : 'Affichage des notes désactivé',
                              type: SnackBarType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackBar.show(
                              context,
                              message: 'Erreur: ${e.toString()}',
                              type: SnackBarType.error,
                            );
                          }
                        }
                      },
                      onEditDeliveryFee: (hanout) =>
                          _showEditHanoutDeliveryFeeDialog(context, hanout),
                      onViewDetails: (hanout) => showAdminHanoutInsightsDialog(
                        context: context,
                        hanout: hanout,
                      ),
                    ),
                    _AccountsList(
                      title: 'Livreurs',
                      users: _filter(state.livreurs, state.query),
                      canCreate: true,
                      onCreate: () => _showCreateDialog(
                        context,
                        role: UserRole.livreur,
                      ),
                      onEdit: (user) => _showEditDialog(context, user),
                      onToggleActive: (user) => _toggleActive(context, user),
                      onViewDetails: (user) => showAdminLivreurInsightsDialog(
                        context: context,
                        livreur: user,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsView(BuildContext context, AdminAccountsState state) {
    final stats = state.stats;
    if (stats == null) {
      return const Center(child: Text('Aucune statistique disponible'));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildPromoConfigCard(context, state),
        const SizedBox(height: AppSpacing.lg),
        Text('Global', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _StatCard(
              label: 'Utilisateurs',
              value: stats.usersTotal.toString(),
            ),
            _StatCard(
              label: 'Hanouts',
              value: stats.hanoutsTotal.toString(),
            ),
            _StatCard(
              label: 'Commandes',
              value: stats.ordersTotal.toString(),
            ),
            _StatCard(
              label: 'Revenus',
              value: '${stats.ordersRevenue.toStringAsFixed(2)} DH',
            ),
            _StatCard(
              label: 'Carnets',
              value: stats.carnetsTotal.toString(),
            ),
            _StatCard(
              label: 'Carnets actifs',
              value: stats.carnetsActive.toString(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Répartition utilisateurs', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        _KeyValueList(data: stats.usersByRole),
        const SizedBox(height: AppSpacing.lg),
        Text('Statut des commandes', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        _KeyValueList(data: stats.ordersByStatus),
        const SizedBox(height: AppSpacing.lg),
        Text('Top Hanouts', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        _TopList(
          rows: stats.topHanouts
              .map(
                (e) => _TopRow(
                  title: e.name,
                  value: '${e.orders} cmd',
                  sub: '${e.revenue.toStringAsFixed(2)} DH',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Top Livreurs', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        _TopList(
          rows: stats.topLivreurs
              .map(
                (e) => _TopRow(
                  title: e.name,
                  value: '${e.orders} cmd',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Quartiers', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        _TopList(
          rows: stats.quartiers
              .map(
                (e) => _TopRow(
                  title: e.name,
                  value: '${e.orders} cmd',
                  sub: '${e.hanouts} hanout(s)',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPromoConfigCard(
    BuildContext context,
    AdminAccountsState state,
  ) {
    final promoConfig = state.firstDeliveryPromoConfig;
    final isEnabled = promoConfig?.firstDeliveryFreeEnabled ?? false;

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
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: AppRadius.medium,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Première livraison gratuite',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'Activée pour les nouveaux comptes eligibles.'
                      : 'Desactivée. Les clients verront le tarif normal.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: (value) async {
              try {
                await context
                    .read<AdminAccountsCubit>()
                    .setFirstDeliveryPromoEnabled(value);
                if (context.mounted) {
                  AppSnackBar.show(
                    context,
                    message: value
                        ? 'Offre première livraison gratuite activée'
                        : 'Offre première livraison gratuite desactivée',
                    type: SnackBarType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.show(
                    context,
                    message: 'Erreur: ${e.toString()}',
                    type: SnackBarType.error,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context, AdminAccountsState state) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        onChanged: (value) =>
            context.read<AdminAccountsCubit>().setQuery(value),
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, téléphone ou email',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: AppRadius.medium,
          ),
          isDense: true,
        ),
      ),
    );
  }

  List<UserModel> _filter(List<UserModel> list, String query) {
    if (query.trim().isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q) ||
          (u.email ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<AdminHanoutModel> _filterHanouts(
    List<AdminHanoutModel> list,
    String query,
  ) {
    if (query.trim().isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((h) {
      return h.name.toLowerCase().contains(q) ||
          h.phone.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q) ||
          (h.ownerName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<BusinessCategoryModel> _filterBusinessCategories(
    List<BusinessCategoryModel> list,
    String query,
  ) {
    if (query.trim().isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((category) {
      return category.name.toLowerCase().contains(q) ||
          (category.nameAr ?? '').toLowerCase().contains(q) ||
          (category.slug ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<JoinApplicationModel> _filterJoinApplications(
    List<JoinApplicationModel> list,
    String query,
  ) {
    if (query.trim().isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((application) {
      return application.nameFr.toLowerCase().contains(q) ||
          application.nameAr.toLowerCase().contains(q) ||
          application.phone.toLowerCase().contains(q) ||
          (application.businessCategoryName ?? '').toLowerCase().contains(q) ||
          (application.businessCategoryNameAr ?? '').toLowerCase().contains(
            q,
          ) ||
          (application.deliveryZoneFr ?? '').toLowerCase().contains(q) ||
          (application.deliveryZoneAr ?? '').toLowerCase().contains(q) ||
          (application.addressFr ?? '').toLowerCase().contains(q) ||
          (application.addressAr ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showCreateDialog(
    BuildContext context, {
    required UserRole role,
  }) async {
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';
    final businessCategories = context
        .read<AdminAccountsCubit>()
        .state
        .businessCategories;
    if (role == UserRole.hanout && businessCategories.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Ajoutez d abord une categorie de commerce',
        type: SnackBarType.warning,
      );
      return;
    }
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final hanoutNameController = TextEditingController();
    final addressController = TextEditingController();
    final deliveryFeeController = TextEditingController(text: '7');
    var selectedBusinessCategoryId =
        role == UserRole.hanout && businessCategories.isNotEmpty
        ? businessCategories.first.id
        : null;
    double? latitude;
    double? longitude;
    final locationService = LocationService();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              title: Text(
                role == UserRole.hanout
                    ? 'Inviter un hanout'
                    : 'Inviter un livreur',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'T�l�phone',
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                        ),
                        obscureText: true,
                      ),
                      if (role == UserRole.hanout) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: hanoutNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom du hanout',
                          ),
                        ),
                        TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          value: selectedBusinessCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categorie du commerce',
                          ),
                          items: businessCategories
                              .map(
                                (category) => DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(
                                    '${category.displayIcon} ${category.displayName(preferArabic: preferArabic)}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedBusinessCategoryId = value);
                          },
                        ),
                        TextField(
                          controller: deliveryFeeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Frais de livraison (DH)',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              final position = await locationService
                                  .getCurrentPosition();
                              if (position == null) {
                                AppSnackBar.show(
                                  context,
                                  message:
                                      'Position indisponible ou permission refus�e',
                                  type: SnackBarType.warning,
                                );
                                return;
                              }
                              latitude = position.latitude;
                              longitude = position.longitude;
                              final address = await locationService
                                  .reverseGeocode(
                                    position.latitude,
                                    position.longitude,
                                    languageCode: Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  );
                              if (address != null &&
                                  address.trim().isNotEmpty) {
                                addressController.text = address.trim();
                              }
                              setState(() {});
                            },
                            icon: const Icon(Icons.my_location),
                            label: const Text('Utiliser ma position actuelle'),
                          ),
                        ),
                        if (latitude != null && longitude != null)
                          Text(
                            'Position captur�e',
                            style: AppTextStyles.bodySmall,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Cr�er'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Nom, téléphone et mot de passe sont obligatoires',
        type: SnackBarType.error,
      );
      return;
    }

    try {
      if (role == UserRole.hanout) {
        final hanoutName = hanoutNameController.text.trim().isEmpty
            ? name
            : hanoutNameController.text.trim();
        final address = addressController.text.trim();

        if (address.isEmpty) {
          AppSnackBar.show(
            context,
            message: 'Adresse obligatoire pour le hanout',
            type: SnackBarType.error,
          );
          return;
        }
        if (selectedBusinessCategoryId == null ||
            selectedBusinessCategoryId!.isEmpty) {
          AppSnackBar.show(
            context,
            message: 'Selectionnez une categorie pour le commerce',
            type: SnackBarType.error,
          );
          return;
        }
        final deliveryFee = double.tryParse(deliveryFeeController.text.trim());
        if (deliveryFee == null || deliveryFee < 0) {
          AppSnackBar.show(
            context,
            message: 'Frais de livraison invalide',
            type: SnackBarType.error,
          );
          return;
        }

        await context.read<AdminAccountsCubit>().createHanout(
          name: name,
          phone: phone,
          email: email.isEmpty ? null : email,
          password: password,
          hanoutName: hanoutName,
          address: address,
          businessCategoryId: selectedBusinessCategoryId!,
          deliveryFee: deliveryFee,
          latitude: latitude,
          longitude: longitude,
        );
      } else {
        await context.read<AdminAccountsCubit>().createLivreur(
          name: name,
          phone: phone,
          email: email.isEmpty ? null : email,
          password: password,
        );
      }

      AppSnackBar.show(
        context,
        message: 'Compte créé avec succès',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: 'Erreur création: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    UserModel user,
  ) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final emailController = TextEditingController(text: user.email ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          title: const Text('Modifier le compte'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      await context.read<AdminAccountsCubit>().updateUser(
        id: user.id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        role: user.role,
      );

      AppSnackBar.show(
        context,
        message: 'Compte mis à jour',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: 'Erreur mise à jour: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _showCreateCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final nameArController = TextEditingController();
    final iconController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          title: const Text('Ajouter une categorie'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la categorie',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: nameArController,
                    decoration: const InputDecoration(
                      labelText: 'Nom categorie arabe',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: iconController,
                    decoration: const InputDecoration(
                      labelText: 'Icone (emoji)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final name = nameController.text.trim();
    final nameAr = nameArController.text.trim();
    final icon = iconController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Le nom de la categorie est obligatoire',
        type: SnackBarType.error,
      );
      return;
    }
    if (nameAr.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Le nom arabe de la categorie est obligatoire',
        type: SnackBarType.error,
      );
      return;
    }

    try {
      await context.read<AdminAccountsCubit>().createBusinessCategory(
        name: name,
        nameAr: nameAr,
        icon: icon.isEmpty ? null : icon,
      );
      AppSnackBar.show(
        context,
        message: 'Categorie ajoutee avec succes',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: 'Erreur categorie: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _showEditHanoutDeliveryFeeDialog(
    BuildContext context,
    AdminHanoutModel hanout,
  ) async {
    final deliveryFeeController = TextEditingController(
      text: (hanout.deliveryFee ?? 7.0).toStringAsFixed(2),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          title: const Text('Modifier frais livraison'),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: deliveryFeeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Frais de livraison (DH)',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    final deliveryFee = double.tryParse(deliveryFeeController.text.trim());
    if (deliveryFee == null || deliveryFee < 0) {
      AppSnackBar.show(
        context,
        message: 'Frais de livraison invalide',
        type: SnackBarType.error,
      );
      return;
    }

    try {
      await context.read<AdminAccountsCubit>().setHanoutDeliveryFee(
        hanoutId: hanout.id,
        deliveryFee: deliveryFee,
      );
      AppSnackBar.show(
        context,
        message: 'Frais de livraison mis a jour',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: 'Erreur mise a jour: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _toggleActive(BuildContext context, UserModel user) async {
    try {
      await context.read<AdminAccountsCubit>().setActive(
        id: user.id,
        isActive: !user.isActive,
        role: user.role,
      );
      AppSnackBar.show(
        context,
        message: user.isActive ? 'Compte désactivé' : 'Compte réactivé',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: 'Erreur: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }
}

class _HanoutSettingsList extends StatelessWidget {
  const _HanoutSettingsList({
    required this.hanouts,
    required this.onCreate,
    required this.onToggleShowRating,
    required this.onEditDeliveryFee,
    required this.onViewDetails,
  });

  final List<AdminHanoutModel> hanouts;
  final VoidCallback onCreate;
  final void Function(AdminHanoutModel hanout, bool value) onToggleShowRating;
  final void Function(AdminHanoutModel hanout) onEditDeliveryFee;
  final void Function(AdminHanoutModel hanout) onViewDetails;

  @override
  Widget build(BuildContext context) {
    if (hanouts.isEmpty) {
      return EmptyView(
        message: 'Aucun hanout trouvé',
        icon: Icons.store_outlined,
        action: onCreate,
        actionLabel: 'Inviter',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Inviter'),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: hanouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final hanout = hanouts[index];
              return _HanoutSettingsTile(
                hanout: hanout,
                onToggleShowRating: onToggleShowRating,
                onEditDeliveryFee: onEditDeliveryFee,
                onViewDetails: onViewDetails,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _JoinApplicationsList extends StatelessWidget {
  const _JoinApplicationsList({required this.applications});

  final List<JoinApplicationModel> applications;

  @override
  Widget build(BuildContext context) {
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (applications.isEmpty) {
      return const EmptyView(
        message: 'Aucune candidature trouvée',
        icon: Icons.handshake_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final application = applications[index];
        final subtitle = application.type == JoinApplicationType.hanout
            ? (preferArabic
                      ? application.businessCategoryNameAr
                      : application.businessCategoryName) ??
                  '-'
            : (preferArabic
                      ? application.deliveryZoneAr
                      : application.deliveryZoneFr) ??
                  '-';
        final secondary = application.type == JoinApplicationType.hanout
            ? (preferArabic ? application.addressAr : application.addressFr) ??
                  '-'
            : application.phone;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.medium,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preferArabic ? application.nameAr : application.nameFr,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _JoinApplicationBadge(
                    label: application.type == JoinApplicationType.hanout
                        ? 'Commerçant'
                        : 'Livreur',
                    color: application.type == JoinApplicationType.hanout
                        ? AppColors.primary
                        : AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _JoinApplicationBadge(
                    label: _joinApplicationStatusLabel(application.status),
                    color: _joinApplicationStatusColor(application.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.phone,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => launchPhoneCall(application.phone),
                    icon: const Icon(Icons.phone, size: 18),
                    tooltip: 'Appeler',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Text(secondary, style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _JoinApplicationMetaChip(
                    icon: Icons.schedule_outlined,
                    label: _formatAdminDateTime(context, application.createdAt),
                  ),
                  if (application.installationId != null &&
                      application.installationId!.isNotEmpty)
                    _JoinApplicationMetaChip(
                      icon: Icons.phone_iphone_outlined,
                      label:
                          'Inst: ${_shortValue(application.installationId!)}',
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JoinApplicationBadge extends StatelessWidget {
  const _JoinApplicationBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.round,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JoinApplicationMetaChip extends StatelessWidget {
  const _JoinApplicationMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.round,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _BusinessCategoryList extends StatelessWidget {
  const _BusinessCategoryList({
    required this.categories,
    required this.onCreate,
  });

  final List<BusinessCategoryModel> categories;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (categories.isEmpty) {
      return EmptyView(
        message: 'Aucune categorie trouvee',
        icon: Icons.category_outlined,
        action: onCreate,
        actionLabel: 'Ajouter',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Text(
                      category.displayIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.displayName(preferArabic: preferArabic),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category.hanoutsCount ?? 0} commerce(s)',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (category.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: AppRadius.small,
                        ),
                        child: Text(
                          'Defaut',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HanoutSettingsTile extends StatelessWidget {
  const _HanoutSettingsTile({
    required this.hanout,
    required this.onToggleShowRating,
    required this.onEditDeliveryFee,
    required this.onViewDetails,
  });

  final AdminHanoutModel hanout;
  final void Function(AdminHanoutModel hanout, bool value) onToggleShowRating;
  final void Function(AdminHanoutModel hanout) onEditDeliveryFee;
  final void Function(AdminHanoutModel hanout) onViewDetails;

  @override
  Widget build(BuildContext context) {
    final preferArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hanout.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hanout.rating != null)
                Text(
                  'Note: ${hanout.rating!.toStringAsFixed(1)}',
                  style: AppTextStyles.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(hanout.address, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(hanout.phone, style: AppTextStyles.bodySmall),
              ),
              IconButton(
                onPressed: () => launchPhoneCall(hanout.phone),
                icon: const Icon(Icons.phone, size: 18),
                tooltip: 'Appeler',
              ),
            ],
          ),
          if (hanout.businessCategory != null) ...[
            const SizedBox(height: 4),
            Text(
              'Categorie: ${hanout.businessCategory!.displayIcon} ${hanout.businessCategory!.displayName(preferArabic: preferArabic)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Frais livraison: ${(hanout.deliveryFee ?? 7.0).toStringAsFixed(2)} DH',
            style: AppTextStyles.bodySmall,
          ),
          if (hanout.ownerName != null) ...[
            const SizedBox(height: 4),
            Text('Owner: ${hanout.ownerName}', style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  onPressed: () => onViewDetails(hanout),
                  icon: const Icon(Icons.insights_outlined, size: 18),
                  label: const Text('Voir détails'),
                ),
                TextButton.icon(
                  onPressed: () => onEditDeliveryFee(hanout),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Modifier frais livraison'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Afficher la note côté client',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              Switch(
                value: hanout.showRating,
                onChanged: (value) => onToggleShowRating(hanout, value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({
    required this.title,
    required this.users,
    required this.canCreate,
    this.onCreate,
    this.onEdit,
    this.onViewDetails,
    this.onToggleActive,
  });

  final String title;
  final List<UserModel> users;
  final bool canCreate;
  final VoidCallback? onCreate;
  final void Function(UserModel user)? onEdit;
  final void Function(UserModel user)? onViewDetails;
  final void Function(UserModel user)? onToggleActive;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return EmptyView(
        message: 'Aucun compte trouvé',
        icon: Icons.people_outline,
        action: canCreate ? onCreate : null,
        actionLabel: canCreate ? 'Inviter' : null,
      );
    }

    return Column(
      children: [
        if (canCreate)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Inviter'),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final user = users[index];
              return _AccountTile(
                user: user,
                onEdit: onEdit,
                onViewDetails: onViewDetails,
                onToggleActive: onToggleActive,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.user,
    this.onEdit,
    this.onViewDetails,
    this.onToggleActive,
  });

  final UserModel user;
  final void Function(UserModel user)? onEdit;
  final void Function(UserModel user)? onViewDetails;
  final void Function(UserModel user)? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (user.role) {
      UserRole.client => 'Client',
      UserRole.hanout => 'Hanout',
      UserRole.livreur => 'Livreur',
      UserRole.admin => 'Admin',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.phone,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => launchPhoneCall(user.phone),
                      icon: const Icon(Icons.phone, size: 18),
                      tooltip: 'Appeler',
                    ),
                  ],
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.email!,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: AppRadius.small,
            ),
            child: Text(
              roleLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: user.isActive
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: AppRadius.small,
            ),
            child: Text(
              user.isActive ? 'Actif' : 'Désactivé',
              style: AppTextStyles.caption.copyWith(
                color: user.isActive ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            children: [
              if (onViewDetails != null)
                IconButton(
                  icon: const Icon(Icons.insights_outlined, size: 18),
                  onPressed: () => onViewDetails!(user),
                ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit == null ? null : () => onEdit!(user),
              ),
              IconButton(
                icon: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  size: 18,
                  color: user.isActive ? AppColors.error : AppColors.success,
                ),
                onPressed: onToggleActive == null
                    ? null
                    : () => onToggleActive!(user),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _KeyValueList extends StatelessWidget {
  const _KeyValueList({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Aucune donnée');
    }
    return Column(
      children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: AppTextStyles.bodyMedium),
              Text(e.value.toString(), style: AppTextStyles.bodyMedium),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TopRow {
  const _TopRow({
    required this.title,
    required this.value,
    this.sub,
  });

  final String title;
  final String value;
  final String? sub;
}

class _TopList extends StatelessWidget {
  const _TopList({required this.rows});

  final List<_TopRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('Aucune donnée');
    }
    return Column(
      children: rows.map((row) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.medium,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (row.sub != null) ...[
                      const SizedBox(height: 4),
                      Text(row.sub!, style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              ),
              Text(row.value, style: AppTextStyles.bodyMedium),
            ],
          ),
        );
      }).toList(),
    );
  }
}

String _joinApplicationStatusLabel(JoinApplicationStatus status) {
  switch (status) {
    case JoinApplicationStatus.contacted:
      return 'Contacté';
    case JoinApplicationStatus.archived:
      return 'Archivé';
    case JoinApplicationStatus.pending:
      return 'Nouveau';
  }
}

Color _joinApplicationStatusColor(JoinApplicationStatus status) {
  switch (status) {
    case JoinApplicationStatus.contacted:
      return AppColors.success;
    case JoinApplicationStatus.archived:
      return AppColors.textSecondary;
    case JoinApplicationStatus.pending:
      return Colors.orange;
  }
}

String _formatAdminDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatShortDate(local);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: true,
  );
  return '$date $time';
}

String _shortValue(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
