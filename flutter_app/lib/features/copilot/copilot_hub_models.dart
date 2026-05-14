import 'package:flutter/material.dart';

/// `CopilotHubKind` — the recommendation domain. Drives tone, icon,
/// and copy default-overrides on the Hub card.
enum CopilotHubKind {
  /// Travel doc renewal (visa expiry, passport renewal, etc).
  travel,

  /// Wallet / FX move (convert now, balance rebase, etc).
  wallet,

  /// Identity tier / trust score (score breakdown, attestation).
  identity,

  /// Boarding / airport / gate movement.
  boarding,

  /// Country advisory (threat escalation, advisory update).
  advisory,
}

/// `CopilotHubUrgency` — how loudly the Hub should surface this
/// recommendation. Drives breathing cadence and eyebrow tone.
enum CopilotHubUrgency {
  /// Cosmetic — quiet card, idle breathing.
  passive,

  /// Worth surfacing — armed breathing, normal eyebrow.
  notable,

  /// Time-bounded — active breathing, urgent eyebrow.
  urgent,

  /// Now-or-never — committed breathing, red eyebrow.
  critical,
}

/// `CopilotHubSuggestion` — one row in the Hub's "Today" list.
///
/// Holds the *what*, the *why*, the *upside*, and the deep-link the
/// CTA points at. Pure data — no widgets — so it's easy to test,
/// JSON-encode, and feed from a real backend in a future phase.
class CopilotHubSuggestion {
  const CopilotHubSuggestion({
    required this.id,
    required this.kind,
    required this.urgency,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.deeplink,
    this.glyph,
    this.impactBadge,
    this.countdown,
    this.tone,
  });

  /// Stable id (e.g. `s_visa_renew_schengen`). Used for
  /// deduplication and analytics.
  final String id;

  final CopilotHubKind kind;
  final CopilotHubUrgency urgency;

  /// Mono-cap eyebrow shown above the title (e.g.
  /// `COPILOT · NOW`).
  final String eyebrow;

  /// Primary headline — short, declarative.
  final String title;

  /// Secondary line — concrete detail / number / context.
  final String subtitle;

  /// CTA label in mono-cap (e.g. `RENEW NOW`).
  final String ctaLabel;

  /// Internal deep-link the CTA navigates to.
  final String deeplink;

  /// Optional glyph rendered next to the eyebrow.
  final IconData? glyph;

  /// Optional impact pill — short "≈ $14 saved" / "+2 trust pts"
  /// blurb rendered below the subtitle.
  final String? impactBadge;

  /// Optional human-readable countdown shown as a chip (e.g.
  /// `11 DAYS` or `4H 12M`). Drives the urgency feel — when
  /// present, the card carries a clock glyph.
  final String? countdown;

  /// Optional override tone. When null, the Hub picks the tone
  /// for the [kind] / [urgency] combination.
  final Color? tone;
}
