import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sevenouti/config/env.dart';
import 'package:sevenouti/core/auth/token_refresh_service.dart';
import 'package:sevenouti/core/device/installation_service.dart';
import 'package:sevenouti/core/storage/token_storage.dart';

class ApiConfig {
  static const Duration timeout = Duration(seconds: 30);
}

class ApiService {
  ApiService() {
    _log('[ApiService] baseUrl=$baseUrl');
  }

  final String baseUrl = Env.baseUrl;
  static final http.Client _client = http.Client();

  String? _token;

  String? get token => _token;

  set token(String token) => _token = token;

  Future<dynamic> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      _log('[ApiService][GET] $url');
      final response = await _sendWithAutoRefresh(
        () async => _client
            .get(Uri.parse(url), headers: await _headers())
            .timeout(ApiConfig.timeout),
      );
      _log('[ApiService][GET] status=${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException("Delai d'attente depasse");
    } catch (e) {
      throw ApiException('Erreur: $e');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final url = '$baseUrl$endpoint';
      _log('[ApiService][POST] $url');
      final response = await _sendWithAutoRefresh(
        () async => _client
            .post(
              Uri.parse(url),
              headers: await _headers(),
              body: body != null ? json.encode(body) : null,
            )
            .timeout(ApiConfig.timeout),
      );
      _log('[ApiService][POST] status=${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException("Delai d'attente depasse");
    } catch (e) {
      throw ApiException('Erreur: $e');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final url = '$baseUrl$endpoint';
      _log('[ApiService][PUT] $url');
      final response = await _sendWithAutoRefresh(
        () async => _client
            .put(
              Uri.parse(url),
              headers: await _headers(),
              body: body != null ? json.encode(body) : null,
            )
            .timeout(ApiConfig.timeout),
      );
      _log('[ApiService][PUT] status=${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException("Delai d'attente depasse");
    } catch (e) {
      throw ApiException('Erreur: $e');
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final url = '$baseUrl$endpoint';
      _log('[ApiService][PATCH] $url');
      final response = await _sendWithAutoRefresh(
        () async => _client
            .patch(
              Uri.parse(url),
              headers: await _headers(),
              body: body != null ? json.encode(body) : null,
            )
            .timeout(ApiConfig.timeout),
      );
      _log('[ApiService][PATCH] status=${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException("Delai d'attente depasse");
    } catch (e) {
      throw ApiException('Erreur: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      _log('[ApiService][DELETE] $url');
      final response = await _sendWithAutoRefresh(
        () async => _client
            .delete(Uri.parse(url), headers: await _headers())
            .timeout(ApiConfig.timeout),
      );
      _log('[ApiService][DELETE] status=${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException("Delai d'attente depasse");
    } catch (e) {
      throw ApiException('Erreur: $e');
    }
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    required String fileField,
    List<int>? bytes,
    String? filePath,
    String? filename,
    MediaType? contentType,
    Map<String, String>? fields,
  }) async {
    try {
      final url = '$baseUrl$endpoint';
      _log('[ApiService][POST multipart] $url');

      Future<http.Response> sender() async {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers.addAll(await _authHeaders());
        if (fields != null) {
          request.fields.addAll(fields);
        }

        if (bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              fileField,
              bytes,
              filename: filename,
              contentType: contentType,
            ),
          );
        } else if (filePath != null) {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, filePath),
          );
        } else {
          throw ApiException('Aucun fichier fourni');
        }

        final streamed = await request.send().timeout(ApiConfig.timeout);
        return http.Response.fromStream(streamed);
      }

      final response = await _sendWithAutoRefresh(sender);
      _log('[ApiService][POST multipart] status=${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException("Delai d'attente depasse");
    } catch (e) {
      throw ApiException('Erreur: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    _log('[ApiService][RESP] status=${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw ApiException('Session expiree, reconnectez-vous');
    } else if (response.statusCode == 404) {
      throw ApiException('Ressource non trouvee');
    } else {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw ApiException(body['message'] as String? ?? 'Erreur serveur');
    }
  }

  Future<http.Response> _sendWithAutoRefresh(
    Future<http.Response> Function() sender,
  ) async {
    _token = await TokenStorage.getToken();
    final response = await sender();
    if (response.statusCode != 401) {
      return response;
    }

    final refreshed = await TokenRefreshService.refreshToken();
    if (!refreshed) {
      return response;
    }

    _token = await TokenStorage.getToken();
    return sender();
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final installationId = await InstallationService.getInstallationId();
    headers['X-Installation-Id'] = installationId;
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, String>> _authHeaders() async {
    final headers = <String, String>{
      'X-Installation-Id': await InstallationService.getInstallationId(),
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
