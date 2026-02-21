import 'package:flutter/material.dart';

/// Couleurs de l'application
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFFE85A2A); // Orange logo
  static const Color primaryLight = Color(0xFFF27A54);
  static const Color primaryDark = Color(0xFFC7471C);

  static const Color secondary = Color(0xFF7CB342); // Vert logo
  static const Color secondaryLight = Color(0xFF9CCC65);
  static const Color secondaryDark = Color(0xFF558B2F);

  // Accents
  static const Color accent = Color(0xFFD9482B); // Rouge chaud
  static const Color gold = Color(0xFFF4C267); // Doré
  static const Color brown = Color(0xFF4A2E1B); // Brun logo (texte/outline)

  // Couleurs de statut
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);

  // Couleurs neutres
  static const Color background = Color(0xFFFAF6F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFDF9F4);

  // Texte
  static const Color textPrimary = Color(0xFF2D241E);
  static const Color textSecondary = Color(0xFF7A6D64);
  static const Color textDisabled = Color(0xFFC7BEB7);

  // Bordures
  static const Color border = Color(0xFFEADFD2);
  static const Color divider = Color(0xFFF1E8DE);

  // Overlay
  static const Color overlay = Color(0x33000000); // 20% noir
  static const Color scrim = Color(0x66000000); // 40% noir
}

/// Espacements de l'application
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Padding par défaut des pages
  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pageVertical = EdgeInsets.symmetric(vertical: md);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardInner = EdgeInsets.all(sm);
}

/// Border radius de l'application
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double roundValue = 999.0; // Pour des boutons complètement ronds

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius round = BorderRadius.all(
    Radius.circular(roundValue),
  );
}

/// Styles de texte de l'application
class AppTextStyles {
  static const String fontFamily = 'Manrope';

  // Titres
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    fontFamily: fontFamily,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
    fontFamily: fontFamily,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamily: fontFamily,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamily: fontFamily,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFamily: fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
    fontFamily: fontFamily,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.3,
    fontFamily: fontFamily,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    fontFamily: fontFamily,
  );

  // Label
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.2,
    fontFamily: fontFamily,
  );
}

/// Ombres de l'application
class AppShadows {
  static const BoxShadow light = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 14,
    offset: Offset(0, 8),
  );

  static const BoxShadow strong = BoxShadow(
    color: Color(0x22000000),
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  static const List<BoxShadow> card = [light];
  static const List<BoxShadow> elevated = [medium];
  static const List<BoxShadow> modal = [strong];
}

/// Durées des animations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// Constantes de l'application
class AppConstants {
  // Radius de recherche par défaut (en mètres)
  static const double defaultSearchRadius = 500.0;

  // Frais
  static const double defaultDeliveryFee = 7.0;
  static const double serviceFee = 2.0;


  // Nombre maximum de caractères pour la commande libre
  static const int maxOrderTextLength = 500;

  // Format de date
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Monnaie
  static const String currency = 'DH';
}

