import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// `/ambient` — Ambient Hub.
///
/// Consolidates every GlobeID ambient surface (Live Activity,
/// Dynamic Island, home-screen widgets, watch faces, lock screen,
/// Quick Settings) into a single hero surface. Each tile renders
/// a hand-crafted mini-preview chip + routes to the dedicated
/// preview screen for full audit.
///
/// The hub itself is the brand's "ambient presence" thesis surface
/// — the design proof that GlobeID exists *outside* the app
/// container.
class AmbientHubScreen extends StatelessWidget {
  const AmbientHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Ambient',
      subtitle: 'GLOBE·ID · presence outside the app',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _Manifesto(),
          const SizedBox(height: Os2.space5),
          const _Eyebrow('SURFACES'),
          const SizedBox(height: Os2.space3),
          for (final t in _tiles)
            Padding(
              padding: const EdgeInsets.only(bottom: Os2.space3),
              child: _SurfaceTile(spec: t),
            ),
          const SizedBox(height: Os2.space3),
          const _Closer(),
        ],
      ),
    );
  }

  static const _tiles = <_TileSpec>[
    _TileSpec(
      handle: 'LIVE ACTIVITY',
      title: 'Dynamic Island',
      subtitle:
          'Boarding countdown that lives in the Dynamic Island while you walk to the gate.',
      route: '/ambient/live-activity',
      preview: _PreviewKind.dynamicIsland,
    ),
    _TileSpec(
      handle: 'HOME WIDGETS',
      title: 'Lock screen + home',
      subtitle:
          'Trip countdown, FX heartbeat, visa expiry warning — at iOS dimensions.',
      route: '/ambient/widgets',
      preview: _PreviewKind.homeWidget,
    ),
    _TileSpec(
      handle: 'WATCH',
      title: 'watchOS · Wear OS',
      subtitle:
          'Four complication families: circular, inline, modular small, modular large.',
      route: '/ambient/watch',
      preview: _PreviewKind.watchFace,
    ),
    _TileSpec(
      handle: 'QUICK SETTINGS',
      title: 'Control Center · QS tiles',
      subtitle:
          'One-tap shortcuts to scan, vault, and Copilot — iOS Control Center + Android QS.',
      route: '/ambient/quick-settings',
      preview: _PreviewKind.quickTile,
    ),
    _TileSpec(
      handle: 'LOCK SCREEN',
      title: 'Widgets · Always-On',
      subtitle:
          'WidgetKit accessory families + Always-On dim variant for low-power glances.',
      route: '/ambient/lock-screen',
      preview: _PreviewKind.lockWidget,
    ),
  ];
}

class _Manifesto extends StatelessWidget {
  const _Manifesto();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space5),
      decoration: BoxDecoration(
        gradient: Os2.foilGoldHero,
        borderRadius: BorderRadius.circular(Os2.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'AMBIENT · MANIFESTO',
            color: Os2.canvas,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.title(
            'GlobeID lives where you live.',
            color: Os2.canvas,
            size: Os2.textXl,
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.body(
            'A credential brand has to be omnipresent — not buried inside an app. The Ambient suite extends GlobeID onto the Dynamic Island, the lock screen, your wrist, your home screen, and the Quick Settings layer. Same gold. Same mono-cap chrome. Same OLED ink.',
            color: Os2.canvas,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Os2Text.monoCap(label, color: Os2.goldDeep, size: Os2.textTiny);
  }
}

enum _PreviewKind { dynamicIsland, homeWidget, watchFace, quickTile, lockWidget }

class _TileSpec {
  const _TileSpec({
    required this.handle,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.preview,
  });
  final String handle;
  final String title;
  final String subtitle;
  final String route;
  final _PreviewKind preview;
}

class _SurfaceTile extends StatelessWidget {
  const _SurfaceTile({required this.spec});
  final _TileSpec spec;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(spec.route),
      semanticLabel: spec.title,
      semanticHint: 'opens the ${spec.handle.toLowerCase()} preview',
      child: Container(
        padding: const EdgeInsets.all(Os2.space4),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(color: Os2.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewChip(kind: spec.preview),
            const SizedBox(width: Os2.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.monoCap(
                    spec.handle,
                    color: Os2.goldDeep,
                    size: Os2.textTiny,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.title(
                    spec.title,
                    color: Os2.inkBright,
                    size: Os2.textMd,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Os2Text.body(
                    spec.subtitle,
                    color: Os2.inkMid,
                    size: Os2.textSm,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Os2.space2),
            Icon(
              Icons.chevron_right_rounded,
              color: Os2.inkLow,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny hand-rendered chip per ambient surface. Each chip is
/// self-contained so the hub renders even when the dedicated
/// preview screens aren't yet on the branch.
class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.kind});
  final _PreviewKind kind;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: switch (kind) {
        _PreviewKind.dynamicIsland => _ChipDynamicIsland(),
        _PreviewKind.homeWidget => _ChipHomeWidget(),
        _PreviewKind.watchFace => _ChipWatchFace(),
        _PreviewKind.quickTile => _ChipQuickTile(),
        _PreviewKind.lockWidget => _ChipLockWidget(),
      },
    );
  }
}

class _ChipDynamicIsland extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Os2.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Os2.hairlineSoft),
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 12,
          decoration: BoxDecoration(
            gradient: Os2.foilGoldHero,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _ChipHomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: Os2.foilGoldHero,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Os2Text.monoCap(
            'TRIP',
            color: Os2.canvas,
            size: Os2.textTiny,
          ),
          Text(
            '12d',
            style: TextStyle(
              fontFamily: 'DepartureMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Os2.canvas,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipWatchFace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Os2.canvas,
        border: Border.all(color: Os2.hairlineSoft),
        gradient: const RadialGradient(
          radius: 0.95,
          colors: [Color(0xFF0A0E1A), Color(0xFF050505)],
        ),
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: Os2.foilGoldHero,
          ),
          child: Center(
            child: Os2Text.monoCap(
              '18',
              color: Os2.canvas,
              size: Os2.textTiny,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipQuickTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: Os2.foilGoldHero,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.center_focus_strong_rounded,
          color: Os2.canvas,
          size: 24,
        ),
      ),
    );
  }
}

class _ChipLockWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Os2.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.42)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Os2Text.monoCap(
              'LH 401',
              color: Os2.goldDeep,
              size: Os2.textTiny,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Os2Text.monoCap(
              '0:18',
              color: Os2.inkBright,
              size: Os2.textTiny,
            ),
          ),
        ],
      ),
    );
  }
}

class _Closer extends StatelessWidget {
  const _Closer();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'BRAND · THREAD',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            'Every ambient surface composes from the same primitives — gold #D4AF37, mono-cap chrome at 2.4 letter-spacing, OLED #050505 ink, hairline 0.06 white frames, GLOBE·ID watermark. No new visual language. The brand is the system.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
