import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sevenouti/client/models/hanout_model.dart';

class HanoutCache {
  static const String _hanoutsKey = 'cached_hanouts';
  static const String _updatedAtKey = 'cached_hanouts_updated_at';

  Future<List<HanoutModel>?> getCachedHanouts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hanoutsKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((json) => HanoutModel.fromJson(json))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveHanouts(List<HanoutModel> hanouts) async {
    final prefs = await SharedPreferences.getInstance();
    final data = hanouts.map((h) => h.toJson()).toList();
    await prefs.setString(_hanoutsKey, jsonEncode(data));
    await prefs.setString(_updatedAtKey, DateTime.now().toIso8601String());
  }
}
