import 'package:flutter/material.dart';

/// Deterministic contextual intelligence engine.
///
/// Combines time + location + trip + wallet + identity state
/// into prioritized contextual insights. All on-device, <10ms.
class ContextualIntelligence {
  ContextualIntelligence._();

  static List<ContextualInsight> generate({
    required DateTime now,
    String? currentAirport,
    String? activeDestination,
    int identityScore = 0,
    int daysUntilPassportExpiry = 365,
    double walletBalanceUsd = 0,
    String? nextFlightGate,
    int? minutesToGate,
  }) {
    final insights = <ContextualInsight>[];
    final hour = now.hour;

    if (currentAirport != null) {
      insights.add(ContextualInsight(
        title: 'You\'re at $currentAirport',
        description: 'Lounge, shops, and gates nearby',
        icon: Icons.flight_takeoff_rounded,
        tone: const Color(0xFF0EA5E9),
        priority: 10,
        actionRoute: '/airport',
      ));
      if (nextFlightGate != null && minutesToGate != null) {
        insights.add(ContextualInsight(
          title: 'Gate $nextFlightGate — ${minutesToGate}min walk',
          description: minutesToGate <= 15
              ? 'You have time for coffee.'
              : 'Head to your gate soon.',
          icon: Icons.directions_walk_rounded,
          tone: minutesToGate <= 10
              ? const Color(0xFFF59E0B)
              : const Color(0xFF22C55E),
          priority: 9,
        ));
      }
    }

    if (activeDestination != null) {
      insights.add(ContextualInsight(
        title: 'Weather in $activeDestination',
        description: '24°C partly cloudy — pack light layers',
        icon: Icons.wb_sunny_rounded,
        tone: const Color(0xFFD97706),
        priority: 7,
      ));
    }

    if (daysUntilPassportExpiry < 180) {
      insights.add(ContextualInsight(
        title: 'Passport expires in $daysUntilPassportExpiry days',
        description: daysUntilPassportExpiry < 90
            ? 'Urgent — renew now'
            : 'Renew before your next trip',
        icon: Icons.warning_amber_rounded,
        tone: daysUntilPassportExpiry < 90
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B),
        priority: daysUntilPassportExpiry < 90 ? 9 : 6,
        actionRoute: '/identity',
      ));
    }

    if (walletBalanceUsd < 100 && walletBalanceUsd > 0) {
      insights.add(ContextualInsight(
        title: 'Low travel balance',
        description: '\$${walletBalanceUsd.toStringAsFixed(0)} remaining',
        icon: Icons.account_balance_wallet_rounded,
        tone: const Color(0xFFF59E0B),
        priority: 5,
        actionRoute: '/wallet',
      ));
    }

    if (identityScore < 50) {
      insights.add(ContextualInsight(
        title: 'Boost your identity score',
        description: 'Verify email and phone to unlock features',
        icon: Icons.trending_up_rounded,
        tone: const Color(0xFF8B5CF6),
        priority: 4,
        actionRoute: '/identity',
      ));
    }

    if (hour >= 6 && hour < 9) {
      insights.add(ContextualInsight(
        title: 'Morning briefing',
        description: 'Check today\'s schedule and alerts',
        icon: Icons.wb_twilight_rounded,
        tone: const Color(0xFFD97706),
        priority: 4,
        actionRoute: '/intelligence',
      ));
    }

    insights.sort((a, b) => b.priority.compareTo(a.priority));
    return insights;
  }
}

class ContextualInsight {
  const ContextualInsight({
    required this.title,
    required this.description,
    required this.icon,
    this.tone = const Color(0xFF0EA5E9),
    this.priority = 5,
    this.actionRoute,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color tone;
  final int priority;
  final String? actionRoute;
}
