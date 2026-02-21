import 'package:flutter/material.dart';
import 'package:sevenouti/auth/data/auth_api.dart';
import 'package:sevenouti/core/storage/token_storage.dart';

class AuthRepository {
  AuthRepository(this._api);
  final AuthApi _api;

  // Future<(String token, String role)> login({
  //   required String email,
  //   required String password,
  // }) async {
  //   final data = await _api.login(
  //     email: email,
  //     password: password,
  //   );

  //   final token = data['token'] as String?;
  //   final role = data['user']?['role'] as String?;

  //   if (token == null || role == null) {
  //     throw Exception('Login response is missing token or role');
  //   }

  //   debugPrint('AuthRepository → login: token=$token, role=$role');

  //   return (token, role);
  // }

  Future<(String token, String role)> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.login(
      email: email,
      password: password,
    );

    final token = data['token'] as String?;
    final role = data['user']?['role'] as String?;

    if (token == null || role == null) {
      throw Exception('Login response is missing token or role');
    }

    // 🔐 SAUVEGARDE DU TOKEN
    await TokenStorage.saveToken(token, role);

    debugPrint('AuthRepository → login: token saved, role=$role');

    return (token, role);
  }

  Future<void> register({
    required String email,
    required String password,
    required String nameFr,
    String? nameAr,
    required String phone,
  }) async {
    final data = await _api.register(
      email: email,
      password: password,
      nameFr: nameFr,
      nameAr: nameAr,
      phone: phone,
    );

    debugPrint('AuthRepository → register: $data');
  }

  Future<void> logout() async {
    await TokenStorage.clear();
  }

  Future<String?> getStoredToken() async {
    return TokenStorage.getToken();
  }

  Future<String?> getStoredRole() async {
    return TokenStorage.getRole();
  }
}
