import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/admin/cubbit/admin_accounts_state.dart';
import 'package:sevenouti/admin/data/admin_repository.dart';
import 'package:sevenouti/admin/models/admin_hanout_model.dart';
import 'package:sevenouti/admin/models/admin_stats.dart';
import 'package:sevenouti/client/models/business_category_model.dart';
import 'package:sevenouti/client/models/first_delivery_promo_config_model.dart';
import 'package:sevenouti/client/models/join_application_model.dart';
import 'package:sevenouti/client/models/user_model.dart';

class AdminAccountsCubit extends Cubit<AdminAccountsState> {
  AdminAccountsCubit(this._repository) : super(AdminAccountsState.initial());

  final AdminRepository _repository;

  Future<void> loadAll() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final results = await Future.wait([
        _repository.listUsers(role: UserRole.client),
        _repository.listUsers(role: UserRole.hanout),
        _repository.listHanouts(),
        _repository.listBusinessCategories(),
        _repository.listJoinApplications(),
        _repository.listUsers(role: UserRole.livreur),
        _repository.getStats(),
        _repository.getFirstDeliveryPromoConfig(),
      ]);
      final clients = results[0] as List<UserModel>;
      final hanouts = results[1] as List<UserModel>;
      final hanoutProfiles = results[2] as List<AdminHanoutModel>;
      final businessCategories = results[3] as List<BusinessCategoryModel>;
      final joinApplications = results[4] as List<JoinApplicationModel>;
      final livreurs = results[5] as List<UserModel>;
      final stats = results[6] as AdminStats;
      final firstDeliveryPromoConfig =
          results[7] as FirstDeliveryPromoConfigModel;
      emit(
        state.copyWith(
          loading: false,
          clients: clients,
          hanouts: hanouts,
          hanoutProfiles: hanoutProfiles,
          businessCategories: businessCategories,
          joinApplications: joinApplications,
          livreurs: livreurs,
          stats: stats,
          firstDeliveryPromoConfig: firstDeliveryPromoConfig,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void setQuery(String value) {
    emit(state.copyWith(query: value));
  }

  Future<void> createHanout({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String hanoutName,
    required String address,
    required String businessCategoryId,
    double deliveryFee = 7.0,
    double? latitude,
    double? longitude,
  }) async {
    final user = await _repository.createUser(
      name: name,
      phone: phone,
      email: email,
      password: password,
      role: UserRole.hanout,
      hanout: {
        'name': hanoutName,
        'address': address,
        'businessCategoryId': businessCategoryId,
        'deliveryFee': deliveryFee,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'phone': phone,
      },
    );
    emit(state.copyWith(hanouts: [user, ...state.hanouts]));
    await loadAll();
  }

  Future<void> createLivreur({
    required String name,
    required String phone,
    String? email,
    required String password,
  }) async {
    final user = await _repository.createUser(
      name: name,
      phone: phone,
      email: email,
      password: password,
      role: UserRole.livreur,
    );
    emit(state.copyWith(livreurs: [user, ...state.livreurs]));
  }

  Future<void> createBusinessCategory({
    required String name,
    required String nameAr,
    String? icon,
  }) async {
    final category = await _repository.createBusinessCategory(
      name: name,
      nameAr: nameAr,
      icon: icon,
    );
    emit(
      state.copyWith(
        businessCategories:
            [
              ...state.businessCategories,
              category,
            ]..sort((a, b) {
              final orderComparison = (a.order ?? 0).compareTo(b.order ?? 0);
              if (orderComparison != 0) return orderComparison;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            }),
      ),
    );
  }

  Future<void> updateUser({
    required String id,
    String? name,
    String? phone,
    String? email,
    required UserRole role,
  }) async {
    final updated = await _repository.updateUser(
      id: id,
      name: name,
      phone: phone,
      email: email,
    );
    if (role == UserRole.hanout) {
      emit(state.copyWith(hanouts: _replace(state.hanouts, updated)));
    } else if (role == UserRole.livreur) {
      emit(state.copyWith(livreurs: _replace(state.livreurs, updated)));
    } else {
      emit(state.copyWith(clients: _replace(state.clients, updated)));
    }
  }

  Future<void> setActive({
    required String id,
    required bool isActive,
    required UserRole role,
  }) async {
    final updated = await _repository.setActive(id: id, isActive: isActive);
    if (role == UserRole.hanout) {
      emit(state.copyWith(hanouts: _replace(state.hanouts, updated)));
    } else if (role == UserRole.livreur) {
      emit(state.copyWith(livreurs: _replace(state.livreurs, updated)));
    } else {
      emit(state.copyWith(clients: _replace(state.clients, updated)));
    }
  }

  Future<void> setHanoutShowRating({
    required String hanoutId,
    required bool showRating,
  }) async {
    final updated = await _repository.setHanoutShowRating(
      hanoutId: hanoutId,
      showRating: showRating,
    );
    emit(
      state.copyWith(
        hanoutProfiles: state.hanoutProfiles
            .map((h) => h.id == updated.id ? updated : h)
            .toList(),
      ),
    );
  }

  Future<void> setHanoutDeliveryFee({
    required String hanoutId,
    required double deliveryFee,
  }) async {
    final updated = await _repository.setHanoutDeliveryFee(
      hanoutId: hanoutId,
      deliveryFee: deliveryFee,
    );
    emit(
      state.copyWith(
        hanoutProfiles: state.hanoutProfiles
            .map((h) => h.id == updated.id ? updated : h)
            .toList(),
      ),
    );
  }

  Future<void> setFirstDeliveryPromoEnabled(bool enabled) async {
    final config = await _repository.updateFirstDeliveryPromoConfig(
      firstDeliveryFreeEnabled: enabled,
    );
    emit(state.copyWith(firstDeliveryPromoConfig: config));
  }

  List<UserModel> _replace(List<UserModel> list, UserModel updated) {
    return list.map((u) => u.id == updated.id ? updated : u).toList();
  }
}
