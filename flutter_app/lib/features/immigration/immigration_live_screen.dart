import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../nexus/nexus_tokens.dart';

/// ImmigrationLive — alive eGate / passport-scan companion.
///
/// Anatomy:
///
///   • Atmosphere backdrop in cyan (the immigration-counter tone)
///   • Central scanner column: country-pair tile (origin flag → dest
///     flag with arc), a passport silhouette beneath, and a green
///     laser scan beam that sweeps top-to-bottom on a 1.2s loop.
///   • BreathingRing ambient halo at "EGATE READY" state.
///   • Live queue-time pill ("4 MIN QUEUE · LANE 2") that ticks every
///     8 seconds with a tonal shimmer.
///   • Step ribbon: SCAN PASSPORT → BIOMETRIC → QUESTIONS → STAMP →
///     EXIT. Each step has a tonal disc that lights up as you progress.
///   • Bottom CTAs — "Open passport" + "Customs declaration".
class ImmigrationLiveScreen extends ConsumerStatefulWidget {
  const ImmigrationLiveScreen({super.key});

  @override
  ConsumerState<ImmigrationLiveScreen> createState() =>
      _ImmigrationLiveScreenState();
}

class _ImmigrationLiveScreenState extends ConsumerState<ImmigrationLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scan;
  int _step = 0;
  _QueueBucket _queueBucket = _QueueBucket.fast;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  /// Map the immigration step to its cinematic surface state:
  ///   SCAN PASSPORT  → armed     (eGate primed, waiting to read)
  ///   BIOMETRIC      → active    (camera + chip are reading)
  ///   QUESTIONS      → active    (officer interview pending)
  ///   STAMP          → committed (single pulse — passport stamped)
  ///   EXIT           → settled   (cleared, walking out)
  LiveSurfaceState _stateForStep(int step) {
    switch (step) {
      case 0:
        return LiveSurfaceState.armed;
      case 1:
      case 2:
        return LiveSurfaceState.active;
      case 3:
        return LiveSurfaceState.committed;
      case 4:
      default:
        return LiveSurfaceState.settled;
    }
  }

  /// Queue depth bumps the cinematic state: fast queue stays at the
  /// step-derived cadence; medium queue promotes idle/armed → active;
  /// heavy queue promotes anything below committed → committed. The
  /// stamp step always wins (the visa-stamp moment is the loudest
  /// commit on the surface).
  LiveSurfaceState _composedState(int step, _QueueBucket bucket) {
    final stepState = _stateForStep(step);
    final queueState = switch (bucket) {
      _QueueBucket.fast => LiveSurfaceState.armed,
      _QueueBucket.medium => LiveSurfaceState.active,
      _QueueBucket.heavy => LiveSurfaceState.committed,
    };
    return stepState.index >= queueState.index ? stepState : queueState;
  }

  @override
  Widget build(BuildContext context) {
    const tone = Color(0xFF06B6D4);
    const steps = [
      _ImmStep('SCAN PASSPORT', Icons.qr_code_2_rounded),
      _ImmStep('BIOMETRIC', Icons.face_rounded),
      _ImmStep('QUESTIONS', Icons.help_outline_rounded),
      _ImmStep('STAMP', Icons.approval_rounded),
      _ImmStep('EXIT', Icons.exit_to_app_rounded),
    ];
    final liveState = _composedState(_step, _queueBucket);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: tone,
        statusBar: _Header(tone: tone, liveState: liveState),
        bottomBar: Row(
          children: [
            Expanded(
              child: LiveCta(
                label: 'Passport',
                icon: Icons.book_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/passport-live');
                },
              ),
            ),
            const SizedBox(width: N.s3),
            Expanded(
              child: LiveCta(
                label: 'Customs',
                icon: Icons.shield_rounded,
                secondary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/customs');
                },
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            _CountryPairTile(),
            const SizedBox(height: N.s4),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final next = (_step + 1) % steps.length;
                  final nextState = _stateForStep(next);
                  // The STAMP frame is the cinematic commit — signature
                  // triple-pulse haptic so the user feels the passport
                  // get stamped. Everything else is a soft selection.
                  if (nextState == LiveSurfaceState.committed) {
                    HapticFeedback.heavyImpact();
                  } else {
                    HapticFeedback.selectionClick();
                  }
                  setState(() => _step = next);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Breathing cadence accelerates as the user steps
                    // forward — armed 2.2 s → active 1.4 s → commit
                    // 0.8 s → settled 4.2 s. Same primitive, the
                    // surface state drives the period.
                    BreathingRing(
                      tone: tone,
                      size: 240,
                      duration: liveState.breathingPeriod,
                    ),
                    // NFC pulse around the scanner — gives the eGate
                    // primed-to-read read instead of static prop.
                    NfcPulse(
                      tone: tone,
                      size: 220,
                      rings: 3,
                      maxAlpha: 0.42,
                      child: _PassportScanner(tone: tone, anim: _scan),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: N.s4),
            _QueueStrip(
              tone: tone,
              onBucketChange: (bucket) {
                if (!mounted) return;
                setState(() => _queueBucket = bucket);
              },
            ),
            const SizedBox(height: N.s4),
            _StepRibbon(steps: steps, active: _step, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _ImmStep {
  const _ImmStep(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _Header extends StatelessWidget {
  const _Header({required this.tone, required this.liveState});
  final Color tone;
  final LiveSurfaceState liveState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: N.s3),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: N.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIVE IMMIGRATION · EGATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'NARITA TERMINAL 1 · ARRIVALS',
                  style: TextStyle(
                    color: tone.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Status pill mirrors the actual scanner state — armed
          // before scan, active during read, committed on stamp,
          // settled on exit. Tone shifts with the bucket so the
          // user can read progress at a glance.
          LiveStatusPill(
            state: liveState,
            tone: liveState == LiveSurfaceState.committed
                ? const Color(0xFFD4AF37)
                : liveState == LiveSurfaceState.settled
                    ? const Color(0xFF10B981)
                    : tone,
          ),
        ],
      ),
    );
  }
}

class _CountryPairTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Text('🇮🇳', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FROM',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'INDIA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Expanded(
            child: SizedBox(
              height: 30,
              child: CustomPaint(
                painter: _ArcPainter(tone: const Color(0xFF06B6D4)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'JAPAN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Text('🇯🇵', style: TextStyle(fontSize: 30)),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.tone});
  final Color tone;
  @override
  void paint(Canvas canvas, Size size) {
    final dash = Paint()
      ..color = tone.withValues(alpha: 0.65)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..quadraticBezierTo(size.width / 2, -10, size.width, size.height / 2);
    final dashLen = 8.0;
    final gap = 5.0;
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      var distance = 0.0;
      while (distance < m.length) {
        final extract = m.extractPath(distance, distance + dashLen);
        canvas.drawPath(extract, dash);
        distance += dashLen + gap;
      }
    }
    final iconRect = Rect.fromCircle(
      center: Offset(size.width / 2, -2),
      radius: 6,
    );
    canvas.drawCircle(iconRect.center, 4, Paint()..color = tone);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => false;
}

class _PassportScanner extends StatelessWidget {
  const _PassportScanner({required this.tone, required this.anim});
  final Color tone;
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = anim.value;
        return SizedBox(
          width: 190,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Passport silhouette.
              Container(
                width: 170,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(Colors.black, tone, 0.55)!,
                      Color.lerp(Colors.black, tone, 0.18)!,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.6,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PASSPORT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.public_rounded,
                        color: Colors.white.withValues(alpha: 0.40),
                        size: 60,
                      ),
                      const Spacer(),
                      Text(
                        'GLOBEID',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scan beam.
              Positioned(
                top: 10 + t * 220,
                child: Container(
                  width: 200,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        tone.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.95),
                        tone.withValues(alpha: 0.95),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Scan-ring sweep — soft radial ring that radiates
              // out from the centre of the passport in sync with
              // the beam. Sells the "eGate is reading the chip"
              // dimension on top of the linear scan. Two staggered
              // rings (offset by 0.5 phase) so there's always one
              // active mid-flight.
              ...List.generate(2, (i) {
                final phase = (t + i * 0.5) % 1.0;
                final radius = 18 + phase * 90;
                final ringAlpha = (1.0 - phase) * 0.55;
                return IgnorePointer(
                  child: Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tone.withValues(alpha: ringAlpha),
                        width: 0.8,
                      ),
                    ),
                  ),
                );
              }),
              // Scan-zone label.
              Positioned(
                bottom: 6,
                child: Text(
                  '${(t * 100).toInt()}% · SCANNING…',
                  style: TextStyle(
                    color: tone.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Three semantic queue-depth buckets driving tone + cadence.
///
///   ≤ 5  min  → green   (lane is moving)
///   6-15 min  → amber   (manageable wait)
///   > 15 min  → red     (heavy queue, expect delay)
///
/// When the bucket changes (e.g. amber → red), the strip fires a
/// cinematic `LiveDataPulse` and a `selectionClick` haptic so the
/// shift in conditions reads as a real airport status update.
enum _QueueBucket { fast, medium, heavy }

_QueueBucket _bucketFor(int minutes) {
  if (minutes <= 5) return _QueueBucket.fast;
  if (minutes <= 15) return _QueueBucket.medium;
  return _QueueBucket.heavy;
}

Color _toneFor(_QueueBucket b) {
  switch (b) {
    case _QueueBucket.fast:
      return const Color(0xFF10B981); // signal green
    case _QueueBucket.medium:
      return const Color(0xFFF59E0B); // amber
    case _QueueBucket.heavy:
      return const Color(0xFFEF4444); // red
  }
}

String _labelFor(_QueueBucket b) {
  switch (b) {
    case _QueueBucket.fast:
      return 'FAST';
    case _QueueBucket.medium:
      return 'STEADY';
    case _QueueBucket.heavy:
      return 'HEAVY';
  }
}

/// Live queue-time strip. Cycles deterministically through a curated
/// schedule of queue depths (3, 5, 9, 16, 12, 6, 4, 3, 11, 18 min)
/// at 7-second intervals; tone + label shift with the bucket so the
/// user can read airport conditions at a glance.
class _QueueStrip extends StatefulWidget {
  const _QueueStrip({required this.tone, this.onBucketChange});
  final Color tone;

  /// Fired when the queue depth bucket changes. Lets the parent
  /// surface compose the queue bucket into its cinematic state
  /// ladder so the breathing cadence accelerates with the queue.
  final ValueChanged<_QueueBucket>? onBucketChange;

  @override
  State<_QueueStrip> createState() => _QueueStripState();
}

class _QueueStripState extends State<_QueueStrip> {
  // Curated cadence — moves through every bucket so the user sees
  // the alive system shift colors over time, never stuck on one
  // value.
  static const _schedule = [3, 5, 9, 16, 12, 6, 4, 3, 11, 18];
  int _ix = 0;
  Timer? _tick;
  final _pulse = LiveDataPulseController();
  late _QueueBucket _bucket;

  @override
  void initState() {
    super.initState();
    _bucket = _bucketFor(_schedule[0]);
    // Propagate the initial bucket once after the first frame so the
    // parent's composed state ladder picks up the queue depth on
    // first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onBucketChange?.call(_bucket);
    });
    _tick = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;
      final nextIx = (_ix + 1) % _schedule.length;
      final nextBucket = _bucketFor(_schedule[nextIx]);
      final changed = nextBucket != _bucket;
      setState(() {
        _ix = nextIx;
        _bucket = nextBucket;
      });
      if (changed) {
        // Heavy queue gets a stronger haptic — the surface escalates
        // physically as the user starts to feel airport friction.
        switch (nextBucket) {
          case _QueueBucket.fast:
            HapticFeedback.selectionClick();
          case _QueueBucket.medium:
            HapticFeedback.lightImpact();
          case _QueueBucket.heavy:
            HapticFeedback.mediumImpact();
        }
        _pulse.pulse();
        widget.onBucketChange?.call(nextBucket);
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _schedule[_ix];
    final liveTone = _toneFor(_bucket);
    final label = _labelFor(_bucket);
    return LiveDataPulse(
      controller: _pulse,
      tone: liveTone,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: liveTone.withValues(alpha: 0.10),
          border:
              Border.all(color: liveTone.withValues(alpha: 0.32), width: 0.6),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: liveTone, size: 16),
            const SizedBox(width: 8),
            // Mono-tabular numeric so the digit width doesn't dance
            // as minutes mutate.
            Text(
              '$minutes MIN QUEUE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            // Tonal bucket label so the user can read conditions
            // (FAST / STEADY / HEAVY) without parsing minutes.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: liveTone.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: liveTone.withValues(alpha: 0.55),
                  width: 0.5,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: liveTone,
                  fontWeight: FontWeight.w900,
                  fontSize: 8.5,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'LANE 2 · GATE 14',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRibbon extends StatelessWidget {
  const _StepRibbon({
    required this.steps,
    required this.active,
    required this.tone,
  });
  final List<_ImmStep> steps;
  final int active;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: steps.length,
        itemBuilder: (_, i) {
          final isActive = i == active;
          final isDone = i < active;
          final discTone = isActive
              ? tone
              : (isDone
                  ? const Color(0xFF10B981)
                  : Colors.white.withValues(alpha: 0.20));
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: discTone.withValues(alpha: 0.18),
                    border: Border.all(color: discTone, width: 0.8),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : steps[i].icon,
                    color: discTone,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i].label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.55),
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


