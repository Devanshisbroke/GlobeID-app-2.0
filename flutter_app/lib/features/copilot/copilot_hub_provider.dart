import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'copilot_hub_models.dart';

/// `copilotHubSuggestionsProvider` — Riverpod provider that returns
/// the canonical list of Copilot recommendations the Hub renders.
///
/// Pure data, deterministic. Today the list is seeded in-process so
/// the demo always shows the same cinematic moments; a future
/// phase (Phase 10) will swap the implementation for one backed by
/// the real intelligence layer without touching consumers.
///
/// Suggestions are returned sorted by urgency (critical → urgent →
/// notable → passive); within a tier the seed order is preserved
/// so the hottest moments always come first.
final copilotHubSuggestionsProvider =
    Provider<List<CopilotHubSuggestion>>((ref) {
  return _CopilotHubSeed.seed();
});

/// `copilotHubUrgentCountProvider` — count of suggestions in the
/// `urgent` + `critical` tiers. Useful for bell badges and the
/// "N items need attention" hero strip.
final copilotHubUrgentCountProvider = Provider<int>((ref) {
  return ref.watch(copilotHubSuggestionsProvider).where(
    (s) {
      return s.urgency == CopilotHubUrgency.urgent ||
          s.urgency == CopilotHubUrgency.critical;
    },
  ).length;
});

/// `copilotHubByKindProvider` — group suggestions by [CopilotHubKind]
/// so the Hub can render per-kind sections without re-iterating.
final copilotHubByKindProvider =
    Provider<Map<CopilotHubKind, List<CopilotHubSuggestion>>>((ref) {
  final out = <CopilotHubKind, List<CopilotHubSuggestion>>{};
  for (final s in ref.watch(copilotHubSuggestionsProvider)) {
    out.putIfAbsent(s.kind, () => []).add(s);
  }
  return out;
});

/// Stable seed data — guaranteed deterministic across runs.
class _CopilotHubSeed {
  static int _urgencyRank(CopilotHubUrgency u) {
    switch (u) {
      case CopilotHubUrgency.critical:
        return 0;
      case CopilotHubUrgency.urgent:
        return 1;
      case CopilotHubUrgency.notable:
        return 2;
      case CopilotHubUrgency.passive:
        return 3;
    }
  }

  static List<CopilotHubSuggestion> seed() {
    final out = <CopilotHubSuggestion>[
      const CopilotHubSuggestion(
        id: 's_passport_expiry',
        kind: CopilotHubKind.travel,
        urgency: CopilotHubUrgency.critical,
        eyebrow: 'COPILOT · DOC',
        title: 'Passport expires in 11 days',
        subtitle: 'Renew before 24 May to keep cleared trips on track.',
        ctaLabel: 'RENEW PASSPORT',
        deeplink: '/passport',
        glyph: Icons.menu_book_rounded,
        countdown: '11 DAYS',
        impactBadge: 'BLOCKS 3 UPCOMING TRIPS',
      ),
      const CopilotHubSuggestion(
        id: 's_visa_renew_schengen',
        kind: CopilotHubKind.travel,
        urgency: CopilotHubUrgency.urgent,
        eyebrow: 'COPILOT · VISA',
        title: 'Schengen visa renewal window opens today',
        subtitle:
            'Apply now to avoid the 6-week summer backlog.',
        ctaLabel: 'OPEN RENEWAL',
        deeplink: '/visa',
        glyph: Icons.flight_takeoff_rounded,
        countdown: '48 DAYS',
        impactBadge: 'TRIP IN 8 WEEKS',
      ),
      const CopilotHubSuggestion(
        id: 's_fx_eur_convert',
        kind: CopilotHubKind.wallet,
        urgency: CopilotHubUrgency.urgent,
        eyebrow: 'COPILOT · FX',
        title: 'Convert \$500 to EUR today',
        subtitle:
            'EUR/USD spiked 0.74% overnight — saves ≈ \$14 vs. yesterday.',
        ctaLabel: 'OPEN EXCHANGE',
        deeplink: '/wallet/exchange',
        glyph: Icons.swap_horiz_rounded,
        impactBadge: '≈ €460 RECEIVED',
      ),
      const CopilotHubSuggestion(
        id: 's_trust_breakdown',
        kind: CopilotHubKind.identity,
        urgency: CopilotHubUrgency.notable,
        eyebrow: 'COPILOT · TRUST',
        title: 'Your trust score moved up 4 points',
        subtitle:
            'Selective disclosure on hotel check-ins lifted your '
            'financial reliability factor.',
        ctaLabel: 'SEE BREAKDOWN',
        deeplink: '/identity',
        glyph: Icons.workspace_premium_rounded,
        impactBadge: '+4 PTS · TIER GOLD',
      ),
      const CopilotHubSuggestion(
        id: 's_advisory_escalation',
        kind: CopilotHubKind.advisory,
        urgency: CopilotHubUrgency.notable,
        eyebrow: 'COPILOT · ADVISORY',
        title: 'Bali advisory moved from MODERATE to HIGH',
        subtitle:
            'Volcanic activity on the east side. Review before your '
            'June 2 leg.',
        ctaLabel: 'OPEN DOSSIER',
        deeplink: '/country',
        glyph: Icons.public_rounded,
        impactBadge: 'TRIP IN 14 DAYS',
      ),
      const CopilotHubSuggestion(
        id: 's_boarding_lhr_b27',
        kind: CopilotHubKind.boarding,
        urgency: CopilotHubUrgency.passive,
        eyebrow: 'COPILOT · BOARDING',
        title: 'Gate B27 walking time ≈ 9 min',
        subtitle:
            'Boarding opens in 1h 18m. Lounge ahead has 12 min wait.',
        ctaLabel: 'OPEN BOARDING',
        deeplink: '/airport',
        glyph: Icons.directions_walk_rounded,
        countdown: '1H 18M',
        impactBadge: 'LOUNGE · 12 MIN WAIT',
      ),
    ];
    out.sort((a, b) => _urgencyRank(a.urgency)
        .compareTo(_urgencyRank(b.urgency)));
    return List.unmodifiable(out);
  }
}
