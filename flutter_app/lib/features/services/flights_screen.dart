import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/airline_brand.dart';
import '../../domain/airports.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import '_bespoke_scaffold.dart';

/// Flights — Skyscanner-grade flight search with origin/destination
/// inputs, flexible-date strip, deterministic fare cards, animated
/// route preview, and a premium booking sheet.
class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key});

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
  static const _tone = Color(0xFF0EA5E9);

  String _from = 'SFO';
  String _to = 'NRT';
  int _dayOffset = 7;
  String _cabin = 'eco';

  /// Pure deterministic departure label for a given day offset, used
  /// to drive the Solari callsign board.
  String _depTimeFor(int offset) {
    final base = DateTime.now().add(Duration(days: offset));
    final hh =
        ((base.day * 7 + offset * 3) % 18 + 5).toString().padLeft(2, '0');
    final mm = ((base.day * 13) % 12 * 5).toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static const _filters = <BespokeFilter>[
    BespokeFilter(
        key: 'eco',
        label: 'Economy',
        icon: Icons.airline_seat_recline_normal_rounded),
    BespokeFilter(
        key: 'premium',
        label: 'Premium',
        icon: Icons.airline_seat_recline_extra_rounded),
    BespokeFilter(
        key: 'business',
        label: 'Business',
        icon: Icons.business_center_rounded),
    BespokeFilter(
        key: 'first', label: 'First', icon: Icons.workspace_premium_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Flights',
      subtitle: 'Smart routes · pricing intelligence · live cards',
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedAppearance(
              child: _SearchHero(
                from: _from,
                to: _to,
                onSwap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    final t = _from;
                    _from = _to;
                    _to = t;
                  });
                },
                onPickFrom: () => _pickAirport(true),
                onPickTo: () => _pickAirport(false),
                tone: _tone,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space3,
              AppTokens.space5,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: AnimatedAppearance(
                delay: const Duration(milliseconds: 80),
                child: FlightCallsignBoard(
                  callsign: 'GID 001',
                  fromIata: _from,
                  toIata: _to,
                  depart: _depTimeFor(_dayOffset),
                  gate: 'A12',
                  tone: _tone,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space4)),
          SliverToBoxAdapter(
            child: _FlexDateStrip(
              activeOffset: _dayOffset,
              onPick: (i) {
                HapticFeedback.selectionClick();
                setState(() => _dayOffset = i);
              },
              tone: _tone,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space4)),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: AppTokens.space2),
                      child: _CabinChip(
                        filter: f,
                        active: f.key == _cabin,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _cabin = f.key);
                        },
                        tone: _tone,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space4)),
          SliverToBoxAdapter(
            child: _RoutePreview(
              from: _from,
              to: _to,
              tone: _tone,
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Best matches',
              subtitle: 'Sorted by value · live pricing',
            ),
          ),
          SliverList.separated(
            itemCount: _fares.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTokens.space2),
            itemBuilder: (_, i) {
              final fare = _fares[i];
              return AnimatedAppearance(
                delay: Duration(milliseconds: 60 * i),
                child: Pressable(
                  scale: 0.985,
                  onTap: () => _showFareDetail(context, fare),
                  child: _FareCard(
                    fare: fare,
                    tone: _tone,
                    from: _from,
                    to: _to,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: AgenticBand(
              title: 'Continue your journey',
              chips: [
                AgenticChip(
                  icon: Icons.hotel_rounded,
                  label: 'Hotels in $_to',
                  eyebrow: 'next',
                  route: '/services/hotels',
                  tone: const Color(0xFF7E22CE),
                ),
                AgenticChip(
                  icon: Icons.local_taxi_rounded,
                  label: 'Airport transfer',
                  eyebrow: 'ground',
                  route: '/services/rides',
                  tone: const Color(0xFFEA580C),
                ),
                AgenticChip(
                  icon: Icons.assignment_ind_rounded,
                  label: 'Visa for $_to',
                  eyebrow: 'docs',
                  route: '/identity',
                  tone: const Color(0xFF059669),
                ),
                AgenticChip(
                  icon: Icons.airline_seat_recline_extra_rounded,
                  label: 'Lounge access',
                  eyebrow: 'pre-flight',
                  route: '/services',
                  tone: const Color(0xFFD97706),
                ),
                AgenticChip(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Travel checklist',
                  eyebrow: 'prep',
                  route: '/planner',
                  tone: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space9)),
        ],
      ),
    );
  }

  Future<void> _pickAirport(bool isFrom) async {
    final airports = kAirports;
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (ctx) => _AirportPicker(airports: airports),
    );
    if (result != null) {
      setState(() {
        if (isFrom) {
          _from = result;
        } else {
          _to = result;
        }
      });
    }
  }

  void _showFareDetail(BuildContext context, _Fare fare) {
    showBespokeDetail(
      context: context,
      builder: (sheetCtx, scroll) {
        final theme = Theme.of(sheetCtx);
        final brand = resolveAirlineBrand(fare.airline);
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space5, vertical: AppTokens.space3),
          children: [
            CinematicHero(
              eyebrow: '${fare.airline} · ${fare.flightNumber}',
              title: '$_from → $_to',
              subtitle:
                  '${fare.duration} · ${fare.stops == 0 ? 'Non-stop' : '${fare.stops} stop'} · ${fare.aircraft}',
              icon: Icons.flight_takeoff_rounded,
              tone: brand.color,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brand.color, brand.color.withValues(alpha: 0.5)],
              ),
              badges: [
                HeroBadge(
                  label: '\$${fare.price.toStringAsFixed(0)}',
                  icon: Icons.payments_rounded,
                ),
                HeroBadge(
                  label: '${(fare.scoreOnTime * 100).round()}% on-time',
                  icon: Icons.timer_rounded,
                ),
                HeroBadge(
                  label: 'CO₂ ${fare.co2.toStringAsFixed(0)} kg',
                  icon: Icons.eco_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space5),
            _ItineraryCard(fare: fare, from: _from, to: _to),
            const SizedBox(height: AppTokens.space5),
            Text('Cabin · $_cabin', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.space3),
            _AmenitiesGrid(fare: fare),
            const SizedBox(height: AppTokens.space5),
            Text('Fare class', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.space3),
            for (final c in const [
              ('Saver', 'Carry-on only · refundable for credit', '\$0'),
              ('Standard', 'Checked bag · seat select · meals', '+\$80'),
              ('Flex', 'Free changes · priority boarding · lounge', '+\$220'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: brand.color.withValues(alpha: 0.16),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.style_rounded,
                            size: 16, color: brand.color),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.$1,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(c.$2,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                )),
                          ],
                        ),
                      ),
                      Text(c.$3,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: brand.color,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.space5),
            CinematicButton(
              label: 'Book · \$${fare.price.toStringAsFixed(0)}',
              icon: Icons.flight_takeoff_rounded,
              gradient: LinearGradient(
                colors: [brand.color, brand.color.withValues(alpha: 0.65)],
              ),
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.of(sheetCtx).maybePop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Hold placed · ${fare.airline} ${fare.flightNumber}'),
                    backgroundColor: brand.color,
                  ),
                );
              },
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        );
      },
    );
  }

  static const List<_Fare> _fares = [
    _Fare(
      airline: 'United',
      flightNumber: 'UA837',
      duration: '11h 05m',
      stops: 0,
      price: 942,
      depart: '09:25',
      arrive: '12:30+1',
      aircraft: 'Boeing 787-9',
      scoreOnTime: 0.86,
      co2: 580,
    ),
    _Fare(
      airline: 'ANA',
      flightNumber: 'NH7',
      duration: '11h 25m',
      stops: 0,
      price: 1080,
      depart: '11:15',
      arrive: '14:40+1',
      aircraft: 'Boeing 777-300ER',
      scoreOnTime: 0.92,
      co2: 612,
    ),
    _Fare(
      airline: 'Japan Airlines',
      flightNumber: 'JL1',
      duration: '11h 35m',
      stops: 0,
      price: 1115,
      depart: '13:00',
      arrive: '16:35+1',
      aircraft: 'Boeing 787-9',
      scoreOnTime: 0.94,
      co2: 565,
    ),
    _Fare(
      airline: 'Singapore',
      flightNumber: 'SQ33',
      duration: '14h 20m',
      stops: 1,
      price: 880,
      depart: '23:55',
      arrive: '06:15+2',
      aircraft: 'Airbus A350-900',
      scoreOnTime: 0.91,
      co2: 670,
    ),
    _Fare(
      airline: 'Delta',
      flightNumber: 'DL167',
      duration: '11h 40m',
      stops: 0,
      price: 990,
      depart: '14:35',
      arrive: '18:15+1',
      aircraft: 'Airbus A350-900',
      scoreOnTime: 0.88,
      co2: 590,
    ),
  ];
}

class _Fare {
  const _Fare({
    required this.airline,
    required this.flightNumber,
    required this.duration,
    required this.stops,
    required this.price,
    required this.depart,
    required this.arrive,
    required this.aircraft,
    required this.scoreOnTime,
    required this.co2,
  });
  final String airline;
  final String flightNumber;
  final String duration;
  final int stops;
  final double price;
  final String depart;
  final String arrive;
  final String aircraft;
  final double scoreOnTime;
  final double co2;
}

class _SearchHero extends StatelessWidget {
  const _SearchHero({
    required this.from,
    required this.to,
    required this.onSwap,
    required this.onPickFrom,
    required this.onPickTo,
    required this.tone,
  });
  final String from;
  final String to;
  final VoidCallback onSwap;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard.hero(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [tone, tone.withValues(alpha: 0.55)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AirportField(
                  label: 'FROM',
                  code: from,
                  onTap: onPickFrom,
                  airport: getAirport(from),
                ),
              ),
              Pressable(
                scale: 0.9,
                onTap: onSwap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child:
                      const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                ),
              ),
              Expanded(
                child: _AirportField(
                  label: 'TO',
                  code: to,
                  onTap: onPickTo,
                  airport: getAirport(to),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text('Mon, 12 Jun · Round-trip',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              const Icon(Icons.person_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text('1 traveler',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _AirportField extends StatelessWidget {
  const _AirportField({
    required this.label,
    required this.code,
    required this.onTap,
    required this.airport,
  });
  final String label;
  final String code;
  final VoidCallback onTap;
  final Airport? airport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space3, vertical: AppTokens.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                )),
            const SizedBox(height: 4),
            Text(code,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                )),
            if (airport != null)
              Text(airport!.city,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _FlexDateStrip extends StatelessWidget {
  const _FlexDateStrip({
    required this.activeOffset,
    required this.onPick,
    required this.tone,
  });

  final int activeOffset;
  final ValueChanged<int> onPick;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = DateTime.utc(2026, 6, 5);
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        physics: const BouncingScrollPhysics(),
        itemCount: 14,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = base.add(Duration(days: i));
          final active = i == activeOffset;
          final price = _priceForOffset(i);
          return Pressable(
            scale: 0.95,
            onTap: () => onPick(i),
            child: AnimatedContainer(
              duration: AppTokens.durationSm,
              curve: AppTokens.easeOutSoft,
              width: 64,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: AppTokens.space2 + 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                color: active
                    ? tone.withValues(alpha: 0.20)
                    : theme.colorScheme.surface.withValues(alpha: 0.55),
                border: Border.all(
                  color: active
                      ? tone.withValues(alpha: 0.6)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.10),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: tone.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_weekdayShort(d.weekday),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: active
                            ? tone
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                      )),
                  Text('${d.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: active ? tone : theme.colorScheme.onSurface,
                      )),
                  const SizedBox(height: 2),
                  Text('\$$price',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: active
                            ? tone
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _weekdayShort(int w) => switch (w) {
        DateTime.monday => 'Mon',
        DateTime.tuesday => 'Tue',
        DateTime.wednesday => 'Wed',
        DateTime.thursday => 'Thu',
        DateTime.friday => 'Fri',
        DateTime.saturday => 'Sat',
        DateTime.sunday => 'Sun',
        _ => '',
      };

  static int _priceForOffset(int offset) {
    final base = 880;
    final wave = (math.sin(offset * 0.7) * 80).round();
    return (base + wave + (offset.isEven ? 40 : 0));
  }
}

class _CabinChip extends StatelessWidget {
  const _CabinChip({
    required this.filter,
    required this.active,
    required this.onTap,
    required this.tone,
  });
  final BespokeFilter filter;
  final bool active;
  final VoidCallback onTap;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        curve: AppTokens.easeOutSoft,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3,
          vertical: AppTokens.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          color: active
              ? tone.withValues(alpha: 0.22)
              : theme.colorScheme.surface.withValues(alpha: 0.55),
          border: Border.all(
            color: active
                ? tone.withValues(alpha: 0.6)
                : theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filter.icon != null) ...[
              Icon(filter.icon,
                  size: 14,
                  color: active
                      ? tone
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
            ],
            Text(filter.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: active
                      ? tone
                      : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                )),
          ],
        ),
      ),
    );
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({
    required this.from,
    required this.to,
    required this.tone,
  });
  final String from;
  final String to;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromAirport = getAirport(from);
    final toAirport = getAirport(to);
    final distance = (fromAirport != null && toAirport != null)
        ? _distance(fromAirport, toAirport)
        : 0;
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, color: tone, size: 18),
              const SizedBox(width: 6),
              Text('Route preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  )),
              const Spacer(),
              if (distance > 0)
                Text('${distance.toStringAsFixed(0)} km',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          SizedBox(
            height: 90,
            child: CustomPaint(
              size: Size.infinite,
              painter: _RouteArcPainter(
                tone: tone,
                from: from,
                to: to,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _distance(Airport a, Airport b) {
    const r = 6371.0;
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLng = (b.lng - a.lng) * math.pi / 180;
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }
}

class _RouteArcPainter extends CustomPainter {
  const _RouteArcPainter(
      {required this.tone, required this.from, required this.to});
  final Color tone;
  final String from;
  final String to;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(28, size.height * 0.7);
    final end = Offset(size.width - 28, size.height * 0.7);
    final mid = Offset((start.dx + end.dx) / 2, size.height * 0.18);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [tone.withValues(alpha: 0.4), tone],
      ).createShader(Rect.fromPoints(start, end));
    canvas.drawPath(path, paint);

    // Dashed shadow
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = tone.withValues(alpha: 0.20);
    final dashes = 28;
    for (var i = 0; i < dashes; i++) {
      if (i.isEven) continue;
      final t1 = i / dashes;
      final t2 = (i + 1) / dashes;
      canvas.drawPath(
        _arcSegment(path, t1, t2),
        shadow,
      );
    }

    // End markers
    final pmark = Paint()..color = tone;
    canvas.drawCircle(start, 5.5, pmark);
    canvas.drawCircle(end, 5.5, pmark);
    canvas.drawCircle(start, 3, Paint()..color = Colors.white);
    canvas.drawCircle(end, 3, Paint()..color = Colors.white);

    // Label codes
    final tp1 = TextPainter(
      text: TextSpan(
        text: from,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.4),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(start.dx - tp1.width / 2, start.dy + 8));

    final tp2 = TextPainter(
      text: TextSpan(
        text: to,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.4),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(end.dx - tp2.width / 2, end.dy + 8));

    // Plane along the arc
    final planeT = 0.55;
    final pos = _bezier(start, mid, end, planeT);
    final tang = _bezier(start, mid, end, planeT + 0.01);
    final angle = math.atan2(tang.dy - pos.dy, tang.dx - pos.dx);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    final tri = Path()
      ..moveTo(8, 0)
      ..lineTo(-6, -4)
      ..lineTo(-6, 4)
      ..close();
    canvas.drawPath(tri, Paint()..color = Colors.white);
    canvas.restore();
  }

  Offset _bezier(Offset a, Offset b, Offset c, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * a.dx + 2 * mt * t * b.dx + t * t * c.dx,
      mt * mt * a.dy + 2 * mt * t * b.dy + t * t * c.dy,
    );
  }

  Path _arcSegment(Path full, double t1, double t2) {
    final m = full.computeMetrics().first;
    return m.extractPath(m.length * t1, m.length * t2);
  }

  @override
  bool shouldRepaint(covariant _RouteArcPainter old) =>
      old.tone != tone || old.from != from || old.to != to;
}

class _FareCard extends StatelessWidget {
  const _FareCard({
    required this.fare,
    required this.tone,
    required this.from,
    required this.to,
  });
  final _Fare fare;
  final Color tone;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = resolveAirlineBrand(fare.airline);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  gradient: LinearGradient(
                    colors: [brand.color, brand.color.withValues(alpha: 0.55)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  brand.shortCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space2 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${fare.airline} ${fare.flightNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    Text(fare.aircraft,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        )),
                  ],
                ),
              ),
              Text('\$${fare.price.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fare.depart,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                  Text(from,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  children: [
                    Text(fare.duration,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fare.stops == 0 ? 'Non-stop' : '${fare.stops} stop',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: fare.stops == 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFD97706),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fare.arrive,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                  Text(to,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              _MicroChip(
                  icon: Icons.timer_rounded,
                  label: '${(fare.scoreOnTime * 100).round()}% on-time'),
              const SizedBox(width: 6),
              _MicroChip(
                  icon: Icons.eco_rounded,
                  label: 'CO₂ ${fare.co2.toStringAsFixed(0)} kg'),
              const SizedBox(width: 6),
              _MicroChip(icon: Icons.wifi_rounded, label: 'Wi-Fi'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicroChip extends StatelessWidget {
  const _MicroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 3),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              )),
        ],
      ),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({
    required this.fare,
    required this.from,
    required this.to,
  });
  final _Fare fare;
  final String from;
  final String to;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Itinerary', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 64,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${fare.depart} · $from',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                    Text(getAirport(from)?.name ?? '—',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                      child: Text(
                          '${fare.duration} · ${fare.stops == 0 ? 'Non-stop' : 'Stop'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    const SizedBox(height: 8),
                    Text('${fare.arrive} · $to',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                    Text(getAirport(to)?.name ?? '—',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmenitiesGrid extends StatelessWidget {
  const _AmenitiesGrid({required this.fare});
  final _Fare fare;
  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.wifi_rounded, 'Wi-Fi'),
      (Icons.power_rounded, 'Power outlet'),
      (Icons.movie_creation_rounded, 'IFE'),
      (Icons.restaurant_rounded, 'Hot meals'),
      (Icons.luggage_rounded, '23 kg bag'),
      (Icons.airline_seat_legroom_extra_rounded, '32" pitch'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 2.0,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final i in items)
          PremiumCard(
            padding: const EdgeInsets.all(8),
            glass: false,
            elevation: PremiumElevation.sm,
            child: Row(
              children: [
                Icon(i.$1,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(i.$2,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AirportPicker extends StatelessWidget {
  const _AirportPicker({required this.airports});
  final List<Airport> airports;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTokens.space3),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
            ),
            Text('Choose airport', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTokens.space3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: airports.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: () => Navigator.of(context).pop(airports[i].iata),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.space2 + 2),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.14),
                          ),
                          child: Text(
                            airports[i].iata,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(airports[i].name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )),
                              Text(
                                  '${airports[i].city} · ${airports[i].country}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
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

extension _AirlineBrandX on AirlineBrand {
  Color get color => primary;
  String get shortCode => iata.startsWith('__') ? 'XX' : iata;
}
