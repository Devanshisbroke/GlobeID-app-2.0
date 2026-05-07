import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// PackingChecklistScreen — smart-pack list adapted to the trip.
///
/// Categorised checklist (Documents, Clothing, Tech, Toiletries, Travel
/// gear). Live progress bar at the top, tap-to-toggle, agentic chain
/// into customs form / phrasebook / wallet (insurance).
class PackingChecklistScreen extends StatefulWidget {
  const PackingChecklistScreen({
    super.key,
    this.destination = 'Tokyo · 🇯🇵',
    this.tone = const Color(0xFF7C3AED),
    this.tripDays = 9,
  });

  final String destination;
  final Color tone;
  final int tripDays;

  @override
  State<PackingChecklistScreen> createState() =>
      _PackingChecklistScreenState();
}

class _PackingChecklistScreenState extends State<PackingChecklistScreen> {
  int _category = 0;
  final Set<String> _packed = {
    'Passport',
    'eVisa printout',
    'Wallet · cards',
  };

  static const _categories = <(IconData, String)>[
    (Icons.assignment_ind_rounded, 'Documents'),
    (Icons.checkroom_rounded, 'Clothing'),
    (Icons.devices_rounded, 'Tech'),
    (Icons.bathtub_rounded, 'Toiletries'),
    (Icons.luggage_rounded, 'Gear'),
  ];

  static const _items = <List<(IconData, String, String)>>[
    [
      (Icons.assignment_ind_rounded, 'Passport',
          'Valid 6+ months past return'),
      (Icons.verified_rounded, 'eVisa printout', 'Backup if offline'),
      (Icons.health_and_safety_rounded, 'Travel insurance card', 'Photo on phone'),
      (Icons.confirmation_number_rounded, 'Boarding pass', 'In wallet · live'),
      (Icons.credit_card_rounded, 'Wallet · cards',
          '2 cards · separate pockets'),
      (Icons.payments_rounded, 'Backup cash', '\$100 · for first 24h'),
    ],
    [
      (Icons.checkroom_rounded, 'T-shirts × 5', 'Lightweight, fast-dry'),
      (Icons.dry_cleaning_rounded, 'Trousers × 2', '1 dressy, 1 casual'),
      (Icons.directions_walk_rounded, 'Walking shoes', 'Broken-in pair'),
      (Icons.beach_access_rounded, 'Light jacket', 'May rain'),
      (Icons.water_drop_rounded, 'Compact umbrella', 'Tsuyu season'),
      (Icons.spa_rounded, 'Sleepwear', '1 pair'),
    ],
    [
      (Icons.smartphone_rounded, 'Phone + charger', 'USB-C cable'),
      (Icons.power_rounded, 'Type A plug adapter', 'Japan = Type A · 100V'),
      (Icons.battery_full_rounded, 'Power bank', '10,000 mAh'),
      (Icons.headphones_rounded, 'Headphones', 'Noise-cancelling'),
      (Icons.camera_alt_rounded, 'Camera', 'With spare battery'),
      (Icons.sim_card_rounded, 'eSIM activated', 'Done in app'),
    ],
    [
      (Icons.brush_rounded, 'Toothbrush + paste', 'Travel size'),
      (Icons.face_rounded, 'Skincare basics', 'Carry-on safe'),
      (Icons.medication_rounded, 'Painkillers + bandaids',
          'Small first-aid kit'),
      (Icons.water_drop_rounded, 'Sunscreen', 'SPF 50'),
      (Icons.face_retouching_natural_rounded, 'Lip balm', ''),
    ],
    [
      (Icons.luggage_rounded, 'Carry-on bag', 'Within airline limits'),
      (Icons.backpack_rounded, 'Daypack', 'For temple days'),
      (Icons.water_rounded, 'Water bottle', 'Refill at konbini'),
      (Icons.shopping_bag_rounded, 'Foldable tote', 'Souvenirs'),
      (Icons.lock_rounded, 'TSA lock', 'For checked bag'),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items[_category];

    final allItems = _items.expand((c) => c).toList();
    final packed = allItems.where((i) => _packed.contains(i.$2)).length;
    final progress = packed / allItems.length;

    return PageScaffold(
      title: 'Packing list',
      subtitle:
          '${widget.destination} · ${widget.tripDays} days · $packed/${allItems.length} packed',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'SMART PACK',
              title: 'Pack like a pro',
              subtitle:
                  'Tailored to ${widget.destination} weather, length & style.',
              tone: widget.tone,
              icon: Icons.luggage_rounded,
              badges: [
                HeroBadge(
                    label: '${(progress * 100).round()}% packed',
                    icon: Icons.task_alt_rounded),
                HeroBadge(
                    label: '${widget.tripDays} days',
                    icon: Icons.calendar_today_rounded),
                const HeroBadge(
                    label: 'Climate-aware',
                    icon: Icons.cloud_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 50),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Progress',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      const Spacer(),
                      Text('$packed / ${allItems.length}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: widget.tone,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusFull),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor:
                          widget.tone.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation(widget.tone),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTokens.space2),
              itemBuilder: (_, i) {
                final selected = i == _category;
                final cat = _categories[i];
                return Pressable(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _category = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? widget.tone.withValues(alpha: 0.18)
                          : theme.colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusFull),
                      border: Border.all(
                        color: selected
                            ? widget.tone
                            : theme.colorScheme.outline
                                .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.$1,
                            size: 14,
                            color: selected
                                ? widget.tone
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          cat.$2,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? widget.tone
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          for (var i = 0; i < items.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 30 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: Pressable(
                  scale: 0.99,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_packed.contains(items[i].$2)) {
                        _packed.remove(items[i].$2);
                      } else {
                        _packed.add(items[i].$2);
                      }
                    });
                  },
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppTokens.space3),
                    borderColor: _packed.contains(items[i].$2)
                        ? widget.tone.withValues(alpha: 0.40)
                        : null,
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _packed.contains(items[i].$2)
                                ? widget.tone
                                : widget.tone.withValues(alpha: 0.18),
                          ),
                          child: Icon(
                            _packed.contains(items[i].$2)
                                ? Icons.check_rounded
                                : items[i].$1,
                            size: 14,
                            color: _packed.contains(items[i].$2)
                                ? Colors.white
                                : widget.tone,
                          ),
                        ),
                        const SizedBox(width: AppTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(items[i].$2,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    decoration:
                                        _packed.contains(items[i].$2)
                                            ? TextDecoration.lineThrough
                                            : null,
                                    color: _packed.contains(items[i].$2)
                                        ? theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5)
                                        : null,
                                  )),
                              if (items[i].$3.isNotEmpty)
                                Text(items[i].$3,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
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
            ),
          const SizedBox(height: AppTokens.space4),
          const SectionHeader(
              title: 'After packing',
              subtitle: 'Common chains from here'),
          AgenticBand(
            title: '',
            chips: const [
              AgenticChip(
                icon: Icons.assignment_rounded,
                label: 'Customs form',
                eyebrow: 'arrival',
                route: '/customs',
                tone: Color(0xFF6366F1),
              ),
              AgenticChip(
                icon: Icons.translate_rounded,
                label: 'Phrasebook',
                eyebrow: 'language',
                route: '/phrasebook',
                tone: Color(0xFFE11D48),
              ),
              AgenticChip(
                icon: Icons.event_note_rounded,
                label: 'Itinerary',
                eyebrow: 'plan',
                route: '/itinerary',
                tone: Color(0xFF6366F1),
              ),
              AgenticChip(
                icon: Icons.health_and_safety_rounded,
                label: 'Insurance',
                eyebrow: 'wallet',
                route: '/wallet',
                tone: Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          CinematicButton(
            label: 'Mark all as packed',
            icon: Icons.task_alt_rounded,
            gradient: LinearGradient(
              colors: [widget.tone, widget.tone.withValues(alpha: 0.55)],
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              setState(() {
                _packed
                  ..clear()
                  ..addAll(allItems.map((i) => i.$2));
              });
            },
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}
