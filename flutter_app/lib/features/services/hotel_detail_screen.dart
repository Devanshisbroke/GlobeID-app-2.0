import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// Cinematic hotel detail — opened from the Hotels list.
///
/// Sections:
///   • Cinematic hero (parallax, gradient + aurora)
///   • Rooms carousel (3 deterministic options with rates)
///   • Amenity grid (12 tiles, tone-tinted)
///   • Neighborhood (walkable POIs strip)
///   • Reviews (3 anchored quotes + composite score)
///   • Map preview (gradient grid + pin)
///   • Booking footer with CinematicButton
///
/// All sub-pieces are pure Flutter, deterministic, no network.
///
/// Route args carrier — passed via go_router `extra` so we can deep-link
/// `/services/hotels/detail` from the bespoke list sheet without losing the
/// per-item context (tonality, price, flag).
class HotelDetailArgs {
  const HotelDetailArgs({
    required this.hotelName,
    required this.city,
    required this.country,
    required this.tonality,
    required this.rating,
    required this.pricePerNight,
    required this.flag,
  });

  final String hotelName;
  final String city;
  final String country;
  final Color tonality;
  final double rating;
  final double pricePerNight;
  final String flag;
}

class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({
    super.key,
    required this.hotelName,
    required this.city,
    required this.country,
    required this.tonality,
    required this.rating,
    required this.pricePerNight,
    required this.flag,
  });

  final String hotelName;
  final String city;
  final String country;
  final Color tonality;
  final double rating;
  final double pricePerNight;
  final String flag;

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  int _selectedRoom = 1;
  int _selectedNights = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _rooms[_selectedRoom].pricePerNight * _selectedNights;
    return PageScaffold(
      title: widget.hotelName,
      subtitle: '${widget.flag} ${widget.city} · ${widget.country}',
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: AnimatedAppearance(
                  child: CinematicHero(
                    eyebrow: '${(widget.rating).toStringAsFixed(1)}★ · ICON',
                    title: widget.hotelName,
                    subtitle:
                        '${widget.city} · 33rd-floor sky pool · spa · concierge',
                    icon: Icons.hotel_rounded,
                    flag: widget.flag,
                    tone: widget.tonality,
                    badges: [
                      const HeroBadge(
                          label: 'Free cancellation',
                          icon: Icons.event_available_rounded),
                      HeroBadge(
                          label:
                              'From \$${widget.pricePerNight.toStringAsFixed(0)}/n',
                          icon: Icons.payments_rounded),
                      const HeroBadge(
                          label: '12 km city center',
                          icon: Icons.place_rounded),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppTokens.space5)),
              SliverToBoxAdapter(
                child: _GalleryStrip(tonality: widget.tonality),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Rooms',
                  subtitle: 'Pick your suite',
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 232,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    itemCount: _rooms.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppTokens.space3),
                    itemBuilder: (_, i) => _RoomCard(
                      room: _rooms[i],
                      tone: widget.tonality,
                      active: _selectedRoom == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedRoom = i);
                      },
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Stay length',
                  subtitle: 'Adjust nights',
                ),
              ),
              SliverToBoxAdapter(
                child: _NightsStepper(
                  nights: _selectedNights,
                  tone: widget.tonality,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedNights = v.clamp(1, 14));
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Amenities',
                  subtitle: 'Everything you need',
                ),
              ),
              SliverToBoxAdapter(
                child: _AmenitiesGrid(tone: widget.tonality),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Neighborhood',
                  subtitle: 'Walkable in 15 minutes',
                ),
              ),
              SliverToBoxAdapter(
                child: _NeighborhoodStrip(tone: widget.tonality),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Reviews',
                  subtitle: '3,412 verified guests',
                ),
              ),
              SliverList.separated(
                itemCount: _reviews.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTokens.space2),
                itemBuilder: (_, i) => _ReviewCard(review: _reviews[i]),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Map',
                  subtitle: 'Tap to expand',
                ),
              ),
              SliverToBoxAdapter(
                child: _MapPreview(
                  tone: widget.tonality,
                  city: widget.city,
                ),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Continue your trip',
                  subtitle: 'GlobeID will line everything up',
                ),
              ),
              SliverToBoxAdapter(
                child: AgenticBand(
                  title: 'Pre-arrival flow',
                  chips: [
                    AgenticChip(
                      icon: Icons.local_taxi_rounded,
                      label: 'Airport pickup',
                      route: '/services/rides',
                      tone: const Color(0xFFEA580C),
                    ),
                    AgenticChip(
                      icon: Icons.restaurant_rounded,
                      label: 'Reserve dinner',
                      route: '/services/food',
                      tone: const Color(0xFFB45309),
                    ),
                    AgenticChip(
                      icon: Icons.assignment_ind_rounded,
                      label: 'Visa for ${widget.country}',
                      route: '/identity',
                      tone: const Color(0xFF059669),
                    ),
                    AgenticChip(
                      icon: Icons.hiking_rounded,
                      label: 'Local activities',
                      route: '/services/activities',
                      tone: theme.colorScheme.primary,
                    ),
                    AgenticChip(
                      icon: Icons.translate_rounded,
                      label: 'Local phrases',
                      route: '/copilot',
                      tone: const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 140),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(
                  AppTokens.space5,
                  AppTokens.space3,
                  AppTokens.space5,
                  AppTokens.space5,
                ),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  glass: true,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total · $_selectedNights ${_selectedNights == 1 ? 'night' : 'nights'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(0)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: widget.tonality,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 196,
                        child: CinematicButton(
                          label: 'Reserve',
                          icon: Icons.lock_rounded,
                          gradient: LinearGradient(
                            colors: [
                              widget.tonality,
                              widget.tonality.withValues(alpha: 0.6),
                            ],
                          ),
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: widget.tonality,
                                content: Text(
                                  'Reservation hold placed · ${_rooms[_selectedRoom].name}',
                                ),
                              ),
                            );
                          },
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
    );
  }

  static const _rooms = <_Room>[
    _Room(
      name: 'Skyline King',
      sqft: 380,
      pricePerNight: 420,
      perks: ['City view', 'Bath tub', 'Espresso bar'],
      icon: Icons.bed_rounded,
    ),
    _Room(
      name: 'Premier Suite',
      sqft: 520,
      pricePerNight: 640,
      perks: ['Lounge access', 'Sky pool', 'Concierge'],
      icon: Icons.workspace_premium_rounded,
    ),
    _Room(
      name: 'Penthouse Loft',
      sqft: 880,
      pricePerNight: 1180,
      perks: ['Private terrace', 'Butler', 'Spa credit'],
      icon: Icons.diamond_rounded,
    ),
  ];

  static const _reviews = <_Review>[
    _Review(
      author: 'Aiko M.',
      flag: '🇯🇵',
      score: 4.9,
      quote:
          'Service felt like a private members club. Concierge had reservations lined up before we asked.',
      stay: '3 nights · Premier Suite',
    ),
    _Review(
      author: 'Marco P.',
      flag: '🇮🇹',
      score: 4.8,
      quote:
          'Sky pool at sunset is unreal. Bedding was the most comfortable I have slept on while traveling.',
      stay: '2 nights · Skyline King',
    ),
    _Review(
      author: 'Priya R.',
      flag: '🇮🇳',
      score: 4.7,
      quote:
          'Loved the rooftop terrace and breakfast. Spa was a perfect way to unwind after long flights.',
      stay: '4 nights · Penthouse Loft',
    ),
  ];
}

class _Room {
  const _Room({
    required this.name,
    required this.sqft,
    required this.pricePerNight,
    required this.perks,
    required this.icon,
  });
  final String name;
  final int sqft;
  final double pricePerNight;
  final List<String> perks;
  final IconData icon;
}

class _Review {
  const _Review({
    required this.author,
    required this.flag,
    required this.score,
    required this.quote,
    required this.stay,
  });
  final String author;
  final String flag;
  final double score;
  final String quote;
  final String stay;
}

class _GalleryStrip extends StatelessWidget {
  const _GalleryStrip({required this.tonality});
  final Color tonality;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 1),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space3),
        itemBuilder: (_, i) {
          return SensorPendulum(
            translation: 2.4,
            rotation: 0.008,
            child: Container(
              width: 188,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tonality.withValues(alpha: 0.85 - i * 0.10),
                    tonality.withValues(alpha: 0.30),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: tonality.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                      ),
                      child: Text(
                        _labels[i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Text(
                      _captions[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static const _labels = ['LOBBY', 'POOL', 'SUITE', 'SPA', 'BAR', 'GYM'];
  static const _captions = [
    'Marble lobby',
    'Sky pool · 33F',
    'Premier suite',
    'Onsen spa',
    'Tonic bar',
    'Skyline gym',
  ];
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.tone,
    required this.active,
    required this.onTap,
  });
  final _Room room;
  final Color tone;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        curve: AppTokens.easeOutSoft,
        width: 232,
        padding: const EdgeInsets.all(AppTokens.space4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [tone.withValues(alpha: 0.95), tone.withValues(alpha: 0.55)]
                : [
                    theme.colorScheme.surface.withValues(alpha: 0.85),
                    theme.colorScheme.surface.withValues(alpha: 0.55),
                  ],
          ),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha: 0.22)
                : theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.34),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : AppTokens.shadowSm(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : tone.withValues(alpha: 0.18),
              ),
              child: Icon(
                room.icon,
                color: active ? Colors.white : tone,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            Text(
              room.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: active ? Colors.white : null,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${room.sqft} sqft',
              style: theme.textTheme.bodySmall?.copyWith(
                color: active
                    ? Colors.white.withValues(alpha: 0.85)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            for (final p in room.perks)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 11,
                        color: active
                            ? Colors.white
                            : tone.withValues(alpha: 0.85)),
                    const SizedBox(width: 4),
                    Text(p,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: active
                              ? Colors.white
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        )),
                  ],
                ),
              ),
            const Spacer(),
            Text(
              '\$${room.pricePerNight.toStringAsFixed(0)} / night',
              style: theme.textTheme.titleSmall?.copyWith(
                color: active ? Colors.white : tone,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NightsStepper extends StatelessWidget {
  const _NightsStepper({
    required this.nights,
    required this.tone,
    required this.onChanged,
  });
  final int nights;
  final Color tone;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: 0.16),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.remove_rounded, color: tone, size: 18),
              onPressed: () => onChanged(nights - 1),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text('$nights',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              Text(
                nights == 1 ? 'night' : 'nights',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: 0.16),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.add_rounded, color: tone, size: 18),
              onPressed: () => onChanged(nights + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenitiesGrid extends StatelessWidget {
  const _AmenitiesGrid({required this.tone});
  final Color tone;

  static const items = <(IconData, String)>[
    (Icons.pool_rounded, 'Sky pool'),
    (Icons.spa_rounded, 'Spa'),
    (Icons.fitness_center_rounded, 'Gym'),
    (Icons.local_bar_rounded, 'Lounge bar'),
    (Icons.local_dining_rounded, 'Tasting menu'),
    (Icons.wifi_rounded, 'Fiber Wi-Fi'),
    (Icons.airline_seat_individual_suite_rounded, 'Butler'),
    (Icons.directions_car_rounded, 'Valet'),
    (Icons.airport_shuttle_rounded, 'Airport shuttle'),
    (Icons.local_laundry_service_rounded, 'Laundry'),
    (Icons.ac_unit_rounded, 'Climate'),
    (Icons.pets_rounded, 'Pet friendly'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.4,
      mainAxisSpacing: AppTokens.space2,
      crossAxisSpacing: AppTokens.space2,
      children: [
        for (final i in items)
          PremiumCard(
            padding: const EdgeInsets.all(AppTokens.space2 + 2),
            glass: false,
            elevation: PremiumElevation.sm,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(i.$1, color: tone, size: 18),
                const SizedBox(height: 4),
                Text(
                  i.$2,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NeighborhoodStrip extends StatelessWidget {
  const _NeighborhoodStrip({required this.tone});
  final Color tone;

  static const _pois = <(IconData, String, String)>[
    (Icons.coffee_rounded, 'Blue Bottle Coffee', '3 min walk'),
    (Icons.museum_rounded, 'Modern Art Museum', '7 min walk'),
    (Icons.park_rounded, 'Imperial Garden', '12 min walk'),
    (Icons.shopping_bag_rounded, 'Ginza Six', '8 min walk'),
    (Icons.train_rounded, 'Tokyo Metro', '4 min walk'),
    (Icons.local_dining_rounded, 'Sushi Saito', '5 min walk'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        physics: const BouncingScrollPhysics(),
        itemCount: _pois.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space2),
        itemBuilder: (_, i) {
          final theme = Theme.of(context);
          final p = _pois[i];
          return Container(
            width: 168,
            padding: const EdgeInsets.all(AppTokens.space3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusXl),
              color: theme.colorScheme.surface.withValues(alpha: 0.65),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: 0.18),
                  ),
                  child: Icon(p.$1, color: tone, size: 16),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.$2,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(p.$3,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          )),
                    ],
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final _Review review;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(review.flag, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.author,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    Text(review.stay,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  color: const Color(0xFFD97706).withValues(alpha: 0.15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFD97706), size: 14),
                    const SizedBox(width: 2),
                    Text('${review.score}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            '"${review.quote}"',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatefulWidget {
  const _MapPreview({required this.tone, required this.city});
  final Color tone;
  final String city;
  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
      child: SizedBox(
        height: 184,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _MapPainter(
              tone: widget.tone,
              t: _ctrl.value,
              city: widget.city,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.tone,
    required this.t,
    required this.city,
  });
  final Color tone;
  final double t;
  final String city;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.85),
            tone.withValues(alpha: 0.30),
          ],
        ).createShader(Offset.zero & size),
    );

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    const step = 22.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pin = Offset(size.width / 2, size.height / 2);
    final pulse = Paint()
      ..color = Colors.white.withValues(alpha: 0.22 - t * 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pin, 22 + t * 28, pulse);

    final outer = Paint()..color = Colors.white;
    final inner = Paint()..color = tone;
    canvas.drawCircle(pin, 12, outer);
    canvas.drawCircle(pin, 7, inner);

    final tp = TextPainter(
      text: TextSpan(
        text: city,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.3,
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
    tp.paint(canvas, Offset(pin.dx - tp.width / 2, pin.dy + 18));

    // Tiny streets
    final rng = math.Random(7);
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 6; i++) {
      final p = Path();
      p.moveTo(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      for (var j = 0; j < 3; j++) {
        p.lineTo(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      }
      canvas.drawPath(p, stroke..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.t != t || old.tone != tone || old.city != city;
}
