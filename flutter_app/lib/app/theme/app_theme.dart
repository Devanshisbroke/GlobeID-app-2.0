import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/settings/theme_prefs_provider.dart';
import 'app_tokens.dart';

/// Builds [ThemeData] from current [ThemePrefs]. Registers a custom
/// [GlassExtension] so any widget can read frosted-surface tokens.
class AppTheme {
  AppTheme._();

  static ThemeData light(ThemePrefs prefs) =>
      _build(brightness: Brightness.light, prefs: prefs);

  static ThemeData dark(ThemePrefs prefs) =>
      _build(brightness: Brightness.dark, prefs: prefs);

  static ThemeData _build({
    required Brightness brightness,
    required ThemePrefs prefs,
  }) {
    final accent = AppTokens.accentByName(prefs.accent).primary;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      secondary: AppTokens.accentByName(prefs.accent).glow,
    );

    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF8FAFC);
    final card = isDark
        ? const Color(0xFF111827).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.78);

    final density = prefs.density;
    final base = density.scale;

    final textTheme = _typography(isDark, base, prefs.highContrast);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.iconButtonSize),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.iconButtonSize),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppTokens.iconButtonSize),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space3,
        ),
      ),
      extensions: [
        GlassExtension(
          surface: card,
          highContrast: prefs.highContrast,
          reduceTransparency: prefs.reduceTransparency,
        ),
      ],
    );
  }

  static TextTheme _typography(bool isDark, double scale, bool highContrast) {
    final body = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted =
        isDark ? Colors.white.withValues(alpha: 0.66) : const Color(0xFF475569);
    Color colored(Color c) => highContrast ? body : c;

    TextStyle s({
      required double size,
      double height = 1.4,
      FontWeight weight = FontWeight.w400,
      double letter = 0,
      Color? color,
    }) =>
        TextStyle(
          fontFamily: 'Inter',
          fontSize: size * scale,
          height: height,
          fontWeight: weight,
          letterSpacing: letter,
          color: colored(color ?? body),
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return TextTheme(
      displayLarge:
          s(size: 56, height: 1.05, weight: FontWeight.w700, letter: -1.2),
      displayMedium:
          s(size: 44, height: 1.08, weight: FontWeight.w700, letter: -0.8),
      displaySmall:
          s(size: 34, height: 1.1, weight: FontWeight.w700, letter: -0.5),
      headlineLarge:
          s(size: 28, height: 1.18, weight: FontWeight.w600, letter: -0.3),
      headlineMedium: s(size: 24, height: 1.2, weight: FontWeight.w600),
      headlineSmall: s(size: 20, height: 1.25, weight: FontWeight.w600),
      titleLarge: s(size: 18, height: 1.35, weight: FontWeight.w600),
      titleMedium: s(size: 16, height: 1.4, weight: FontWeight.w500),
      titleSmall: s(size: 14, height: 1.45, weight: FontWeight.w500),
      bodyLarge: s(size: 16, height: 1.55),
      bodyMedium: s(size: 14, height: 1.5),
      bodySmall: s(size: 12.5, height: 1.45, color: muted),
      labelLarge: s(size: 14, height: 1.4, weight: FontWeight.w600),
      labelMedium:
          s(size: 12, height: 1.35, weight: FontWeight.w600, letter: 0.4),
      labelSmall: s(
          size: 11,
          height: 1.3,
          weight: FontWeight.w600,
          letter: 0.6,
          color: muted),
    );
  }
}

/// Theme extension carrying frosted-surface tokens.
class GlassExtension extends ThemeExtension<GlassExtension> {
  const GlassExtension({
    required this.surface,
    required this.highContrast,
    required this.reduceTransparency,
  });

  final Color surface;
  final bool highContrast;
  final bool reduceTransparency;

  @override
  GlassExtension copyWith({
    Color? surface,
    bool? highContrast,
    bool? reduceTransparency,
  }) =>
      GlassExtension(
        surface: surface ?? this.surface,
        highContrast: highContrast ?? this.highContrast,
        reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      );

  @override
  GlassExtension lerp(ThemeExtension<GlassExtension>? other, double t) {
    if (other is! GlassExtension) return this;
    return GlassExtension(
      surface: Color.lerp(surface, other.surface, t)!,
      highContrast: t < 0.5 ? highContrast : other.highContrast,
      reduceTransparency:
          t < 0.5 ? reduceTransparency : other.reduceTransparency,
    );
  }
}
