import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class InstallationService {
  static const _storageKey = 'installation_id';
  static String? _cachedInstallationId;

  static Future<String> getInstallationId() async {
    final cached = _cachedInstallationId;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_storageKey)?.trim();
    if (storedId != null && storedId.isNotEmpty) {
      _cachedInstallationId = storedId;
      return storedId;
    }

    final generatedId = _generateUuidV4();
    await prefs.setString(_storageKey, generatedId);
    _cachedInstallationId = generatedId;
    return generatedId;
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final buffer = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
      if (i == 3 || i == 5 || i == 7 || i == 9) {
        buffer.write('-');
      }
    }

    return buffer.toString();
  }
}
