import 'package:sevenouti/auth/models/user_role.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {

  Authenticated({
    required this.token,
    required this.role,
  });
  
  final String token;
  final UserRole role;
}

class Unauthenticated extends AuthState {}
