import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../core/storage/preferences.dart';

/// Mirrors `lib/themePrefs.ts` from the React app.
@immutable
class ThemePrefs {
  const ThemePrefs({
    this.accent = 'azure',
    this.themeMode = ThemeMode.system,
    this.highContrast = false,
    this.reduceTransparency = false,
    this.density = AppDensity.comfortable,
    this.autoTheme = true,
    this.quietHours = false,
    this.quietStart = 23,
    this.quietEnd = 7,
  });

  final String accent;
  final ThemeMode themeMode;
  final bool highContrast;
  final bool reduceTransparency;
  final AppDensity density;
  final bool autoTheme;
  final bool quietHours;
  final int quietStart;
  final int quietEnd;

  ThemePrefs copyWith({
    String? accent,
    ThemeMode? themeMode,
    bool? highContrast,
    bool? reduceTransparency,
    AppDensity? density,
    bool? autoTheme,
    bool? quietHours,
    int? quietStart,
    int? quietEnd,
  }) =>
      ThemePrefs(
        accent: accent ?? this.accent,
        themeMode: themeMode ?? this.themeMode,
        highContrast: highContrast ?? this.highContrast,
        reduceTransparency: reduceTransparency ?? this.reduceTransparency,
        density: density ?? this.density,
        autoTheme: autoTheme ?? this.autoTheme,
        quietHours: quietHours ?? this.quietHours,
        quietStart: quietStart ?? this.quietStart,
        quietEnd: quietEnd ?? this.quietEnd,
      );

  Map<String, dynamic> toJson() => {
        'accent': accent,
        'themeMode': themeMode.name,
        'highContrast': highContrast,
        'reduceTransparency': reduceTransparency,
        'density': density.name,
        'autoTheme': autoTheme,
        'quietHours': quietHours,
        'quietStart': quietStart,
        'quietEnd': quietEnd,
      };

  static ThemePrefs fromJson(Map<String, dynamic> json) => ThemePrefs(
        accent: (json['accent'] as String?) ?? 'azure',
        themeMode: ThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => ThemeMode.system,
        ),
        highContrast: (json['highContrast'] as bool?) ?? false,
        reduceTransparency: (json['reduceTransparency'] as bool?) ?? false,
        density: AppDensity.values.firstWhere(
          (d) => d.name == json['density'],
          orElse: () => AppDensity.comfortable,
        ),
        autoTheme: (json['autoTheme'] as bool?) ?? true,
        quietHours: (json['quietHours'] as bool?) ?? false,
        quietStart: (json['quietStart'] as int?) ?? 23,
        quietEnd: (json['quietEnd'] as int?) ?? 7,
      );
}

class ThemePrefsController extends Notifier<ThemePrefs> {
  static const _key = 'themePrefs';

  @override
  ThemePrefs build() {
    final json = Preferences.instance.readJson(_key);
    if (json != null) return ThemePrefs.fromJson(json);
    return const ThemePrefs();
  }

  Future<void> _save() => Preferences.instance.writeJson(_key, state.toJson());

  void setAccent(String accent) {
    state = state.copyWith(accent: accent);
    _save();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void toggleHighContrast() {
    state = state.copyWith(highContrast: !state.highContrast);
    _save();
  }

  void toggleReduceTransparency() {
    state = state.copyWith(reduceTransparency: !state.reduceTransparency);
    _save();
  }

  void setDensity(AppDensity density) {
    state = state.copyWith(density: density);
    _save();
  }

  void toggleAutoTheme() {
    state = state.copyWith(autoTheme: !state.autoTheme);
    _save();
  }

  void setQuietHours({bool? enabled, int? start, int? end}) {
    state = state.copyWith(
      quietHours: enabled ?? state.quietHours,
      quietStart: start ?? state.quietStart,
      quietEnd: end ?? state.quietEnd,
    );
    _save();
  }
}

final themePrefsProvider = NotifierProvider<ThemePrefsController, ThemePrefs>(
    ThemePrefsController.new);
