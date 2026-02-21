import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sevenouti/utils/location_cache.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String?> reverseGeocode(
    double latitude,
    double longitude, {
    String? languageCode,
  }) async {
    final normalizedLang = languageCode?.trim().toLowerCase();
    final localeCandidates = _localeCandidates(normalizedLang);

    for (final locale in localeCandidates) {
      try {
        final placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
          localeIdentifier: locale,
        );
        final address = _composeAddress(placemarks);
        if (address == null) continue;

        // If Arabic is requested, prefer an actual Arabic-script result.
        if (normalizedLang == 'ar' && !_containsArabic(address)) {
          continue;
        }
        return _normalizeAddress(address, normalizedLang);
      } catch (_) {
        // Try next locale candidate.
      }
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      final address = _composeAddress(placemarks);
      if (address == null) return null;
      return _normalizeAddress(address, normalizedLang);
    } catch (_) {
      return null;
    }
  }

  Future<CachedLocation?> getCachedLocation() {
    return LocationCache().getLastKnown();
  }

  Future<CachedLocation?> fetchAndCacheCurrentLocation({
    String? languageCode,
  }) async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final address = await reverseGeocode(
      position.latitude,
      position.longitude,
      languageCode: languageCode,
    );

    await LocationCache().save(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );

    return CachedLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      updatedAt: DateTime.now(),
    );
  }

  List<String> _localeCandidates(String? languageCode) {
    switch (languageCode) {
      case 'ar':
        return const ['ar_MA', 'ar', 'ar_SA', 'fr_MA', 'fr', 'en'];
      case 'fr':
        return const ['fr_MA', 'fr', 'en'];
      case 'en':
        return const ['en', 'fr_MA', 'fr'];
      default:
        return const ['fr_MA', 'fr', 'en'];
    }
  }

  String? _composeAddress(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return null;
    final place = placemarks.first;
    final parts = <String>[
      if (place.street != null && place.street!.isNotEmpty) place.street!,
      if (place.subLocality != null && place.subLocality!.isNotEmpty)
        place.subLocality!,
      if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
      if (place.administrativeArea != null &&
          place.administrativeArea!.isNotEmpty)
        place.administrativeArea!,
      if (place.country != null && place.country!.isNotEmpty) place.country!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  bool _containsArabic(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }

  String _normalizeAddress(String address, String? languageCode) {
    if (languageCode == 'ar') {
      return address.replaceAll(',', '،');
    }
    return address;
  }
}
