import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/admin/cubbit/admin_accounts_cubit.dart';
import 'package:sevenouti/admin/data/admin_repository.dart';
import 'package:sevenouti/admin/view/pages/admin_dashboard_page.dart';
import 'package:sevenouti/auth/cubbit/auth_cubit.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/core/widgets/app_logo_header.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminAccountsCubit(
        AdminRepository(ApiService()),
      )..loadAll(),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: -15,
          title: const AppLogoHeader(height: 44, width: 136),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                context.read<AuthCubit>().logout();
              },
            ),
          ],
        ),
        body: const AdminDashboardPage(),
      ),
    );
  }
}
