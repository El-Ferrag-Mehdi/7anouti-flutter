import 'package:sevenouti/client/data/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  
  AuthService(this._apiService);
  
  /// Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    
    // Stocke le token
       final token = response['token'] as String;
    final user = response['user'] as Map<String, dynamic>;
    
    _apiService.setToken(token);
    await _saveToken(token);
    await _saveUserId(user['id'].toString());
    
    return user;
  }
  
  /// Logout
  Future<void> logout() async {
    _apiService.setToken('');
    await _clearToken();
    await _clearUserId();
  }
  
  /// Vérifie si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    if (token != null) {
      _apiService.setToken(token);
      return true;
    }
    return false;
  }
  
  /// Récupère le token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  /// Sauvegarde le token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  /// Supprime le token
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  /// Récupère l'ID user
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  /// Sauvegarde l'ID user
  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }
  
  /// Supprime l'ID user
  Future<void> _clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
}