import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sevenouti/config/env.dart';
import 'package:sevenouti/core/device/installation_service.dart';

class AuthApi {
  final String url = Env.baseUrl;

  // ------------------- LOGIN -------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final installationId = await InstallationService.getInstallationId();
    final response = await http.post(
      Uri.parse('$url/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'X-Installation-Id': installationId,
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'installationId': installationId,
      }),
    );

    debugPrint('LOGIN STATUS: ${response.statusCode}');
    debugPrint('LOGIN BODY: ${response.body}');

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Login failed');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ------------------- REGISTER -------------------
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nameFr,
    required String phone,
    String? nameAr,
  }) async {
    final installationId = await InstallationService.getInstallationId();
    final response = await http.post(
      Uri.parse('$url/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'X-Installation-Id': installationId,
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'nameFr': nameFr,
        'nameAr': nameAr,
        'phone': phone,
        'installationId': installationId,
      }),
    );

    debugPrint('REGISTER STATUS: ${response.statusCode}');
    debugPrint('REGISTER BODY: ${response.body}');

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Register failed');
    }

    // Return the JSON body from backend
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
