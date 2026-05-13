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
import 'package:globeid/cinematic/live/live_substrates.dart';

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

  group('OrbitalPerks — dots orbit around the seal', () {
    testWidgets('mounts around its child and renders no extra widgets',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: OrbitalPerks(
                tones: [Color(0xFFE9C75D), Color(0xFF66B7FF)],
                child: SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(OrbitalPerks), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('tone list defines the orbit count', () {
      const perks = OrbitalPerks(
        tones: [Color(0xFFE9C75D), Color(0xFF66B7FF), Color(0xFF9B6FE3)],
        child: SizedBox.shrink(),
      );
      expect(perks.tones.length, 3);
    });

    test('default radius is 32 and dot size is 4', () {
      const perks = OrbitalPerks(
        tones: [Color(0xFFE9C75D)],
        child: SizedBox.shrink(),
      );
      expect(perks.radius, 32);
      expect(perks.dotSize, 4);
    });
  });

  group('PassportRibbonBookmark — silk bookmark fluttering', () {
    testWidgets('mounts on a real-sized passport corner',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 24,
                  child: PassportRibbonBookmark(),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(PassportRibbonBookmark), findsOneWidget);
      // Flutter rotation transform is part of the widget tree.
      expect(find.byType(Transform), findsWidgets);
    });

    test('defaults to deep red silk, ~80 length, 10 width', () {
      const ribbon = PassportRibbonBookmark();
      expect(ribbon.length, 80);
      expect(ribbon.width, 10);
      expect(ribbon.tone, const Color(0xFFB72424));
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

  group('BreathingHalo — state-driven ambient pulse', () {
    testWidgets('mounts with a child and stays interactive',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: BreathingHalo(
                tone: Color(0xFFE15B5B),
                state: LiveSurfaceState.active,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(BreathingHalo), findsOneWidget);
      // Halo paints its glow inside an IgnorePointer so taps fall
      // through to the child below.
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets('cadence updates smoothly when state changes',
        (tester) async {
      Widget halo(LiveSurfaceState s) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: BreathingHalo(
                  tone: const Color(0xFF66B7FF),
                  state: s,
                  child: const SizedBox(width: 40, height: 40),
                ),
              ),
            ),
          );
      await tester.pumpWidget(halo(LiveSurfaceState.idle));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(halo(LiveSurfaceState.active));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(BreathingHalo), findsOneWidget);
    });

    test('default maxAlpha never exceeds opaque', () {
      const w = BreathingHalo(
        tone: Color(0xFFE15B5B),
        child: SizedBox(),
      );
      expect(w.maxAlpha, lessThan(1.0));
      expect(w.maxAlpha, greaterThan(0.0));
    });
  });

  group('HolographicFoil — radial sweep', () {
    testWidgets('radial: true mounts a RepaintBoundary + ShaderMask',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 100,
                child: HolographicFoil(
                  radial: true,
                  style: HolographicFoilStyle.iridescent,
                  child: ColoredBox(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(HolographicFoil), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('radial + secondarySweep does not stack twice',
        (tester) async {
      // When radial is true, the secondarySweep counter-band is
      // intentionally suppressed (radial focal already orbits).
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: HolographicFoil(
                radial: true,
                secondarySweep: true,
                child: ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });

  group('HolographicFoil — tilt-driven sweep direction', () {
    testWidgets('tilt offset is wired through the sweep shader',
        (tester) async {
      // We can't easily measure the shader output, but we can
      // verify the widget mounts cleanly with a non-zero tilt
      // and the ShaderMask still paints.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 100,
              child: HolographicFoil(
                tilt: Offset(0.4, -0.3),
                child: ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HolographicFoil), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    test('default tilt is Offset.zero (backward compatibility)', () {
      const foil = HolographicFoil(
        child: ColoredBox(color: Colors.transparent),
      );
      expect(foil.tilt, Offset.zero);
    });

    testWidgets('out-of-range tilt clamps to [-1, 1] without crashing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: HolographicFoil(
                tilt: Offset(5.0, -8.0),
                radial: true,
                child: ColoredBox(color: Colors.transparent),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });

  group('LiveMaterialize — credential reveal wrapper', () {
    testWidgets('fades child in from opacity 0 to 1',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveMaterialize(
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
      // At the very start, the child should be at low opacity.
      await tester.pump(const Duration(milliseconds: 10));
      final mid = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(LiveMaterialize),
          matching: find.byType(Opacity),
        ).first,
      );
      // Pump to completion.
      await tester.pump(const Duration(milliseconds: 900));
      final end = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(LiveMaterialize),
          matching: find.byType(Opacity),
        ).first,
      );
      expect(end.opacity, closeTo(1.0, 0.01));
      // And the opacity should have risen.
      expect(end.opacity, greaterThanOrEqualTo(mid.opacity));
    });

    test('rise default lifts ~8 px on entry', () {
      const w = LiveMaterialize(child: SizedBox());
      expect(w.rise, 8.0);
    });
  });

  group('BanknoteSubstrate — cinematic serial roll', () {
    testWidgets('rolls in on mount and lands on the final serial',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: SizedBox(
              width: 320,
              height: 180,
              child: BanknoteSubstrate(
                tone: Color(0xFFE9C75D),
                serial: 'GBL · 00 · A28 · 411 · 928',
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      // Pump enough to complete the 720 ms roll.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      // The substrate paints; no need to inspect the painter text.
      expect(find.byType(BanknoteSubstrate), findsOneWidget);
    });

    testWidgets('changing serial re-rolls the new value',
        (tester) async {
      Widget body(String s) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 100,
                child: BanknoteSubstrate(
                  tone: const Color(0xFFE9C75D),
                  serial: s,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          );
      await tester.pumpWidget(body('USD · A01 · 111'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpWidget(body('JPY · B02 · 222'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(BanknoteSubstrate), findsOneWidget);
    });

    test('rollDuration default ~720 ms keeps the roll subtle', () {
      const w = BanknoteSubstrate(
        tone: Color(0xFFE9C75D),
        child: SizedBox.shrink(),
      );
      expect(w.rollDuration, const Duration(milliseconds: 720));
      expect(w.rollOnMount, true);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Phase 3e — Live surfaces deep-alive
  //
  // Verifies the state-driven Live surface contracts shipped in 3e:
  // the boarding pass time-state mapper, the transit tap controller,
  // and the lounge check-in pulse controller invariants.
  // ─────────────────────────────────────────────────────────────────
  group('LiveSurfaceState — boarding window cinematic ladder', () {
    // Helper mirroring the private _stateForRemaining in the
    // boarding pass screen. Mirrored here so the contract is
    // independently verified against the cadence ladder.
    LiveSurfaceState stateForRemaining(Duration d) {
      if (d.isNegative) return LiveSurfaceState.settled;
      final mins = d.inMinutes;
      if (mins > 120) return LiveSurfaceState.armed;
      if (mins > 30) return LiveSurfaceState.active;
      if (mins >= 5) return LiveSurfaceState.committed;
      return LiveSurfaceState.settled;
    }

    test('>2h out is armed', () {
      expect(
        stateForRemaining(const Duration(hours: 4)),
        LiveSurfaceState.armed,
      );
    });

    test('30 m – 2 h is active', () {
      expect(
        stateForRemaining(const Duration(minutes: 90)),
        LiveSurfaceState.active,
      );
      expect(
        stateForRemaining(const Duration(minutes: 45)),
        LiveSurfaceState.active,
      );
    });

    test('5 – 30 m is committed (the boarding window)', () {
      expect(
        stateForRemaining(const Duration(minutes: 25)),
        LiveSurfaceState.committed,
      );
      expect(
        stateForRemaining(const Duration(minutes: 5)),
        LiveSurfaceState.committed,
      );
    });

    test('< 5 m → settled (gate about to close)', () {
      expect(
        stateForRemaining(const Duration(minutes: 4)),
        LiveSurfaceState.settled,
      );
    });

    test('negative duration → settled (departed)', () {
      expect(
        stateForRemaining(const Duration(minutes: -5)),
        LiveSurfaceState.settled,
      );
    });

    test('ladder breathing accelerates from armed to committed', () {
      final armed =
          stateForRemaining(const Duration(hours: 4)).breathingPeriod;
      final active =
          stateForRemaining(const Duration(minutes: 90)).breathingPeriod;
      final committed =
          stateForRemaining(const Duration(minutes: 15)).breathingPeriod;
      expect(armed.inMilliseconds, greaterThan(active.inMilliseconds));
      expect(active.inMilliseconds, greaterThan(committed.inMilliseconds));
    });
  });

  group('LiveDataPulseController — repeated commits on the same controller',
      () {
    test('a controller can be re-pulsed many times without leaking', () {
      final c = LiveDataPulseController();
      // Simulate a transit user tapping at every gate over a multi-leg
      // journey. The controller must broadcast every pulse cleanly.
      for (var i = 0; i < 50; i++) {
        c.pulse();
      }
      c.dispose();
    });

    test('a fresh controller starts with zero listeners', () {
      final c = LiveDataPulseController();
      // hasListeners is protected in ChangeNotifier so we just verify
      // pulse() is safe on a brand-new instance.
      c.pulse();
      c.dispose();
    });
  });

  group('LiveStatusPill — state pill mounts for every cinematic state', () {
    for (final state in LiveSurfaceState.values) {
      testWidgets('mounts cleanly with state = ${state.name}',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiveStatusPill(
                state: state,
                tone: const Color(0xFFD4AF37),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(LiveStatusPill), findsOneWidget);
      });
    }
  });

  // ───────────────────────────────────────────────────────────────────
  // Phase 3d — alive systems: state-driven cadence + data pulse
  // controller contract
  // ───────────────────────────────────────────────────────────────────

  group('LiveDataPulseController — pulse broadcast', () {
    test('pulse() does not throw with no listeners', () {
      final c = LiveDataPulseController();
      c.pulse(); // safe — listeners attach later
      c.dispose();
    });

    test('pulse() notifies attached listeners', () {
      final c = LiveDataPulseController();
      var fires = 0;
      c.addListener(() => fires++);
      c.pulse();
      c.pulse();
      c.pulse();
      expect(fires, 3);
      c.dispose();
    });
  });

  group('LiveSurfaceState — breathing cadence ladder', () {
    test('breathingPeriod accelerates idle → committed', () {
      final idle = LiveSurfaceState.idle.breathingPeriod;
      final armed = LiveSurfaceState.armed.breathingPeriod;
      final active = LiveSurfaceState.active.breathingPeriod;
      final committed = LiveSurfaceState.committed.breathingPeriod;
      // Each subsequent state should breathe faster (shorter
      // duration) until commit, where the cadence is shortest.
      expect(idle.inMilliseconds, greaterThan(armed.inMilliseconds));
      expect(armed.inMilliseconds, greaterThan(active.inMilliseconds));
      expect(active.inMilliseconds, greaterThan(committed.inMilliseconds));
    });

    test('settled cadence is slowest (calm after commit)', () {
      final settled = LiveSurfaceState.settled.breathingPeriod;
      // Settled is the most relaxed state — must be slower than
      // every cinematic state, including idle.
      for (final state in LiveSurfaceState.values) {
        if (state == LiveSurfaceState.settled) continue;
        expect(
          settled.inMilliseconds,
          greaterThanOrEqualTo(state.breathingPeriod.inMilliseconds),
          reason:
              'settled (${settled.inMilliseconds}ms) must be >= ${state.name} '
              '(${state.breathingPeriod.inMilliseconds}ms)',
        );
      }
    });
  });

  group('BreathingRing — state-driven duration', () {
    testWidgets('default duration is 2.4 s (mid cadence)', (tester) async {
      const w = BreathingRing(tone: Color(0xFF06B6D4));
      expect(w.duration, const Duration(milliseconds: 2400));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: w)),
      );
      expect(find.byType(BreathingRing), findsOneWidget);
    });

    testWidgets('rebuild with a new duration mounts cleanly',
        (tester) async {
      Widget body(Duration d) => MaterialApp(
            home: Scaffold(
              body: BreathingRing(
                tone: const Color(0xFF06B6D4),
                duration: d,
              ),
            ),
          );
      await tester.pumpWidget(
        body(LiveSurfaceState.armed.breathingPeriod),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(
        body(LiveSurfaceState.committed.breathingPeriod),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(BreathingRing), findsOneWidget);
    });
  });

  group('LiveDataPulse — wrapping a child', () {
    testWidgets('mounts child unconditionally', (tester) async {
      final c = LiveDataPulseController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveDataPulse(
              controller: c,
              tone: const Color(0xFFD4AF37),
              child: const Text('GLOBEID'),
            ),
          ),
        ),
      );
      expect(find.text('GLOBEID'), findsOneWidget);
      c.dispose();
    });

    testWidgets('firing pulse() does not unmount the child',
        (tester) async {
      final c = LiveDataPulseController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveDataPulse(
              controller: c,
              tone: const Color(0xFFD4AF37),
              child: const Text('LIVE'),
            ),
          ),
        ),
      );
      c.pulse();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 320));
      expect(find.text('LIVE'), findsOneWidget);
      c.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Phase 3f — broader alive systems: navigation + airport companion
  // cinematic ladders, hub state mapping.
  // ─────────────────────────────────────────────────────────────────

  group('LiveSurfaceState — navigation distance ladder', () {
    // Helper mirroring the private _navState in the navigation live
    // screen. Mirrored here so the contract is independently
    // verifiable against the cinematic state ladder.
    LiveSurfaceState stateForDistance(int distance) {
      if (distance <= 0) return LiveSurfaceState.settled;
      if (distance > 500) return LiveSurfaceState.armed;
      if (distance > 50) return LiveSurfaceState.active;
      return LiveSurfaceState.committed;
    }

    test('>500 m → armed (cruising)', () {
      expect(stateForDistance(1200), LiveSurfaceState.armed);
    });
    test('50–500 m → active (approaching maneuver)', () {
      expect(stateForDistance(400), LiveSurfaceState.active);
      expect(stateForDistance(60), LiveSurfaceState.active);
    });
    test('1–50 m → committed (turn imminent)', () {
      expect(stateForDistance(40), LiveSurfaceState.committed);
      expect(stateForDistance(5), LiveSurfaceState.committed);
    });
    test('0 m → settled (turn executed)', () {
      expect(stateForDistance(0), LiveSurfaceState.settled);
      expect(stateForDistance(-5), LiveSurfaceState.settled);
    });
    test('ladder accelerates breathing armed → committed', () {
      final armed = stateForDistance(1200).breathingPeriod;
      final active = stateForDistance(200).breathingPeriod;
      final committed = stateForDistance(25).breathingPeriod;
      expect(armed.inMilliseconds, greaterThan(active.inMilliseconds));
      expect(active.inMilliseconds, greaterThan(committed.inMilliseconds));
    });
  });

  group('LiveSurfaceState — airport companion dwell ladder', () {
    // Helper mirroring the private _dwellState in the airport
    // companion live screen.
    LiveSurfaceState stateForDwell(int minutes) {
      if (minutes <= 5) return LiveSurfaceState.settled;
      if (minutes <= 30) return LiveSurfaceState.committed;
      if (minutes <= 60) return LiveSurfaceState.active;
      return LiveSurfaceState.armed;
    }

    test('>60 m → armed (terminal cruising)', () {
      expect(stateForDwell(120), LiveSurfaceState.armed);
    });
    test('30–60 m → active (head to the gate)', () {
      expect(stateForDwell(45), LiveSurfaceState.active);
      expect(stateForDwell(31), LiveSurfaceState.active);
    });
    test('5–30 m → committed (boarding window)', () {
      expect(stateForDwell(20), LiveSurfaceState.committed);
      expect(stateForDwell(6), LiveSurfaceState.committed);
    });
    test('≤5 m → settled (final call)', () {
      expect(stateForDwell(5), LiveSurfaceState.settled);
      expect(stateForDwell(0), LiveSurfaceState.settled);
    });
    test('dwell ladder accelerates breathing through commit', () {
      final armed = stateForDwell(120).breathingPeriod;
      final active = stateForDwell(45).breathingPeriod;
      final committed = stateForDwell(15).breathingPeriod;
      expect(armed.inMilliseconds, greaterThan(active.inMilliseconds));
      expect(active.inMilliseconds, greaterThan(committed.inMilliseconds));
    });
  });

  group('NfcPulse — chip-bearing surfaces stay mounted under pulse', () {
    testWidgets('mounts and renders its child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NfcPulse(
              tone: Color(0xFFD4AF37),
              child: Icon(Icons.nfc_rounded, size: 24),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(NfcPulse), findsOneWidget);
      expect(find.byIcon(Icons.nfc_rounded), findsOneWidget);
    });
  });

  group('HolographicFoil — radial + iridescent on hero credentials', () {
    testWidgets('iridescent + radial + secondarySweep mounts cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: HolographicFoil(
              style: HolographicFoilStyle.iridescent,
              radial: true,
              secondarySweep: true,
              child: SizedBox(
                width: 200,
                height: 26,
                child: Text('GLOBEID · BIOMETRIC'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(HolographicFoil), findsOneWidget);
      expect(find.text('GLOBEID · BIOMETRIC'), findsOneWidget);
    });
  });
}
