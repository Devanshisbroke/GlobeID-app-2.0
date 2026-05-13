// GlobeID Refinement Phase 2 — semantic haptic vocabulary tests.
//
// These tests verify the *contract* of the [Haptics] vocabulary: every
// semantic name routes to a HapticFeedback method, the master gate
// suppresses every call when disabled, and the multi-pulse signature /
// success patterns complete without throwing.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/motion/motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final invocations = <MethodCall>[];

  setUp(() {
    invocations.clear();
    Haptics.enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        invocations.add(call);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('Haptics — semantic vocabulary', () {
    test('selection() fires selectionClick', () async {
      Haptics.selection();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('selectionClick'));
    });

    test('tap() fires lightImpact', () async {
      Haptics.tap();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('lightImpact'));
    });

    test('open() fires mediumImpact', () async {
      Haptics.open();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('mediumImpact'));
    });

    test('confirm() fires heavyImpact', () async {
      Haptics.confirm();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('heavyImpact'));
    });

    test('snapDetent() fires mediumImpact (a sheet snap should feel deliberate)',
        () async {
      Haptics.snapDetent();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('mediumImpact'));
    });

    test('pullArmed() fires selectionClick (a soft "armed" tick)', () async {
      Haptics.pullArmed();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('selectionClick'));
    });

    test('pullCommitted() fires lightImpact (the refresh actually started)',
        () async {
      Haptics.pullCommitted();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('lightImpact'));
    });

    test('success() fires a multi-pulse pattern (light → medium)', () async {
      await Haptics.success();
      // Two distinct vibrate calls — light, then medium after a 60 ms gap.
      expect(invocations.length, 2);
      expect(invocations.first.arguments, contains('lightImpact'));
      expect(invocations.last.arguments, contains('mediumImpact'));
    });

    test('signature() fires a triple-pulse pattern (light → medium → light)',
        () async {
      await Haptics.signature();
      // Three distinct vibrate calls.
      expect(invocations.length, 3);
      expect(invocations.first.arguments, contains('lightImpact'));
      expect(invocations[1].arguments, contains('mediumImpact'));
      expect(invocations.last.arguments, contains('lightImpact'));
    });

    test('error() fires heavyImpact', () async {
      Haptics.error();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('heavyImpact'));
    });

    test('warning() fires mediumImpact', () async {
      Haptics.warning();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('mediumImpact'));
    });
  });

  group('Haptics — master accessibility gate', () {
    test('Haptics.enabled = false suppresses selection()', () async {
      Haptics.enabled = false;
      Haptics.selection();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations, isEmpty);
    });

    test('Haptics.enabled = false suppresses confirm()', () async {
      Haptics.enabled = false;
      Haptics.confirm();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations, isEmpty);
    });

    test('Haptics.enabled = false suppresses the multi-pulse signature()',
        () async {
      Haptics.enabled = false;
      await Haptics.signature();
      expect(invocations, isEmpty);
    });

    test('Haptics.enabled = false suppresses the multi-pulse success()',
        () async {
      Haptics.enabled = false;
      await Haptics.success();
      expect(invocations, isEmpty);
    });
  });

  group('Haptics — source-compat aliases', () {
    test('scrub() is an alias for selection()', () async {
      Haptics.scrub();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('selectionClick'));
    });

    test('pressDown() is an alias for selection()', () async {
      Haptics.pressDown();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('selectionClick'));
    });

    test('pressUp() is an alias for tap()', () async {
      Haptics.pressUp();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('lightImpact'));
    });

    test('navigate() fires lightImpact', () async {
      Haptics.navigate();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(invocations.length, 1);
      expect(invocations.first.arguments, contains('lightImpact'));
    });
  });
}
