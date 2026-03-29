import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    await _safeWrite(_tokenKey, token);
    await _safeWrite(_roleKey, role);
    final resolvedUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : _extractUserIdFromJwt(token);
    if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
      await _safeWrite(_userIdKey, resolvedUserId);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _safeWrite(_refreshTokenKey, refreshToken);
    }
  }

  static Future<String?> getToken() async {
    return _safeRead(_tokenKey);
  }

  static Future<String?> getRole() async {
    return _safeRead(_roleKey);
  }

  static Future<String?> getRefreshToken() async {
    return _safeRead(_refreshTokenKey);
  }

  static Future<String?> getUserId() async {
    final stored = await _safeRead(_userIdKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    final extracted = _extractUserIdFromJwt(token);
    if (extracted != null && extracted.isNotEmpty) {
      await _safeWrite(_userIdKey, extracted);
    }
    return extracted;
  }

  static Future<void> clear() async {
    await _safeDeleteAll();
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

  static Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error) {
      await _handleStorageFailure(error, operation: 'read', key: key);
      return null;
    }
  }

  static Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (error) {
      await _handleStorageFailure(error, operation: 'write', key: key);
      await _storage.write(key: key, value: value);
    }
  }

  static Future<void> _safeDeleteAll() async {
    try {
      await _storage.deleteAll();
    } on PlatformException catch (error) {
      debugPrint(
        '[TokenStorage] secure storage deleteAll failed, trying per-key cleanup: $error',
      );
      await _safeDelete(_tokenKey);
      await _safeDelete(_refreshTokenKey);
      await _safeDelete(_roleKey);
      await _safeDelete(_userIdKey);
    }
  }

  static Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (error) {
      debugPrint(
        '[TokenStorage] secure storage delete failed for $key: $error',
      );
    }
  }

  static Future<void> _handleStorageFailure(
    PlatformException error, {
    required String operation,
    required String key,
  }) async {
    debugPrint(
      '[TokenStorage] secure storage $operation failed for $key. Clearing local auth cache. $error',
    );
    await _safeDeleteAll();
  }
}
