import 'package:flutter/material.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../chrome/bible_buttons.dart';
import '../chrome/bible_pressable.dart';
import '../chrome/bible_premium_card.dart';
import '../chrome/bible_scaffold.dart';
import '../chrome/bible_widgets.dart';

/// GlobeID — **Lounge** (§11.10 _The Velvet Room_).
///
/// Registers: Stillness. Spine: Lounge.
///
/// Cinematic hero photo, capacity meter, amenities rail, sensory
/// rating, reserve-pod sheet. The colour story is warm
/// (Champagne Sand, Velvet Mauve, Honey Amber) — never cyan.
class BibleLoungeScreen extends StatelessWidget {
  const BibleLoungeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BiblePageScaffold(
      emotion: BEmotion.stillness,
      tone: B.velvetMauve.withValues(alpha: 0.08),
      density: BDensity.concourse,
      eyebrow: '— sanctuary · NRT terminal 2 —',
      title: 'JAL Sakura',
      trailing: const BibleStatusPill(
        label: 'reserved',
        tone: B.honeyAmber,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CinemaHero(),
          const SizedBox(height: B.space4),
          _CapacityMeter(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'sensory rating',
            title: 'Velvet room signature',
          ),
          _SensoryGrid(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'amenities',
            title: 'On offer right now',
          ),
          _AmenitiesRail(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'pods',
            title: 'Choose your sanctuary',
          ),
          _PodSelector(),
          const SizedBox(height: B.space6),
          _ReserveSheet(),
          const SizedBox(height: B.space6),
        ],
      ),
    );
  }
}

class _CinemaHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(B.rCard),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                B.velvetMauve.withValues(alpha: 0.75),
                B.honeyAmber.withValues(alpha: 0.55),
                B.champagneSand.withValues(alpha: 0.40),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Soft window light streak
              Positioned(
                top: 0,
                left: -40,
                bottom: 0,
                child: SizedBox(
                  width: 200,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(B.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BText.eyebrow(
                      'concept · zen sanctuary',
                      color: B.snowfieldWhite,
                    ),
                    const SizedBox(height: B.space1),
                    BText.display(
                      'Velvet, brass, dim sunlight.',
                      size: 20,
                      color: B.snowfieldWhite,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapacityMeter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.honeyAmber,
      padding: const EdgeInsets.all(B.space4),
      child: Row(
        children: [
          BibleProgressArc(
            value: 0.42,
            tone: B.honeyAmber,
            diameter: 88,
            label: 'cap · 42%',
          ),
          const SizedBox(width: B.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BText.eyebrow('current capacity', color: B.honeyAmber),
                const SizedBox(height: B.space1),
                BText.title('108 of 256 guests', size: 17),
                const SizedBox(height: B.space2),
                BText.caption(
                  'Best time to arrive — the Tatami corner is empty.',
                  color: B.inkOnDarkMid,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensoryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SensoryDial(label: 'noise', value: 0.18, tone: B.equatorTeal, units: 'dB · 38')),
        SizedBox(width: B.space2),
        Expanded(child: _SensoryDial(label: 'lighting', value: 0.42, tone: B.honeyAmber, units: 'lux · 110')),
        SizedBox(width: B.space2),
        Expanded(child: _SensoryDial(label: 'scent', value: 0.62, tone: B.velvetMauve, units: 'cedar · soft')),
      ],
    );
  }
}

class _SensoryDial extends StatelessWidget {
  const _SensoryDial({
    required this.label,
    required this.value,
    required this.tone,
    required this.units,
  });
  final String label;
  final double value;
  final Color tone;
  final String units;
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: tone,
      padding: const EdgeInsets.all(B.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BText.eyebrow(label, color: tone),
          const SizedBox(height: B.space3),
          BibleProgressArc(
            value: value,
            tone: tone,
            diameter: 64,
            strokeWidth: 4,
          ),
          const SizedBox(height: B.space2),
          BText.mono(units, color: B.inkOnDarkHigh, size: 11),
        ],
      ),
    );
  }
}

class _AmenitiesRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          _AmenityChip(
            icon: Icons.restaurant_menu_rounded,
            label: 'Omakase',
            caption: 'Open 17–22',
            tone: B.diplomaticGarnet,
          ),
          _AmenityChip(
            icon: Icons.spa_rounded,
            label: 'Onsen',
            caption: '38°C · steam',
            tone: B.velvetMauve,
          ),
          _AmenityChip(
            icon: Icons.local_bar_rounded,
            label: 'Whisky Bar',
            caption: '42 expressions',
            tone: B.foilGold,
          ),
          _AmenityChip(
            icon: Icons.shower_rounded,
            label: 'Suites',
            caption: '6 available',
            tone: B.polarBlue,
          ),
          _AmenityChip(
            icon: Icons.spa_outlined,
            label: 'Garden',
            caption: 'Zen koi pond',
            tone: B.equatorTeal,
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({
    required this.icon,
    required this.label,
    required this.caption,
    required this.tone,
  });
  final IconData icon;
  final String label;
  final String caption;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: B.space3),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(B.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(B.rCard),
          color: tone.withValues(alpha: 0.10),
          border: Border.all(color: tone.withValues(alpha: 0.30), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BibleGlyphHalo(icon: icon, tone: tone, size: 32),
            const SizedBox(height: B.space2),
            BText.title(label, size: 14),
            BText.caption(caption, color: B.inkOnDarkMid),
          ],
        ),
      ),
    );
  }
}

class _PodSelector extends StatefulWidget {
  @override
  State<_PodSelector> createState() => _PodSelectorState();
}

class _PodSelectorState extends State<_PodSelector> {
  int _selected = 0;
  static const _pods = <_Pod>[
    _Pod(
      name: 'Tatami Corner',
      time: '2h slot · 18:00 → 20:00',
      tone: B.velvetMauve,
      icon: Icons.weekend_rounded,
    ),
    _Pod(
      name: 'Riverside Pod',
      time: '90m slot · 18:30 → 20:00',
      tone: B.equatorTeal,
      icon: Icons.air_rounded,
    ),
    _Pod(
      name: 'Onsen Suite',
      time: '3h slot · 19:00 → 22:00',
      tone: B.honeyAmber,
      icon: Icons.spa_rounded,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _pods.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: B.space2),
            child: BiblePressable(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: B.dQuick,
                padding: const EdgeInsets.all(B.space3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(B.rCard),
                  color: _selected == i
                      ? _pods[i].tone.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: _selected == i
                        ? _pods[i].tone.withValues(alpha: 0.55)
                        : B.hairlineLightSoft,
                    width: _selected == i ? 0.8 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    BibleGlyphHalo(
                      icon: _pods[i].icon,
                      tone: _pods[i].tone,
                      size: 36,
                    ),
                    const SizedBox(width: B.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BText.title(_pods[i].name, size: 14),
                          BText.caption(_pods[i].time, color: B.inkOnDarkMid),
                        ],
                      ),
                    ),
                    if (_selected == i)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: _pods[i].tone,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Pod {
  const _Pod({
    required this.name,
    required this.time,
    required this.tone,
    required this.icon,
  });
  final String name;
  final String time;
  final Color tone;
  final IconData icon;
}

class _ReserveSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.foilGold,
      padding: const EdgeInsets.all(B.space4),
      child: Column(
        children: [
          Row(
            children: [
              BibleGlyphHalo(
                icon: Icons.workspace_premium_rounded,
                tone: B.foilGold,
                size: 44,
              ),
              const SizedBox(width: B.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BText.eyebrow('platinum guest', color: B.foilGold),
                    BText.title('No cost · complimentary', size: 14),
                  ],
                ),
              ),
              BText.solari('¥ 0', size: 26, color: B.foilGold),
            ],
          ),
          const SizedBox(height: B.space3),
          const BibleDivider(),
          const SizedBox(height: B.space3),
          BibleCinematicButton(
            label: 'Reserve pod',
            icon: Icons.check_rounded,
            tone: B.foilGold,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
