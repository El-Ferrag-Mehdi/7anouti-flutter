import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sevenouti/config/env.dart';
import 'package:sevenouti/core/auth/auth_session_notifier.dart';
import 'package:sevenouti/core/storage/token_storage.dart';

class TokenRefreshService {
  TokenRefreshService._();

  static Completer<bool>? _refreshCompleter;

  static Future<bool> refreshToken() async {
    final pending = _refreshCompleter;
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      final storedRole = await TokenStorage.getRole();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearAndNotify();
        completer.complete(false);
        return false;
      }

      final response = await http
          .post(
            Uri.parse('${Env.baseUrl}/auth/refresh'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        await _clearAndNotify();
        completer.complete(false);
        return false;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final nextAccessToken =
          (json['token'] ?? json['accessToken'])?.toString().trim();
      final nextRefreshToken = json['refreshToken']?.toString().trim();
      final nextRole =
          json['user']?['role']?.toString().trim() ?? storedRole ?? 'CLIENT';

      if (nextAccessToken == null || nextAccessToken.isEmpty) {
        await _clearAndNotify();
        completer.complete(false);
        return false;
      }

      await TokenStorage.saveToken(
        nextAccessToken,
        nextRole,
        refreshToken: (nextRefreshToken == null || nextRefreshToken.isEmpty)
            ? refreshToken
            : nextRefreshToken,
      );
      completer.complete(true);
      return true;
    } on Object {
      await _clearAndNotify();
      completer.complete(false);
      return false;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  static Future<void> _clearAndNotify() async {
    await TokenStorage.clear();
    AuthSessionNotifier.instance.notifySessionExpired();
  }
}
