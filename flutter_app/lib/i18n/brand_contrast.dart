import 'dart:math' as math;
import 'dart:ui';

/// Phase 13e — WCAG 2.1 contrast math for the GlobeID brand palette.
///
/// The brand chrome is deeply gold on deeply OLED. The contrast
/// math has to actually compute the ratio — gut feel about
/// "obviously readable" is unreliable for thin foil hairlines on
/// near-black substrates. This file ships the math + a WCAG band
/// classifier so every brand-vs-substrate pair can be audited
/// objectively.
///
/// References:
///   * https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum
///   * https://www.w3.org/WAI/GL/wiki/Contrast_(Minimum)
class BrandContrast {
  BrandContrast._();

  /// Relative luminance of [color] per WCAG 2.1 (linearized RGB).
  /// Range: 0.0 (pure black) → 1.0 (pure white).
  static double relativeLuminance(Color color) {
    // ignore: deprecated_member_use
    double linearize(double channel) {
      final c = channel / 255.0;
      return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    // ignore: deprecated_member_use
    final r = linearize(color.red.toDouble());
    // ignore: deprecated_member_use
    final g = linearize(color.green.toDouble());
    // ignore: deprecated_member_use
    final b = linearize(color.blue.toDouble());
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Contrast ratio between two colors per WCAG 2.1 — `(L1 + 0.05)
  /// / (L2 + 0.05)`, where L1 is the lighter luminance. Returns a
  /// ratio in `[1.0, 21.0]`.
  static double ratio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Classify a contrast ratio into a WCAG band.
  ///
  /// Thresholds:
  ///   * `aa_normal`     ≥ 4.5  — AA normal text
  ///   * `aa_large`      ≥ 3.0  — AA large text (≥ 18 pt / 14 pt bold) + non-text
  ///   * `aaa_normal`    ≥ 7.0  — AAA normal text
  ///   * `aaa_large`     ≥ 4.5  — AAA large text
  ///   * Anything < 3.0 fails.
  static ContrastBand bandFor(double ratio) {
    if (ratio >= 7.0) return ContrastBand.aaaNormal;
    if (ratio >= 4.5) return ContrastBand.aaNormal;
    if (ratio >= 3.0) return ContrastBand.aaLarge;
    return ContrastBand.fail;
  }

  /// Composite a translucent foreground over an opaque background
  /// and return the resulting opaque color. Useful when measuring
  /// the visual contrast of a translucent hairline / overlay
  /// against its substrate (the WCAG math assumes opaque colors).
  static Color compositeOver(Color foreground, Color opaqueBackground) {
    // ignore: deprecated_member_use
    final a = foreground.alpha / 255.0;
    // ignore: deprecated_member_use
    final r = foreground.red * a + opaqueBackground.red * (1 - a);
    // ignore: deprecated_member_use
    final g = foreground.green * a + opaqueBackground.green * (1 - a);
    // ignore: deprecated_member_use
    final b = foreground.blue * a + opaqueBackground.blue * (1 - a);
    return Color.fromARGB(255, r.round(), g.round(), b.round());
  }

  /// Effective contrast ratio when [foreground] is translucent —
  /// composites onto [opaqueBackground] before measuring.
  static double effectiveRatio(Color foreground, Color opaqueBackground) =>
      ratio(compositeOver(foreground, opaqueBackground), opaqueBackground);

  /// True if the pair passes WCAG AA for normal text.
  static bool passesAaNormal(Color a, Color b) => ratio(a, b) >= 4.5;

  /// True if the pair passes WCAG AA for large text or non-text
  /// (e.g. icons, hairlines).
  static bool passesAaLarge(Color a, Color b) => ratio(a, b) >= 3.0;

  /// True if the pair passes WCAG AAA for normal text.
  static bool passesAaaNormal(Color a, Color b) => ratio(a, b) >= 7.0;
}

enum ContrastBand {
  /// ≥ 7.0 — best-in-class. Passes AAA for normal text.
  aaaNormal,

  /// ≥ 4.5 — passes AA normal text + AAA large text.
  aaNormal,

  /// ≥ 3.0 — passes AA for large text / non-text only.
  aaLarge,

  /// < 3.0 — fails WCAG.
  fail,
}

extension ContrastBandLabels on ContrastBand {
  String get label {
    switch (this) {
      case ContrastBand.aaaNormal:
        return 'AAA';
      case ContrastBand.aaNormal:
        return 'AA';
      case ContrastBand.aaLarge:
        return 'AA · LARGE';
      case ContrastBand.fail:
        return 'FAIL';
    }
  }

  String get note {
    switch (this) {
      case ContrastBand.aaaNormal:
        return 'Passes AAA normal text';
      case ContrastBand.aaNormal:
        return 'Passes AA normal text';
      case ContrastBand.aaLarge:
        return 'Passes AA for large text / non-text only';
      case ContrastBand.fail:
        return 'Fails WCAG — re-tune the tone';
    }
  }
}
