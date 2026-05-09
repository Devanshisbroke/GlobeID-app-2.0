import 'package:flutter/material.dart';

/// Deterministic smart suggestion engine.
///
/// Port of `smartSuggestions.ts` — takes user state signals (documents,
/// trips, wallet, score, time of day) and emits a prioritised list of
/// actionable nudges. Runs in <10 ms, fully offline, no ML required.
class SmartSuggestion {
  const SmartSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.tone = const Color(0xFF0EA5E9),
    this.priority = 0,
    this.dismissable = true,
  });

  final String id;
  final SuggestionType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color tone;
  final int priority; // Higher = more important, shown first.
  final bool dismissable;
}

enum SuggestionType {
  visa,
  packing,
  currency,
  identity,
  travel,
  weather,
  security,
  social,
  general,
}

/// Generate contextual suggestions from current user state.
///
/// Inputs are raw signals; the function applies deterministic rules
/// and returns suggestions sorted by priority (highest first).
List<SmartSuggestion> generateSuggestions({
  required int identityScore,
  required int tripCount,
  required int documentCount,
  required int walletBalanceCount,
  required bool hasUpcomingTrip,
  required String? nextTripDestination,
  required int daysUntilTrip,
  required int hour,
}) {
  final suggestions = <SmartSuggestion>[];

  // Identity score improvement
  if (identityScore < 40) {
    suggestions.add(SmartSuggestion(
      id: 'boost-identity',
      type: SuggestionType.identity,
      title: 'Boost your identity score',
      subtitle: 'Score $identityScore — verify email and phone to reach 60+',
      icon: Icons.verified_user_rounded,
      route: '/identity',
      tone: const Color(0xFF7E22CE),
      priority: 90,
      dismissable: false,
    ));
  } else if (identityScore < 70) {
    suggestions.add(SmartSuggestion(
      id: 'identity-next-tier',
      type: SuggestionType.identity,
      title: 'Next tier: Verified',
      subtitle: 'Add a government ID to unlock premium features',
      icon: Icons.workspace_premium_rounded,
      route: '/identity',
      tone: const Color(0xFF8B5CF6),
      priority: 60,
    ));
  }

  // Trip preparation
  if (hasUpcomingTrip && daysUntilTrip <= 7) {
    suggestions.add(SmartSuggestion(
      id: 'trip-prep',
      type: SuggestionType.travel,
      title: '${nextTripDestination ?? 'Trip'} in $daysUntilTrip days',
      subtitle: 'Review packing list, visa docs, and currency',
      icon: Icons.flight_takeoff_rounded,
      route: '/travel',
      tone: const Color(0xFFE11D48),
      priority: 100,
      dismissable: false,
    ));
  }

  if (hasUpcomingTrip && daysUntilTrip <= 14) {
    suggestions.add(SmartSuggestion(
      id: 'packing-reminder',
      type: SuggestionType.packing,
      title: 'Start packing checklist',
      subtitle: 'AI-curated list based on your destination and forecast',
      icon: Icons.luggage_rounded,
      route: '/packing',
      tone: const Color(0xFFD97706),
      priority: 70,
    ));

    suggestions.add(SmartSuggestion(
      id: 'currency-prep',
      type: SuggestionType.currency,
      title: 'Get local currency',
      subtitle: 'Check exchange rates and load your travel wallet',
      icon: Icons.currency_exchange_rounded,
      route: '/multi-currency',
      tone: const Color(0xFF059669),
      priority: 65,
    ));
  }

  // Wallet nudge
  if (walletBalanceCount == 0) {
    suggestions.add(SmartSuggestion(
      id: 'add-wallet',
      type: SuggestionType.currency,
      title: 'Set up your wallet',
      subtitle: 'Add a currency to track balances and expenses',
      icon: Icons.account_balance_wallet_rounded,
      route: '/wallet',
      tone: const Color(0xFF0EA5E9),
      priority: 50,
    ));
  }

  // Document scan
  if (documentCount == 0) {
    suggestions.add(SmartSuggestion(
      id: 'scan-first-doc',
      type: SuggestionType.identity,
      title: 'Scan your passport',
      subtitle: 'Machine-readable zone scan to build your identity profile',
      icon: Icons.document_scanner_rounded,
      route: '/scan',
      tone: const Color(0xFF06B6D4),
      priority: 80,
    ));
  }

  // No trips yet
  if (tripCount == 0) {
    suggestions.add(SmartSuggestion(
      id: 'first-trip',
      type: SuggestionType.travel,
      title: 'Plan your first trip',
      subtitle: 'Explore destinations and create your travel timeline',
      icon: Icons.explore_rounded,
      route: '/planner',
      tone: const Color(0xFF10B981),
      priority: 45,
    ));
  }

  // Time-of-day contextual
  if (hour >= 18 || hour < 6) {
    suggestions.add(SmartSuggestion(
      id: 'evening-review',
      type: SuggestionType.general,
      title: 'Daily travel briefing',
      subtitle: 'Review tomorrow\'s itinerary, weather, and alerts',
      icon: Icons.nightlight_rounded,
      route: '/intelligence',
      tone: const Color(0xFF6366F1),
      priority: 30,
    ));
  }

  // Security audit
  suggestions.add(SmartSuggestion(
    id: 'security-audit',
    type: SuggestionType.security,
    title: 'Security audit',
    subtitle: 'Review access logs and session history',
    icon: Icons.shield_rounded,
    route: '/audit-log',
    tone: const Color(0xFFEA580C),
    priority: 20,
  ));

  suggestions.sort((a, b) => b.priority.compareTo(a.priority));
  return suggestions;
}
