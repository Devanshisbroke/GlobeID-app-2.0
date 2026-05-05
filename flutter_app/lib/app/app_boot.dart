import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/preferences.dart';

/// One-shot bootstrap: open SharedPreferences boxes, prime caches.
///
/// Mirrors the React app's `applyThemePrefs()` + Zustand `persist` rehydration
/// step. Riverpod providers handle their own lazy hydration thereafter.
class AppBoot {
  AppBoot._();

  static Future<void> bootstrap() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    Preferences.instance = Preferences(prefs);
  }
}
