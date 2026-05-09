import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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

/// LoungeScreen — premium airport lounge experience.
///
/// Polaris-style lounge with capacity meter, amenity grid, F&B menu,
/// shower & nap suite booking, and a "boarding in 38m" countdown
/// chained directly back into the Airport / Boarding flow.
class LoungeScreen extends StatefulWidget {
  const LoungeScreen({
    super.key,
    this.lounge = 'United Polaris',
    this.terminal = 'SFO · T3',
    this.tone = const Color(0xFFD97706),
  });

  final String lounge;
  final String terminal;
  final Color tone;

  @override
  State<LoungeScreen> createState() => _LoungeScreenState();
}

class _LoungeScreenState extends State<LoungeScreen> {
  final _selectedDishes = <int>{1, 4};
  final _amenitiesUsed = <int>{};

  static const _amenities = <(IconData, String, String)>[
    (Icons.shower_rounded, 'Shower suite', '12 min wait · towels included'),
    (Icons.king_bed_rounded, 'Nap pod', 'Reserve 90 min · noise-cancelling'),
    (Icons.local_bar_rounded, 'Bar & sommelier', 'Curated wines · espresso bar'),
    (Icons.spa_rounded, 'Spa & massage', '20 min chair massage · ¥4,500'),
    (Icons.print_rounded, 'Workspaces', 'Booths · 4K monitors · printing'),
    (Icons.child_care_rounded, 'Family room', 'Toys · changing · quiet zone'),
  ];

  static const _menu = <(IconData, String, String, String)>[
    (Icons.ramen_dining_rounded, 'Tonkotsu ramen', 'Pork broth · chashu · ajitama', '¥1,800'),
    (Icons.set_meal_rounded, 'Sushi omakase', '8 nigiri · seasonal', '¥4,200'),
    (Icons.coffee_rounded, 'Single-origin pour-over', 'Ethiopia Yirgacheffe', '¥620'),
    (Icons.cake_rounded, 'Wagashi platter', 'Mochi · dorayaki · matcha', '¥980'),
    (Icons.local_bar_rounded, 'Yamazaki 12 highball', 'Single-malt highball', '¥2,100'),
    (Icons.breakfast_dining_rounded, 'Avocado toast', 'Sourdough · eggs · chili oil', '¥1,400'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: widget.lounge,
      subtitle: '${widget.terminal} · access via Polaris',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'PREMIUM LOUNGE',
              title: widget.lounge,
              subtitle: '${widget.terminal} · 124/180 capacity · open until 23:30',
              icon: Icons.airline_seat_recline_extra_rounded,
              tone: widget.tone,
              badges: const [
                HeroBadge(label: 'Polaris', icon: Icons.diamond_rounded),
                HeroBadge(label: 'Wi-Fi 720 Mbps', icon: Icons.wifi_rounded),
                HeroBadge(label: '24/7', icon: Icons.access_time_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            child: AnimatedAppearance(
              delay: const Duration(milliseconds: 60),
              child: LoungeOccupancyMeter(
                occupied: 124,
                capacity: 180,
                tone: widget.tone,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded,
                          color: widget.tone, size: 16),
                      const SizedBox(width: 6),
                      Text('Lounge capacity',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      const Spacer(),
                      Text('124 / 180',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: widget.tone,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusFull),
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Container(
                              color: widget.tone.withValues(alpha: 0.16)),
                          FractionallySizedBox(
                            widthFactor: 124 / 180,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  widget.tone,
                                  widget.tone.withValues(alpha: 0.55),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('~7 min wait for shower suites · 0 min for seats',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      )),
                ],
              ),
            ),
          ),
          const SectionHeader(
              title: 'Amenities', subtitle: 'Tap to reserve or check in'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: AppTokens.space2,
            crossAxisSpacing: AppTokens.space2,
            children: [
              for (var i = 0; i < _amenities.length; i++)
                Pressable(
                  scale: 0.97,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_amenitiesUsed.contains(i)) {
                        _amenitiesUsed.remove(i);
                      } else {
                        _amenitiesUsed.add(i);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppTokens.durationSm,
                    padding: const EdgeInsets.all(AppTokens.space3),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTokens.radius2xl),
                      gradient: _amenitiesUsed.contains(i)
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.tone,
                                widget.tone.withValues(alpha: 0.50),
                              ],
                            )
                          : null,
                      color: _amenitiesUsed.contains(i)
                          ? null
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: _amenitiesUsed.contains(i)
                            ? Colors.transparent
                            : widget.tone.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_amenities[i].$1,
                            color: _amenitiesUsed.contains(i)
                                ? Colors.white
                                : widget.tone,
                            size: 20),
                        const Spacer(),
                        Text(_amenities[i].$2,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _amenitiesUsed.contains(i)
                                  ? Colors.white
                                  : null,
                            )),
                        Text(_amenities[i].$3,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _amenitiesUsed.contains(i)
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SectionHeader(
              title: 'Today\'s menu', subtitle: 'Tap to add to your tab'),
          for (var i = 0; i < _menu.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space2),
              child: Pressable(
                scale: 0.99,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (_selectedDishes.contains(i)) {
                      _selectedDishes.remove(i);
                    } else {
                      _selectedDishes.add(i);
                    }
                  });
                },
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  borderColor: _selectedDishes.contains(i)
                      ? widget.tone.withValues(alpha: 0.45)
                      : null,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.tone.withValues(alpha: 0.18),
                        ),
                        child: Icon(_menu[i].$1, color: widget.tone, size: 18),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_menu[i].$2,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                            Text(_menu[i].$3,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                )),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          color: _selectedDishes.contains(i)
                              ? widget.tone
                              : widget.tone.withValues(alpha: 0.18),
                        ),
                        child: Text(_menu[i].$4,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _selectedDishes.contains(i)
                                  ? Colors.white
                                  : widget.tone,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppTokens.space4),
          AgenticBand(
            title: 'Boarding in 38m',
            chips: [
              AgenticChip(
                icon: Icons.flight_takeoff_rounded,
                label: 'Back to gate 78A',
                route: '/airport',
                tone: widget.tone,
              ),
              const AgenticChip(
                icon: Icons.qr_code_2_rounded,
                label: 'Boarding pass',
                route: '/boarding/trp-001/leg-ua837',
                tone: Color(0xFF1E40AF),
              ),
              const AgenticChip(
                icon: Icons.smart_toy_rounded,
                label: 'Ask copilot',
                route: '/copilot',
                tone: Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          CinematicButton(
            label: 'Charge to GlobeID wallet',
            icon: Icons.account_balance_wallet_rounded,
            gradient: LinearGradient(
              colors: [widget.tone, widget.tone.withValues(alpha: 0.55)],
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              GoRouter.of(context).push('/wallet');
            },
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}
