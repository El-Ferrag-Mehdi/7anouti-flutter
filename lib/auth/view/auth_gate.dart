import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/admin/view/admin_shell.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/auth/cubbit/auth_state.dart';
import 'package:sevenouti/auth/models/user_role.dart';
import 'package:sevenouti/auth/view/login_page.dart';
import 'package:sevenouti/client/view/client_shell.dart';
import 'package:sevenouti/hanout/view/hanout_shell.dart';
import 'package:sevenouti/livreur/view/livreur_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
   return BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    if (state is Authenticated) {
      switch (state.role) {
        case UserRole.client:
          return const ClientShell();

        case UserRole.hanout:
          return const HanoutShell();

        case UserRole.livreur:
          return const LivreurShell();

        case UserRole.admin:
          return const AdminShell();
      }
    }

    return const LoginPage();
  },
);

  }
}
