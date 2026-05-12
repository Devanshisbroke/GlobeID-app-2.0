import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/toast.dart';

/// TripJournalScreen — cinematic memory feed for a current trip.
///
/// A vertical timeline of entries (photo + caption + location + chip
/// tags) with a cover hero, day pills, and a "create new" CTA. Demo
/// content only — no asset images, just deterministic gradient mocks.
class TripJournalScreen extends StatelessWidget {
  const TripJournalScreen({
    super.key,
    this.trip = 'Tokyo · spring \'26',
    this.tone = const Color(0xFF14B8A6),
  });

  final String trip;
  final Color tone;

  static const _entries = <_Entry>[
    _Entry(
      day: 'Day 1',
      date: 'Mon · 6 May',
      title: 'Landed at Haneda',
      caption:
          'Cleared customs in 11 minutes. The arrival hall has its own scent — cedar + airflow.',
      icon: Icons.flight_land_rounded,
      tags: ['arrival', 'photo'],
      gradient: [Color(0xFF6366F1), Color(0xFF22D3EE)],
    ),
    _Entry(
      day: 'Day 1',
      date: 'Mon · 6 May',
      title: 'Aman Tokyo · suite 3201',
      caption:
          'Cedar-lined onsen on the 33rd floor. The skyline at dusk is unreal.',
      icon: Icons.hotel_rounded,
      tags: ['hotel', 'sunset'],
      gradient: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    ),
    _Entry(
      day: 'Day 2',
      date: 'Tue · 7 May',
      title: 'Tsukiji breakfast crawl',
      caption:
          'Tamago, uni, and matcha — in that order. Mr Yamamoto remembered me.',
      icon: Icons.restaurant_rounded,
      tags: ['food', 'morning'],
      gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
    ),
    _Entry(
      day: 'Day 2',
      date: 'Tue · 7 May',
      title: 'TeamLab Borderless',
      caption:
          'Forgot to take my shoes off in the mirror room. Got photographed wide-eyed.',
      icon: Icons.local_activity_rounded,
      tags: ['art', 'must-see'],
      gradient: [Color(0xFF6366F1), Color(0xFFEC4899)],
    ),
    _Entry(
      day: 'Day 3',
      date: 'Wed · 8 May',
      title: 'Kamakura day trip',
      caption:
          'Bamboo at Hokokuji whispered. The big Buddha is bigger than photos suggest.',
      icon: Icons.train_rounded,
      tags: ['day-trip', 'temple'],
      gradient: [Color(0xFF10B981), Color(0xFF14B8A6)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Trip journal',
      subtitle: '$trip · ${_entries.length} memories',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'YOUR MEMORIES',
              title: trip,
              subtitle:
                  'Auto-stitched from your timeline. Tap any moment to expand.',
              tone: tone,
              icon: Icons.menu_book_rounded,
              badges: [
                HeroBadge(
                    label: '${_entries.length} entries',
                    icon: Icons.bookmark_rounded),
                const HeroBadge(
                    label: 'Auto-stitch', icon: Icons.auto_awesome_rounded),
                const HeroBadge(label: 'Private', icon: Icons.lock_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 50),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Days in',
                      value: '3 / 9',
                      tone: tone),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: _StatTile(
                      icon: Icons.directions_walk_rounded,
                      label: 'Steps',
                      value: '32k',
                      tone: tone),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: _StatTile(
                      icon: Icons.photo_camera_rounded,
                      label: 'Photos',
                      value: '142',
                      tone: tone),
                ),
              ],
            ),
          ),
          const SectionHeader(
              title: 'Timeline', subtitle: 'Your trip, told as a feed'),
          for (var i = 0; i < _entries.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 50 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space3),
                child: _EntryCard(
                  entry: _entries[i],
                  tone: tone,
                  isLast: i == _entries.length - 1,
                ),
              ),
            ),
          const SizedBox(height: AppTokens.space4),
          AgenticBand(
            title: 'Quick chains',
            chips: const [
              AgenticChip(
                icon: Icons.timeline_rounded,
                label: 'Open timeline',
                eyebrow: 'feed',
                route: '/timeline',
                tone: Color(0xFF6366F1),
              ),
              AgenticChip(
                icon: Icons.event_note_rounded,
                label: 'Edit itinerary',
                eyebrow: 'plan',
                route: '/itinerary',
                tone: Color(0xFF6366F1),
              ),
              AgenticChip(
                icon: Icons.public_rounded,
                label: 'Country profile',
                eyebrow: 'country',
                route: '/country',
                tone: Color(0xFFE11D48),
              ),
              AgenticChip(
                icon: Icons.share_rounded,
                label: 'Share trip',
                eyebrow: 'social',
                route: '/social',
                tone: Color(0xFFEC4899),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          CinematicButton(
            label: 'Add a moment',
            icon: Icons.add_a_photo_rounded,
            gradient: LinearGradient(
              colors: [tone, tone.withValues(alpha: 0.55)],
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              AppToast.show(
                context,
                title: 'Captured',
                message: 'Stitched into ${_entries.first.day}',
                tone: AppToastTone.success,
              );
            },
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry({
    required this.day,
    required this.date,
    required this.title,
    required this.caption,
    required this.icon,
    required this.tags,
    required this.gradient,
  });
  final String day;
  final String date;
  final String title;
  final String caption;
  final IconData icon;
  final List<String> tags;
  final List<Color> gradient;
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.tone,
    required this.isLast,
  });
  final _Entry entry;
  final Color tone;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day rail
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(entry.day,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    )),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone,
                    boxShadow: [
                      BoxShadow(
                        color: tone.withValues(alpha: 0.45),
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
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image / hero stand-in
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTokens.radius2xl),
                    ),
                    child: SizedBox(
                      height: 132,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _MemoryPainter(
                          colors: entry.gradient,
                          icon: entry.icon,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.space3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(entry.icon, color: tone, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(entry.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  )),
                            ),
                            Text(entry.date,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(entry.caption,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.78),
                              height: 1.4,
                            )),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final t in entry.tags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tone.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.radiusFull),
                                ),
                                child: Text('#$t',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: tone,
                                    )),
                              ),
                          ],
                        ),
                      ],
                    ),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
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
          Icon(icon, color: tone, size: 16),
          const SizedBox(height: 6),
          Text(value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              )),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
        ],
      ),
    );
  }
}

class _MemoryPainter extends CustomPainter {
  const _MemoryPainter({required this.colors, required this.icon});
  final List<Color> colors;
  final IconData icon;
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final glow = Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withValues(alpha: 0.32),
        Colors.white.withValues(alpha: 0.0),
      ]).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.7, size.height * 0.4),
          radius: size.width * 0.5,
        ),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.4),
      size.width * 0.4,
      glow,
    );

    // Stars
    final rng = math.Random(icon.codePoint);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 30; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height * 0.7;
      canvas.drawCircle(Offset(dx, dy), rng.nextDouble() * 1.4 + 0.3, star);
    }

    // Big glyph
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 86,
          color: Colors.white.withValues(alpha: 0.85),
          fontFamily: icon.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.06, size.height - tp.height - 8));
  }

  @override
  bool shouldRepaint(covariant _MemoryPainter old) => false;
}
