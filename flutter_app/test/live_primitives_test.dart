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
}
