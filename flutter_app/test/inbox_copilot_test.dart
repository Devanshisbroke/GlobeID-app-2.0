import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/features/inbox/inbox_models.dart';
import 'package:globeid/features/inbox/inbox_provider.dart';

void main() {
  group('InboxKind.copilot', () {
    test('resolves to champagne gold + COPILOT label + spark glyph', () {
      final res = resolveInboxKind(InboxKind.copilot);
      expect(res.label, 'Copilot');
      expect(res.icon, Icons.auto_awesome_rounded);
      expect(res.accent, const Color(0xFFD4AF37));
    });
  });

  group('InboxNotifier — pre-emptive Copilot alerts', () {
    test('seeds three Copilot alerts at the top of the inbox', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final items = container.read(inboxProvider);
      final firstThree = items.take(3).toList();

      expect(firstThree.every((i) => i.kind == InboxKind.copilot), isTrue,
          reason: 'first three inbox items must be Copilot voice');
      expect(firstThree.map((i) => i.id), [
        'i_copilot_passport_expiry',
        'i_copilot_visa_renew',
        'i_copilot_advisory_escalation',
      ]);
    });

    test('addCopilotAlert prepends a new alert with COPILOT prefix', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(inboxProvider.notifier);

      notifier.addCopilotAlert(
        id: 'i_test_alert',
        title: 'FX spike — convert now',
        body: 'EUR/USD moved 0.7% in the last 30 minutes.',
        deeplink: '/multi-currency',
      );

      final first = container.read(inboxProvider).first;
      expect(first.id, 'i_test_alert');
      expect(first.kind, InboxKind.copilot);
      expect(first.body.startsWith('COPILOT ·'), isTrue);
    });

    test('addCopilotAlert is idempotent on the same id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(inboxProvider.notifier);
      final base = container.read(inboxProvider).length;

      notifier.addCopilotAlert(
        id: 'i_idempotent',
        title: 'Same alert',
        body: 'Should only land once.',
        deeplink: '/intelligence',
      );
      notifier.addCopilotAlert(
        id: 'i_idempotent',
        title: 'Same alert',
        body: 'Should only land once.',
        deeplink: '/intelligence',
      );

      expect(container.read(inboxProvider).length, base + 1);
    });

    test('inboxCopilotUnreadProvider counts Copilot items only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(inboxCopilotUnreadProvider);
      // The 3 seeded Copilot alerts are unread by default.
      expect(n, 3);
    });
  });
}
