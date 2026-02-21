import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/app/cubbit/app_cubbit.dart';
import 'package:sevenouti/l10n/l10n.dart';

class LanguageSelectorTile extends StatelessWidget {
  const LanguageSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return DropdownButtonFormField<String>(
          initialValue: state.locale.languageCode,
          decoration: InputDecoration(
            labelText: l10n.authLanguageLabel,
            prefixIcon: const Icon(Icons.language),
          ),
          items: [
            DropdownMenuItem(
              value: 'fr',
              child: Text(l10n.authFrench),
            ),
            DropdownMenuItem(
              value: 'ar',
              child: Text(l10n.authArabic),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            unawaited(context.read<AppCubit>().setLocale(Locale(value)));
          },
        );
      },
    );
  }
}
