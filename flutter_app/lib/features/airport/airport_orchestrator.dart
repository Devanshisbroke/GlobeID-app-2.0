import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../boarding_pass/boarding_gate_clock.dart';
import 'airport_journey_strip.dart';

/// Airport orchestration — terminal maps, gate info, connection timers,
/// amenity chips, and real-time gate assignment simulation.
class AirportOrchestratorScreen extends StatefulWidget {
  const AirportOrchestratorScreen({super.key});
  @override
  State<AirportOrchestratorScreen> createState() => _AirportOrchestratorState();
}

class _AirportOrchestratorState extends State<AirportOrchestratorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final String _gate = 'B44';
  final int _walkMin = 8;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Airport Mode',
      subtitle: 'FRA · Frankfurt International',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppTokens.space5, 0, AppTokens.space5, AppTokens.space9),
        children: [
          // ── Premium gate clock + journey strip ─────────────
          AnimatedAppearance(
            child: BoardingGateClock(
              gate: _gate,
              boardingTime:
                  DateTime.now().add(const Duration(minutes: 28)),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 40),
            child: const AirportJourneyStrip(
              activeIndex: 2,
              stages: [
                AirportStage(
                    id: 'check-in',
                    title: 'Check-in',
                    icon: Icons.assignment_turned_in_rounded,
                    subtitle: 'OK'),
                AirportStage(
                    id: 'security',
                    title: 'Security',
                    icon: Icons.shield_rounded,
                    subtitle: '6 min'),
                AirportStage(
                    id: 'lounge',
                    title: 'Lounge',
                    icon: Icons.weekend_rounded,
                    subtitle: 'Open'),
                AirportStage(
                    id: 'gate',
                    title: 'Gate',
                    icon: Icons.airplane_ticket_rounded,
                    subtitle: 'B44'),
                AirportStage(
                    id: 'boarding',
                    title: 'Boarding',
                    icon: Icons.airline_seat_recline_normal_rounded,
                    subtitle: '14:25'),
                AirportStage(
                    id: 'onboard',
                    title: 'Onboard',
                    icon: Icons.flight_takeoff_rounded),
                AirportStage(
                    id: 'arrival',
                    title: 'Arrival',
                    icon: Icons.flag_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          // ── Live gate card ─────────────────────────────────
          AnimatedAppearance(child: _GateHero(gate: _gate, pulse: _pulse, walkMin: _walkMin)),
          const SizedBox(height: AppTokens.space4),

          // ── Connection timer ───────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: _ConnectionTimer()),
          const SizedBox(height: AppTokens.space4),

          // ── Terminal map ────────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 140),
            child: _TerminalMap()),
          const SizedBox(height: AppTokens.space4),

          // ── Amenities ──────────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: _AmenitiesGrid()),
          const SizedBox(height: AppTokens.space4),

          // ── Lounge status ──────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 260),
            child: _LoungeStatus()),
          const SizedBox(height: AppTokens.space4),

          // ── Quick actions ──────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 320),
            child: _QuickActions()),
        ],
      ),
    );
  }
}

class _GateHero extends StatelessWidget {
  const _GateHero({required this.gate, required this.pulse, required this.walkMin});
  final String gate; final Animation<double> pulse; final int walkMin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(children: [
        Row(children: [
          AnimatedBuilder(animation: pulse, builder: (_, __) => Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: const Color(0xFF22C55E).withValues(alpha: 0.5 + 0.5 * pulse.value),
              boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.3 * pulse.value), blurRadius: 8)],
            ),
          )),
          const SizedBox(width: 8),
          Text('LIVE GATE ASSIGNMENT', style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800, letterSpacing: 1.4, color: const Color(0xFF22C55E))),
        ]),
        const SizedBox(height: AppTokens.space4),
        Text(gate, style: theme.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w900, letterSpacing: 2,
          fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 4),
        Text('Terminal 1 · Concourse B', style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: AppTokens.space3),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            color: theme.colorScheme.primary.withValues(alpha: 0.12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.directions_walk_rounded, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text('$walkMin min walk from current location',
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ])),
        const SizedBox(height: AppTokens.space3),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _GateMeta(label: 'Boarding', value: '14:35'),
          _GateMeta(label: 'Departure', value: '15:10'),
          _GateMeta(label: 'Status', value: 'On Time', color: const Color(0xFF22C55E)),
        ]),
      ]),
    );
  }
}

class _GateMeta extends StatelessWidget {
  const _GateMeta({required this.label, required this.value, this.color});
  final String label, value; final Color? color;
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(label, style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(value, style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800, color: color,
        fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

class _ConnectionTimer extends StatelessWidget {
  const _ConnectionTimer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 6),
              Text('Connection Timer',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                ),
                child: const Text('TIGHT',
                    style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              _ConnLeg(code: 'FRA', terminal: 'T1', gate: 'A22', time: '12:40'),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    Text('52 min layover',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _ConnLeg(code: 'FRA', terminal: 'T1', gate: 'B44', time: '13:32'),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Container(
            padding: const EdgeInsets.all(AppTokens.space3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_run_rounded,
                    color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Walk briskly. Gate B44 is 12 min from A22 via tunnel.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                    ),
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

class _ConnLeg extends StatelessWidget {
  const _ConnLeg({required this.code, required this.terminal, required this.gate, required this.time});
  final String code, terminal, gate, time;
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(code, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      Text('$terminal · $gate', style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      Text(time, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()])),
    ]);
  }
}

class _TerminalMap extends StatelessWidget {
  const _TerminalMap();
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.map_rounded, color: Color(0xFF0EA5E9), size: 18),
          const SizedBox(width: 6),
          Text('Terminal Map', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: AppTokens.space3),
        Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04)),
          child: CustomPaint(painter: _TerminalPainter(theme: theme), size: const Size.square(double.infinity)),
        ),
        const SizedBox(height: AppTokens.space2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _MapLegend(color: const Color(0xFF22C55E), label: 'You'),
          const SizedBox(width: 16),
          _MapLegend(color: const Color(0xFFEF4444), label: 'Gate'),
          const SizedBox(width: 16),
          _MapLegend(color: const Color(0xFFF59E0B), label: 'Lounge'),
        ]),
      ]),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.color, required this.label});
  final Color color; final String label;
  @override Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    const SizedBox(width: 4),
    Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
  ]);
}

class _TerminalPainter extends CustomPainter {
  _TerminalPainter({required this.theme});
  final ThemeData theme;
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.12)
      ..strokeWidth = 1.5..style = PaintingStyle.stroke;
    // Simplified terminal outline
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 0.9, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..close();
    canvas.drawPath(path, linePaint);
    // Concourse lines
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.7), linePaint);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7), linePaint);
    canvas.drawLine(Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.7), linePaint);
    // You dot
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.5), 6,
      Paint()..color = const Color(0xFF22C55E));
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.5), 10,
      Paint()..color = const Color(0xFF22C55E).withValues(alpha: 0.2));
    // Gate dot
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.45), 6,
      Paint()..color = const Color(0xFFEF4444));
    // Lounge dot
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.38), 5,
      Paint()..color = const Color(0xFFF59E0B));
    // Labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, offset) in [
      ('A', Offset(size.width * 0.2, size.height * 0.45)),
      ('B', Offset(size.width * 0.4, size.height * 0.45)),
      ('C', Offset(size.width * 0.6, size.height * 0.45)),
    ]) {
      tp.text = TextSpan(text: label, style: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        fontSize: 12, fontWeight: FontWeight.w800));
      tp.layout(); tp.paint(canvas, offset);
    }
  }
  @override bool shouldRepaint(covariant _TerminalPainter old) => false;
}

class _AmenitiesGrid extends StatelessWidget {
  const _AmenitiesGrid();
  static const _amenities = [
    (Icons.wifi_rounded, 'Free WiFi', 'globeid-guest'),
    (Icons.shower_rounded, 'Showers', '4 available'),
    (Icons.restaurant_rounded, 'Dining', '12 options nearby'),
    (Icons.shopping_bag_rounded, 'Duty Free', '8 min walk'),
    (Icons.local_pharmacy_rounded, 'Pharmacy', 'Gate A area'),
    (Icons.currency_exchange_rounded, 'FX', 'Mid-market rates'),
    (Icons.child_care_rounded, 'Kids Zone', 'Near gate A15'),
    (Icons.power_rounded, 'Charging', 'Every 4th seat'),
  ];
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('AMENITIES NEARBY', style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800, letterSpacing: 1.4,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
      const SizedBox(height: AppTokens.space3),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final a in _amenities)
          GlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(a.$1, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.$2, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(a.$3, style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              ]),
            ]),
          ),
      ]),
    ]);
  }
}

class _LoungeStatus extends StatelessWidget {
  const _LoungeStatus();
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.weekend_rounded, color: Color(0xFFD4AF37), size: 18),
          const SizedBox(width: 6),
          Text('Senator Lounge', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              color: const Color(0xFF22C55E).withValues(alpha: 0.15)),
            child: const Text('OPEN', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: AppTokens.space3),
        _LoungeMeta(label: 'Location', value: 'Concourse A · Gate A22'),
        _LoungeMeta(label: 'Walk time', value: '4 min from you'),
        _LoungeMeta(label: 'Capacity', value: '32% · Light'),
        _LoungeMeta(label: 'Showers', value: '4 available · no queue'),
        _LoungeMeta(label: 'Hours', value: '05:30 – 23:30'),
        const SizedBox(height: AppTokens.space3),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final c in ['☕ Coffee', '🍽 Hot food', '🍷 Bar', '🚿 Showers', '😴 Sleep pods', '👶 Kids'])
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
              child: Text(c, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600))),
        ]),
      ]),
    );
  }
}

class _LoungeMeta extends StatelessWidget {
  const _LoungeMeta({required this.label, required this.value});
  final String label, value;
  @override Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: t.textTheme.bodySmall?.copyWith(
          color: t.colorScheme.onSurface.withValues(alpha: 0.5)))),
        Text(value, style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
      ]));
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('QUICK ACTIONS', style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800, letterSpacing: 1.4,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
      const SizedBox(height: AppTokens.space3),
      Row(children: [
        _ActionButton(icon: Icons.qr_code_scanner_rounded, label: 'Scan Pass',
          onTap: () => GoRouter.of(context).push('/scan')),
        const SizedBox(width: 8),
        _ActionButton(icon: Icons.sim_card_rounded, label: 'Buy eSIM',
          onTap: () => GoRouter.of(context).push('/esim')),
        const SizedBox(width: 8),
        _ActionButton(icon: Icons.translate_rounded, label: 'Phrasebook',
          onTap: () => GoRouter.of(context).push('/phrasebook')),
      ]),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(child: Pressable(scale: 0.95, onTap: () {
      HapticFeedback.lightImpact(); onTap();
    }, child: GlassSurface(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
      child: Column(children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
      ]),
    )));
  }
}
