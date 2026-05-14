import 'package:flutter/material.dart';

import '../../cinematic/branding/seal_loading_state.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Operator screen for the [SealLoadingState] cold-mount ceremony.
///
/// Provides a viewport that holds the seal animation plus a foil-pill
/// CTA that triggers playback. The PHASE LADDER card on the right
/// documents the choreography so designers, engineers, and reviewers
/// can read what each frame is doing without diving into source.
class SealColdMountScreen extends StatefulWidget {
  const SealColdMountScreen({super.key});

  @override
  State<SealColdMountScreen> createState() => _SealColdMountScreenState();
}

class _SealColdMountScreenState extends State<SealColdMountScreen> {
  final GlobalKey<SealLoadingStateState> _sealKey =
      GlobalKey<SealLoadingStateState>();
  int _playCount = 0;
  Color _tone = const Color(0xFFD4AF37);

  static const _tones = <(String, Color)>[
    ('GOLD · STANDARD', Color(0xFFD4AF37)),
    ('CHAMPAGNE', Color(0xFFE9C75D)),
    ('AMBER · STAMP', Color(0xFFC8932F)),
    ('WINE · CLASSIFIED', Color(0xFF7B1A1A)),
    ('CLEARED · GREEN', Color(0xFF1F6F4A)),
  ];

  void _play() {
    setState(() => _playCount++);
    _sealKey.currentState?.play();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Cold-mount seal',
      subtitle: 'Phase 12b · GlobeID seal loading state operator',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          // ── Viewport ────────────────────────────────────────
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF050912),
              borderRadius: BorderRadius.circular(Os2.rCard),
              border: Border.all(color: Os2.hairline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Os2.rCard),
              child: SealLoadingState(
                key: _sealKey,
                tone: _tone,
                autoPlay: false,
              ),
            ),
          ),
          const SizedBox(height: Os2.space4),
          // ── CTA ─────────────────────────────────────────────
          _PressCta(
            tone: _tone,
            replay: _playCount > 0,
            onTap: _play,
          ),
          const SizedBox(height: Os2.space5),
          // ── Tone picker ──────────────────────────────────────
          Os2Text.monoCap(
            'TONE · PICKER',
            color: _tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tone in _tones)
                _ToneChip(
                  label: tone.$1,
                  tone: tone.$2,
                  selected: _tone == tone.$2,
                  onTap: () => setState(() {
                    _tone = tone.$2;
                    _sealKey.currentState?.reset();
                    _playCount = 0;
                  }),
                ),
            ],
          ),
          const SizedBox(height: Os2.space5),
          // ── Phase ladder ────────────────────────────────────
          _PhaseLadder(tone: _tone),
        ],
      ),
    );
  }
}

class _PressCta extends StatelessWidget {
  const _PressCta({
    required this.tone,
    required this.replay,
    required this.onTap,
  });
  final Color tone;
  final bool replay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pressable(
        onTap: onTap,
        semanticLabel: replay ? 'Replay seal press' : 'Press seal',
        semanticHint: 'plays the cold-mount seal ceremony',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tone.withValues(alpha: 0.85),
                tone.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: tone),
            boxShadow: [
              BoxShadow(
                color: tone.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Os2Text.monoCap(
            replay ? 'REPLAY · SEAL' : 'PRESS · SEAL',
            color: const Color(0xFF050505),
            size: Os2.textXs,
          ),
        ),
      ),
    );
  }
}

class _ToneChip extends StatelessWidget {
  const _ToneChip({
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Pick tone $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? tone.withValues(alpha: 0.2)
              : const Color(0xFF0E0E12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? tone : tone.withValues(alpha: 0.35),
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tone,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: tone.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Os2Text.monoCap(
              label,
              color: selected ? tone : Os2.inkMid,
              size: Os2.textTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseLadder extends StatelessWidget {
  const _PhaseLadder({required this.tone});
  final Color tone;

  static const _rows = <(String, String, String)>[
    ('0.00 → 0.18', 'SUBSTRATE · FADE', 'OLED scrim eases in @ 290 ms'),
    ('0.18 → 0.48',
        'PRESS · OVERSHOOT', 'Disc scales 0.40 → 1.12 · easeOutBack'),
    (
      '0.48 → 0.62',
      'SETTLE · INK',
      'Disc returns 1.12 → 1.00 · signature haptic'
    ),
    ('0.62 → 0.80', 'BLEED · RADIATE', 'Ink ring radiates +85 % · fade 1→0'),
    ('0.80 → 1.00', 'MARKED · GLOBE · ID', 'Mono-cap label fades up'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap('PHASE · LADDER', color: tone, size: Os2.textTiny),
          const SizedBox(height: Os2.space3),
          for (final row in _rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  child: Os2Text.monoCap(
                    row.$1,
                    color: tone.withValues(alpha: 0.8),
                    size: Os2.textTiny,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Os2Text.monoCap(
                        row.$2,
                        color: Os2.inkBright,
                        size: Os2.textTiny,
                      ),
                      const SizedBox(height: 2),
                      Os2Text.monoCap(
                        row.$3,
                        color: Os2.inkMid,
                        size: Os2.textTiny,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
