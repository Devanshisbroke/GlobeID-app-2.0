import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/lifecycle.dart';
import '../../domain/airline_brand.dart';
import '../../domain/airports.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/pressable.dart';
import '../lifecycle/lifecycle_provider.dart';
import '../user/user_provider.dart';

/// BoardingPassLive — a real airline-grade boarding pass for any leg
/// of any trip. Loaded via `/boarding/:tripId/:legId`.
///
/// Surface anatomy:
///   • Brand-tinted top header with airline name + flight number
///   • Big IATA → IATA route with animated airplane that flies the arc
///   • Live countdown to scheduled departure, ticking every second
///   • Boarding info grid (gate, terminal, seat, group) in mono font
///   • Holographic foil strip + perforation tear strip
///   • Flippable barcode panel: PDF417 → QR with shimmer transition
///   • Passenger / sequence / class info on the back side
///   • Brightness ramp veil so the barcode reads at a real gate
class BoardingPassLiveScreen extends ConsumerStatefulWidget {
  const BoardingPassLiveScreen({
    super.key,
    required this.tripId,
    required this.legId,
  });
  final String tripId;
  final String legId;
  @override
  ConsumerState<BoardingPassLiveScreen> createState() =>
      _BoardingPassLiveScreenState();
}

class _BoardingPassLiveScreenState extends ConsumerState<BoardingPassLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _foil;
  late final AnimationController _flip;
  late final AnimationController _airplane;
  Timer? _tick;
  bool _flipped = false;
  bool _boost = false;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _foil = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _airplane = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _foil.dispose();
    _flip.dispose();
    _airplane.dispose();
    _tick?.cancel();
    super.dispose();
  }

  Duration _calcRemaining(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return Duration.zero;
    return t.difference(DateTime.now());
  }

  String _fmtRemaining(Duration d) {
    if (d.isNegative) return '— DEPARTED —';
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final lifecycle = ref.watch(lifecycleProvider);
    final user = ref.watch(userProvider);
    final trip = lifecycle.trips.cast<TripLifecycle?>().firstWhere(
          (t) => t?.id == widget.tripId,
          orElse: () => null,
        );
    final leg = trip?.legs.cast<FlightLeg?>().firstWhere(
          (l) => l?.id == widget.legId,
          orElse: () => null,
        );

    if (trip == null || leg == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white54,
                  size: 56,
                ),
                const SizedBox(height: AppTokens.space3),
                Text(
                  'Boarding pass not found',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _remaining = _calcRemaining(leg.scheduled);
    final brand = resolveAirlineBrand(leg.flightNumber);
    final fromAir = getAirport(leg.from);
    final toAir = getAirport(leg.to);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Brand backdrop ──────────────────────────────────────
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 360),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.4,
                    colors: [
                      brand.primary.withValues(alpha: 0.50),
                      brand.colors.last.withValues(alpha: 0.85),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            // ── Drifting cloud silhouettes ──────────────────────────
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _airplane,
                  builder: (_, __) => CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _CloudsPainter(t: _airplane.value),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Pressable(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        PremiumHud(
                          label: 'BOARDING',
                          tone: brand.primary,
                          trailing: Text('GATE ${leg.gate}'),
                        ),
                        const Spacer(),
                        Pressable(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() => _boost = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusFull,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.brightness_high_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Boost',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (_flipped) {
                              _flip.reverse();
                            } else {
                              _flip.forward();
                            }
                            setState(() => _flipped = !_flipped);
                          },
                          child: AnimatedBuilder(
                            animation: _flip,
                            builder: (_, __) {
                              final t = _flip.value;
                              final showBack = t >= 0.5;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0014)
                                  ..rotateY(math.pi * t),
                                child: showBack
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(math.pi),
                                        child: _BackFace(
                                          leg: leg,
                                          brand: brand,
                                          passengerName: user.profile.name,
                                        ),
                                      )
                                    : _FrontFace(
                                        leg: leg,
                                        brand: brand,
                                        fromAirport: fromAir,
                                        toAirport: toAir,
                                        passengerName: user.profile.name,
                                        countdown: _fmtRemaining(_remaining),
                                        foil: _foil,
                                        airplane: _airplane,
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, top: 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: Text(
                          _flipped
                              ? 'Tap to flip back'
                              : 'Tap to see passenger details',
                          key: ValueKey(_flipped),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Brightness boost veil ───────────────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 320),
              opacity: _boost ? 1 : 0,
              curve: Curves.easeOutCubic,
              child: IgnorePointer(
                ignoring: !_boost,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _boost = false);
                  },
                  child: Container(color: Colors.white),
                ),
              ),
            ),
            if (_boost)
              Positioned.fill(
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _boost = false);
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: QrImageView(
                            data: 'GLOBEID|BP|${trip.id}|${leg.id}|'
                                '${leg.from}|${leg.to}|${leg.flightNumber}|'
                                '${leg.scheduled}',
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// FRONT FACE
// ─────────────────────────────────────────────────────────────────────

class _FrontFace extends StatelessWidget {
  const _FrontFace({
    required this.leg,
    required this.brand,
    required this.fromAirport,
    required this.toAirport,
    required this.passengerName,
    required this.countdown,
    required this.foil,
    required this.airplane,
  });
  final FlightLeg leg;
  final AirlineBrand brand;
  final Airport? fromAirport;
  final Airport? toAirport;
  final String passengerName;
  final String countdown;
  final AnimationController foil;
  final AnimationController airplane;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusXl),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: brand.primary.withValues(alpha: 0.35),
              blurRadius: 60,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Brand header ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: brand.gradient(),
              ),
              child: Row(
                children: [
                  Text(
                    brand.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    leg.flightNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // ── Foil shimmer strip ───────────────────────────────
            AnimatedBuilder(
              animation: foil,
              builder: (_, __) => Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + foil.value * 2, 0),
                    end: Alignment(1 + foil.value * 2, 0),
                    colors: const [
                      Color(0xFFD4AF37),
                      Color(0xFFE9C75D),
                      Color(0xFFE9F1F9),
                      Color(0xFFB8902B),
                    ],
                  ),
                ),
              ),
            ),
            // ── Route ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leg.from,
                          style: TextStyle(
                            color: brand.primary,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          fromAirport?.city ?? leg.from,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Arc with airplane ───────────────────────────
                  SizedBox(
                    width: 120,
                    height: 60,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: airplane,
                        builder: (_, __) => CustomPaint(
                          isComplex: true,
                          willChange: true,
                          painter: _ArcAirplanePainter(
                            progress: airplane.value,
                            color: brand.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          leg.to,
                          style: TextStyle(
                            color: brand.primary,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          toAirport?.city ?? leg.to,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Countdown ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: brand.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: brand.primary.withValues(alpha: 0.32),
                  ),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: brand.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TIME TO DEPARTURE',
                      style: TextStyle(
                        color: brand.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      countdown,
                      style: TextStyle(
                        color: brand.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Courier',
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Info grid ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _Info(label: 'GATE', value: leg.gate ?? '—'),
                  _Info(label: 'TERM', value: leg.terminal ?? '—'),
                  _Info(label: 'SEAT', value: leg.seat ?? 'OPEN'),
                  _Info(
                    label: 'BOARDS',
                    value: _hhmm(leg.boarding ?? leg.scheduled),
                  ),
                  _Info(
                    label: 'DEPARTS',
                    value: _hhmm(leg.scheduled),
                  ),
                  _Info(
                    label: 'CLASS',
                    value: 'ECONOMY',
                    accent: brand.primary,
                  ),
                ],
              ),
            ),
            // ── Perforation tear strip ───────────────────────────
            RepaintBoundary(
              child: CustomPaint(
                isComplex: true,
                size: const Size(double.infinity, 14),
                painter: _PerforationPainter(),
              ),
            ),
            // ── PDF417 barcode ───────────────────────────────────
            // Static painter — wrap so the barcode is rasterised once
            // and then composited as a layer.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: SizedBox(
                height: 56,
                child: RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    painter: _Pdf417Painter(
                      seed: '${leg.flightNumber}|${leg.from}|${leg.to}',
                      color: Colors.black87,
                    ),
                    size: const Size(double.infinity, 56),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                children: [
                  Text(
                    passengerName.toUpperCase().replaceAll(' ', ' / '),
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'SEQ ${_seq(leg.id)}',
                    style: TextStyle(
                      color: brand.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value, this.accent});
  final String label;
  final String value;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: accent ?? const Color(0xFF111827),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.6,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}

class _ArcAirplanePainter extends CustomPainter {
  _ArcAirplanePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path();
    final start = Offset(0, size.height * 0.7);
    final end = Offset(size.width, size.height * 0.7);
    final ctrl = Offset(size.width / 2, -size.height * 0.2);
    p.moveTo(start.dx, start.dy);
    p.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    // Dashed arc.
    final dashed = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final metrics = p.computeMetrics().first;
    var i = 0.0;
    while (i < metrics.length) {
      final seg = metrics.extractPath(i, i + 4);
      canvas.drawPath(seg, dashed);
      i += 9;
    }

    // Airplane glyph at progress.
    final pt = metrics.getTangentForOffset(progress * metrics.length);
    if (pt == null) return;
    canvas.save();
    canvas.translate(pt.position.dx, pt.position.dy);
    canvas.rotate(pt.angle);
    final plane = Path()
      ..moveTo(-10, 0)
      ..lineTo(10, 0)
      ..moveTo(-2, -4)
      ..lineTo(6, 0)
      ..lineTo(-2, 4);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(plane, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArcAirplanePainter old) =>
      old.progress != progress || old.color != color;
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final y = size.height / 2;
    var x = 6.0;
    while (x < size.width - 6) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), p);
      x += 8;
    }
    // Half-circles (eyelets).
    canvas.drawCircle(
      Offset(0, y),
      6,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      Offset(size.width, y),
      6,
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter old) => false;
}

class _Pdf417Painter extends CustomPainter {
  _Pdf417Painter({required this.seed, required this.color});
  final String seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed.hashCode);
    const cols = 96;
    final w = size.width / cols;
    final rectPaint = Paint()..color = color;
    for (var i = 0; i < cols; i++) {
      // Random bar width 1..3 stripes thick.
      final thick = 1 + rng.nextInt(3);
      final x = i * w;
      // Two narrow rows so it visually resembles a PDF417.
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w * thick / 4, size.height * 0.45),
        rectPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          x + w * thick / 4,
          size.height * 0.55,
          w * thick / 4,
          size.height * 0.45,
        ),
        rectPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Pdf417Painter old) =>
      old.seed != seed || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────
// BACK FACE
// ─────────────────────────────────────────────────────────────────────

class _BackFace extends StatelessWidget {
  const _BackFace({
    required this.leg,
    required this.brand,
    required this.passengerName,
  });
  final FlightLeg leg;
  final AirlineBrand brand;
  final String passengerName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusXl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: brand.gradient(),
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BOARDING DETAILS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.4,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              brand.name.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _BackRow(
              label: 'PASSENGER',
              value: passengerName.isEmpty ? 'GLOBEID USER' : passengerName,
            ),
            _BackRow(label: 'CONFIRMATION', value: _confirmation(leg.id)),
            _BackRow(
              label: 'FFP TIER',
              value: 'PLATINUM ELITE',
            ),
            _BackRow(
              label: 'AIRCRAFT',
              value: _aircraftFor(leg.flightNumber),
            ),
            _BackRow(label: 'BAGGAGE', value: '2 × 32 kg + 1 hand'),
            _BackRow(label: 'PRIORITY', value: 'GROUP 1'),
            const SizedBox(height: 18),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            const Text(
              'IMPORTANT',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.4,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gate closes 15 minutes before departure. Have your '
              'GlobeID and physical passport ready at security and at '
              'the gate. Connection passengers should follow Group 1 '
              'signage to minimum-connect-time corridors.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                height: 1.4,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                fontSize: 9,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                fontFamily: 'Courier',
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// CLOUDS
// ─────────────────────────────────────────────────────────────────────

class _CloudsPainter extends CustomPainter {
  _CloudsPainter({required this.t});
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(11);
    for (var i = 0; i < 4; i++) {
      final w = 220.0 + rng.nextInt(120);
      final h = 60.0 + rng.nextInt(40);
      final y = 60 + i * 130 + rng.nextInt(20).toDouble();
      final dx = (t * 1.0 + i * 0.25) % 1.0;
      final x = -w + (size.width + w * 2) * dx;
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.04 + 0.02 * (i % 2));
      canvas.drawOval(Rect.fromLTWH(x, y, w, h), p);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudsPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────

String _hhmm(String iso) {
  final t = DateTime.tryParse(iso);
  if (t == null) return '—';
  final local = t.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _seq(String legId) {
  var h = 0;
  for (final c in legId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return (1 + (h % 999)).toString().padLeft(3, '0');
}

String _confirmation(String legId) {
  // 6-char alphanumeric like a real PNR.
  const alpha = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  var h = 1;
  for (final c in legId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  final sb = StringBuffer();
  for (var i = 0; i < 6; i++) {
    sb.write(alpha[h % alpha.length]);
    h = (h * 17 + 7) & 0x7fffffff;
  }
  return sb.toString();
}

String _aircraftFor(String flightNo) {
  const fleet = [
    'Boeing 787-9 Dreamliner',
    'Airbus A350-900',
    'Boeing 777-300ER',
    'Airbus A321neo',
    'Boeing 737 MAX 8',
    'Airbus A320neo',
  ];
  var h = 0;
  for (final c in flightNo.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return fleet[h % fleet.length];
}
