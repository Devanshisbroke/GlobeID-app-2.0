import 'package:flutter/material.dart';

/// Phase 13c — Dynamic Type / brand-aware text scaling.
///
/// Body copy must scale with the user's accessibility settings —
/// somebody using 200% Dynamic Type needs the labels to be readable.
/// But brand chrome (mono-cap watermarks, foil hairlines, case
/// numbers) is a *trademark*; if it scales linearly with body copy
/// the layout fractures (8 pt watermark at 200% = 16 pt watermark,
/// which overwhelms the credential face). This file ships the
/// primitives that draw the line between *scaling* text and *frozen*
/// chrome.
///
/// Policy:
///   * BODY (display / headline / title / body / label) — full
///     respect for MediaQuery.textScaler. Scales linearly with the
///     user's setting.
///   * CHROME (mono-cap, watermark, case number, eyebrows) — caps
///     out at 1.35× the system default. Above that, the trademark
///     reads identically regardless of scale.
///   * CREDENTIAL · NUMBER (trust score, queue %, balance) — also
///     capped at 1.20× because these compete with the body copy
///     for visual weight and overcompetition breaks the hierarchy.
class BrandTextScale {
  BrandTextScale._();

  /// Brand chrome cap — mono-cap labels stop scaling beyond this
  /// multiple of the system default. Tuned so 13c lab preview at
  /// 200% still keeps the watermark readable without dominating.
  static const double chromeCap = 1.35;

  /// Credential number cap — big stat numbers (trust score, queue
  /// %, balance) don't outrun the body copy.
  static const double credentialCap = 1.20;

  /// Body text is unrestricted — full respect for accessibility.
  static double clampForBody(double systemScale) => systemScale;

  /// Chrome text is capped at [chromeCap].
  static double clampForChrome(double systemScale) =>
      systemScale.clamp(1.0, chromeCap);

  /// Credential numbers are capped at [credentialCap].
  static double clampForCredential(double systemScale) =>
      systemScale.clamp(1.0, credentialCap);

  /// Resolves a brand-aware [TextScaler] for the given role from the
  /// current [MediaQuery].
  static TextScaler scalerOf(BuildContext context, BrandTextRole role) {
    final base = MediaQuery.textScalerOf(context);
    switch (role) {
      case BrandTextRole.body:
        return base;
      case BrandTextRole.chrome:
        return _ClampedTextScaler(base: base, cap: chromeCap);
      case BrandTextRole.credential:
        return _ClampedTextScaler(base: base, cap: credentialCap);
    }
  }
}

/// Role of a text element with respect to the GlobeID type policy.
enum BrandTextRole { body, chrome, credential }

/// A [TextScaler] that delegates to [base] until the scaled font
/// size would exceed [cap]× the input — then it linearly clamps.
class _ClampedTextScaler extends TextScaler {
  const _ClampedTextScaler({required this.base, required this.cap});
  final TextScaler base;
  final double cap;

  @override
  double scale(double fontSize) {
    final scaled = base.scale(fontSize);
    final maxAllowed = fontSize * cap;
    return scaled > maxAllowed ? maxAllowed : scaled;
  }

  @override
  // ignore: deprecated_member_use, non_constant_identifier_names
  double get textScaleFactor {
    // ignore: deprecated_member_use
    final raw = base.textScaleFactor;
    return raw > cap ? cap : raw;
  }

  @override
  bool operator ==(Object other) =>
      other is _ClampedTextScaler && other.base == base && other.cap == cap;

  @override
  int get hashCode => Object.hash(base, cap);
}

/// Wrap brand chrome (watermark, mono-cap eyebrow, case N°) in this
/// widget — the subtree clamps its text scaling to the chrome cap.
class ChromeTextScale extends StatelessWidget {
  const ChromeTextScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: BrandTextScale.scalerOf(context, BrandTextRole.chrome),
      ),
      child: child,
    );
  }
}

/// Wrap credential statistic numbers (trust score, queue %, balance)
/// in this widget — the subtree clamps to [BrandTextScale.credentialCap].
class CredentialTextScale extends StatelessWidget {
  const CredentialTextScale({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: BrandTextScale.scalerOf(context, BrandTextRole.credential),
      ),
      child: child,
    );
  }
}
