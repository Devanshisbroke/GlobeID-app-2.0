import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One of GlobeID's three identity-signet variants.
///
/// The signet is the brand mark that stands in wherever the OS would
/// render the app icon — Settings header, vault corner, lock-screen
/// preview, watch complication. Three variants:
///
/// * [standard] — Foil-gold seal on OLED. The flagship.
/// * [atelier] — Stealth-OLED, hairline gold rim, gold monogram.
///   Reads invisible on a dark wallpaper; the discrete option.
/// * [pilot] — Deep-navy seal with champagne monogram. The brand
///   variant for the pilot / corporate / aviation tier.
enum SignetVariant {
  standard,
  atelier,
  pilot,
}

/// Reference palette per signet variant. Tone is the dominant brand
/// accent, ink is the centred monogram colour, substrate is the seal
/// fill colour.
class SignetPalette {
  const SignetPalette({
    required this.tone,
    required this.ink,
    required this.substrate,
    required this.name,
  });

  final Color tone;
  final Color ink;
  final Color substrate;
  final String name;

  static const standard = SignetPalette(
    tone: Color(0xFFD4AF37),
    ink: Color(0xFF1A1207),
    substrate: Color(0xFF050505),
    name: 'STANDARD · FOIL',
  );

  static const atelier = SignetPalette(
    tone: Color(0xFFE9C75D),
    ink: Color(0xFFE9C75D),
    substrate: Color(0xFF050505),
    name: 'ATELIER · STEALTH',
  );

  static const pilot = SignetPalette(
    tone: Color(0xFFC9A961),
    ink: Color(0xFFEAD79B),
    substrate: Color(0xFF0A1426),
    name: 'PILOT · NAVY',
  );

  static SignetPalette of(SignetVariant variant) {
    switch (variant) {
      case SignetVariant.standard:
        return standard;
      case SignetVariant.atelier:
        return atelier;
      case SignetVariant.pilot:
        return pilot;
    }
  }
}

/// GlobeID identity signet rendered at any [size].
///
/// Square card with [borderRadius] = `size * 0.22` (matches the
/// iOS app-icon corner radius family). Inside the card a circular
/// seal carries the brand monogram. Three variants codified in
/// [SignetVariant]:
///
/// * [SignetVariant.standard] — full foil-gold seal on OLED
/// * [SignetVariant.atelier] — stealth OLED with hairline rim only
/// * [SignetVariant.pilot] — deep-navy substrate with foil seal
///
/// Used by:
/// * Lab gallery [IdentitySignetScreen]
/// * Future Phase 12 surfaces (settings header, vault corner,
///   watch complication, share sheet receipts)
class IdentitySignet extends StatelessWidget {
  const IdentitySignet({
    super.key,
    required this.variant,
    this.size = 96,
    this.monogram = 'G·ID',
  });

  final SignetVariant variant;
  final double size;
  final String monogram;

  @override
  Widget build(BuildContext context) {
    final palette = SignetPalette.of(variant);
    final radius = size * 0.22;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Substrate square (the icon background).
          Container(
            decoration: BoxDecoration(
              color: palette.substrate,
              borderRadius: BorderRadius.circular(radius),
              gradient: variant == SignetVariant.pilot
                  ? const RadialGradient(
                      center: Alignment(-0.4, -0.4),
                      radius: 1.1,
                      colors: [Color(0xFF0F1B33), Color(0xFF050912)],
                    )
                  : null,
              border: Border.all(
                color: palette.tone.withValues(alpha: 0.32),
                width: 0.6,
              ),
            ),
          ),
          // The seal — different chrome per variant.
          Center(
            child: CustomPaint(
              size: Size.square(size * 0.72),
              painter: _SignetPainter(
                variant: variant,
                palette: palette,
              ),
            ),
          ),
          // Centre monogram.
          Center(
            child: Text(
              monogram,
              style: TextStyle(
                color: variant == SignetVariant.atelier
                    ? palette.tone.withValues(alpha: 0.92)
                    : palette.ink,
                fontSize: size * 0.20,
                fontWeight: FontWeight.w900,
                letterSpacing: size * 0.012,
              ),
            ),
          ),
          // Foil hairline at the top-left (manufacturer touch).
          Positioned(
            top: size * 0.08,
            left: size * 0.08,
            child: Container(
              width: size * 0.12,
              height: 0.6,
              color: palette.tone.withValues(alpha: 0.46),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignetPainter extends CustomPainter {
  _SignetPainter({required this.variant, required this.palette});
  final SignetVariant variant;
  final SignetPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;
    final tone = palette.tone;

    switch (variant) {
      case SignetVariant.standard:
        _paintFilled(canvas, center, r, tone);
        break;
      case SignetVariant.atelier:
        _paintStealth(canvas, center, r, tone);
        break;
      case SignetVariant.pilot:
        _paintFilled(canvas, center, r, tone, deep: true);
        break;
    }
  }

  void _paintFilled(
    Canvas canvas,
    Offset center,
    double r,
    Color tone, {
    bool deep = false,
  }) {
    // Filled gold disc with radial gradient.
    final disc = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.25),
        radius: 0.85,
        colors: [
          tone.withValues(alpha: 0.96),
          HSLColor.fromColor(tone)
              .withLightness(deep ? 0.32 : 0.42)
              .toColor()
              .withValues(alpha: 0.94),
          HSLColor.fromColor(tone)
              .withLightness(deep ? 0.14 : 0.20)
              .toColor()
              .withValues(alpha: 0.96),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, disc);
    _paintRing(canvas, center, r, tone, alpha: 0.78);
    _paintNotches(canvas, center, r, tone, alpha: 0.62);
  }

  void _paintStealth(Canvas canvas, Offset center, double r, Color tone) {
    // Hairline gold outline only — atelier reads as a discreet
    // engraving on OLED black.
    final outline = Paint()
      ..color = tone.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, r, outline);
    _paintRing(canvas, center, r, tone, alpha: 0.46);
    _paintNotches(canvas, center, r, tone, alpha: 0.48);
  }

  void _paintRing(
    Canvas canvas,
    Offset center,
    double r,
    Color tone, {
    required double alpha,
  }) {
    final ring = Paint()
      ..color = HSLColor.fromColor(tone)
          .withLightness(0.24)
          .toColor()
          .withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, r * 0.78, ring);
  }

  void _paintNotches(
    Canvas canvas,
    Offset center,
    double r,
    Color tone, {
    required double alpha,
  }) {
    final notch = Paint()
      ..color = HSLColor.fromColor(tone)
          .withLightness(0.24)
          .toColor()
          .withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi - math.pi / 2;
      final p = center +
          Offset(math.cos(angle) * r * 0.88, math.sin(angle) * r * 0.88);
      canvas.drawCircle(p, math.max(1.0, r * 0.025), notch);
    }
  }

  @override
  bool shouldRepaint(_SignetPainter old) =>
      old.variant != variant || old.palette.tone != palette.tone;
}
