import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/user_model.dart';

class ClientProfileRepository {
  ClientProfileRepository(this._apiService);

  final ApiService _apiService;

  Future<UserModel> getMyProfile() async {
    final dynamic response = await _apiService.get('/auth/me');
    final responseMap = response as Map<String, dynamic>;
    return UserModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateMyProfile({
    required String name,
    required String phone,
    String? address,
  }) async {
    final dynamic response = await _apiService.put(
      '/auth/me',
      body: {
        'name': name,
        'phone': phone,
        'address': address,
      },
    );
    final responseMap = response as Map<String, dynamic>;
    return UserModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMyAccount() async {
    await _apiService.delete('/auth/me');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiService.put(
      '/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
