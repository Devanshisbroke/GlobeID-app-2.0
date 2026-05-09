import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

// ═══════════════════════════════════════════════════════════════════
// SOCIAL TRAVEL FEED — travel recap cards, reactions, weekly digest
//
// Civilization-scale social layer: trip recap cards with stats,
// photo placeholders, reactions, comments. Weekly digest banner.
// ═══════════════════════════════════════════════════════════════════

/// Weekly digest banner shown at the top of the social feed.
class WeeklyDigestCard extends StatelessWidget {
  const WeeklyDigestCard({super.key});

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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Digest',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Your week in travel',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Text(_weekLabel(),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4))),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          // Stats row
          Row(
            children: const [
              _DigestStat(
                  label: 'Trips', value: '2', icon: Icons.flight_rounded,
                  color: Color(0xFF0EA5E9)),
              _DigestStat(
                  label: 'Spent', value: '€847', icon: Icons.account_balance_wallet_rounded,
                  color: Color(0xFF22C55E)),
              _DigestStat(
                  label: 'Countries', value: '3', icon: Icons.public_rounded,
                  color: Color(0xFFF59E0B)),
              _DigestStat(
                  label: 'Score', value: '+4', icon: Icons.trending_up_rounded,
                  color: Color(0xFFEC4899)),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          // Alerts
          _DigestAlert(
            icon: Icons.warning_rounded,
            color: const Color(0xFFF59E0B),
            text: 'German passport expires in 47 days',
          ),
          _DigestAlert(
            icon: Icons.currency_exchange_rounded,
            color: const Color(0xFF22C55E),
            text: 'JPY dropped 2.1% — good time to preload',
          ),
          _DigestAlert(
            icon: Icons.star_rounded,
            color: const Color(0xFF8B5CF6),
            text: 'Loyalty: 2,400 miles from Star Alliance Gold',
          ),
        ],
      ),
    );
  }

  String _weekLabel() {
    final now = DateTime.now();
    final weekNum = ((now.difference(DateTime(now.year)).inDays) / 7).ceil();
    return 'Week $weekNum';
  }
}

class _DigestStat extends StatelessWidget {
  const _DigestStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

class _DigestAlert extends StatelessWidget {
  const _DigestAlert(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65))),
          ),
        ],
      ),
    );
  }
}

/// Travel recap card posted to the social feed after a trip.
class TravelRecapCard extends StatefulWidget {
  const TravelRecapCard({super.key, required this.recap});
  final TripRecap recap;
  @override
  State<TravelRecapCard> createState() => _TravelRecapCardState();
}

class _TravelRecapCardState extends State<TravelRecapCard> {
  final _reactions = <String, int>{
    '✈️': 12,
    '🌍': 8,
    '🔥': 5,
    '❤️': 24,
  };
  String? _myReaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.recap;

    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.space4, AppTokens.space4, AppTokens.space4, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.5),
                    ]),
                  ),
                  child: Center(
                    child: Text(r.userName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.userName,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(r.timeAgo,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusFull),
                    color:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Text('Trip Recap',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.space3),

          // ── Photo strip (gradient placeholders) ──────────────
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
              itemCount: r.photoColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        r.photoColors[i],
                        r.photoColors[i].withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      r.photoIcons[i],
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Stats strip ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Container(
              padding: const EdgeInsets.all(AppTokens.space3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _RecapStat(label: 'Days', value: '${r.days}'),
                  _RecapStat(label: 'Countries', value: '${r.countries}'),
                  _RecapStat(label: 'km', value: '${r.distanceKm}'),
                  _RecapStat(label: 'Spent', value: '€${r.spent}'),
                ],
              ),
            ),
          ),

          // ── Route line ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            child: Row(
              children: [
                for (var i = 0; i < r.route.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.25),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusFull),
                      border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.3)),
                    ),
                    child: Text(r.route[i],
                        style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppTokens.space3),

          // ── Caption ──────────────────────────────────────────
          if (r.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
              child: Text(r.caption,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ),

          const SizedBox(height: AppTokens.space3),

          // ── Reactions ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.space4, 0, AppTokens.space4, AppTokens.space4),
            child: Row(
              children: [
                for (final entry in _reactions.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Pressable(
                      scale: 0.90,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (_myReaction == entry.key) {
                            _reactions[entry.key] = entry.value - 1;
                            _myReaction = null;
                          } else {
                            if (_myReaction != null) {
                              _reactions[_myReaction!] =
                                  (_reactions[_myReaction!] ?? 1) - 1;
                            }
                            _reactions[entry.key] = entry.value + 1;
                            _myReaction = entry.key;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          color: _myReaction == entry.key
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.18)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.06),
                          border: _myReaction == entry.key
                              ? Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 3),
                            Text('${entry.value}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                Pressable(
                  scale: 0.95,
                  onTap: () => HapticFeedback.selectionClick(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text('${r.comments}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4))),
                    ],
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

class _RecapStat extends StatelessWidget {
  const _RecapStat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()])),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }
}

/// Model for a trip recap.
class TripRecap {
  const TripRecap({
    required this.userName,
    required this.timeAgo,
    required this.days,
    required this.countries,
    required this.distanceKm,
    required this.spent,
    required this.route,
    required this.caption,
    required this.photoColors,
    required this.photoIcons,
    this.comments = 0,
  });
  final String userName, timeAgo, caption;
  final int days, countries, distanceKm, spent, comments;
  final List<String> route;
  final List<Color> photoColors;
  final List<IconData> photoIcons;

  static List<TripRecap> demos() => [
        TripRecap(
          userName: 'Alex Chen',
          timeAgo: '2 hours ago',
          days: 7,
          countries: 2,
          distanceKm: 9340,
          spent: 1842,
          route: ['FRA', 'NRT', 'KIX'],
          caption: 'Japan in cherry blossom season is unreal. The contrast between ancient temples and neon-lit streets never gets old. Already planning the next one. 🌸',
          photoColors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF0EA5E9), Color(0xFFF59E0B)],
          photoIcons: [Icons.temple_buddhist_rounded, Icons.castle_rounded, Icons.ramen_dining_rounded, Icons.location_city_rounded],
          comments: 8,
        ),
        TripRecap(
          userName: 'Maria Santos',
          timeAgo: '1 day ago',
          days: 4,
          countries: 3,
          distanceKm: 2100,
          spent: 920,
          route: ['BCN', 'LIS', 'FAO'],
          caption: 'Iberian Peninsula road trip — pastéis de nata are worth every calorie. Porto wine, fado music, and the Algarve cliffs. Perfect autumn escape.',
          photoColors: [Color(0xFFF59E0B), Color(0xFF22C55E), Color(0xFFEF4444)],
          photoIcons: [Icons.landscape_rounded, Icons.wine_bar_rounded, Icons.beach_access_rounded],
          comments: 14,
        ),
        TripRecap(
          userName: 'James Wright',
          timeAgo: '3 days ago',
          days: 10,
          countries: 1,
          distanceKm: 6800,
          spent: 3200,
          route: ['JFK', 'SFO'],
          caption: 'Cross-country US trip. Big Sur, Yosemite, Silicon Valley coffee shops. The Pacific Coast Highway at sunset is still the most beautiful drive on Earth.',
          photoColors: [Color(0xFF0EA5E9), Color(0xFF14B8A6), Color(0xFF8B5CF6), Color(0xFFEF4444), Color(0xFF22C55E)],
          photoIcons: [Icons.directions_car_rounded, Icons.park_rounded, Icons.coffee_rounded, Icons.photo_camera_rounded, Icons.waves_rounded],
          comments: 22,
        ),
      ];
}
