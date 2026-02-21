import 'package:shared_preferences/shared_preferences.dart';

class CachedLocation {
  const CachedLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? updatedAt;
}

class LocationCache {
  static const String _latKey = 'last_location_lat';
  static const String _lonKey = 'last_location_lon';
  static const String _addressKey = 'last_location_address';
  static const String _updatedAtKey = 'last_location_updated_at';

  Future<CachedLocation?> getLastKnown() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lon = prefs.getDouble(_lonKey);
    if (lat == null || lon == null) return null;

    final address = prefs.getString(_addressKey);
    final updatedAtMillis = prefs.getInt(_updatedAtKey);
    final updatedAt = updatedAtMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(updatedAtMillis)
        : null;

    return CachedLocation(
      latitude: lat,
      longitude: lon,
      address: address,
      updatedAt: updatedAt,
    );
  }

  Future<void> save({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, latitude);
    await prefs.setDouble(_lonKey, longitude);
    if (address != null && address.isNotEmpty) {
      await prefs.setString(_addressKey, address);
    }
    await prefs.setInt(
      _updatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
