import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/copilot/copilot_hub_models.dart';
import '../../features/copilot/copilot_hub_provider.dart';
import '../../os2/os2_tokens.dart';
import 'copilot_suggestion_strip.dart';

/// `CopilotMomentStrip` — provider-aware wrapper around
/// [CopilotSuggestionStrip].
///
/// Selects the most urgent suggestion from
/// [copilotHubSuggestionsProvider] matching the supplied
/// [contextKinds], maps domain types onto the cinematic widget's API,
/// and wires the CTA to the suggestion's deep link.
///
/// Designed to drop in at the top of any of the six worlds so the
/// Copilot voice is always present in context. Returns
/// [SizedBox.shrink] when no suggestion matches — the strip never
/// reserves space when there is nothing to say.
class CopilotMomentStrip extends ConsumerWidget {
  const CopilotMomentStrip({
    super.key,
    required this.contextKinds,
    this.tone,
    this.padding = EdgeInsets.zero,
  });

  /// Kinds of Copilot suggestions this surface cares about. The most
  /// urgent suggestion of any of these kinds is picked.
  final Set<CopilotHubKind> contextKinds;

  /// Optional tone override (defaults to the strip's own pulse tone).
  final Color? tone;

  /// Outer padding around the strip card.
  final EdgeInsets padding;

  CopilotUrgency _mapUrgency(CopilotHubUrgency u) {
    switch (u) {
      case CopilotHubUrgency.passive:
        return CopilotUrgency.normal;
      case CopilotHubUrgency.notable:
        return CopilotUrgency.armed;
      case CopilotHubUrgency.urgent:
        return CopilotUrgency.active;
      case CopilotHubUrgency.critical:
        return CopilotUrgency.critical;
    }
  }

  IconData _glyphFor(CopilotHubKind kind, IconData? override) {
    if (override != null) return override;
    switch (kind) {
      case CopilotHubKind.travel:
        return Icons.flight_takeoff_rounded;
      case CopilotHubKind.wallet:
        return Icons.currency_exchange_rounded;
      case CopilotHubKind.identity:
        return Icons.verified_user_rounded;
      case CopilotHubKind.boarding:
        return Icons.confirmation_number_rounded;
      case CopilotHubKind.advisory:
        return Icons.public_rounded;
    }
  }

  Color _toneFor(CopilotHubKind kind) {
    switch (kind) {
      case CopilotHubKind.travel:
        return Os2.travelTone;
      case CopilotHubKind.wallet:
        return Os2.walletTone;
      case CopilotHubKind.identity:
        return Os2.identityTone;
      case CopilotHubKind.boarding:
        return Os2.signalLive;
      case CopilotHubKind.advisory:
        return Os2.signalCritical;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(copilotHubSuggestionsProvider);
    final inScope = all.where((s) => contextKinds.contains(s.kind)).toList();
    if (inScope.isEmpty) {
      return const SizedBox.shrink();
    }
    // The hub provider sorts by urgency; the first in-scope is the
    // most urgent for this world.
    final pick = inScope.first;
    return Padding(
      padding: padding,
      child: CopilotSuggestionStrip(
        eyebrow: pick.eyebrow,
        headline: pick.title,
        subhead: pick.subtitle,
        ctaLabel: pick.ctaLabel,
        glyph: _glyphFor(pick.kind, pick.glyph),
        tone: tone ?? pick.tone ?? _toneFor(pick.kind),
        urgency: _mapUrgency(pick.urgency),
        impactBadge: pick.impactBadge,
        countdown: pick.countdown,
        onCta: () {
          final deeplink = pick.deeplink;
          if (deeplink.isNotEmpty) {
            GoRouter.of(context).push(deeplink);
          }
        },
        onLongPress: () => GoRouter.of(context).push('/copilot/hub'),
      ),
    );
  }
}
