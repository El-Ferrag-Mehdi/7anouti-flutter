import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

bool isArabicLocale(BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'ar';
}

String formatDh(BuildContext context, num amount, {int decimals = 2}) {
  final localeCode = Localizations.localeOf(context).languageCode;
  final pattern = decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}';
  final value = NumberFormat(pattern, localeCode).format(amount);
  if (localeCode == 'ar') {
    return '$value Ø¯.Ù…';
  }
  return '$value DH';
}

String formatRelativeDateLocalized(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  final localeCode = Localizations.localeOf(context).languageCode;
  final time = DateFormat('HH:mm', localeCode).format(date);

  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      if (difference.inMinutes == 0) {
        if (localeCode == 'ar') return 'Ø§Ù„Ø¢Ù†';
        if (localeCode == 'en') return 'Just now';
        return "A l'instant";
      }
      if (localeCode == 'ar') return 'Ù…Ù†Ø° ${difference.inMinutes} Ø¯';
      if (localeCode == 'en') return '${difference.inMinutes} min ago';
      return 'Il y a ${difference.inMinutes} min';
    }
    if (localeCode == 'ar') return 'Ù…Ù†Ø° ${difference.inHours} Ø³';
    if (localeCode == 'en') return '${difference.inHours} h ago';
    return 'Il y a ${difference.inHours} h';
  }

  if (difference.inDays == 1) {
    if (localeCode == 'ar') return 'Ø£Ù…Ø³ Ø¹Ù„Ù‰ $time';
    if (localeCode == 'en') return 'Yesterday at $time';
    return 'Hier a $time';
  }

  if (difference.inDays < 7) {
    if (localeCode == 'ar') return 'Ù…Ù†Ø° ${difference.inDays} ÙŠÙˆÙ…';
    if (localeCode == 'en') return '${difference.inDays} days ago';
    return 'Il y a ${difference.inDays} jours';
  }

  return DateFormat('dd/MM/yyyy', localeCode).format(date);
}

String formatAddressLocalized(BuildContext context, String? address) {
  final fallback = '-';
  if (address == null || address.trim().isEmpty) return fallback;
  final value = address.trim();
  if (!isArabicLocale(context)) return value;
  return value.replaceAll(',', '،');
}

String pickLocalizedAddress(
  BuildContext context, {
  String? addressFr,
  String? addressAr,
  String? fallback,
}) {
  if (isArabicLocale(context)) {
    final arabic = addressAr?.trim();
    if (arabic != null && arabic.isNotEmpty) {
      return formatAddressLocalized(context, arabic);
    }
  }

  final french = addressFr?.trim();
  if (french != null && french.isNotEmpty) {
    return formatAddressLocalized(context, french);
  }

  return formatAddressLocalized(context, fallback);
}
