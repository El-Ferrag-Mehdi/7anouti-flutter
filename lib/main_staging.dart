import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/app/app.dart';
import 'package:sevenouti/app/cubbit/app_cubbit.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/auth/data/auth_api.dart';
import 'package:sevenouti/auth/repository/auth_repository.dart';
import 'package:sevenouti/bootstrap.dart';
import 'package:sevenouti/config/env.dart';

Future<void> main() async {
  Env.baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sevenanouti-backend.onrender.com/api',
  );
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
        BlocProvider(
          create: (_) {
            final cubit = AuthCubit(AuthRepository(AuthApi()));
            unawaited(cubit.checkAuthStatus());
            return cubit;
          },
        ),
      ],
      child: const App(),
    ),
  );
}
