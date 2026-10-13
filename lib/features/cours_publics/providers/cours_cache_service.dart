import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CoursCacheService {
  static const String _keyCours = 'cours_gratuits_cache';
  static const String _keyTimestamp = 'cours_gratuits_cache_ts';
  static const Duration _ttl = Duration(hours: 24);

  Future<bool> hasValidCache() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_keyTimestamp);
    if (ts == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts),
    );
    return age < _ttl;
  }

  Future<List<Map<String, dynamic>>?> getCachedCours() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCours);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      await clearCache();
      return null;
    }
  }

  Future<void> saveCours(List<Map<String, dynamic>> cours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCours, jsonEncode(cours));
    await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCours);
    await prefs.remove(_keyTimestamp);
  }
}
