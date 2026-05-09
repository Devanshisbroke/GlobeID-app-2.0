import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/pressable.dart';

/// Rich action card rendered inside the Copilot chat bubble stream.
///
/// Types: booking confirmation, gate change, FX alert, document expiry,
/// spending insight, weather warning. Each has a primary action button
/// wired to go_router.
class AgentActionCard extends StatelessWidget {
  const AgentActionCard({super.key, required this.action});
  final AgentAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            action.tone.withValues(alpha: 0.14),
            action.tone.withValues(alpha: 0.04)
          ],
        ),
        border: Border.all(color: action.tone.withValues(alpha: 0.20)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                color: action.tone.withValues(alpha: 0.18),
              ),
              child: Icon(action.icon, color: action.tone, size: 16)),
          const SizedBox(width: AppTokens.space2),
          Text(action.category.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: action.tone,
              )),
          const Spacer(),
          Text(action.timestamp,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              )),
        ]),
        const SizedBox(height: AppTokens.space2),
        Text(action.title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(action.body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            )),
        if (action.route != null) ...[
          const SizedBox(height: AppTokens.space3),
          Pressable(
              scale: 0.97,
              onTap: () {
                HapticFeedback.lightImpact();
                GoRouter.of(context).push(action.route!);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  gradient: LinearGradient(colors: [
                    action.tone,
                    action.tone.withValues(alpha: 0.7)
                  ]),
                  boxShadow: [
                    BoxShadow(
                        color: action.tone.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Text(action.actionLabel ?? 'View',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              )),
        ],
      ]),
    );
  }
}

class AgentAction {
  const AgentAction({
    required this.category,
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
    this.route,
    this.actionLabel,
    this.timestamp = 'Just now',
  });
  final String category, title, body, timestamp;
  final IconData icon;
  final Color tone;
  final String? route, actionLabel;

  /// Demo action cards for the copilot empty state.
  static List<AgentAction> demoActions() => const [
        AgentAction(
            category: 'Flight',
            title: 'Gate changed to B44',
            body:
                'Your LH 401 FRA→JFK gate has moved from A22 to B44. Terminal shuttle takes 8 min.',
            icon: Icons.flight_rounded,
            tone: Color(0xFFE11D48),
            route: '/travel',
            actionLabel: 'View Trip'),
        AgentAction(
            category: 'Wallet',
            title: 'JPY dropped 2.1%',
            body:
                'Japanese Yen fell vs EUR. Good time to preload ¥ for your Tokyo trip next week.',
            icon: Icons.currency_exchange_rounded,
            tone: Color(0xFF22C55E),
            route: '/multi-currency',
            actionLabel: 'Buy JPY'),
        AgentAction(
            category: 'Document',
            title: 'Passport expires in 47 days',
            body:
                'Your German passport expires Aug 2026. Many countries require 6-month validity.',
            icon: Icons.warning_rounded,
            tone: Color(0xFFF59E0B),
            route: '/identity',
            actionLabel: 'Renew Info'),
        AgentAction(
            category: 'Insight',
            title: 'You spent 3x on food this trip',
            body:
                'Tokyo dining budget exceeded by 210%. Consider switching to konbini for lunches.',
            icon: Icons.restaurant_rounded,
            tone: Color(0xFF8B5CF6),
            route: '/analytics',
            actionLabel: 'See Breakdown'),
      ];
}
