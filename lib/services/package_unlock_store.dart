import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PackageUnlockStore {
  PackageUnlockStore({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const _key = 'package_unlocks_v1';
  static const unlockDuration = Duration(hours: 24);
  final DateTime Function() _now;

  Future<Set<String>> activeIds() async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final raw = preferences.getString(_key);
      final decoded = raw == null ? <String, dynamic>{} : jsonDecode(raw);
      if (decoded is! Map) throw const FormatException();
      final now = _now().millisecondsSinceEpoch;
      final active = <String, int>{};
      for (final entry in decoded.entries) {
        if (entry.key is! String || entry.value is! int) {
          throw const FormatException();
        }
        if (entry.value > now) {
          active[entry.key] = entry.value;
        }
      }
      await preferences.setString(_key, jsonEncode(active));
      return active.keys.toSet();
    } catch (_) {
      await preferences.remove(_key);
      return {};
    }
  }

  Future<void> grant(String id) async {
    final preferences = await SharedPreferences.getInstance();
    await activeIds();
    final raw = preferences.getString(_key);
    final map = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map;
    map[id] = _now().add(unlockDuration).millisecondsSinceEpoch;
    await preferences.setString(_key, jsonEncode(map));
  }
}
