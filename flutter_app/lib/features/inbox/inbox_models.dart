import 'package:flutter/material.dart';

/// Notification kinds used by the global inbox. Each maps to an
/// accent + icon + section bucket. New kinds can be added freely.
enum InboxKind {
  alert, // critical / warning
  travel, // gate change, boarding, delay, layover
  identity, // tier change, document expiring, security event
  money, // payment, fx alert, statement
  system, // app update, feature drop
  social, // friend nearby, follower, comment
}

/// One inbox notification.
class InboxItem {
  const InboxItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.deeplink,
    this.read = false,
    this.priority = InboxPriority.normal,
    this.actorAvatar,
    this.heroIcon,
  });

  final String id;
  final InboxKind kind;
  final String title;
  final String body;
  final DateTime timestamp;
  final String deeplink;
  final bool read;
  final InboxPriority priority;
  final String? actorAvatar;
  final IconData? heroIcon;

  InboxItem copyWith({bool? read}) => InboxItem(
        id: id,
        kind: kind,
        title: title,
        body: body,
        timestamp: timestamp,
        deeplink: deeplink,
        read: read ?? this.read,
        priority: priority,
        actorAvatar: actorAvatar,
        heroIcon: heroIcon,
      );
}

enum InboxPriority { low, normal, high, critical }

/// Cosmetic resolution for each kind.
class InboxKindResolved {
  const InboxKindResolved({
    required this.label,
    required this.icon,
    required this.accent,
  });
  final String label;
  final IconData icon;
  final Color accent;
}

InboxKindResolved resolveInboxKind(InboxKind kind) {
  switch (kind) {
    case InboxKind.alert:
      return const InboxKindResolved(
        label: 'Alerts',
        icon: Icons.notifications_active_rounded,
        accent: Color(0xFFE11D48),
      );
    case InboxKind.travel:
      return const InboxKindResolved(
        label: 'Travel',
        icon: Icons.flight_takeoff_rounded,
        accent: Color(0xFFEA580C),
      );
    case InboxKind.identity:
      return const InboxKindResolved(
        label: 'Identity',
        icon: Icons.verified_user_rounded,
        accent: Color(0xFF7C3AED),
      );
    case InboxKind.money:
      return const InboxKindResolved(
        label: 'Money',
        icon: Icons.account_balance_wallet_rounded,
        accent: Color(0xFF10B981),
      );
    case InboxKind.system:
      return const InboxKindResolved(
        label: 'System',
        icon: Icons.bolt_rounded,
        accent: Color(0xFF06B6D4),
      );
    case InboxKind.social:
      return const InboxKindResolved(
        label: 'Social',
        icon: Icons.people_alt_rounded,
        accent: Color(0xFF3B82F6),
      );
  }
}
