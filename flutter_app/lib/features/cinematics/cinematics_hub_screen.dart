import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Phase 11 capstone — Cinematics Hub. A single curated screen
/// that catalogues every cinematic ceremony GlobeID owns. Five
/// signature tiles, foil-gold cover chrome, mono-cap copy, OLED
/// substrate. The hub is the brand contract for "every motion
/// in this app is engineered, not stock."
class CinematicsHubScreen extends StatelessWidget {
  const CinematicsHubScreen({super.key});

  static const _tiles = [
    _CeremonyTile(
      route: '/lab/passport-ceremony',
      tone: Color(0xFFD4AF37),
      eyebrow: 'CEREMONY · ONE',
      title: 'Passport opening',
      duration: '3.0s',
      detail:
          'Substrate fade · foil sweep · watermark drift · bearer page snap',
      icon: Icons.menu_book_rounded,
    ),
    _CeremonyTile(
      route: '/lab/visa-stamp',
      tone: Color(0xFFC8932F),
      eyebrow: 'CEREMONY · TWO',
      title: 'Visa stamp',
      duration: '1.7s',
      detail: 'Ink load · arc swing · press flash · bleed settle',
      icon: Icons.approval_rounded,
    ),
    _CeremonyTile(
      route: '/lab/boarding-printed',
      tone: Color(0xFFE9C75D),
      eyebrow: 'CEREMONY · THREE',
      title: 'Boarding PRINTED',
      duration: '2.4s',
      detail: 'Slot arm · 5-strike extrude · 6 px overshoot · ribbon',
      icon: Icons.print_outlined,
    ),
    _CeremonyTile(
      route: '/lab/declassified',
      tone: Color(0xFFB73E3E),
      eyebrow: 'CEREMONY · FOUR',
      title: 'Country DECLASSIFIED',
      duration: '3.2s',
      detail: 'Cover lift · 3 CLASSIFIED strikes · dossier reveal',
      icon: Icons.folder_special_outlined,
    ),
    _CeremonyTile(
      route: '/lab/velvet-rope',
      tone: Color(0xFF7B1A1A),
      eyebrow: 'CEREMONY · FIVE',
      title: 'Lounge velvet rope',
      duration: '2.8s',
      detail: 'Brass arm · catenary lift · world dim · member reveal',
      icon: Icons.workspaces_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Cinematics',
      subtitle: 'Phase 11 capstone · five GlobeID-engineered ceremonies',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _HubCover(),
          const SizedBox(height: Os2.space5),
          Os2Text.monoCap(
            'FIVE · CEREMONIES',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          for (final tile in _tiles) ...[
            tile,
            const SizedBox(height: Os2.space3),
          ],
          const SizedBox(height: Os2.space2),
          _Contract(),
        ],
      ),
    );
  }
}

class _HubCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F1A12), Color(0xFF0F0B07)],
        ),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: Os2.foilGoldHero,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Os2Text.monoCap(
              'GLOBE · ID · CINEMATICS',
              color: Os2.canvas,
              size: Os2.textTiny,
            ),
          ),
          const SizedBox(height: 14),
          Os2Text.display(
            'Every motion · engineered',
            color: Os2.inkBright,
            size: Os2.textH2,
            gradient: Os2.foilGoldHero,
          ),
          const SizedBox(height: 8),
          Os2Text.monoCap(
            'PASSPORT · VISA · BOARDING · DOSSIER · LOUNGE',
            color: Os2.inkLow,
            size: Os2.textTiny,
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Os2.goldDeep.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          Row(
            children: [
              _CoverStat(value: '5', label: 'CEREMONIES'),
              const SizedBox(width: 28),
              _CoverStat(value: '13.1s', label: 'TOTAL · DURATION'),
              const Spacer(),
              Os2Text.monoCap(
                'CASE · A · CLASS',
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverStat extends StatelessWidget {
  const _CoverStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.credential(
          value,
          color: Os2.inkBright,
          size: Os2.textLg,
        ),
        const SizedBox(height: 2),
        Os2Text.monoCap(
          label,
          color: Os2.inkLow,
          size: Os2.textTiny,
        ),
      ],
    );
  }
}

class _CeremonyTile extends StatelessWidget {
  const _CeremonyTile({
    required this.route,
    required this.tone,
    required this.eyebrow,
    required this.title,
    required this.duration,
    required this.detail,
    required this.icon,
  });

  final String route;
  final Color tone;
  final String eyebrow;
  final String title;
  final String duration;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(route),
      semanticLabel: 'Play $title cinematic',
      semanticHint: 'opens the cinematic operator screen',
      child: Container(
        padding: const EdgeInsets.all(Os2.space4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1F), Color(0xFF0E0E12)],
          ),
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(color: tone.withValues(alpha: 0.38)),
          boxShadow: [
            BoxShadow(
              color: tone.withValues(alpha: 0.14),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tone.withValues(alpha: 0.32),
                    tone.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tone.withValues(alpha: 0.55)),
              ),
              child: Icon(icon, color: tone, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Os2Text.monoCap(
                        eyebrow,
                        color: tone,
                        size: Os2.textTiny,
                      ),
                      const Spacer(),
                      Os2Text.monoCap(
                        duration,
                        color: Os2.inkLow,
                        size: Os2.textTiny,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Os2Text.display(
                    title,
                    color: Os2.inkBright,
                    size: Os2.textLg,
                  ),
                  const SizedBox(height: 4),
                  Os2Text.monoCap(
                    detail,
                    color: Os2.inkMid,
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: tone.withValues(alpha: 0.65)),
          ],
        ),
      ),
    );
  }
}

class _Contract extends StatelessWidget {
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
            'CONTRACT',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          for (final line in const [
            '· Each ceremony is a multi-phase animation primitive',
            '· Every phase has a MONO-CAP handle',
            '· Every ceremony carries a signature haptic at its commit',
            '· Every ceremony reuses GlobeID gold / OLED / hairline chrome',
            '· No ceremony reuses stock Material or Cupertino transitions',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Os2Text.monoCap(
                line,
                color: Os2.inkMid,
                size: Os2.textTiny,
              ),
            ),
        ],
      ),
    );
  }
}
