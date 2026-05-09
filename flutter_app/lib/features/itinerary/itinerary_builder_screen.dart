import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

/// ItineraryBuilderScreen — drag-feel daily timeline composer.
///
/// Day picker rail at the top, draggable / reorderable timeline cards
/// for each slot, a "smart fill" agentic action that synthesises a full
/// day from the user's interest profile, and a chain into bookings.
class ItineraryBuilderScreen extends StatefulWidget {
  const ItineraryBuilderScreen({
    super.key,
    this.city = 'Tokyo',
    this.flag = '🇯🇵',
    this.tone = const Color(0xFF6366F1),
  });

  final String city;
  final String flag;
  final Color tone;

  @override
  State<ItineraryBuilderScreen> createState() => _ItineraryBuilderScreenState();
}

class _ItineraryBuilderScreenState extends State<ItineraryBuilderScreen> {
  int _day = 0;

  static const _days = <(String, String)>[
    ('Mon', '06'),
    ('Tue', '07'),
    ('Wed', '08'),
    ('Thu', '09'),
    ('Fri', '10'),
    ('Sat', '11'),
    ('Sun', '12'),
  ];

  // Each day -> list of slots
  late final List<List<_Slot>> _plan = [
    [
      _Slot(
          time: '07:30',
          title: 'Tsukiji breakfast crawl',
          subtitle: 'Sushi · tamago · matcha',
          icon: Icons.restaurant_rounded,
          tone: const Color(0xFFD97706),
          duration: '90m',
          tag: 'food'),
      _Slot(
          time: '10:00',
          title: 'Senso-ji temple',
          subtitle: 'Asakusa · cultural · photo',
          icon: Icons.account_balance_rounded,
          tone: const Color(0xFFE11D48),
          duration: '2h',
          tag: 'culture'),
      _Slot(
          time: '13:00',
          title: 'TeamLab Borderless',
          subtitle: 'Odaiba · digital art',
          icon: Icons.local_activity_rounded,
          tone: const Color(0xFF6366F1),
          duration: '3h',
          tag: 'art'),
      _Slot(
          time: '19:30',
          title: 'Shinjuku Omoide Yokocho',
          subtitle: 'Yakitori · drinks · neon alley',
          icon: Icons.local_bar_rounded,
          tone: const Color(0xFF14B8A6),
          duration: '2h',
          tag: 'night'),
    ],
    [
      _Slot(
          time: '08:00',
          title: 'Shibuya scramble walk',
          subtitle: 'Crossing · Hachiko · Center-gai',
          icon: Icons.directions_walk_rounded,
          tone: const Color(0xFF10B981),
          duration: '90m',
          tag: 'walk'),
      _Slot(
          time: '11:00',
          title: 'Meiji Jingu shrine',
          subtitle: 'Shibuya · forest path',
          icon: Icons.forest_rounded,
          tone: const Color(0xFF22C55E),
          duration: '90m',
          tag: 'culture'),
      _Slot(
          time: '14:00',
          title: 'Harajuku · Takeshita street',
          subtitle: 'Crepes · vintage · purikura',
          icon: Icons.icecream_rounded,
          tone: const Color(0xFFEC4899),
          duration: '2h',
          tag: 'shopping'),
    ],
    [],
    [],
    [],
    [],
    [],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slots = _plan[_day];

    return PageScaffold(
      title: 'Itinerary builder',
      subtitle: '${widget.city} ${widget.flag} · ${slots.length} stops today',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'PLAN MODE',
              title: 'Build your perfect day',
              subtitle:
                  'Drag, drop, smart-fill. Every stop chains into bookings.',
              tone: widget.tone,
              icon: Icons.event_note_rounded,
              flag: widget.flag,
              badges: [
                HeroBadge(
                    label:
                        '${_plan.fold<int>(0, (s, l) => s + l.length)} stops',
                    icon: Icons.bookmark_rounded),
                const HeroBadge(
                    label: 'Smart fill', icon: Icons.auto_awesome_rounded),
                const HeroBadge(
                    label: 'Sync to wallet',
                    icon: Icons.account_balance_wallet_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _days.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTokens.space2),
              itemBuilder: (_, i) {
                final selected = i == _day;
                final d = _days[i];
                return Pressable(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _day = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 64,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected ? widget.tone : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      border: Border.all(
                        color: selected
                            ? widget.tone
                            : theme.colorScheme.outline.withValues(alpha: 0.18),
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: widget.tone.withValues(alpha: 0.32),
                                blurRadius: 16,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(d.$1,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                            )),
                        Text(d.$2,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          if (slots.isEmpty)
            AnimatedAppearance(
              child: PremiumCard(
                padding: const EdgeInsets.all(AppTokens.space5),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded,
                        color: widget.tone, size: 36),
                    const SizedBox(height: AppTokens.space3),
                    Text('No plans yet for ${_days[_day].$1}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      "Tap 'Smart fill' below — your copilot will draft a day "
                      'from your taste profile.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (var i = 0; i < slots.length; i++)
              AnimatedAppearance(
                delay: Duration(milliseconds: 40 * i),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space2),
                  child: _SlotTile(
                    slot: slots[i],
                    isLast: i == slots.length - 1,
                    onRemove: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _plan[_day].removeAt(i);
                      });
                    },
                  ),
                ),
              ),
          const SizedBox(height: AppTokens.space4),
          AgenticBand(
            title: 'Quick plan moves',
            chips: [
              AgenticChip(
                icon: Icons.auto_awesome_rounded,
                label: 'Smart fill day',
                eyebrow: 'AI',
                tone: widget.tone,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  setState(() {
                    if (_plan[_day].isEmpty) {
                      _plan[_day] = [
                        _Slot(
                            time: '09:00',
                            title: 'Coffee at Onibus',
                            subtitle: 'Nakameguro · v60 specialty',
                            icon: Icons.local_cafe_rounded,
                            tone: const Color(0xFF92400E),
                            duration: '45m',
                            tag: 'food'),
                        _Slot(
                            time: '11:00',
                            title: 'TeamLab Planets',
                            subtitle: 'Toyosu · barefoot art',
                            icon: Icons.local_activity_rounded,
                            tone: const Color(0xFF6366F1),
                            duration: '2h30',
                            tag: 'art'),
                        _Slot(
                            time: '15:00',
                            title: 'Akihabara crawl',
                            subtitle: 'Retro arcades · Don Quijote',
                            icon: Icons.videogame_asset_rounded,
                            tone: const Color(0xFFEC4899),
                            duration: '2h',
                            tag: 'shopping'),
                        _Slot(
                            time: '19:00',
                            title: 'Ramen at Tsuta',
                            subtitle: 'Sugamo · michelin · truffle shoyu',
                            icon: Icons.ramen_dining_rounded,
                            tone: const Color(0xFFD97706),
                            duration: '90m',
                            tag: 'food'),
                      ];
                    }
                  });
                },
              ),
              AgenticChip(
                icon: Icons.restaurant_rounded,
                label: 'Add a meal',
                eyebrow: 'food',
                route: '/services/food',
                tone: const Color(0xFFD97706),
              ),
              AgenticChip(
                icon: Icons.local_taxi_rounded,
                label: 'Add transit',
                eyebrow: 'cabs',
                route: '/services/rides',
                tone: const Color(0xFFEA580C),
              ),
              AgenticChip(
                icon: Icons.hotel_rounded,
                label: 'Add a stay',
                eyebrow: 'hotels',
                route: '/services/hotels',
                tone: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          CinematicButton(
            label: 'Send to wallet · pay later',
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

class _Slot {
  _Slot({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.duration,
    required this.tag,
  });
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final String duration;
  final String tag;
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.isLast,
    required this.onRemove,
  });
  final _Slot slot;
  final bool isLast;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rail
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(slot.time,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slot.tone,
                    boxShadow: [
                      BoxShadow(
                        color: slot.tone.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      color: theme.colorScheme.outline.withValues(alpha: 0.18),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Expanded(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      color: slot.tone.withValues(alpha: 0.18),
                    ),
                    child: Icon(slot.icon, color: slot.tone, size: 20),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slot.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        Text(slot.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Chip(label: slot.duration, tone: slot.tone),
                            const SizedBox(width: 6),
                            _Chip(label: slot.tag, tone: slot.tone),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(Icons.delete_outline_rounded,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone});
  final String label;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: tone,
          )),
    );
  }
}
