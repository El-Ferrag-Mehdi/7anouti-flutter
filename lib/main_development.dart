import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/app/app.dart';
import 'package:sevenouti/app/cubbit/app_cubbit.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/auth/data/auth_api.dart';
import 'package:sevenouti/auth/repository/auth_repository.dart';
import 'package:sevenouti/bootstrap.dart';
import 'package:sevenouti/config/env.dart';

void appLog(String message) {
  debugPrint('🟢 [APP LOG] $message');
}

void appError(String message, [Object? error, StackTrace? stack]) {
  debugPrint('🔴 [APP ERROR] $message');
  if (error != null) debugPrint('Error: $error');
  if (stack != null) debugPrint('StackTrace: $stack');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Env.baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );

  try {
    appLog('Starting app...');

    await bootstrap(
      () => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) {
              final cubit = AppCubit();
              unawaited(cubit.loadSavedLocale());
              return cubit;
            },
          ),

          /// 🔑 AuthCubit CHECK l’auth au démarrage
          BlocProvider(
            create: (_) {
              final cubit = AuthCubit(
                AuthRepository(AuthApi()),
              );
              unawaited(cubit.checkAuthStatus());
              return cubit;
            }, // 👈 TRÈS IMPORTANT
          ),
        ],
        child: const App(),
      ),
    );

    appLog('✅ App started successfully!');
  } on Object catch (e, stackTrace) {
    appError('❌ App failed to start', e, stackTrace);
  }
}
