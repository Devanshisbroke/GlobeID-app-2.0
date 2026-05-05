import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around [SharedPreferences] that mimics the
/// `globeid:` localStorage namespace used by Zustand `persist` in the
/// React app. Each store gets its own JSON-encoded blob keyed under
/// `globeid:<store-name>`.
class Preferences {
  Preferences(this._prefs);

  final SharedPreferences _prefs;

  static Preferences? _instance;

  static Preferences get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
          'Preferences not initialised. Call AppBoot.bootstrap().');
    }
    return i;
  }

  static set instance(Preferences value) => _instance = value;

  static const String _prefix = 'globeid:';

  String _key(String name) => '$_prefix$name';

  Map<String, dynamic>? readJson(String name) {
    final raw = _prefs.getString(_key(name));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String name, Map<String, dynamic> value) async {
    await _prefs.setString(_key(name), jsonEncode(value));
  }

  String? readString(String name) => _prefs.getString(_key(name));

  Future<void> writeString(String name, String value) =>
      _prefs.setString(_key(name), value);

  Future<void> remove(String name) => _prefs.remove(_key(name));

  /// Used by sign-out to wipe everything in the GlobeID namespace.
  Future<void> wipe() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
