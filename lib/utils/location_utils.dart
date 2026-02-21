import 'dart:math';

/// Utilitaires pour la géolocalisation
class LocationUtils {
  /// Calcule la distance entre deux points géographiques (formule de Haversine)
  /// Retourne la distance en mètres
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // Rayon de la Terre en mètres

    // Conversion en radians
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convertit des degrés en radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Formate une distance en mètres vers un string lisible
  /// Ex: 350m ou 1.2km
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Vérifie si un point est dans un rayon donné
  static bool isWithinRadius(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= radiusInMeters;
  }

  /// Trie une liste de hanouts par distance
  /// Note: Cette fonction sera utilisée dans le Cubit
  static List<T> sortByDistance<T>({
    required List<T> items,
    required double userLat,
    required double userLon,
    required double Function(T) getLat,
    required double Function(T) getLon,
  }) {
    final itemsWithDistance = items.map((item) {
      final distance = calculateDistance(
        userLat,
        userLon,
        getLat(item),
        getLon(item),
      );
      return MapEntry(item, distance);
    }).toList();

    // Trie par distance croissante
    itemsWithDistance.sort((a, b) => a.value.compareTo(b.value));

    return itemsWithDistance.map((e) => e.key).toList();
  }
}