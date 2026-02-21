import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sevenouti/config/env.dart';
import 'package:sevenouti/core/storage/token_storage.dart';

/// Configuration de l'API
class ApiConfig {
  // Change ces URLs selon ton environnement
  static const String developmentUrl = 'http://localhost:3000/api';
  static const String productionUrl = 'https://your-production-url.com/api';

  /// Retourne l'URL de base selon l'environnement
  static String get baseUrl {
    // Tu peux utiliser const String.fromEnvironment('ENV') pour dÃ©tecter l'env
    return developmentUrl; // Pour l'instant en dev
  }

  /// Timeout pour les requÃªtes
  static const Duration timeout = Duration(seconds: 30);
}

/// Exception personnalisÃ©e pour les erreurs API
// class ApiException implements Exception {
//   final String message;
//   final int? statusCode;
//   final dynamic data;

//   ApiException({
//     required this.message,
//     this.statusCode,
//     this.data,
//   });

//   @override
//   String toString() => 'ApiException: $message (Status: $statusCode)';
// }

/// Service de base pour les appels API
class ApiService {
  // REMPLACE localhost par ton IP local
  // static const String baseUrl = 'http:// 192.168.43.149:4000/api'; // â† TON IP ICI
  final String baseUrl = '${Env.baseUrl}';

  ApiService() {
    debugPrint('ðŸŸ¦ [ApiService] baseUrl=$baseUrl');
  }

  // Stockage du token
  String? _token;

  // Getter pour le token
  String? get token => _token;

  // Setter pour le token (appelÃ© aprÃ¨s login)
  void setToken(String token) {
    _token = token;
  }

  // Headers avec authentification
  Future<Map<String, String>> _headers() async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // PrioritÃ© au token en mÃ©moire, sinon lecture depuis le storage
    final token = _token ?? await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, String>> _authHeaders() async {
    final headers = <String, String>{};
    final token = _token ?? await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('ðŸŸ¦ [ApiService][GET] $url');
      final response = await http
          .get(
            Uri.parse(url),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ðŸŸ¦ [ApiService][GET] status=${response.statusCode}');

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException('DÃ©lai d\'attente dÃ©passÃ©');
    } catch (e) {
      throw ApiException('Erreur: ${e.toString()}');
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('ðŸŸ¦ [ApiService][POST] $url');
      final response = await http
          .post(
            Uri.parse(url),
            headers: await _headers(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ðŸŸ¦ [ApiService][POST] status=${response.statusCode}');

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException('DÃ©lai d\'attente dÃ©passÃ©');
    } catch (e) {
      throw ApiException('Erreur: ${e.toString()}');
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('ðŸŸ¦ [ApiService][PUT] $url');
      final response = await http
          .put(
            Uri.parse(url),
            headers: await _headers(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ðŸŸ¦ [ApiService][PUT] status=${response.statusCode}');

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException('DÃ©lai d\'attente dÃ©passÃ©');
    } catch (e) {
      throw ApiException('Erreur: ${e.toString()}');
    }
  }

  // PATCH request
  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('ðŸŸ¦ [ApiService][PATCH] $url');
      final response = await http
          .patch(
            Uri.parse(url),
            headers: await _headers(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ðŸŸ¦ [ApiService][PATCH] status=${response.statusCode}');

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException('DÃ©lai d\'attente dÃ©passÃ©');
    } catch (e) {
      throw ApiException('Erreur: ${e.toString()}');
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('ðŸŸ¦ [ApiService][DELETE] $url');
      final response = await http
          .delete(
            Uri.parse(url),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('ðŸŸ¦ [ApiService][DELETE] status=${response.statusCode}');

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException('DÃ©lai d\'attente dÃ©passÃ©');
    } catch (e) {
      throw ApiException('Erreur: ${e.toString()}');
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
      debugPrint('ðŸŸ¦ [ApiService][POST multipart] $url');
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

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      debugPrint(
        'ðŸŸ¦ [ApiService][POST multipart] status=${response.statusCode}',
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Pas de connexion internet');
    } on TimeoutException {
      throw ApiException('DÃ©lai d\'attente dÃ©passÃ©');
    } catch (e) {
      throw ApiException('Erreur: ${e.toString()}');
    }
  }

  // Gestion des rÃ©ponses
  dynamic _handleResponse(http.Response response) {
    debugPrint(
      'ðŸŸ¦ [ApiService][RESP] status=${response.statusCode} body=${response.body}',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw ApiException('Non autorisÃ© - Token invalide');
    } else if (response.statusCode == 404) {
      throw ApiException('Ressource non trouvÃ©e');
    } else {
      final body = json.decode(response.body) as Map<String, dynamic>;
      throw ApiException(body['message'] as String? ?? 'Erreur serveur');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
