import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';

  static Future<void> saveToken(
    String token,
    String role, {
    String? refreshToken,
    String? userId,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    final resolvedUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : _extractUserIdFromJwt(token);
    if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
      await _storage.write(key: _userIdKey, value: resolvedUserId);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<String?> getRole() async {
    return _storage.read(key: _roleKey);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<String?> getUserId() async {
    final stored = await _storage.read(key: _userIdKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    final extracted = _extractUserIdFromJwt(token);
    if (extracted != null && extracted.isNotEmpty) {
      await _storage.write(key: _userIdKey, value: extracted);
    }
    return extracted;
  }

  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _userIdKey);
  }

  static String? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return null;
      final id = json['id']?.toString().trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } on Object {
      return null;
    }
  }
}
