import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/user_model.dart';
import 'package:sevenouti/admin/models/admin_stats.dart';
import 'package:sevenouti/admin/models/admin_hanout_model.dart';

class AdminRepository {
  AdminRepository(this._apiService);

  final ApiService _apiService;

  Future<List<UserModel>> listUsers({
    UserRole? role,
    String? query,
  }) async {
    var endpoint = '/admin/users';
    final params = <String>[];
    if (role != null) params.add('role=${role.value}');
    if (query != null && query.trim().isNotEmpty) {
      params.add('q=${Uri.encodeComponent(query.trim())}');
    }
    if (params.isNotEmpty) {
      endpoint = '$endpoint?${params.join('&')}';
    }

    final dynamic response = await _apiService.get(endpoint);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> data = responseMap['data'] as List<dynamic>;
    return data
        .map((dynamic json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> createUser({
    required String name,
    required String phone,
    String? email,
    required String password,
    required UserRole role,
    Map<String, dynamic>? hanout,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role.value,
    };
    if (hanout != null) {
      body['hanout'] = hanout;
    }
    final dynamic response = await _apiService.post(
      '/admin/users',
      body: body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return UserModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateUser({
    required String id,
    String? name,
    String? phone,
    String? email,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;

    final dynamic response = await _apiService.put(
      '/admin/users/$id',
      body: body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return UserModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<UserModel> setActive({
    required String id,
    required bool isActive,
  }) async {
    final dynamic response = await _apiService.patch(
      '/admin/users/$id/active',
      body: {'isActive': isActive},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return UserModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<AdminStats> getStats() async {
    final dynamic response = await _apiService.get('/admin/stats');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return AdminStats.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<List<AdminHanoutModel>> listHanouts({String? query}) async {
    var endpoint = '/admin/hanouts';
    if (query != null && query.trim().isNotEmpty) {
      endpoint = '$endpoint?q=${Uri.encodeComponent(query.trim())}';
    }

    final dynamic response = await _apiService.get(endpoint);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> data = responseMap['data'] as List<dynamic>;
    return data
        .map(
          (dynamic json) =>
              AdminHanoutModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<AdminHanoutModel> setHanoutShowRating({
    required String hanoutId,
    required bool showRating,
  }) async {
    final dynamic response = await _apiService.patch(
      '/admin/hanouts/$hanoutId/show-rating',
      body: {'showRating': showRating},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return AdminHanoutModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<AdminHanoutModel> setHanoutDeliveryFee({
    required String hanoutId,
    required double deliveryFee,
  }) async {
    final dynamic response = await _apiService.patch(
      '/admin/hanouts/$hanoutId/delivery-fee',
      body: {'deliveryFee': deliveryFee},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return AdminHanoutModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }
}
