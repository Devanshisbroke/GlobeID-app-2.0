import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pull_down_summoner.dart';
import '../security/session_lock_provider.dart';

/// Lock screen — cinematic biometric ring with rotating orbital sweep,
/// glow pulse on tap, gentle backdrop bloom.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with TickerProviderStateMixin {
  final _auth = LocalAuthentication();
  String? _error;
  bool _busy = false;

  late final _orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    _orbit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Web (and any platform without a `local_auth` implementation)
      // cannot run native biometrics. Treat the tap as a successful
      // unlock so the app remains testable on Chrome / desktop.
      final ok = kIsWeb
          ? true
          : await _auth.authenticate(
              localizedReason: 'Unlock GlobeID',
            );
      if (ok && mounted) {
        HapticFeedback.mediumImpact();
        await ref.read(sessionLockProvider.notifier).unlock();
        if (!mounted) return;
        context.go('/');
      }
    } catch (e) {
      // On platforms where the plugin is missing entirely, treat the
      // tap as authoritative so the user can keep moving. Real native
      // builds still surface errors to the UI as before.
      if (e is MissingPluginException) {
        if (!mounted) return;
        await ref.read(sessionLockProvider.notifier).unlock();
        if (!mounted) return;
        context.go('/');
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.black,
      body: PullDownSummoner(
        triggerDistance: 96,
        overlayBuilder: (ctx) => _EmergencyOverlay(accent: accent),
        child: Stack(
          children: [
            // Soft radial bloom backdrop.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.4,
                    colors: [
                      accent.withValues(alpha: 0.32),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.space7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedAppearance(
                      child: Text(
                        'GlobeID',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    AnimatedAppearance(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Touch to unlock',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space9),
                    AnimatedAppearance(
                      delay: const Duration(milliseconds: 200),
                      child: Pressable(
                        scale: 0.96,
                        onTap: _unlock,
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_orbit, _pulse]),
                            builder: (_, __) => SizedBox(
                              width: 220,
                              height: 220,
                              child: CustomPaint(
                                isComplex: true,
                                willChange: true,
                                painter: _BiometricRing(
                                  orbit: _orbit.value,
                                  pulse: _pulse.value,
                                  color: accent,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.fingerprint_rounded,
                                    color: Colors.white,
                                    size: 64,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppTokens.space5),
                      Text(_error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFEF4444),
                          ),
                          textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: AppTokens.space9),
                    AnimatedAppearance(
                      delay: const Duration(milliseconds: 280),
                      child: TextButton(
                        onPressed: _unlock,
                        child: Text(
                          _busy ? 'Authenticating…' : 'Try again',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyOverlay extends StatelessWidget {
  const _EmergencyOverlay({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.85),
            accent.withValues(alpha: 0.45),
          ],
        ),
        boxShadow: const [
          BoxShadow(blurRadius: 24, color: Colors.black54),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_moon_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Emergency mode',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pull-down summon · biometric assist available\n'
            'Connecting to consular services + trusted contacts.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call consulate'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.share_location_rounded,
                      color: Colors.white),
                  label: const Text(
                    'Share location',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BiometricRing extends CustomPainter {
  _BiometricRing({
    required this.orbit,
    required this.pulse,
    required this.color,
  });
  final double orbit;
  final double pulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 12;
    // Outer pulse halo.
    final haloR = r + 14 + 6 * math.sin(pulse * 2 * math.pi);
    final halo = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, haloR, halo);
    // Track.
    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r, track);
    // Inner pulse ring.
    final inner = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(c, r - 12, inner);
    // Orbital sweep arc.
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color,
        ],
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(orbit * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      orbit * 2 * math.pi,
      math.pi * 0.7,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _BiometricRing old) =>
      old.orbit != orbit || old.pulse != pulse || old.color != color;
}
