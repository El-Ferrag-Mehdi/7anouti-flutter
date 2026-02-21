import 'package:sevenouti/client/models/user_model.dart';
import 'package:sevenouti/admin/models/admin_stats.dart';
import 'package:sevenouti/admin/models/admin_hanout_model.dart';

class AdminAccountsState {
  const AdminAccountsState({
    required this.loading,
    required this.clients,
    required this.hanouts,
    required this.hanoutProfiles,
    required this.livreurs,
    required this.query,
    required this.disabledIds,
    required this.stats,
    this.error,
  });

  final bool loading;
  final List<UserModel> clients;
  final List<UserModel> hanouts;
  final List<AdminHanoutModel> hanoutProfiles;
  final List<UserModel> livreurs;
  final String query;
  final Set<String> disabledIds;
  final AdminStats? stats;
  final String? error;

  factory AdminAccountsState.initial() {
    return const AdminAccountsState(
      loading: true,
      clients: [],
      hanouts: [],
      hanoutProfiles: [],
      livreurs: [],
      query: '',
      disabledIds: {},
      stats: null,
      error: null,
    );
  }

  AdminAccountsState copyWith({
    bool? loading,
    List<UserModel>? clients,
    List<UserModel>? hanouts,
    List<AdminHanoutModel>? hanoutProfiles,
    List<UserModel>? livreurs,
    String? query,
    Set<String>? disabledIds,
    AdminStats? stats,
    String? error,
    bool clearError = false,
  }) {
    return AdminAccountsState(
      loading: loading ?? this.loading,
      clients: clients ?? this.clients,
      hanouts: hanouts ?? this.hanouts,
      hanoutProfiles: hanoutProfiles ?? this.hanoutProfiles,
      livreurs: livreurs ?? this.livreurs,
      query: query ?? this.query,
      disabledIds: disabledIds ?? this.disabledIds,
      stats: stats ?? this.stats,
      error: clearError ? null : error ?? this.error,
    );
  }
}
