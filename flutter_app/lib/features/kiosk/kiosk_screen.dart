import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

/// Kiosk simulator v3 — multi-phase biometric verification.
///
/// Phases: idle → align → liveness → match → hmac → verified.
/// Each phase advances on a deterministic timer, exposes its own
/// status copy and indicator, and the final phase reveals a mocked
/// HMAC payload that mirrors the gate-side handshake the app does
/// against the boarding-pass server.
enum _KioskPhase { idle, align, liveness, match, hmac, verified, failed }

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});
  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5400),
  );
  _KioskPhase _phase = _KioskPhase.idle;
  Timer? _phaseTimer;
  String _payloadHash = '';
  String _hmacSig = '';
  final List<_AttemptLog> _log = [];

  static const _phases = <_KioskPhase>[
    _KioskPhase.align,
    _KioskPhase.liveness,
    _KioskPhase.match,
    _KioskPhase.hmac,
    _KioskPhase.verified,
  ];

  String _statusFor(_KioskPhase p) {
    switch (p) {
      case _KioskPhase.idle:
        return 'Stand in frame';
      case _KioskPhase.align:
        return 'Aligning your face…';
      case _KioskPhase.liveness:
        return 'Liveness check — blink please';
      case _KioskPhase.match:
        return 'Matching against your enrolment…';
      case _KioskPhase.hmac:
        return 'Signing payload (HMAC-SHA256)';
      case _KioskPhase.verified:
        return 'Verified · gate cleared';
      case _KioskPhase.failed:
        return 'Could not verify · try again';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _KioskPhase.align;
    });
    _ctrl.forward(from: 0);
    var i = 0;
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      if (!mounted) return;
      i++;
      if (i >= _phases.length) {
        t.cancel();
        // Final phase has been set last iteration.
        _logAttempt(success: true);
        HapticFeedback.heavyImpact();
        return;
      }
      setState(() {
        _phase = _phases[i];
        if (_phase == _KioskPhase.hmac) {
          _payloadHash = _mockHash(8);
          _hmacSig = _mockHash(16);
        }
      });
      // Per-phase haptic vocabulary — kiosk scan beeps on align /
      // liveness / match, then arrivalChime on verified.
      if (_phase == _KioskPhase.verified) {
        HapticPatterns.arrivalChime.play();
      } else {
        HapticPatterns.kioskScan.play();
      }
    });
  }

  void _logAttempt({required bool success}) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    setState(() {
      _log.insert(
        0,
        _AttemptLog(
          time: '$hh:$mm:$ss',
          success: success,
          payload: _payloadHash,
          signature: _hmacSig,
        ),
      );
      if (_log.length > 4) _log.removeLast();
    });
  }

  String _mockHash(int chars) {
    const alphabet = '0123456789abcdef';
    final rnd = math.Random(DateTime.now().millisecondsSinceEpoch);
    final b = StringBuffer();
    for (var i = 0; i < chars; i++) {
      b.write(alphabet[rnd.nextInt(alphabet.length)]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanning =
        _phase != _KioskPhase.idle && _phase != _KioskPhase.verified;
    final verified = _phase == _KioskPhase.verified;
    return PageScaffold(
      title: 'Kiosk simulator',
      subtitle: 'Practice biometric identity verification',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Departure-board status header ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space3,
              AppTokens.space5,
              AppTokens.space3,
            ),
            child: AnimatedAppearance(
              child: ContextualSurface(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GATE STATUS',
                              style:
                                  AirportFontStack.caption(context)),
                          const SizedBox(height: 4),
                          DepartureBoardText(
                            text: _phase.name.toUpperCase(),
                            style: AirportFontStack.board(
                              context,
                              size: 22,
                            ),
                            tone: verified
                                ? const Color(0xFF10B981)
                                : theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('CALLSIGN',
                            style: AirportFontStack.caption(context)),
                        const SizedBox(height: 4),
                        DepartureBoardText(
                          text: 'GID 001',
                          style: AirportFontStack.flightNumber(context,
                              size: 18),
                          tone: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Capture frame ─────────────────────────────────────
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.20),
                  theme.colorScheme.primary.withValues(alpha: 0.04),
                ],
              ),
              child: SizedBox(
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => SizedBox(
                        width: 240,
                        height: 240,
                        child: CustomPaint(
                          painter: _FaceFrame(
                            progress: _ctrl.value,
                            scanning: scanning,
                            verified: verified,
                            color: theme.colorScheme.primary,
                          ),
                          child: Center(
                            child: Icon(
                              verified
                                  ? Icons.verified_user_rounded
                                  : Icons.face_retouching_natural_rounded,
                              size: 96,
                              color: verified
                                  ? const Color(0xFF10B981)
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: Text(
                          _statusFor(_phase),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          // ── Phase pills ───────────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: _phases.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final p = _phases[i];
                  final reached = _phaseIndex(_phase) >= i ||
                      _phase == _KioskPhase.verified;
                  return _PhasePill(
                    label: _phaseLabel(p),
                    icon: _phaseIcon(p),
                    active: reached,
                    accent: theme.colorScheme.primary,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          // ── HMAC payload card (visible once we hit hmac/verified) ─
          AnimatedSwitcher(
            duration: AppTokens.durationMd,
            child: (_phase == _KioskPhase.hmac ||
                    _phase == _KioskPhase.verified)
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space3),
                    child: _HmacCard(
                      payload: _payloadHash,
                      signature: _hmacSig,
                      verified: verified,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // ── Start / Retry ────────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
              child: Pressable(
                scale: 0.97,
                onTap: scanning ? () {} : _start,
                child: AnimatedContainer(
                  duration: AppTokens.durationSm,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    gradient: LinearGradient(
                      colors: verified
                          ? const [Color(0xFF10B981), Color(0xFF059669)]
                          : [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary
                                  .withValues(alpha: 0.6),
                            ],
                    ),
                    boxShadow: AppTokens.shadowMd(
                      tint: verified
                          ? const Color(0xFF10B981)
                          : theme.colorScheme.primary,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (scanning)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        Icon(
                          verified
                              ? Icons.replay_rounded
                              : Icons.fingerprint_rounded,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        verified
                            ? 'Verify again'
                            : (scanning
                                ? 'Verifying…'
                                : 'Start verification'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── How it works ──────────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How this works',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stand 50–80cm from the camera, look straight ahead, '
                    'and stay still. The kiosk runs alignment → liveness → '
                    'face-match → HMAC-signed gate handshake against the '
                    'boarding-pass server. No biometrics leave the device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Attempt log ───────────────────────────────────────
          if (_log.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space5),
            AnimatedAppearance(
              child: Text(
                'RECENT ATTEMPTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            for (var i = 0; i < _log.length; i++)
              AnimatedAppearance(
                delay: Duration(milliseconds: 30 * i),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space2),
                  child: _AttemptRow(log: _log[i]),
                ),
              ),
          ],
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }

  int _phaseIndex(_KioskPhase p) {
    if (p == _KioskPhase.idle) return -1;
    if (p == _KioskPhase.failed) return -1;
    return _phases.indexOf(p);
  }

  String _phaseLabel(_KioskPhase p) {
    switch (p) {
      case _KioskPhase.align:
        return 'Align';
      case _KioskPhase.liveness:
        return 'Liveness';
      case _KioskPhase.match:
        return 'Match';
      case _KioskPhase.hmac:
        return 'HMAC';
      case _KioskPhase.verified:
        return 'Done';
      default:
        return '—';
    }
  }

  IconData _phaseIcon(_KioskPhase p) {
    switch (p) {
      case _KioskPhase.align:
        return Icons.center_focus_strong_rounded;
      case _KioskPhase.liveness:
        return Icons.remove_red_eye_rounded;
      case _KioskPhase.match:
        return Icons.face_retouching_natural_rounded;
      case _KioskPhase.hmac:
        return Icons.lock_rounded;
      case _KioskPhase.verified:
        return Icons.verified_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
  });
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppTokens.durationSm,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        gradient: active
            ? LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)])
            : null,
        color: active
            ? null
            : theme.colorScheme.onSurface.withValues(alpha: 0.06),
        border: Border.all(
          color: active
              ? Colors.transparent
              : theme.colorScheme.onSurface.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: active
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: active
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _HmacCard extends StatelessWidget {
  const _HmacCard({
    required this.payload,
    required this.signature,
    required this.verified,
  });
  final String payload;
  final String signature;
  final bool verified;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      gradient: LinearGradient(
        colors: verified
            ? const [Color(0x3310B981), Color(0x3306B6D4)]
            : [
                theme.colorScheme.primary.withValues(alpha: 0.18),
                theme.colorScheme.primary.withValues(alpha: 0.04),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verified
                          ? 'Gate handshake — VERIFIED'
                          : 'Gate handshake — SIGNING',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'HMAC-SHA256 · device-bound',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              if (verified)
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF10B981),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          _Mono(label: 'PAYLOAD', value: '0x$payload'),
          const SizedBox(height: 4),
          _Mono(label: 'SIG', value: '0x$signature'),
        ],
      ),
    );
  }
}

class _Mono extends StatelessWidget {
  const _Mono({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              color: Colors.black.withValues(alpha: 0.30),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttemptLog {
  const _AttemptLog({
    required this.time,
    required this.success,
    required this.payload,
    required this.signature,
  });
  final String time;
  final bool success;
  final String payload;
  final String signature;
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.log});
  final _AttemptLog log;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone =
        log.success ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              color: tone.withValues(alpha: 0.18),
            ),
            child: Icon(
              log.success
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: tone,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.success ? 'Verified' : 'Failed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${log.time} · sig 0x${log.signature.substring(0, 8)}…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceFrame extends CustomPainter {
  _FaceFrame({
    required this.progress,
    required this.scanning,
    required this.verified,
    required this.color,
  });
  final double progress;
  final bool scanning;
  final bool verified;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - 12;
    final c = Offset(size.width / 2, size.height / 2);
    // Outer dashed ring.
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const segments = 36;
    for (var i = 0; i < segments; i++) {
      if (i.isOdd) continue;
      final a1 = i / segments * 2 * math.pi;
      final a2 = (i + 0.6) / segments * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a1,
        a2 - a1,
        false,
        dashPaint,
      );
    }
    // Sweep arc when scanning.
    if (scanning) {
      final sweep = Paint()
        ..shader = SweepGradient(
          colors: [Colors.transparent, color],
          startAngle: 0,
          endAngle: math.pi * 2,
          transform: GradientRotation(progress * 2 * math.pi),
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        progress * 2 * math.pi,
        math.pi * 0.7,
        false,
        sweep,
      );
    }
    // Frame corners (always drawn for the gate-side visual cue).
    final corner = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLen = 18.0;
    final tl = Offset(c.dx - r * 0.7, c.dy - r * 0.7);
    final tr = Offset(c.dx + r * 0.7, c.dy - r * 0.7);
    final bl = Offset(c.dx - r * 0.7, c.dy + r * 0.7);
    final br = Offset(c.dx + r * 0.7, c.dy + r * 0.7);
    canvas
      ..drawLine(tl, Offset(tl.dx + cornerLen, tl.dy), corner)
      ..drawLine(tl, Offset(tl.dx, tl.dy + cornerLen), corner)
      ..drawLine(tr, Offset(tr.dx - cornerLen, tr.dy), corner)
      ..drawLine(tr, Offset(tr.dx, tr.dy + cornerLen), corner)
      ..drawLine(bl, Offset(bl.dx + cornerLen, bl.dy), corner)
      ..drawLine(bl, Offset(bl.dx, bl.dy - cornerLen), corner)
      ..drawLine(br, Offset(br.dx - cornerLen, br.dy), corner)
      ..drawLine(br, Offset(br.dx, br.dy - cornerLen), corner);
    // Verified ring.
    if (verified) {
      final ok = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(c, r, ok);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceFrame old) =>
      old.progress != progress ||
      old.scanning != scanning ||
      old.verified != verified;
}
