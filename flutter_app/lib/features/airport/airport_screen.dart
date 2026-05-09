import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/journey_strip.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// AirportScreen — premium airline-grade boarding lobby.
///
/// Sections:
///   • Cinematic hero with live gate countdown
///   • Boarding lifecycle strip (Check-in → Security → Lounge → Gate
///     → Board → Depart)
///   • Lounge map / terminal nav (deterministic painter)
///   • Travel checklist (8 actionable items)
///   • Immigration prep (passport, eVisa, customs)
///   • Agentic chain ("when you land")
class AirportScreen extends StatefulWidget {
  const AirportScreen({
    super.key,
    this.airline = 'United',
    this.flightNumber = 'UA837',
    this.gate = '78A',
    this.terminal = 'T3',
    this.boardingMinutes = 38,
    this.from = 'SFO',
    this.to = 'NRT',
    this.tone = const Color(0xFF1E40AF),
  });

  final String airline;
  final String flightNumber;
  final String gate;
  final String terminal;
  final int boardingMinutes;
  final String from;
  final String to;
  final Color tone;

  @override
  State<AirportScreen> createState() => _AirportScreenState();
}

class _AirportScreenState extends State<AirportScreen> {
  late int _seconds;
  Timer? _tick;
  final _checked = <int>{0, 2};

  @override
  void initState() {
    super.initState();
    _seconds = widget.boardingMinutes * 60;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = (_seconds - 1).clamp(0, 99999));
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String get _countdown {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = _seconds > 25 * 60
        ? 1
        : _seconds > 15 * 60
            ? 2
            : _seconds > 5 * 60
                ? 3
                : 4;
    return PageScaffold(
      title: 'Airport · ${widget.terminal}',
      subtitle:
          '${widget.airline} ${widget.flightNumber} · ${widget.from} → ${widget.to}',
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedAppearance(
              child: CinematicHero(
                eyebrow: 'BOARDING IN',
                title: _countdown,
                subtitle:
                    'Gate ${widget.gate} · ${widget.terminal} · zone 3 · seat 12A',
                icon: Icons.flight_takeoff_rounded,
                tone: widget.tone,
                badges: [
                  HeroBadge(
                      label: 'Gate ${widget.gate}', icon: Icons.location_pin),
                  const HeroBadge(
                      label: 'Polaris',
                      icon: Icons.airline_seat_recline_extra_rounded),
                  const HeroBadge(label: 'On-time', icon: Icons.timer_rounded),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space3)),
          // Bridge into the orchestrator (live gate, terminal map,
          // amenity timing) so the boarding lobby flows into the
          // full airport-mode HUD without a dead-end.
          SliverToBoxAdapter(
            child: AnimatedAppearance(
              delay: const Duration(milliseconds: 80),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.space5),
                child: CinematicButton(
                  label: 'Open airport mode',
                  icon: Icons.hub_rounded,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.push('/airport-mode');
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: JourneyStrip(
                activeIndex: stage,
                steps: const [
                  JourneyStep(
                      label: 'Check-in', icon: Icons.assignment_ind_rounded),
                  JourneyStep(label: 'Security', icon: Icons.security_rounded),
                  JourneyStep(
                      label: 'Lounge',
                      icon: Icons.airline_seat_recline_extra_rounded),
                  JourneyStep(label: 'Gate', icon: Icons.location_pin),
                  JourneyStep(
                      label: 'Board', icon: Icons.flight_takeoff_rounded),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Terminal map',
              subtitle: 'Polaris lounge → gate 78A',
            ),
          ),
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radius2xl),
              child: SizedBox(
                height: 220,
                child: CustomPaint(
                  painter:
                      _TerminalPainter(tone: widget.tone, gate: widget.gate),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Pre-flight checklist',
              subtitle: 'Tap to complete',
            ),
          ),
          SliverList.separated(
            itemCount: _checklist.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTokens.space2),
            itemBuilder: (_, i) => Pressable(
              scale: 0.99,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (_checked.contains(i)) {
                    _checked.remove(i);
                  } else {
                    _checked.add(i);
                  }
                });
              },
              child: PremiumCard(
                padding: const EdgeInsets.all(AppTokens.space3),
                borderColor: _checked.contains(i)
                    ? widget.tone.withValues(alpha: 0.40)
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _checked.contains(i)
                            ? widget.tone
                            : widget.tone.withValues(alpha: 0.18),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _checked.contains(i)
                            ? Icons.check_rounded
                            : _checklist[i].$1,
                        color:
                            _checked.contains(i) ? Colors.white : widget.tone,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_checklist[i].$2,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              )),
                          Text(_checklist[i].$3,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Immigration prep',
              subtitle: 'Things you will need at NRT',
            ),
          ),
          SliverToBoxAdapter(
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              mainAxisSpacing: AppTokens.space2,
              crossAxisSpacing: AppTokens.space2,
              children: const [
                _ImmigrationTile(
                    icon: Icons.assignment_ind_rounded,
                    title: 'Passport',
                    subtitle: 'P1234567 · valid 2030'),
                _ImmigrationTile(
                    icon: Icons.verified_rounded,
                    title: 'eVisa',
                    subtitle: 'Active · valid 15 Aug'),
                _ImmigrationTile(
                    icon: Icons.location_on_rounded,
                    title: 'Address',
                    subtitle: 'Aman Tokyo'),
                _ImmigrationTile(
                    icon: Icons.health_and_safety_rounded,
                    title: 'Customs',
                    subtitle: 'Nothing to declare'),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: AgenticBand(
              title: 'When you land',
              chips: [
                AgenticChip(
                  icon: Icons.qr_code_rounded,
                  label: 'Open immigration kiosk',
                  route: '/kiosk-sim',
                  tone: const Color(0xFF10B981),
                ),
                AgenticChip(
                  icon: Icons.local_taxi_rounded,
                  label: 'Airport pickup',
                  route: '/services/rides',
                  tone: const Color(0xFFEA580C),
                ),
                AgenticChip(
                  icon: Icons.sim_card_rounded,
                  label: 'Activate eSIM',
                  route: '/services',
                  tone: const Color(0xFF7E22CE),
                ),
                AgenticChip(
                  icon: Icons.translate_rounded,
                  label: 'Welcome to Japan',
                  route: '/copilot',
                  tone: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: CinematicButton(
              label: 'Open boarding pass',
              icon: Icons.flight_rounded,
              gradient: LinearGradient(
                colors: [widget.tone, widget.tone.withValues(alpha: 0.55)],
              ),
              onPressed: () {
                HapticFeedback.heavyImpact();
                GoRouter.of(context).push(
                  '/boarding/trp-001/leg-ua837',
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space9)),
        ],
      ),
    );
  }

  static const _checklist = <(IconData, String, String)>[
    (Icons.qr_code_rounded, 'Mobile boarding pass', 'Loaded · TSA Pre-check'),
    (Icons.luggage_rounded, 'Bag drop', '2 checked · 7 kg carry-on'),
    (Icons.security_rounded, 'Security', '18 min wait at TSA-Pre'),
    (Icons.local_atm_rounded, 'Currency', 'JPY 80,000 loaded'),
    (
      Icons.battery_charging_full_rounded,
      'Power-ups',
      'Phone 92% · power bank 100%'
    ),
    (Icons.water_drop_rounded, 'Hydrate', 'Refill at gate fountain'),
    (Icons.bedtime_rounded, 'Jet-lag', 'Sleep window 22:00–06:00 local'),
    (Icons.medical_services_rounded, 'Meds', 'Carry-on accessible'),
  ];
}

class _ImmigrationTile extends StatelessWidget {
  const _ImmigrationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      glass: false,
      elevation: PremiumElevation.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 14),
          ),
          const Spacer(),
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _TerminalPainter extends CustomPainter {
  const _TerminalPainter({required this.tone, required this.gate});
  final Color tone;
  final String gate;
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF111827),
          const Color(0xFF1F2937),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Terminal trunk
    final corridor = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(40, size.height / 2),
      Offset(size.width - 40, size.height / 2),
      corridor,
    );

    // Branches (gates)
    final branch = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final positions = <Offset>[];
    final step = (size.width - 80) / 6;
    for (var i = 0; i < 6; i++) {
      final x = 40 + step * (i + 0.5);
      final dy = i.isEven ? -54.0 : 54.0;
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x, size.height / 2 + dy),
        branch,
      );
      positions.add(Offset(x, size.height / 2 + dy));
    }

    // Lounge marker
    canvas.drawCircle(
      Offset(40 + step * 0.5, size.height / 2 - 54),
      11,
      Paint()..color = const Color(0xFFD97706),
    );

    // Active gate
    final activePos = positions[3];
    canvas.drawCircle(activePos, 14, Paint()..color = tone);
    canvas.drawCircle(activePos, 8, Paint()..color = Colors.white);

    // Gate label
    final tp = TextPainter(
      text: TextSpan(
        text: 'GATE $gate',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.6,
          shadows: [
            Shadow(
              color: Color(0x66000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(activePos.dx - tp.width / 2, activePos.dy + 18));

    final tpL = TextPainter(
      text: const TextSpan(
        text: 'POLARIS',
        style: TextStyle(
          color: Color(0xFFD97706),
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpL.paint(
        canvas, Offset(40 + step * 0.5 - tpL.width / 2, size.height / 2 - 84));
  }

  @override
  bool shouldRepaint(covariant _TerminalPainter old) =>
      old.tone != tone || old.gate != gate;
}
