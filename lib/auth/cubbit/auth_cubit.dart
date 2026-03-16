import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/auth/cubbit/auth_state.dart';
import 'package:sevenouti/auth/models/user_role.dart';
import 'package:sevenouti/auth/repository/auth_repository.dart';
import 'package:sevenouti/core/auth/auth_session_notifier.dart';
import 'package:sevenouti/core/notifications/push_notification_service.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(AuthInitial()) {
    _sessionExpiredSubscription = AuthSessionNotifier.instance.onSessionExpired
        .listen((_) async {
      // Session already invalid: skip extra backend calls.
      final alreadyUnauthenticated = state is Unauthenticated;
      if (alreadyUnauthenticated || _isHandlingSessionExpiry) {
        return;
      }
      _isHandlingSessionExpiry = true;
      try {
        await PushNotificationService.instance.clearDeviceTokenForLogout();
        await _repository.logout();
        emit(Unauthenticated());
      } finally {
        _isHandlingSessionExpiry = false;
      }
    });
  }
  final AuthRepository _repository;
  late final StreamSubscription<void> _sessionExpiredSubscription;
  bool _isHandlingSessionExpiry = false;

  Future<void> register({
    required String email,
    required String password,
    required String nameFr,
    required String phone,
    String? nameAr,
  }) async {
    await _repository.register(
      email: email,
      password: password,
      nameFr: nameFr,
      nameAr: nameAr,
      phone: phone,
    );

    await login(email: email, password: password);
  }

  Future<void> checkAuthStatus() async {
    try {
      debugPrint('[Auth] Checking auth status...');

      final token = await _repository.getStoredToken();
      final role = await _repository.getStoredRole();

      if (token != null && role != null) {
        emit(
          Authenticated(
            token: token,
            role: UserRoleParser.fromString(role),
          ),
        );
        await PushNotificationService.instance.syncTokenWithBackend();
      } else {
        emit(Unauthenticated());
      }
    } on Object catch (e, stack) {
      debugPrint('[Auth] checkAuthStatus error: $e');
      debugPrint(stack.toString());
      emit(Unauthenticated());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final (token, role) = await _repository.login(
        email: email,
        password: password,
      );

      emit(
        Authenticated(
          token: token,
          role: UserRoleParser.fromString(role),
        ),
      );
      await PushNotificationService.instance.syncTokenWithBackend();
    } catch (e) {
      emit(Unauthenticated());
      rethrow;
    }
  }

  Future<void> logout() async {
    await PushNotificationService.instance.clearDeviceTokenForLogout();
    await _repository.logout();
    debugPrint('[Auth] logout');
    emit(Unauthenticated());
  }

  @override
  Future<void> close() async {
    await _sessionExpiredSubscription.cancel();
    return super.close();
  }
}
