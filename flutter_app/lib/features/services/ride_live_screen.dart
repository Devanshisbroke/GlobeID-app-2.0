import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/journey_strip.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/toast.dart';

/// RideLiveScreen — premium Uber/Lyft-style live trip view.
///
/// Sections:
///   • Cinematic hero (eta + distance + status badge)
///   • Animated map with route + moving car marker
///   • Journey strip (Confirmed → Driver enroute → Arrived → On trip → Done)
///   • Driver card (rating, plate, vehicle)
///   • Fare breakdown
///   • Agentic chain (continue trip with hotel / food / etc)
class RideLiveScreen extends StatefulWidget {
  const RideLiveScreen({
    super.key,
    this.driverName = 'Hiroshi T.',
    this.vehicle = 'Toyota Crown · 黒',
    this.plate = 'KA 4218',
    this.tone = const Color(0xFFEA580C),
    this.from = 'Aman Tokyo',
    this.to = 'Narita Intl. Airport · T1',
  });

  final String driverName;
  final String vehicle;
  final String plate;
  final Color tone;
  final String from;
  final String to;

  @override
  State<RideLiveScreen> createState() => _RideLiveScreenState();
}

class _RideLiveScreenState extends State<RideLiveScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  int _stage = 1; // 0=confirmed, 1=enroute, 2=arrived, 3=on trip, 4=done
  Timer? _stepper;

  @override
  void initState() {
    super.initState();
    _stepper = Timer.periodic(const Duration(seconds: 14), (_) {
      if (!mounted) return;
      setState(() => _stage = (_stage + 1) % 5);
      HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _stepper?.cancel();
    super.dispose();
  }

  String get _stageLabel {
    switch (_stage) {
      case 0:
        return 'Confirmed';
      case 1:
        return 'Driver enroute';
      case 2:
        return 'Arrived';
      case 3:
        return 'On trip';
      case 4:
      default:
        return 'Completed';
    }
  }

  String get _eta {
    switch (_stage) {
      case 0:
      case 1:
        return '6 min';
      case 2:
        return 'Arrived';
      case 3:
        return '32 min';
      case 4:
      default:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Live trip',
      subtitle: '${widget.from} → ${widget.to}',
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedAppearance(
              child: CinematicReveal(
                tone: widget.tone,
                child: Stack(
                  children: [
                    CinematicHero(
                      eyebrow: _stageLabel.toUpperCase(),
                      title: _eta,
                      subtitle: '${widget.driverName} · ${widget.vehicle}',
                      icon: Icons.local_taxi_rounded,
                      tone: widget.tone,
                      badges: [
                        HeroBadge(
                            label: 'Plate ${widget.plate}',
                            icon: Icons.confirmation_number_rounded),
                        const HeroBadge(
                            label: '4.94★ rated', icon: Icons.star_rounded),
                        const HeroBadge(
                            label: 'A/C · charger', icon: Icons.bolt_rounded),
                      ],
                    ),
                    Positioned(
                      top: AppTokens.space3,
                      right: AppTokens.space3,
                      child: PremiumHud(
                        label: 'LIVE',
                        tone: widget.tone,
                        trailing: Text(_eta),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space3)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            sliver: SliverToBoxAdapter(
              child: PremiumPulseStrip(
                pulses: [
                  PulseTile(
                    label: 'Stage',
                    value: _stageLabel,
                    tone: widget.tone,
                    icon: Icons.directions_car_rounded,
                  ),
                  PulseTile(
                    label: 'ETA',
                    value: _eta,
                    tone: const Color(0xFF10B981),
                    icon: Icons.schedule_rounded,
                  ),
                  PulseTile(
                    label: 'Driver',
                    value: '4.94★',
                    tone: const Color(0xFFEAB308),
                    icon: Icons.star_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space3)),
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radius2xl),
              child: SizedBox(
                height: 240,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => CustomPaint(
                      painter: _RideMapPainter(
                        tone: widget.tone,
                        progress: _ctrl.value,
                        stage: _stage,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: JourneyStrip(
                activeIndex: _stage,
                steps: const [
                  JourneyStep(
                      label: 'Confirm', icon: Icons.check_circle_rounded),
                  JourneyStep(
                      label: 'Pickup', icon: Icons.directions_car_rounded),
                  JourneyStep(label: 'Onboard', icon: Icons.event_seat_rounded),
                  JourneyStep(label: 'On trip', icon: Icons.timeline_rounded),
                  JourneyStep(label: 'Drop', icon: Icons.flag_rounded),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Driver',
              subtitle: 'Verified GlobeID partner',
            ),
          ),
          SliverToBoxAdapter(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.tone,
                          widget.tone.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.driverName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        Text(widget.vehicle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            )),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.tone.withValues(alpha: 0.16),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                          ),
                          child: Text(
                            'Plate ${widget.plate}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.tone,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _CircleAction(
                        icon: Icons.message_rounded,
                        tone: widget.tone,
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                      const SizedBox(height: 6),
                      _CircleAction(
                        icon: Icons.call_rounded,
                        tone: widget.tone,
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Fare breakdown',
              subtitle: 'Live estimate · USD',
            ),
          ),
          SliverToBoxAdapter(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                children: [
                  for (final r in const [
                    ('Base fare', '\$8.40'),
                    ('Distance · 64.2 km', '\$22.10'),
                    ('Time · 32 min', '\$6.20'),
                    ('Service fee', '\$2.30'),
                    ('GlobeID Pass discount', '-\$3.00'),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child:
                                Text(r.$1, style: theme.textTheme.bodyMedium),
                          ),
                          Text(r.$2,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              )),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 1,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  Row(
                    children: [
                      const Expanded(
                          child: Text('Estimated total',
                              style: TextStyle(fontWeight: FontWeight.w800))),
                      Text(
                        '\$36.00',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: widget.tone,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: AgenticBand(
              title: 'Once you arrive',
              chips: [
                AgenticChip(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'Boarding pass · UA837',
                  route: '/boarding/trp-001/leg-ua837',
                  tone: theme.colorScheme.primary,
                ),
                AgenticChip(
                  icon: Icons.airline_seat_recline_extra_rounded,
                  label: 'Lounge access',
                  route: '/services',
                  tone: const Color(0xFFD97706),
                ),
                AgenticChip(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Departure checklist',
                  route: '/planner',
                  tone: const Color(0xFF059669),
                ),
                AgenticChip(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Duty-free deals',
                  tone: const Color(0xFF7E22CE),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: CinematicButton(
              label: _stage >= 4 ? 'Trip completed' : 'Cancel trip',
              icon: _stage >= 4
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              gradient: LinearGradient(
                colors: _stage >= 4
                    ? const [Color(0xFF10B981), Color(0xFF059669)]
                    : [
                        widget.tone,
                        widget.tone.withValues(alpha: 0.55),
                      ],
              ),
              onPressed: () {
                HapticFeedback.heavyImpact();
                AppToast.show(
                  context,
                  title: _stage >= 4
                      ? 'Trip archived · receipt available in Wallet'
                      : 'Driver notified · trip held',
                  tone: AppToastTone.success,
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space9)),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tone,
    required this.onTap,
  });
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tone.withValues(alpha: 0.18),
          border: Border.all(color: tone.withValues(alpha: 0.32)),
        ),
        child: Icon(icon, color: tone, size: 16),
      ),
    );
  }
}

class _RideMapPainter extends CustomPainter {
  const _RideMapPainter({
    required this.tone,
    required this.progress,
    required this.stage,
  });
  final Color tone;
  final double progress;
  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0F172A),
          const Color(0xFF1E293B),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Roads (deterministic)
    final roads = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(20, size.height * 0.7),
        Offset(size.width - 20, size.height * 0.4), roads);
    canvas.drawLine(Offset(60, size.height * 0.85),
        Offset(size.width - 60, size.height * 0.15), roads);
    canvas.drawLine(
        Offset(size.width * 0.2, size.height - 10),
        Offset(size.width * 0.6, 20),
        roads..color = Colors.white.withValues(alpha: 0.08));

    // Route arc
    final start = Offset(36, size.height - 36);
    final end = Offset(size.width - 36, 36);
    final mid =
        Offset((start.dx + end.dx) / 2 + 12, (start.dy + end.dy) / 2 + 18);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [tone.withValues(alpha: 0.5), tone],
        ).createShader(Rect.fromPoints(start, end)),
    );

    // Anchor pins
    canvas.drawCircle(start, 8, Paint()..color = Colors.white);
    canvas.drawCircle(start, 5, Paint()..color = tone);
    canvas.drawCircle(end, 8, Paint()..color = Colors.white);
    canvas.drawCircle(end, 5, Paint()..color = const Color(0xFF10B981));

    // Animated car along the path (glow)
    final t = (progress + 0.3 * stage) % 1.0;
    final pos = _bezier(start, mid, end, t);
    final tang = _bezier(start, mid, end, t + 0.01);
    final angle = math.atan2(tang.dy - pos.dy, tang.dx - pos.dx);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 12),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 18, height: 8),
      Paint()..color = tone,
    );
    canvas.restore();

    // Pulse halo around the car
    canvas.drawCircle(
      pos,
      14 + math.sin(progress * math.pi * 2) * 4,
      Paint()
        ..color = tone.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
  }

  Offset _bezier(Offset a, Offset b, Offset c, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * a.dx + 2 * mt * t * b.dx + t * t * c.dx,
      mt * mt * a.dy + 2 * mt * t * b.dy + t * t * c.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _RideMapPainter old) =>
      old.progress != progress || old.tone != tone || old.stage != stage;
}
