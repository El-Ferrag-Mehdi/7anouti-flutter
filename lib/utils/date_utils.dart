import 'package:intl/intl.dart';

/// Utilitaires legacy pour formater les dates.
/// Preferer `localized_formatters.dart` pour l'affichage localise avec contexte.
class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return "A l'instant";
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours} h';
    }

    if (difference.inDays == 1) {
      return 'Hier a ${formatTime(date)}';
    }

    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    }

    return formatDate(date);
  }

  static String getDayOfWeek(DateTime date) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return days[date.weekday - 1];
  }

  static String getMonth(DateTime date) {
    const months = [
      'Janvier',
      'Fevrier',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Aout',
      'Septembre',
      'Octobre',
      'Novembre',
      'Decembre',
    ];
    return months[date.month - 1];
  }

  static String formatDeliveryTime(int minutes) {
    final min = minutes;
    final max = minutes + 5;
    return '$min-$max min';
  }
}
