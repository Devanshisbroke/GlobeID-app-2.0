import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';

/// SensorsLabScreen — flagship surface for live device sensor data.
///
/// Subscribes to:
///   • accelerometer (low-pass filtered)
///   • gyroscope
///   • magnetometer
/// and renders three live cards plus a holographic credential card
/// that tilts in 3D based on the accelerometer (parallax). Provides
/// a "haptic chord" CTA that fires four shaped haptic taps.
class SensorsLabScreen extends StatefulWidget {
  const SensorsLabScreen({super.key});

  @override
  State<SensorsLabScreen> createState() => _SensorsLabScreenState();
}

class _SensorsLabScreenState extends State<SensorsLabScreen> {
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  double _accX = 0, _accY = 0, _accZ = 0;
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;
  double _magX = 0, _magY = 0, _magZ = 0;

  // Smoothed tilt for the holographic card.
  double _tiltX = 0, _tiltY = 0;
  static const _alpha = 0.12; // low-pass

  @override
  void initState() {
    super.initState();
    try {
      _accSub = accelerometerEventStream().listen((e) {
        if (!mounted) return;
        setState(() {
          _accX = e.x;
          _accY = e.y;
          _accZ = e.z;
          _tiltY = _tiltY + (e.x.clamp(-9.8, 9.8) / 9.8 - _tiltY) * _alpha;
          _tiltX = _tiltX + (-e.y.clamp(-9.8, 9.8) / 9.8 - _tiltX) * _alpha;
        });
      });
      _gyroSub = gyroscopeEventStream().listen((e) {
        if (!mounted) return;
        setState(() {
          _gyroX = e.x;
          _gyroY = e.y;
          _gyroZ = e.z;
        });
      });
      _magSub = magnetometerEventStream().listen((e) {
        if (!mounted) return;
        setState(() {
          _magX = e.x;
          _magY = e.y;
          _magZ = e.z;
        });
      });
    } catch (_) {
      // Sensor unavailable on this platform; the painter shows zeros.
    }
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  Future<void> _hapticChord() async {
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final tone = const Color(0xFF6366F1);
    return PageScaffold(
      title: 'Sensors Lab',
      subtitle: 'Live device intelligence · parallax · haptics',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: const CinematicHero(
              eyebrow: 'DEVICE INTELLIGENCE',
              title: 'Your phone is awake',
              subtitle:
                  'Accelerometer · gyroscope · magnetometer · haptic chord',
              icon: Icons.sensors_rounded,
              tone: Color(0xFF6366F1),
              badges: [
                HeroBadge(label: 'Live', icon: Icons.bolt_rounded),
                HeroBadge(label: '120Hz', icon: Icons.speed_rounded),
                HeroBadge(label: 'On-device', icon: Icons.lock_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: _HolographicTiltCard(tiltX: _tiltX, tiltY: _tiltY),
          ),
          const SectionHeader(
              title: 'Live readings', subtitle: 'Updated in real time'),
          Row(
            children: [
              Expanded(
                child: _SensorCard(
                  title: 'Accel',
                  unit: 'm/s²',
                  x: _accX,
                  y: _accY,
                  z: _accZ,
                  tone: tone,
                  icon: Icons.speed_rounded,
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: _SensorCard(
                  title: 'Gyro',
                  unit: 'rad/s',
                  x: _gyroX,
                  y: _gyroY,
                  z: _gyroZ,
                  tone: const Color(0xFF10B981),
                  icon: Icons.threesixty_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          _SensorCard(
            title: 'Magnetometer',
            unit: 'µT',
            x: _magX,
            y: _magY,
            z: _magZ,
            tone: const Color(0xFFD97706),
            icon: Icons.explore_rounded,
            wide: true,
          ),
          const SizedBox(height: AppTokens.space5),
          AgenticBand(
            title: 'Bring me elsewhere',
            chips: [
              AgenticChip(
                icon: Icons.public_rounded,
                label: 'Cinematic globe',
                route: '/globe-cinematic',
                tone: tone,
              ),
              AgenticChip(
                icon: Icons.book_rounded,
                label: 'Live passport',
                route: '/passport-live',
                tone: const Color(0xFF7E22CE),
              ),
              AgenticChip(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Kiosk',
                route: '/kiosk-sim',
                tone: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space5),
          CinematicButton(
            label: 'Play haptic chord',
            icon: Icons.vibration_rounded,
            gradient: LinearGradient(
              colors: [tone, tone.withValues(alpha: 0.55)],
            ),
            onPressed: _hapticChord,
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.title,
    required this.unit,
    required this.x,
    required this.y,
    required this.z,
    required this.tone,
    required this.icon,
    this.wide = false,
  });
  final String title;
  final String unit;
  final double x, y, z;
  final Color tone;
  final IconData icon;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      borderColor: tone.withValues(alpha: 0.40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  )),
              const Spacer(),
              Text(unit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          if (wide)
            Row(
              children: [
                Expanded(child: _AxisBar(label: 'X', value: x, tone: tone)),
                const SizedBox(width: 10),
                Expanded(child: _AxisBar(label: 'Y', value: y, tone: tone)),
                const SizedBox(width: 10),
                Expanded(child: _AxisBar(label: 'Z', value: z, tone: tone)),
              ],
            )
          else ...[
            _AxisBar(label: 'X', value: x, tone: tone),
            const SizedBox(height: 6),
            _AxisBar(label: 'Y', value: y, tone: tone),
            const SizedBox(height: 6),
            _AxisBar(label: 'Z', value: z, tone: tone),
          ],
        ],
      ),
    );
  }
}

class _AxisBar extends StatelessWidget {
  const _AxisBar(
      {required this.label, required this.value, required this.tone});
  final String label;
  final double value;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (value.abs() / 12).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: tone.withValues(alpha: 0.16)),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tone, tone.withValues(alpha: 0.55)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 50,
          child: Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _HolographicTiltCard extends StatelessWidget {
  const _HolographicTiltCard({required this.tiltX, required this.tiltY});
  final double tiltX;
  final double tiltY;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(tiltX * 0.18)
      ..rotateY(tiltY * 0.18);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
      child: Center(
        child: Transform(
          transform: m,
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: 1.6,
            child: PremiumCard(
              radius: AppTokens.radius2xl,
              padding: const EdgeInsets.all(AppTokens.space5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1),
                  Color.lerp(const Color(0xFF6366F1), const Color(0xFF06B6D4),
                      0.5 + tiltY * 0.4)!,
                  const Color(0xFF0F172A),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ShimmerPainter(
                        tilt: math.atan2(tiltY, tiltX),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'GLOBEID',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.4,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusFull),
                            ),
                            child: const Text(
                              'HOLO · LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Devansh Barai',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              )),
                          Text('GID-IN-2002 · Verified · Sovereign Identity',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              )),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  const _ShimmerPainter({required this.tilt});
  final double tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = (math.sin(tilt) + 1) / 2;
    final shader = LinearGradient(
      begin: Alignment(-1 + pos * 2, -1),
      end: Alignment(1 - pos * 2, 1),
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.40),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.tilt != tilt;
}
