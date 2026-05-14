import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../motion/motion.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/pressable.dart';
import 'copilot_hub_models.dart';
import 'copilot_hub_provider.dart';

/// `CopilotHubScreen` — the one place to see every Copilot
/// recommendation in flight.
///
/// Apple Wallet shows you cards. GlobeID shows you a *room* full of
/// proactive intelligence — what's expiring, what's spiking, what's
/// escalating, all in mono-cap chrome with gold thread.
///
/// Composes existing GlobeID primitives only:
///   • [Os2Text] variants for typography
///   • [BreathingHalo] for the alive thread on critical rows
///   • [Pressable] + Semantics on every affordance
///   • foil-gold gradients on hero glyphs and CTAs
class CopilotHubScreen extends ConsumerWidget {
  const CopilotHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(copilotHubSuggestionsProvider);
    final urgentCount = ref.watch(copilotHubUrgentCountProvider);
    return Scaffold(
      backgroundColor: Os2.canvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Chrome(
                urgentCount: urgentCount,
                total: suggestions.length,
                onClose: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/copilot');
                  }
                },
              ),
            ),
            const SliverToBoxAdapter(child: _GoldHairlineDivider()),
            const SliverToBoxAdapter(child: SizedBox(height: Os2.space5)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Os2.space5,
                    0,
                    Os2.space5,
                    Os2.space3,
                  ),
                  child: _HubCard(
                    suggestion: suggestions[i],
                    onTap: () {
                      Haptics.tap();
                      context.push(suggestions[i].deeplink);
                    },
                  ),
                ),
                childCount: suggestions.length,
              ),
            ),
            const SliverToBoxAdapter(child: _GoldHairlineDivider()),
            SliverToBoxAdapter(
              child: _Footer(onAsk: () {
                Haptics.tap();
                context.push('/copilot');
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Chrome
// ─────────────────────────────────────────────────────────────────

class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.urgentCount,
    required this.total,
    required this.onClose,
  });

  final int urgentCount;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final urgentText = switch (urgentCount) {
      0 => 'ALL CLEAR · $total ITEMS',
      1 => '1 ITEM NEEDS ATTENTION',
      _ => '$urgentCount ITEMS NEED ATTENTION',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Os2.space5,
        Os2.space5,
        Os2.space5,
        Os2.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Os2Text.monoCap(
                  'GLOBE·ID · COPILOT',
                  color: Os2.inkMid,
                  size: Os2.textXs,
                ),
              ),
              Pressable(
                scale: 0.92,
                semanticLabel: 'Close Copilot Hub',
                semanticHint: 'returns to the chat surface',
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(Os2.space2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Os2.floor2,
                    border: Border.all(color: Os2.hairline),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Os2.inkHigh,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          const Os2Text.headline(
            'Your travel intelligence',
            color: Os2.inkBright,
          ),
          const SizedBox(height: Os2.space2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Os2.space3,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: urgentCount > 0
                  ? Os2.goldDeep.withValues(alpha: 0.12)
                  : Os2.floor2,
              borderRadius: BorderRadius.circular(Os2.rChip),
              border: Border.all(
                color: urgentCount > 0
                    ? Os2.goldDeep.withValues(alpha: 0.34)
                    : Os2.hairline,
              ),
            ),
            child: Os2Text.monoCap(
              urgentText,
              color: urgentCount > 0
                  ? Os2.goldDeep
                  : Os2.inkMid,
              size: Os2.textTiny,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldHairlineDivider extends StatelessWidget {
  const _GoldHairlineDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Os2.strokeFine,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x00D4AF37),
            Os2.goldHairline,
            Color(0x00D4AF37),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Hub card
// ─────────────────────────────────────────────────────────────────

class _HubCard extends StatelessWidget {
  const _HubCard({required this.suggestion, required this.onTap});
  final CopilotHubSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(suggestion);
    final liveState = _liveStateFor(suggestion.urgency);
    final isLoud = suggestion.urgency == CopilotHubUrgency.critical ||
        suggestion.urgency == CopilotHubUrgency.urgent;

    return Pressable(
      scale: 0.98,
      semanticLabel: suggestion.title,
      semanticHint: 'opens ${suggestion.ctaLabel.toLowerCase()}',
      onTap: onTap,
      child: BreathingHalo(
        tone: tone,
        state: liveState,
        maxAlpha: isLoud ? 0.32 : 0.18,
        expand: isLoud ? 22 : 12,
        child: Container(
          padding: const EdgeInsets.all(Os2.space4),
          decoration: BoxDecoration(
            color: Os2.floor1,
            borderRadius: BorderRadius.circular(Os2.rCard),
            border: Border.all(
              color: tone.withValues(alpha: isLoud ? 0.40 : 0.20),
              width: Os2.strokeFine,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardEyebrow(suggestion: suggestion, tone: tone),
              const SizedBox(height: Os2.space3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (suggestion.glyph != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tone.withValues(alpha: 0.14),
                        border: Border.all(
                          color: tone.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Icon(
                        suggestion.glyph,
                        size: 22,
                        color: tone,
                      ),
                    ),
                    const SizedBox(width: Os2.space3),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Os2Text.title(
                          suggestion.title,
                          color: Os2.inkBright,
                          size: Os2.textLg,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Os2Text.body(
                          suggestion.subtitle,
                          color: Os2.inkHigh,
                          size: Os2.textSm,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (suggestion.impactBadge != null ||
                  suggestion.countdown != null) ...[
                const SizedBox(height: Os2.space3),
                Wrap(
                  spacing: Os2.space2,
                  runSpacing: 6,
                  children: [
                    if (suggestion.countdown != null)
                      _Chip(
                        label: suggestion.countdown!,
                        tone: tone,
                        glyph: Icons.schedule_rounded,
                      ),
                    if (suggestion.impactBadge != null)
                      _Chip(
                        label: suggestion.impactBadge!,
                        tone: Os2.inkMid,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Os2.space4),
              Container(
                height: Os2.touchMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isLoud ? Os2.foilGoldHero : null,
                  color: isLoud ? null : tone.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(Os2.rChip),
                  border: Border.all(
                    color: tone.withValues(alpha: isLoud ? 0.0 : 0.34),
                  ),
                ),
                child: Os2Text.monoCap(
                  suggestion.ctaLabel,
                  color: isLoud ? Os2.canvas : tone,
                  size: Os2.textSm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _toneFor(CopilotHubSuggestion s) {
    if (s.tone != null) return s.tone!;
    switch (s.urgency) {
      case CopilotHubUrgency.critical:
        return const Color(0xFFE11D48); // crimson
      case CopilotHubUrgency.urgent:
        return Os2.goldDeep;
      case CopilotHubUrgency.notable:
        return Os2.pulseTone;
      case CopilotHubUrgency.passive:
        return Os2.signalLive;
    }
  }

  LiveSurfaceState _liveStateFor(CopilotHubUrgency u) {
    switch (u) {
      case CopilotHubUrgency.critical:
        return LiveSurfaceState.committed;
      case CopilotHubUrgency.urgent:
        return LiveSurfaceState.active;
      case CopilotHubUrgency.notable:
        return LiveSurfaceState.armed;
      case CopilotHubUrgency.passive:
        return LiveSurfaceState.idle;
    }
  }
}

class _CardEyebrow extends StatelessWidget {
  const _CardEyebrow({required this.suggestion, required this.tone});
  final CopilotHubSuggestion suggestion;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tone,
          ),
        ),
        const SizedBox(width: Os2.space2),
        Expanded(
          child: Os2Text.monoCap(
            suggestion.eyebrow,
            color: tone,
            size: Os2.textTiny,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tone, this.glyph});
  final String label;
  final Color tone;
  final IconData? glyph;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space3,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Os2.rChip),
        border: Border.all(color: tone.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Icon(glyph, size: 12, color: tone),
            const SizedBox(width: 4),
          ],
          Os2Text.monoCap(
            label,
            color: tone,
            size: Os2.textTiny,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Footer — "Ask the Copilot anything"
// ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.onAsk});
  final VoidCallback onAsk;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Os2.space5,
        Os2.space5,
        Os2.space5,
        Os2.space7,
      ),
      child: Pressable(
        scale: 0.97,
        semanticLabel: 'Ask the Copilot',
        semanticHint: 'opens the chat surface',
        onTap: onAsk,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Os2.space4,
            vertical: Os2.space4,
          ),
          decoration: BoxDecoration(
            color: Os2.floor1,
            borderRadius: BorderRadius.circular(Os2.rCard),
            border: Border.all(color: Os2.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Os2.foilGoldHero,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Os2.canvas,
                  size: 18,
                ),
              ),
              const SizedBox(width: Os2.space3),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Os2Text.monoCap(
                      'OR ASK',
                      color: Os2.inkMid,
                      size: Os2.textTiny,
                    ),
                    SizedBox(height: 2),
                    Os2Text.title(
                      'Ask the Copilot anything',
                      color: Os2.inkBright,
                      size: Os2.textRg,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.east_rounded,
                color: Os2.inkLow,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
