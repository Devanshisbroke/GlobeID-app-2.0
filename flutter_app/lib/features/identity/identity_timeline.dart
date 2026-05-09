import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_tokens.dart';

/// Identity timeline — Notion-style activity stream of credential events.
///
/// Each event shows icon + title + timestamp + score delta. Entries
/// animate in with a staggered cascade.
class IdentityTimeline extends StatelessWidget {
  const IdentityTimeline({super.key, required this.events});

  final List<IdentityEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < events.length; i++)
          _EventRow(event: events[i], isLast: i == events.length - 1)
              .animate()
              .fadeIn(
                duration: AppTokens.durationMd,
                delay: Duration(milliseconds: 60 * i),
                curve: AppTokens.easeOutSoft,
              )
              .slideX(begin: -0.02, end: 0),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.isLast});
  final IdentityEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deltaColor = event.scoreDelta > 0
        ? const Color(0xFF22C55E)
        : event.scoreDelta < 0
            ? const Color(0xFFEF4444)
            : theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final deltaSign = event.scoreDelta > 0 ? '+' : '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: event.tone.withValues(alpha: 0.14),
                    border: Border.all(
                      color: event.tone.withValues(alpha: 0.32),
                      width: 0.7,
                    ),
                  ),
                  child: Icon(event.icon, size: 15, color: event.tone),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.2,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppTokens.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.scoreDelta != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                            color: deltaColor.withValues(alpha: 0.12),
                          ),
                          child: Text(
                            '$deltaSign${event.scoreDelta}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: deltaColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.60),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.timestamp,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w600,
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

class IdentityEvent {
  const IdentityEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    this.tone = const Color(0xFF0EA5E9),
    this.scoreDelta = 0,
  });

  final String title;
  final String description;
  final String timestamp;
  final IconData icon;
  final Color tone;
  final int scoreDelta;

  /// Demo events for development.
  static List<IdentityEvent> demo() => const [
        IdentityEvent(
          title: 'Email verified',
          description: 'Primary email confirmed via one-time link',
          timestamp: '2 hours ago',
          icon: Icons.email_rounded,
          tone: Color(0xFF0EA5E9),
          scoreDelta: 8,
        ),
        IdentityEvent(
          title: 'Passport MRZ scanned',
          description: 'Machine-readable zone parsed and stored locally',
          timestamp: '1 day ago',
          icon: Icons.document_scanner_rounded,
          tone: Color(0xFF22C55E),
          scoreDelta: 15,
        ),
        IdentityEvent(
          title: 'Phone number linked',
          description: 'SMS verification completed for +1 *** *** 4821',
          timestamp: '3 days ago',
          icon: Icons.phone_android_rounded,
          tone: Color(0xFF8B5CF6),
          scoreDelta: 10,
        ),
        IdentityEvent(
          title: 'Biometric enrolled',
          description: 'Face ID / fingerprint stored in Secure Enclave',
          timestamp: '1 week ago',
          icon: Icons.fingerprint_rounded,
          tone: Color(0xFFD97706),
          scoreDelta: 12,
        ),
        IdentityEvent(
          title: 'Account created',
          description: 'GlobeID identity initialized',
          timestamp: '2 weeks ago',
          icon: Icons.person_add_rounded,
          tone: Color(0xFF6366F1),
          scoreDelta: 5,
        ),
      ];
}
