import 'package:intl/intl.dart';

/// Utilitaires pour formater les dates
class DateUtils {
  /// Formate une date au format court (ex: 29/01/2026)
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formate une date avec l'heure (ex: 29/01/2026 14:30)
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Formate uniquement l'heure (ex: 14:30)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Retourne une date relative (ex: "Aujourd'hui", "Hier", "Il y a 2 jours")
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Aujourd'hui
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return "À l'instant";
        }
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    }

    // Hier
    if (difference.inDays == 1) {
      return 'Hier à ${formatTime(date)}';
    }

    // Cette semaine
    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    }

    // Plus ancien
    return formatDate(date);
  }

  /// Retourne le jour de la semaine en français
  static String getDayOfWeek(DateTime date) {
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return days[date.weekday - 1];
  }

  /// Retourne le mois en français
  static String getMonth(DateTime date) {
    final months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return months[date.month - 1];
  }

  /// Formate une durée en minutes vers un string lisible
  /// Ex: "5-10 min" ou "20-25 min"
  static String formatDeliveryTime(int minutes) {
    final min = minutes;
    final max = minutes + 5;
    return '$min-$max min';
  }
}