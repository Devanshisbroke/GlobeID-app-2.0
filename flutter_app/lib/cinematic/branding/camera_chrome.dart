import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Five canonical scan modes the GlobeID camera reads as.
///
/// Each mode keys its own aim region, chip copy, scan-line cadence
/// and accent tone so the entire UI shifts when the operator picks
/// the credential type they're scanning.
enum ScanMode {
  passport,
  face,
  qr,
  nfc,
  document,
}

/// Per-[ScanMode] manifest — chip copy, aim shape, and accent tone.
class ScanModeSpec {
  const ScanModeSpec({
    required this.eyebrow,
    required this.label,
    required this.aim,
    required this.tone,
    required this.scanCadence,
  });

  /// Mono-cap eyebrow above the chip body (e.g. `MODE`).
  final String eyebrow;

  /// Mono-cap chip body (e.g. `SCANNING · PASSPORT`).
  final String label;

  /// Aim region shape — `aspect ∈ (0, 1]` controls the cutout's
  /// vertical proportion (1.0 = square, 0.625 = passport).
  final ScanAim aim;

  /// Foil-tone accent that colours brackets, scan line, chip, and
  /// watermark hairline.
  final Color tone;

  /// Cadence of the scan-line sweep. Slower for high-precision modes
  /// (passport MRZ), faster for low-effort modes (QR).
  final Duration scanCadence;

  static const passport = ScanModeSpec(
    eyebrow: 'MODE',
    label: 'SCANNING · PASSPORT',
    aim: ScanAim(aspect: 0.62, widthFraction: 0.84),
    tone: Color(0xFFD4AF37),
    scanCadence: Duration(milliseconds: 2200),
  );

  static const face = ScanModeSpec(
    eyebrow: 'MODE',
    label: 'SCANNING · FACE',
    aim: ScanAim(aspect: 1.18, widthFraction: 0.58, oval: true),
    tone: Color(0xFFE9C75D),
    scanCadence: Duration(milliseconds: 1800),
  );

  static const qr = ScanModeSpec(
    eyebrow: 'MODE',
    label: 'SCANNING · QR · CODE',
    aim: ScanAim(aspect: 1.0, widthFraction: 0.62),
    tone: Color(0xFFC9A961),
    scanCadence: Duration(milliseconds: 1400),
  );

  static const nfc = ScanModeSpec(
    eyebrow: 'MODE',
    label: 'NFC · TAP · TO · READ',
    aim: ScanAim(aspect: 0.42, widthFraction: 0.74),
    tone: Color(0xFF6B8FB8),
    scanCadence: Duration(milliseconds: 2600),
  );

  static const document = ScanModeSpec(
    eyebrow: 'MODE',
    label: 'SCANNING · DOCUMENT',
    aim: ScanAim(aspect: 1.41, widthFraction: 0.78),
    tone: Color(0xFFE9C75D),
    scanCadence: Duration(milliseconds: 2000),
  );

  static ScanModeSpec of(ScanMode mode) {
    switch (mode) {
      case ScanMode.passport:
        return passport;
      case ScanMode.face:
        return face;
      case ScanMode.qr:
        return qr;
      case ScanMode.nfc:
        return nfc;
      case ScanMode.document:
        return document;
    }
  }
}

/// The aim region a [ScanMode] paints inside the viewfinder.
class ScanAim {
  const ScanAim({
    required this.aspect,
    required this.widthFraction,
    this.oval = false,
  });

  /// Height : width ratio.
  final double aspect;

  /// Fraction of the viewfinder width the aim region occupies.
  final double widthFraction;

  /// Oval (true) vs square-with-corner-brackets (false).
  final bool oval;
}

/// Computes the rect of the aim region inside a viewfinder.
///
/// Pure function — exposed so tests can verify the aim geometry
/// without driving the widget.
Rect computeAimRect(Size viewport, ScanAim aim) {
  final width = viewport.width * aim.widthFraction;
  final height = width * aim.aspect;
  final left = (viewport.width - width) / 2;
  final top = (viewport.height - height) / 2 - viewport.height * 0.04;
  return Rect.fromLTWH(left, top, width, height);
}

/// GlobeID camera chrome — gold corner brackets, mono-cap mode chip,
/// animated scan line, watermark.
///
/// Wraps any [child] (typically a live camera preview). The chrome
/// is brand-consistent across every scan mode (passport, face, QR,
/// NFC, document), driven by the [mode] parameter. Tone, aim shape,
/// chip copy, and scan-line cadence all flex per mode.
///
/// Layered top-to-bottom:
///   1. [child] — caller's viewfinder
///   2. Dim scrim outside the aim region (radial vignette + 38 %
///      black scrim everywhere except the aim cutout)
///   3. Aim cutout — square corner brackets or oval rim
///   4. Animated scan line — gold hairline that sweeps the aim
///   5. Mono-cap mode chip at the top
///   6. GLOBE · ID watermark at the bottom-right
class CameraChrome extends StatefulWidget {
  const CameraChrome({
    super.key,
    required this.mode,
    required this.child,
    this.caseNumber = 'N° SCAN-OPEN',
  });

  /// Active scan mode — drives chrome appearance + cadence.
  final ScanMode mode;

  /// The viewfinder (live camera preview, or a placeholder).
  final Widget child;

  /// Optional GLOBE · ID watermark case number (mono-cap, bottom-right).
  final String caseNumber;

  @override
  State<CameraChrome> createState() => _CameraChromeState();
}

class _CameraChromeState extends State<CameraChrome>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final spec = ScanModeSpec.of(widget.mode);
    _ctrl = AnimationController(
      vsync: this,
      duration: spec.scanCadence,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CameraChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      final spec = ScanModeSpec.of(widget.mode);
      _ctrl.duration = spec.scanCadence;
      _ctrl
        ..stop()
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = ScanModeSpec.of(widget.mode);
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        // Vignette scrim — gives the aim a "spotlight" feel.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.05),
                  radius: 1.4,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Aim + scan line + brackets are painted in one CustomPaint
        // so they always align pixel-perfect with the same Rect.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _AimPainter(
                  spec: spec,
                  progress: _ctrl.value,
                ),
              ),
            ),
          ),
        ),
        // Top chip — mono-cap mode label.
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Center(child: _ModeChip(spec: spec)),
        ),
        // Bottom-right watermark — same chrome as AppleSheet.
        Positioned(
          right: 20,
          bottom: 22,
          child: _Watermark(
            tone: spec.tone,
            caseNumber: widget.caseNumber,
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.spec});
  final ScanModeSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF050505).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: spec.tone.withValues(alpha: 0.62),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: spec.tone.withValues(alpha: 0.22),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: spec.tone,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: spec.tone.withValues(alpha: 0.85),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            spec.label,
            style: TextStyle(
              color: spec.tone,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _Watermark extends StatelessWidget {
  const _Watermark({required this.tone, required this.caseNumber});
  final Color tone;
  final String caseNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 88,
          height: 0.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                tone.withValues(alpha: 0.42),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'GLOBE · ID',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.22),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 1),
        Text(
          caseNumber,
          style: TextStyle(
            color: tone.withValues(alpha: 0.46),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _AimPainter extends CustomPainter {
  _AimPainter({required this.spec, required this.progress});
  final ScanModeSpec spec;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = computeAimRect(size, spec.aim);
    final tone = spec.tone;

    if (spec.aim.oval) {
      // Face mode — oval rim + scan line.
      final rim = Paint()
        ..color = tone.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawOval(rect, rim);
      // Subtle inner rim at 92 % for a "manufactured optic" feel.
      final inner = Paint()
        ..color = tone.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      canvas.drawOval(rect.deflate(rect.width * 0.04), inner);
    } else {
      // Corner brackets — 4 L-shapes at each corner of the rect.
      _drawBrackets(canvas, rect, tone);
    }

    // Animated horizontal scan line. progress ∈ [0..1], oscillates
    // top→bottom→top because controller uses repeat(reverse: true).
    final scanY = rect.top + rect.height * progress;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          tone.withValues(alpha: 0.0),
          tone.withValues(alpha: 0.78),
          tone.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(
        rect.left,
        scanY - 1,
        rect.right,
        scanY + 1,
      ))
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(rect.left, scanY),
      Offset(rect.right, scanY),
      linePaint,
    );

    // Soft glow halo around the line.
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          tone.withValues(alpha: 0.34),
          tone.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(rect.center.dx, scanY),
        width: rect.width,
        height: 22,
      ))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(rect.center.dx, scanY),
        width: rect.width,
        height: 12,
      ),
      halo,
    );
  }

  void _drawBrackets(Canvas canvas, Rect rect, Color tone) {
    final paint = Paint()
      ..color = tone.withValues(alpha: 0.86)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final bracketLen = math.min(rect.width, rect.height) * 0.12;
    final corners = [
      // top-left
      [rect.topLeft, Offset(rect.left + bracketLen, rect.top),
        rect.topLeft, Offset(rect.left, rect.top + bracketLen)],
      // top-right
      [rect.topRight, Offset(rect.right - bracketLen, rect.top),
        rect.topRight, Offset(rect.right, rect.top + bracketLen)],
      // bottom-left
      [rect.bottomLeft, Offset(rect.left + bracketLen, rect.bottom),
        rect.bottomLeft, Offset(rect.left, rect.bottom - bracketLen)],
      // bottom-right
      [rect.bottomRight, Offset(rect.right - bracketLen, rect.bottom),
        rect.bottomRight, Offset(rect.right, rect.bottom - bracketLen)],
    ];
    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[2], c[3], paint);
    }
  }

  @override
  bool shouldRepaint(_AimPainter old) =>
      old.progress != progress || old.spec != spec;
}
