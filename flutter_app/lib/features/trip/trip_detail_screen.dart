import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/lifecycle.dart';
import '../../data/models/travel_record.dart';
import '../../domain/airline_brand.dart';
import '../../domain/airports.dart';
import '../../domain/connection_detector.dart';
import '../../domain/packing_list.dart';
import '../../domain/predictive_departure.dart';
import '../../nexus/chrome/nexus_legacy_scaffold.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../lifecycle/lifecycle_provider.dart';
import '../user/user_provider.dart';
import 'pre_trip_intel.dart';
import 'trip_intel_cards.dart';

/// Immersive trip detail. Hero brand-tinted backdrop, animated leg
/// timeline (IATA → IATA with airplane), per-leg pass card, location +
/// timezone strip, predictive departure card, packing list.
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycle = ref.watch(lifecycleProvider);
    final user = ref.watch(userProvider);
    var trip = lifecycle.trips.cast<TripLifecycle?>().firstWhere(
          (t) => t?.id == tripId,
          orElse: () => null,
        );

    // Travel history records (the `userProvider.records` list) are a
    // superset of the lifecycle store — past flights live there only.
    // If the requested trip isn't in the lifecycle store, derive a
    // minimal TripLifecycle from the matching record so the screen
    // still renders correctly instead of bouncing to an empty state.
    if (trip == null) {
      final TravelRecord? record =
          user.records.cast<TravelRecord?>().firstWhere(
                (r) => r?.id == tripId,
                orElse: () => null,
              );
      if (record != null) {
        trip = TripLifecycle(
          id: record.id,
          name: '${record.from} → ${record.to}',
          stage: record.type == 'past' ? 'past' : 'upcoming',
          legs: [
            FlightLeg(
              id: 'leg-${record.id}',
              from: record.from,
              to: record.to,
              airline: record.airline,
              flightNumber: record.flightNumber ?? '',
              scheduled: '${record.date}T00:00:00Z',
            ),
          ],
          startDate: record.date,
        );
      }
    }
    final theme = Theme.of(context);

    if (trip == null) {
      return const NexusLegacyScaffold(
        eyebrow: 'GLOBE ID · TRAVEL',
        title: 'Trip not found',
        subtitle: 'This trip may have been removed.',
        body: EmptyState(
          title: 'Trip not found',
          message: 'This trip may have been removed.',
          icon: Icons.search_off_rounded,
        ),
      );
    }

    final tightLegIds = detectConnections(trip.legs)
        .where((c) => c.severity == 'tight')
        .map((c) => c.toLegId)
        .toSet();

    final from = trip.legs.isNotEmpty ? trip.legs.first.from : null;
    final to = trip.legs.isNotEmpty ? trip.legs.last.to : null;

    final brand = trip.legs.isNotEmpty
        ? resolveAirlineBrand(trip.legs.first.flightNumber)
        : resolveAirlineBrand('GID');

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            leading: BackButton(onPressed: () => context.pop()),
            stretch: true,
            expandedHeight: 240,
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                trip.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Hero(
                tag: 'trip-${trip.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: brand.gradient()),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppTokens.space5,
                AppTokens.space3, AppTokens.space5, AppTokens.space9),
            sliver: SliverList.list(
              children: [
                AnimatedAppearance(
                  child: Row(
                    children: [
                      PillChip(
                          label: trip.stage.toUpperCase(),
                          icon: Icons.flight_rounded),
                      const SizedBox(width: AppTokens.space2),
                      if (from != null && to != null)
                        PillChip(
                            label: '$from → $to', icon: Icons.route_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space5),
                if (from != null && to != null)
                  AnimatedAppearance(
                    delay: const Duration(milliseconds: 80),
                    child: _RouteHero(from: from, to: to),
                  ),
                if (trip.legs.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.space4),
                  AnimatedAppearance(
                    delay: const Duration(milliseconds: 120),
                    child: FlightCallsignBoard(
                      callsign: trip.legs.first.flightNumber,
                      fromIata: trip.legs.first.from,
                      toIata: trip.legs.last.to,
                      depart: trip.legs.first.scheduled,
                      gate: trip.legs.first.gate,
                      tone: brand.primary,
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.space4),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 140),
                  child: _TripLiveActions(tripId: trip.id),
                ),
                const SizedBox(height: AppTokens.space5),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 160),
                  child: const SectionHeader(title: 'Itinerary', dense: true),
                ),
                _LegList(
                  tripId: trip.id,
                  legs: trip.legs,
                  tightLegIds: tightLegIds,
                ),
                if (trip.legs.isNotEmpty) ...[
                  const SectionHeader(
                      title: 'Predictive departure', dense: true),
                  AnimatedAppearance(
                    delay: const Duration(milliseconds: 240),
                    child: _DepartureCard(leg: trip.legs.first),
                  ),
                ],
                const SectionHeader(title: 'Packing list', dense: true),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 320),
                  child: _PackingCard(trip: trip),
                ),

                // ── Destination intel cluster ──────────────────
                const SectionHeader(title: 'Destination intel', dense: true),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 360),
                  child: _AnchorStrip(anchors: const [
                    'Weather',
                    'Visa',
                    'Currency',
                    'Time',
                    'Health',
                  ]),
                ),
                const SizedBox(height: AppTokens.space3),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 380),
                  child: _WeatherCard(to: to),
                ),
                const SizedBox(height: AppTokens.space3),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 400),
                  child: const _VisaCard(),
                ),
                const SizedBox(height: AppTokens.space3),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 420),
                  child: const _CurrencyCard(),
                ),
                if (to != null && from != null) ...[
                  const SizedBox(height: AppTokens.space3),
                  AnimatedAppearance(
                    delay: const Duration(milliseconds: 440),
                    child: TripTimezoneCard(
                      origin: from,
                      destination: to,
                      offsetHours: _offsetHoursFor(to),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space5),
                  AnimatedAppearance(
                    delay: const Duration(milliseconds: 460),
                    child: PreTripIntel(
                      destination: to,
                      sections: IntelSection.demo(to),
                    ),
                  ),
                ],

                // ── Ground operations ──────────────────────────
                const SectionHeader(title: 'On the ground', dense: true),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 460),
                  child: const _TransportCard(),
                ),
                const SizedBox(height: AppTokens.space3),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 480),
                  child: const _LoungeCard(),
                ),
                const SizedBox(height: AppTokens.space3),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 500),
                  child: const _EsimCard(),
                ),
                const SizedBox(height: AppTokens.space3),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 520),
                  child: const _InsuranceCard(),
                ),

                // ── Spending envelope quick-jump ───────────────
                const SectionHeader(title: 'Spend envelope', dense: true),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 540),
                  child: _TripWalletCta(tripName: trip.name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Anchor strip ──────────────────────────────────────────────
class _AnchorStrip extends StatelessWidget {
  const _AnchorStrip({required this.anchors});
  final List<String> anchors;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: anchors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space3, vertical: 6),
          decoration: BoxDecoration(
            color: t.colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: Border.all(
                color: t.colorScheme.onSurface.withValues(alpha: 0.10)),
          ),
          child: Center(
            child: Text(
              anchors[i],
              style: t.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Weather card ──────────────────────────────────────────────
class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.to});
  final String? to;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.cloud_rounded, color: Color(0xFF06B6D4), size: 18),
            const SizedBox(width: 6),
            Text('Weather · ${to ?? 'Destination'}',
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: AppTokens.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('21°',
                  style: t.textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Mostly cloudy · feels 19°',
                    style: t.textTheme.bodySmall?.copyWith(
                        color:
                            t.colorScheme.onSurface.withValues(alpha: 0.65))),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: const [
              _ForecastTile(
                  time: 'Now', temp: '21°', icon: Icons.cloud_rounded),
              _ForecastTile(
                  time: '12:00', temp: '22°', icon: Icons.wb_sunny_rounded),
              _ForecastTile(
                  time: '15:00', temp: '23°', icon: Icons.wb_sunny_rounded),
              _ForecastTile(
                  time: '18:00', temp: '20°', icon: Icons.cloud_queue_rounded),
              _ForecastTile(
                  time: '21:00', temp: '17°', icon: Icons.nights_stay_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  const _ForecastTile(
      {required this.time, required this.temp, required this.icon});
  final String time;
  final String temp;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(time,
              style: t.textTheme.labelSmall?.copyWith(
                  color: t.colorScheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 4),
          Icon(icon,
              size: 18, color: t.colorScheme.onSurface.withValues(alpha: 0.78)),
          const SizedBox(height: 4),
          Text(temp,
              style: t.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Visa card ─────────────────────────────────────────────────
class _VisaCard extends StatelessWidget {
  const _VisaCard();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
      onTap: () => context.push('/visa-live/JP'),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.assignment_ind_rounded,
                  color: Color(0xFF7C3AED), size: 18),
              const SizedBox(width: 6),
              Text('Visa & entry',
                  style: t.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: const Text('VISA-FREE',
                    style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: t.colorScheme.onSurface.withValues(alpha: 0.45)),
            ]),
            const SizedBox(height: AppTokens.space3),
            const _MetaRow(
                label: 'Stay allowed', value: '90 days within 180-day window'),
            const _MetaRow(
                label: 'Passport validity', value: '6 months beyond entry'),
            const _MetaRow(label: 'Onward ticket', value: 'Required'),
            const _MetaRow(label: 'Customs', value: 'Declare > €10,000'),
          ],
        ),
      ),
    );
  }
}

// ── Currency card ─────────────────────────────────────────────
class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.currency_exchange_rounded,
                color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 6),
            Text('Currency',
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: AppTokens.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1.00 EUR',
                  style: t.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Icon(Icons.arrow_forward_rounded, size: 16),
              Text('1.0863 USD',
                  style: t.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Text('Live mid-market · updated 4m ago',
              style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: AppTokens.space3),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/wallet/exchange'),
                icon: const Icon(Icons.swap_vert_rounded, size: 18),
                label: const Text('Convert'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/multi-currency'),
                icon: const Icon(Icons.show_chart_rounded, size: 18),
                label: const Text('Watchlist'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Transport ─────────────────────────────────────────────────
class _TransportCard extends StatelessWidget {
  const _TransportCard();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.alt_route_rounded,
                color: Color(0xFFEA580C), size: 18),
            const SizedBox(width: 6),
            Text('Transport',
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: AppTokens.space3),
          for (final r in const [
            (
              Icons.train_rounded,
              'Express train',
              '€11.40 · 28 min · every 15 min'
            ),
            (
              Icons.local_taxi_rounded,
              'Premium ride',
              '€44 · 22–35 min · 4.9★ avg'
            ),
            (
              Icons.airport_shuttle_rounded,
              'Airport shuttle',
              '€8 · 38 min · departs xx:05 + xx:35'
            ),
            (Icons.directions_subway_rounded, 'Metro + bus', '€3.20 · 47 min'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Icon(r.$1,
                    size: 18,
                    color: t.colorScheme.onSurface.withValues(alpha: 0.78)),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$2,
                          style: t.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(r.$3,
                          style: t.textTheme.bodySmall?.copyWith(
                              color: t.colorScheme.onSurface
                                  .withValues(alpha: 0.60))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: t.colorScheme.onSurface.withValues(alpha: 0.32)),
              ]),
            ),
        ],
      ),
    );
  }
}

// ── Lounge ────────────────────────────────────────────────────
class _LoungeCard extends StatelessWidget {
  const _LoungeCard();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
      onTap: () => context.push('/lounge-live'),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.weekend_rounded,
                color: Color(0xFFD4AF37), size: 18),
            const SizedBox(width: 6),
            Text('Lounge access',
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
              child: const Text('PRIORITY PASS',
                  style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6)),
            ),
          ]),
          const SizedBox(height: AppTokens.space3),
          _MetaRow(
              label: 'Closest lounge',
              value: 'Senator Lounge · A22 · 4 min walk'),
          _MetaRow(label: 'Open', value: 'Now · until 23:30'),
          _MetaRow(label: 'Capacity', value: 'Light · 32%'),
          _MetaRow(label: 'Showers', value: '4 available'),
        ],
      ),
      ),
    );
  }
}

// ── eSIM ──────────────────────────────────────────────────────
class _EsimCard extends StatelessWidget {
  const _EsimCard();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.sim_card_rounded,
                color: Color(0xFF06B6D4), size: 18),
            const SizedBox(width: 6),
            Text('eSIM',
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: AppTokens.space3),
          Text('Stay connected on arrival',
              style: t.textTheme.bodyMedium?.copyWith(
                  color: t.colorScheme.onSurface.withValues(alpha: 0.78))),
          const SizedBox(height: AppTokens.space3),
          Row(children: const [
            Expanded(
                child: _EsimPlanTile(label: '1 GB · 7 days', price: '€4.50')),
            SizedBox(width: 8),
            Expanded(
                child: _EsimPlanTile(label: '5 GB · 30 days', price: '€11.90')),
            SizedBox(width: 8),
            Expanded(
                child: _EsimPlanTile(label: 'Unlimited · 30d', price: '€34')),
          ]),
        ],
      ),
    );
  }
}

class _EsimPlanTile extends StatelessWidget {
  const _EsimPlanTile({required this.label, required this.price});
  final String label;
  final String price;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: AppTokens.space3, horizontal: 8),
      decoration: BoxDecoration(
        color: t.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border:
            Border.all(color: t.colorScheme.onSurface.withValues(alpha: 0.10)),
      ),
      child: Column(children: [
        Text(label,
            textAlign: TextAlign.center,
            style: t.textTheme.labelSmall?.copyWith(
                color: t.colorScheme.onSurface.withValues(alpha: 0.65))),
        const SizedBox(height: 4),
        Text(price,
            style:
                t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

// ── Insurance ─────────────────────────────────────────────────
class _InsuranceCard extends StatelessWidget {
  const _InsuranceCard();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.health_and_safety_rounded,
                color: Color(0xFFE11D48), size: 18),
            const SizedBox(width: 6),
            Text('Travel insurance',
                style: t.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
              child: const Text('COVERED',
                  style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6)),
            ),
          ]),
          const SizedBox(height: AppTokens.space3),
          _MetaRow(label: 'Provider', value: 'AXA Worldwide Premium'),
          _MetaRow(label: 'Medical', value: 'Up to €1,000,000'),
          _MetaRow(label: 'Trip cancel', value: 'Up to €5,000'),
          _MetaRow(label: 'Baggage', value: 'Up to €2,500'),
          _MetaRow(label: 'Emergency hotline', value: '+44 20 7173 7000'),
        ],
      ),
    );
  }
}

// ── Shared meta row ───────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label,
                style: t.textTheme.bodySmall?.copyWith(
                    color: t.colorScheme.onSurface.withValues(alpha: 0.60))),
          ),
          const SizedBox(width: AppTokens.space3),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: t.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Big horizontal IATA → IATA strip with an airplane traversing.
class _RouteHero extends StatefulWidget {
  const _RouteHero({required this.from, required this.to});
  final String from;
  final String to;

  @override
  State<_RouteHero> createState() => _RouteHeroState();
}

class _RouteHeroState extends State<_RouteHero>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final fromAirport = getAirport(widget.from);
    final toAirport = getAirport(widget.to);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: _IataBlock(
                  code: widget.from,
                  city: fromAirport?.city ?? 'Origin',
                ),
              ),
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 56,
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => CustomPaint(
                      painter: _RouteArc(
                        progress: _ctrl.value,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                child: _IataBlock(
                  code: widget.to,
                  city: toAirport?.city ?? 'Destination',
                  end: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IataBlock extends StatelessWidget {
  const _IataBlock({required this.code, required this.city, this.end = false});
  final String code;
  final String city;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          code.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          city,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: end ? TextAlign.end : TextAlign.start,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _RouteArc extends CustomPainter {
  _RouteArc({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = Offset(size.width / 2, size.height / 2);
    final left = Offset(0, mid.dy);
    final right = Offset(size.width, mid.dy);
    // Dashed line with accent.
    final line = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..strokeWidth = 1.4;
    const dash = 5.0, gap = 4.0;
    var x = left.dx;
    while (x < right.dx) {
      canvas.drawLine(Offset(x, mid.dy), Offset(x + dash, mid.dy), line);
      x += dash + gap;
    }
    // Solid accent endpoints.
    final dot = Paint()..color = color;
    canvas.drawCircle(left.translate(2, 0), 3.5, dot);
    canvas.drawCircle(right.translate(-2, 0), 3.5, dot);
    // Plane glyph.
    final px = left.dx + (right.dx - left.dx) * progress;
    final plane = Paint()..color = color;
    final p = Path()
      ..moveTo(px - 8, mid.dy - 5)
      ..lineTo(px + 6, mid.dy)
      ..lineTo(px - 8, mid.dy + 5)
      ..close();
    canvas.drawPath(p, plane);
    // Glow trail.
    final trail = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 2.4;
    canvas.drawLine(Offset(left.dx, mid.dy), Offset(px - 10, mid.dy), trail);
  }

  @override
  bool shouldRepaint(covariant _RouteArc old) =>
      old.progress != progress || old.color != color;
}

class _LegList extends StatelessWidget {
  const _LegList({
    required this.tripId,
    required this.legs,
    required this.tightLegIds,
  });
  final String tripId;
  final List<FlightLeg> legs;
  final Set<String> tightLegIds;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < legs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space3),
            child: AnimatedAppearance(
              delay: Duration(milliseconds: 200 + i * 60),
              child: InkWell(
                onTap: () => context.push('/boarding/$tripId/${legs[i].id}'),
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                child: GlassSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${legs[i].from} → ${legs[i].to}',
                              style: theme.textTheme.titleLarge),
                          const Spacer(),
                          Text(legs[i].flightNumber,
                              style: theme.textTheme.titleSmall?.copyWith(
                                letterSpacing: 1.4,
                              )),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space2),
                      Wrap(
                        spacing: AppTokens.space2,
                        runSpacing: AppTokens.space2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.access_time_rounded,
                                size: 14,
                                color: theme.textTheme.bodySmall?.color),
                            const SizedBox(width: 4),
                            Text(legs[i].scheduled,
                                style: theme.textTheme.bodySmall),
                          ]),
                          if (legs[i].gate != null)
                            PillChip(label: 'Gate ${legs[i].gate}'),
                          if (legs[i].seat != null)
                            PillChip(label: 'Seat ${legs[i].seat}'),
                          if (tightLegIds.contains(legs[i].id))
                            const PillChip(
                              label: 'Tight conn',
                              icon: Icons.warning_amber_rounded,
                              tone: Color(0xFFD97706),
                            ),
                        ],
                      ),
                      if (getAirport(legs[i].from) != null) ...[
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          '${getAirport(legs[i].from)!.city} → ${getAirport(legs[i].to)?.city ?? legs[i].to}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppTokens.space2),
                      Row(
                        children: [
                          Icon(
                            Icons.airplane_ticket_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Open boarding pass',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
      ],
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.leg});
  final FlightLeg leg;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boarding = DateTime.tryParse(leg.boarding ?? leg.scheduled) ??
        DateTime.now().add(const Duration(hours: 2));
    final est = predictLeaveBy(departureLocal: boarding);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.space2),
              Text('Leave by', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            '${est.leaveBy.hour.toString().padLeft(2, '0')}:${est.leaveBy.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
              '${est.travelTimeMinutes} min travel + ${est.bufferMinutes} min airport buffer',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PackingCard extends StatelessWidget {
  const _PackingCard({required this.trip});
  final TripLifecycle trip;
  @override
  Widget build(BuildContext context) {
    final dest = trip.legs.isNotEmpty ? trip.legs.last.to : 'XXX';
    final destInfo = getAirport(dest);
    final dep = DateTime.tryParse(
            trip.legs.isNotEmpty ? trip.legs.first.scheduled : '') ??
        DateTime.now();
    final items = PackingList.generate(
      destinationCountry: destInfo?.country ?? 'Unknown',
      days: 5,
      departure: dep,
    );
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in items.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                      i.essential
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: i.essential ? Colors.green : Colors.grey),
                  const SizedBox(width: AppTokens.space2),
                  Expanded(child: Text(i.label)),
                  PillChip(label: i.category),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Trip wallet CTA ───────────────────────────────────────────
class _TripWalletCta extends StatelessWidget {
  const _TripWalletCta({required this.tripName});
  final String tripName;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
      onTap: () => context.push('/trip-wallet'),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip wallet · $tripName',
                      style: t.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    'Per-trip envelope · category breakdown · auto-tagging',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: t.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: t.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

/// Deterministic timezone offset between FRA (assumed home) and the
/// destination IATA — used by the [TripTimezoneCard].
int _offsetHoursFor(String iata) {
  return switch (iata.toUpperCase()) {
    'NRT' || 'HND' || 'KIX' || 'NGO' => 8,
    'SIN' || 'KUL' || 'BKK' || 'HKG' || 'TPE' => 7,
    'DXB' || 'AUH' || 'DOH' => 3,
    'JFK' || 'EWR' || 'LGA' || 'BOS' || 'IAD' || 'YUL' || 'YYZ' => -6,
    'LAX' || 'SFO' || 'SEA' || 'PDX' || 'YVR' => -9,
    'GRU' || 'EZE' || 'SCL' => -4,
    'SYD' || 'MEL' || 'AKL' => 10,
    'JNB' || 'CPT' => 1,
    _ => 0,
  };
}

// ─────────────────────────────────────────────────────────────────────
// _TripLiveActions — horizontal row of buttons that open the Live
// surfaces scoped to this trip (boarding, live trip timeline, airport
// companion, immigration, lounge, arrival, navigation, country intel).
// Matches the Pulse home Alive rail but anchored to the trip context.
// ─────────────────────────────────────────────────────────────────────
class _TripLiveActions extends StatelessWidget {
  const _TripLiveActions({required this.tripId});
  final String tripId;

  static const _items = <({String label, IconData icon, Color tone, String route})>[
    (label: 'Boarding', icon: Icons.qr_code_2_rounded, tone: Color(0xFF0EA5E9), route: '/boarding-pass-live'),
    (label: 'Live trip', icon: Icons.timeline_rounded, tone: Color(0xFF6366F1), route: '/trip-timeline-live'),
    (label: 'Airport', icon: Icons.radar_rounded, tone: Color(0xFF60A5FA), route: '/airport-companion-live'),
    (label: 'Immigration', icon: Icons.how_to_reg_rounded, tone: Color(0xFF06B6D4), route: '/immigration-live'),
    (label: 'Lounge', icon: Icons.weekend_rounded, tone: Color(0xFFD4A574), route: '/lounge-live'),
    (label: 'Arrival', icon: Icons.flight_land_rounded, tone: Color(0xFF10B981), route: '/arrival-live'),
    (label: 'Navigate', icon: Icons.alt_route_rounded, tone: Color(0xFF2DD4BF), route: '/navigation-live'),
    (label: 'Country', icon: Icons.public_rounded, tone: Color(0xFFF59E0B), route: '/country-live/JP'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final it = _items[i];
          final route = it.label == 'Live trip'
              ? '/trip-timeline-live/$tripId'
              : it.route;
          return GestureDetector(
            onTap: () => context.push(route),
            child: Container(
              width: 100,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    it.tone.withValues(alpha: 0.20),
                    it.tone.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: it.tone.withValues(alpha: 0.32),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(it.icon, color: it.tone, size: 18),
                  const Spacer(),
                  Text(
                    it.label.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

