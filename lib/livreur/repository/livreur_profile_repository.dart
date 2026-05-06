import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/user_model.dart';

class LivreurProfileRepository {
  LivreurProfileRepository(this._apiService);

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
    double? latitude,
    double? longitude,
    bool? isLivreurZoneActive,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
    };
    if (latitude != null) {
      body['latitude'] = latitude;
    }
    if (longitude != null) {
      body['longitude'] = longitude;
    }
    if (isLivreurZoneActive != null) {
      body['isLivreurZoneActive'] = isLivreurZoneActive;
    }

    final dynamic response = await _apiService.put(
      '/auth/me',
      body: body,
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
