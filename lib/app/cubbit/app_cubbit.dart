import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  const AppState({required this.locale});
  final Locale locale;

  AppState copyWith({Locale? locale}) {
    return AppState(
      locale: locale ?? this.locale,
    );
  }
}

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState(locale: Locale('fr')));
  static const _localeStorageKey = 'app_locale';

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocaleCode = prefs.getString(_localeStorageKey);
    if (savedLocaleCode == null || savedLocaleCode.isEmpty) return;
    if (savedLocaleCode == state.locale.languageCode) return;

    emit(state.copyWith(locale: Locale(savedLocaleCode)));
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == state.locale.languageCode) return;

    emit(state.copyWith(locale: Locale(locale.languageCode)));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeStorageKey, locale.languageCode);
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to persist locale: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> setFrench() => setLocale(const Locale('fr'));

  Future<void> setArabic() => setLocale(const Locale('ar'));
}
