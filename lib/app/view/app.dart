import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/app/cubbit/app_cubbit.dart';
import 'package:sevenouti/auth/view/auth_gate.dart';
import 'package:sevenouti/core/theme/app_theme.dart';
import 'package:sevenouti/l10n/l10n.dart';

// class App extends StatefulWidget {
//   const App({super.key});

//   @override
//   State<App> createState() => _AppState();
// }

// class _AppState extends State<App> {

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AppCubit, AppState>(
//       builder: (context, state) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,

//           locale: state.locale,
//           supportedLocales: AppLocalizations.supportedLocales,
//           localizationsDelegates: AppLocalizations.localizationsDelegates,

//           home: const AuthGate(),
//         );
//       },
//     );
//   }
// }


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          locale: state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

          theme: buildAppTheme(),
          home: const AuthGate(),
        );
      },
    );
  }
}
