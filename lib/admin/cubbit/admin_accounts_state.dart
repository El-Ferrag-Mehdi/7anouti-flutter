import 'package:sevenouti/client/models/user_model.dart';
import 'package:sevenouti/client/models/business_category_model.dart';
import 'package:sevenouti/client/models/first_delivery_promo_config_model.dart';
import 'package:sevenouti/client/models/join_application_model.dart';
import 'package:sevenouti/admin/models/admin_stats.dart';
import 'package:sevenouti/admin/models/admin_hanout_model.dart';

class AdminAccountsState {
  const AdminAccountsState({
    required this.loading,
    required this.clients,
    required this.hanouts,
    required this.hanoutProfiles,
    required this.businessCategories,
    required this.joinApplications,
    required this.livreurs,
    required this.query,
    required this.disabledIds,
    required this.stats,
    required this.firstDeliveryPromoConfig,
    this.error,
  });

  final bool loading;
  final List<UserModel> clients;
  final List<UserModel> hanouts;
  final List<AdminHanoutModel> hanoutProfiles;
  final List<BusinessCategoryModel> businessCategories;
  final List<JoinApplicationModel> joinApplications;
  final List<UserModel> livreurs;
  final String query;
  final Set<String> disabledIds;
  final AdminStats? stats;
  final FirstDeliveryPromoConfigModel? firstDeliveryPromoConfig;
  final String? error;

  factory AdminAccountsState.initial() {
    return const AdminAccountsState(
      loading: true,
      clients: [],
      hanouts: [],
      hanoutProfiles: [],
      businessCategories: [],
      joinApplications: [],
      livreurs: [],
      query: '',
      disabledIds: {},
      stats: null,
      firstDeliveryPromoConfig: null,
      error: null,
    );
  }

  AdminAccountsState copyWith({
    bool? loading,
    List<UserModel>? clients,
    List<UserModel>? hanouts,
    List<AdminHanoutModel>? hanoutProfiles,
    List<BusinessCategoryModel>? businessCategories,
    List<JoinApplicationModel>? joinApplications,
    List<UserModel>? livreurs,
    String? query,
    Set<String>? disabledIds,
    AdminStats? stats,
    FirstDeliveryPromoConfigModel? firstDeliveryPromoConfig,
    String? error,
    bool clearError = false,
  }) {
    return AdminAccountsState(
      loading: loading ?? this.loading,
      clients: clients ?? this.clients,
      hanouts: hanouts ?? this.hanouts,
      hanoutProfiles: hanoutProfiles ?? this.hanoutProfiles,
      businessCategories: businessCategories ?? this.businessCategories,
      joinApplications: joinApplications ?? this.joinApplications,
      livreurs: livreurs ?? this.livreurs,
      query: query ?? this.query,
      disabledIds: disabledIds ?? this.disabledIds,
      stats: stats ?? this.stats,
      firstDeliveryPromoConfig:
          firstDeliveryPromoConfig ?? this.firstDeliveryPromoConfig,
      error: clearError ? null : error ?? this.error,
    );
  }
}
