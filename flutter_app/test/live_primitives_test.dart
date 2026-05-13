// GlobeID Refinement Phase 3 — live primitives tests.
//
// Verifies the contract of the depth/foil/state primitives that the
// Live family of surfaces (Live Passport, Live Boarding, Live Visa,
// Live Forex, Live Lounge, Live Transit, Live Country Intel) rely
// on. Pure data-level checks — no widget pumping — so the suite
// stays cheap.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/live/live_primitives.dart';

void main() {
  group('HolographicFoilStyle — presets', () {
    test('every style is constructable on the widget', () {
      for (final style in HolographicFoilStyle.values) {
        // Construction is the contract — every style must yield a
        // valid HolographicFoil that the framework can mount.
        final foil = HolographicFoil(
          style: style,
          child: const SizedBox.shrink(),
        );
        expect(foil.style, style);
      }
    });

    test('default style is gold (backward compatibility)', () {
      const foil = HolographicFoil(child: SizedBox.shrink());
      expect(foil.style, HolographicFoilStyle.gold);
      expect(foil.secondarySweep, false);
    });

    test('explicit colors override the style', () {
      const customColors = [Colors.red, Colors.blue];
      const foil = HolographicFoil(
        colors: customColors,
        style: HolographicFoilStyle.aurora,
        child: SizedBox.shrink(),
      );
      // colors takes precedence; style is still recorded for
      // introspection.
      expect(foil.colors, customColors);
    });

    test('secondarySweep is opt-in', () {
      const off = HolographicFoil(child: SizedBox.shrink());
      const on = HolographicFoil(
        secondarySweep: true,
        child: SizedBox.shrink(),
      );
      expect(off.secondarySweep, false);
      expect(on.secondarySweep, true);
    });
  });

  group('LayeredParallax — depth stack', () {
    test('builds with one layer', () {
      const layered = LayeredParallax(
        tilt: Offset.zero,
        layers: [
          ParallaxLayer(child: SizedBox.shrink(), depth: 4),
        ],
      );
      expect(layered.layers.length, 1);
      expect(layered.layers.first.depth, 4);
    });

    test('preserves layer ordering back-to-front', () {
      const layered = LayeredParallax(
        tilt: Offset.zero,
        layers: [
          ParallaxLayer(child: Text('a'), depth: 2),
          ParallaxLayer(child: Text('b'), depth: 8),
          ParallaxLayer(child: Text('c'), depth: 16),
        ],
      );
      expect(layered.layers[0].depth, 2);
      expect(layered.layers[1].depth, 8);
      expect(layered.layers[2].depth, 16);
    });

    test('default perspective + rotateScale', () {
      const layered = LayeredParallax(
        tilt: Offset.zero,
        layers: [],
      );
      expect(layered.perspective, closeTo(0.001, 1e-6));
      expect(layered.rotateScale, closeTo(0.06, 1e-6));
    });

    testWidgets('mounts with tilt applied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LayeredParallax(
              tilt: Offset(0.3, -0.2),
              layers: [
                ParallaxLayer(child: Text('back'), depth: 2),
                ParallaxLayer(child: Text('front'), depth: 10),
              ],
            ),
          ),
        ),
      );
      expect(find.text('back'), findsOneWidget);
      expect(find.text('front'), findsOneWidget);
    });
  });

  group('LiveSurfaceState — semantics', () {
    test('label is mono-cap for every state', () {
      for (final state in LiveSurfaceState.values) {
        expect(state.label, state.label.toUpperCase());
        expect(state.label.length, greaterThan(2));
      }
    });

    test('label is the canonical short form', () {
      expect(LiveSurfaceState.idle.label, 'IDLE');
      expect(LiveSurfaceState.armed.label, 'ARMED');
      expect(LiveSurfaceState.active.label, 'LIVE');
      expect(LiveSurfaceState.committed.label, 'COMMITTED');
      expect(LiveSurfaceState.settled.label, 'SETTLED');
    });

    test('glowAlpha rises through armed → active → committed', () {
      // The visual intensity climbs as the user moves up the
      // commitment ladder — armed glows brighter than idle, active
      // brighter than armed, committed brightest.
      expect(LiveSurfaceState.armed.glowAlpha,
          greaterThan(LiveSurfaceState.idle.glowAlpha));
      expect(LiveSurfaceState.active.glowAlpha,
          greaterThan(LiveSurfaceState.armed.glowAlpha));
      expect(LiveSurfaceState.committed.glowAlpha,
          greaterThan(LiveSurfaceState.active.glowAlpha));
    });

    test('settled glow is lower than committed (calmed-down)', () {
      // Once the surface has settled the cinematic reveal is over;
      // glow drops to a steady ambient level (~30% — brighter than
      // idle, dimmer than every interactive state).
      expect(LiveSurfaceState.settled.glowAlpha,
          lessThan(LiveSurfaceState.committed.glowAlpha));
      expect(LiveSurfaceState.settled.glowAlpha,
          greaterThan(LiveSurfaceState.idle.glowAlpha));
    });

    test('glowAlpha is in the valid 0..1 range for every state', () {
      for (final state in LiveSurfaceState.values) {
        expect(state.glowAlpha, inInclusiveRange(0, 1));
      }
    });
  });

  group('GlobeIdSignature — signature mark', () {
    testWidgets('renders the default GLOBE·ID watermark', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(children: [GlobeIdSignature()]),
          ),
        ),
      );
      expect(find.text('GLOBE\u00B7ID'), findsOneWidget);
    });

    testWidgets('appends an optional serial', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GlobeIdSignature(serial: 'GBL-7Q3\u00B724M'),
              ],
            ),
          ),
        ),
      );
      // Serial is concatenated with the watermark in a single Text
      // run so the whole signature reads as one glyph.
      expect(
        find.textContaining('GBL-7Q3\u00B724M'),
        findsOneWidget,
      );
    });
  });

  group('NfcPulse — chip-is-live radial pulse', () {
    testWidgets('mounts and renders its child icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NfcPulse(
                child: Icon(Icons.contactless_rounded, size: 22),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.contactless_rounded), findsOneWidget);
      // Allow one frame so the controller starts; do NOT pump for
      // ever or testWidgets will time out on the repeating loop.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NfcPulse), findsOneWidget);
    });

    test('default cadence is heart-rate band (~1.4 s)', () {
      const pulse = NfcPulse(child: SizedBox.shrink());
      expect(pulse.period, const Duration(milliseconds: 1400));
      expect(pulse.rings, 2);
      expect(pulse.size, 56);
      expect(pulse.maxAlpha, closeTo(0.55, 1e-9));
    });

    test('rings count is configurable', () {
      const one = NfcPulse(rings: 1, child: SizedBox.shrink());
      const three = NfcPulse(rings: 3, child: SizedBox.shrink());
      expect(one.rings, 1);
      expect(three.rings, 3);
    });
  });

  group('LiveStatusPill — cinematic state ladder badge', () {
    testWidgets('renders the state label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveStatusPill(state: LiveSurfaceState.active),
            ),
          ),
        ),
      );
      expect(find.text('LIVE'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LiveStatusPill), findsOneWidget);
    });

    testWidgets('reflects the requested state', (tester) async {
      for (final state in LiveSurfaceState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: LiveStatusPill(state: state)),
            ),
          ),
        );
        expect(find.text(state.label), findsOneWidget);
      }
    });

    test('compact mode is on by default', () {
      const pill = LiveStatusPill(state: LiveSurfaceState.idle);
      expect(pill.compact, true);
    });
  });

  group('LiveDataPulse — one-shot data-change attention', () {
    test('controller increments generation on each pulse', () {
      final c = LiveDataPulseController();
      expect(c.generation, 0);
      c.pulse();
      expect(c.generation, 1);
      c.pulse();
      c.pulse();
      expect(c.generation, 3);
    });

    test('controller notifies listeners on pulse', () {
      final c = LiveDataPulseController();
      var ticks = 0;
      c.addListener(() => ticks++);
      c.pulse();
      c.pulse();
      expect(ticks, 2);
    });

    testWidgets('mounts around its child', (tester) async {
      final c = LiveDataPulseController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveDataPulse(
                controller: c,
                child: const SizedBox(width: 80, height: 32),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(LiveDataPulse), findsOneWidget);
      // Fire one pulse and let the animation run a few frames.
      c.pulse();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LiveDataPulse), findsOneWidget);
    });
  });

  group('LiveLift — credentials float off OLED', () {
    testWidgets('mounts around its child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveLift(
                child: SizedBox(width: 200, height: 120),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(LiveLift), findsOneWidget);
      // Sanity: child still mounts inside.
      expect(find.byType(SizedBox), findsWidgets);
    });

    test('default depth is 14 (Apple-Wallet-style cast shadow)', () {
      const lift = LiveLift(child: SizedBox.shrink());
      expect(lift.depth, 14);
      expect(lift.spread, 0.0);
    });

    test('respects an explicit tone override', () {
      const lift = LiveLift(
        tone: Color(0xFF66B7FF),
        child: SizedBox.shrink(),
      );
      expect(lift.tone, const Color(0xFF66B7FF));
    });
  });

  group('LiveSurfaceStateCadence — breathing semantics', () {
    test('breathing period gets faster from idle through committed',
        () {
      final idle = LiveSurfaceState.idle.breathingPeriod;
      final armed = LiveSurfaceState.armed.breathingPeriod;
      final active = LiveSurfaceState.active.breathingPeriod;
      final committed = LiveSurfaceState.committed.breathingPeriod;
      expect(idle.inMilliseconds, greaterThan(armed.inMilliseconds));
      expect(armed.inMilliseconds, greaterThan(active.inMilliseconds));
      expect(active.inMilliseconds, greaterThan(committed.inMilliseconds));
    });

    test('settled returns to a slow breathing cadence', () {
      final settled = LiveSurfaceState.settled.breathingPeriod;
      final committed = LiveSurfaceState.committed.breathingPeriod;
      expect(settled.inMilliseconds, greaterThan(committed.inMilliseconds));
    });

    test('NFC ring count rises with the state ladder', () {
      expect(LiveSurfaceState.idle.suggestedNfcRings, 1);
      expect(LiveSurfaceState.armed.suggestedNfcRings, 2);
      expect(LiveSurfaceState.active.suggestedNfcRings, 3);
      expect(LiveSurfaceState.committed.suggestedNfcRings, 3);
      expect(LiveSurfaceState.settled.suggestedNfcRings, 1);
    });
  });

  group('RollingDigits — Apple-Wallet card-number roll', () {
    testWidgets('lands on the target after the animation runs',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RollingDigits(
                target: 100,
                digits: 3,
                duration: Duration(milliseconds: 600),
              ),
            ),
          ),
        ),
      );
      // Final value is reached after the animation completes.
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('zero-pads to the configured digit count',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RollingDigits(
                target: 42,
                digits: 6,
                duration: Duration(milliseconds: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('000042'), findsOneWidget);
    });

    testWidgets('prefix and suffix render around the rolling value',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RollingDigits(
                target: 50,
                digits: 1,
                prefix: 'A',
                suffix: 'K',
                duration: Duration(milliseconds: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('A50K'), findsOneWidget);
    });
  });

  group('LiveEntrance — staggered substrate \u2192 content \u2192 foil', () {
    testWidgets('mounts all three layers and they remain visible '
        'after the cinematic completes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: LiveEntrance(
                substrate: Text('SUB'),
                content: Text('CON'),
                foil: Text('FOIL'),
                duration: Duration(milliseconds: 200),
              ),
            ),
          ),
        ),
      );
      // After the cinematic completes all three layers are visible.
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('SUB'), findsOneWidget);
      expect(find.text('CON'), findsOneWidget);
      expect(find.text('FOIL'), findsOneWidget);
    });

    testWidgets('foil layer is optional', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: LiveEntrance(
                substrate: Text('SUB'),
                content: Text('CON'),
                duration: Duration(milliseconds: 200),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('SUB'), findsOneWidget);
      expect(find.text('CON'), findsOneWidget);
      expect(find.text('FOIL'), findsNothing);
    });
  });

  group('GlobeIdWatermarkDrift — subliminal signature layer', () {
    testWidgets('mounts as a non-interactive overlay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: GlobeIdWatermarkDrift(),
            ),
          ),
        ),
      );
      expect(find.byType(GlobeIdWatermarkDrift), findsOneWidget);
      // Drift uses IgnorePointer — never blocks taps on substrate.
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    test('defaults to faint gold tone alpha far below opaque', () {
      const w = GlobeIdWatermarkDrift();
      expect(w.alpha, lessThan(0.10));
    });
  });
}
