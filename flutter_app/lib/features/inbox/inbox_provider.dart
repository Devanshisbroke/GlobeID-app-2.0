import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inbox_models.dart';

/// In-memory inbox. Seeded on first read with realistic-looking
/// notifications across every kind so the UI always has content.
/// State is process-local — no persistence layer is required for the
/// flagship surface to feel alive.
class InboxNotifier extends StateNotifier<List<InboxItem>> {
  InboxNotifier() : super(_seed());

  static List<InboxItem> _seed() {
    final now = DateTime.now();
    return [
      InboxItem(
        id: 'i_gate_change',
        kind: InboxKind.travel,
        title: 'Gate change · LH 401',
        body: 'New gate B22 at Frankfurt Airport. Boarding starts in 38 min.',
        timestamp: now.subtract(const Duration(minutes: 12)),
        deeplink: '/travel',
        priority: InboxPriority.high,
        heroIcon: null,
      ),
      InboxItem(
        id: 'i_score_up',
        kind: InboxKind.identity,
        title: 'Trust score +6',
        body: 'New verified factor: passport biometric scan succeeded.',
        timestamp: now.subtract(const Duration(minutes: 28)),
        deeplink: '/identity',
        priority: InboxPriority.normal,
      ),
      InboxItem(
        id: 'i_fx_alert',
        kind: InboxKind.money,
        title: 'EUR → USD favourable rate',
        body: 'EUR strengthened 0.4% in the last 6h. Lock in your transfer?',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 14)),
        deeplink: '/multi-currency',
        priority: InboxPriority.normal,
      ),
      InboxItem(
        id: 'i_delay_warn',
        kind: InboxKind.alert,
        title: 'Delay risk · BA 286',
        body: 'Departure tomorrow may slip 35–55 min based on inbound aircraft.',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 41)),
        deeplink: '/intelligence',
        priority: InboxPriority.high,
      ),
      InboxItem(
        id: 'i_doc_exp',
        kind: InboxKind.identity,
        title: 'Driving license expires in 47 days',
        body: 'Renew now from your Vault to avoid travel disruption.',
        timestamp: now.subtract(const Duration(hours: 5)),
        deeplink: '/vault',
        priority: InboxPriority.normal,
      ),
      InboxItem(
        id: 'i_traveler_near',
        kind: InboxKind.social,
        title: 'Aria is in Tokyo, too',
        body: '3 of your contacts are within 12 km of you right now.',
        timestamp: now.subtract(const Duration(hours: 7, minutes: 22)),
        deeplink: '/social',
        priority: InboxPriority.low,
        read: true,
      ),
      InboxItem(
        id: 'i_feature_drop',
        kind: InboxKind.system,
        title: 'New: Travel intelligence v2',
        body: 'Connection-risk scoring + cinematic flight-arc playback.',
        timestamp: now.subtract(const Duration(hours: 18)),
        deeplink: '/intelligence',
        priority: InboxPriority.low,
        read: true,
      ),
      InboxItem(
        id: 'i_charge',
        kind: InboxKind.money,
        title: 'Charge approved · €184.20',
        body: 'Hotel Le Meurice · 1 night · Paris',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        deeplink: '/wallet',
        priority: InboxPriority.normal,
        read: true,
      ),
      InboxItem(
        id: 'i_visa_change',
        kind: InboxKind.alert,
        title: 'Visa policy updated · Indonesia',
        body: 'Visa-on-arrival fee raised to USD 50. Effective in 12 days.',
        timestamp: now.subtract(const Duration(days: 1, hours: 14)),
        deeplink: '/explore',
        priority: InboxPriority.normal,
        read: true,
      ),
      InboxItem(
        id: 'i_signin',
        kind: InboxKind.identity,
        title: 'New sign-in from Berlin',
        body: 'Confirm this was you to keep your devices in sync.',
        timestamp: now.subtract(const Duration(days: 2)),
        deeplink: '/audit-log',
        priority: InboxPriority.high,
        read: true,
      ),
      InboxItem(
        id: 'i_loyalty',
        kind: InboxKind.social,
        title: '3 new countries this quarter',
        body: 'You are 1 country away from your 30-mark stamp.',
        timestamp: now.subtract(const Duration(days: 3)),
        deeplink: '/passport-book',
        priority: InboxPriority.low,
        read: true,
      ),
    ];
  }

  void markRead(String id) {
    state = [
      for (final i in state) i.id == id ? i.copyWith(read: true) : i,
    ];
  }

  void markAllRead() {
    state = [for (final i in state) i.copyWith(read: true)];
  }

  void dismiss(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void clear() {
    state = const [];
  }

  int get unreadCount => state.where((i) => !i.read).length;
}

final inboxProvider =
    StateNotifierProvider<InboxNotifier, List<InboxItem>>((ref) {
  return InboxNotifier();
});

/// Convenience selector for the unread badge in app chrome.
final inboxUnreadProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).where((i) => !i.read).length;
});
