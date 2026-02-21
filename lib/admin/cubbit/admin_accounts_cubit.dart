import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/admin/cubbit/admin_accounts_state.dart';
import 'package:sevenouti/admin/data/admin_repository.dart';
import 'package:sevenouti/admin/models/admin_hanout_model.dart';
import 'package:sevenouti/admin/models/admin_stats.dart';
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
        _repository.listUsers(role: UserRole.livreur),
        _repository.getStats(),
      ]);
      final clients = results[0] as List<UserModel>;
      final hanouts = results[1] as List<UserModel>;
      final hanoutProfiles = results[2] as List<AdminHanoutModel>;
      final livreurs = results[3] as List<UserModel>;
      final stats = results[4] as AdminStats;
      emit(
        state.copyWith(
          loading: false,
          clients: clients,
          hanouts: hanouts,
          hanoutProfiles: hanoutProfiles,
          livreurs: livreurs,
          stats: stats,
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

  List<UserModel> _replace(List<UserModel> list, UserModel updated) {
    return list.map((u) => u.id == updated.id ? updated : u).toList();
  }
}
