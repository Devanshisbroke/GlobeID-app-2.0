import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Phase 12f — Brand Surface Gallery capstone.
///
/// Hub for every Phase 12 brand surface: the watermark (12a, baked
/// into AppleSheet), the cold-mount seal (12b), the identity signet
/// ladder (12c), the camera chrome (12d), and the share-sheet
/// receipts (12e). Operator can tap any tile to walk through the
/// dedicated lab gallery for that surface.
///
/// Reads as a "manufactured credential atelier" — gold-foil hero
/// vignette + mono-cap eyebrow + display titles, hairline-framed
/// tiles, each one toned to its surface's accent.
class BrandSurfaceGalleryScreen extends StatelessWidget {
  const BrandSurfaceGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'PHASE · 12 · BRAND',
      title: 'Brand surface gallery',
      subtitle: '5 GlobeID-engineered chrome surfaces · one hub',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: const [
          _BrandHero(),
          SizedBox(height: Os2.space6),
          _SurfaceTile(
            phase: '12a',
            eyebrow: 'SHEET · WATERMARK',
            title: 'GLOBE · ID watermark',
            description:
                'Foil-hairline + GLOBE · ID + N° case number — baked '
                'into every AppleSheet. Deterministic case numbers '
                '(FNV-1a) so the same sheet always reads as the '
                'same case file.',
            tone: Color(0xFFD4AF37),
            route: '/wallet', // any sheet-opening screen surfaces it
            cta: 'OPEN · A · WALLET · SHEET',
          ),
          SizedBox(height: Os2.space3),
          _SurfaceTile(
            phase: '12b',
            eyebrow: 'COLD · MOUNT',
            title: 'GlobeID seal',
            description:
                'Five-phase stamp ceremony — substrate fade → press '
                'overshoot (easeOutBack) → settle (signature haptic) '
                '→ ink bleed → label. 1.6 s · one moment of intent.',
            tone: Color(0xFFE9C75D),
            route: '/lab/seal-coldmount',
            cta: 'PRESS · A · SEAL',
          ),
          SizedBox(height: Os2.space3),
          _SurfaceTile(
            phase: '12c',
            eyebrow: 'IDENTITY · MARK',
            title: 'Signet variants',
            description:
                'Three-tier signet ladder — STANDARD · FOIL on OLED, '
                'ATELIER · STEALTH hairline-only, PILOT · NAVY with '
                'champagne seal. Square + circular die + 8 notches.',
            tone: Color(0xFFC9A961),
            route: '/lab/identity-signet',
            cta: 'WALK · THE · LADDER',
          ),
          SizedBox(height: Os2.space3),
          _SurfaceTile(
            phase: '12d',
            eyebrow: 'CAMERA · CHROME',
            title: '5 scan modes',
            description:
                'PASSPORT · FACE · QR · NFC · DOCUMENT — corner '
                'brackets, oval rim, mono-cap mode chip, animated '
                'scan line. Cadence + tone flex per mode.',
            tone: Color(0xFFE9C75D),
            route: '/lab/camera-chrome',
            cta: 'OPEN · VIEWFINDER',
          ),
          SizedBox(height: Os2.space3),
          _SurfaceTile(
            phase: '12e',
            eyebrow: 'SHARE · TEMPLATES',
            title: 'Receipts',
            description:
                'Five share-sheet receipts (PAYMENT · TRIP · '
                'CREDENTIAL · IMMIGRATION · VISA) — OLED + foil '
                'hairline + perforation + GLOBE · ID watermark. '
                'Every shared screenshot advertises the brand.',
            tone: Color(0xFF3FB68B),
            route: '/lab/receipts',
            cta: 'PRINT · A · RECEIPT',
          ),
          SizedBox(height: Os2.space6),
          _ChronicleStamp(),
          SizedBox(height: Os2.space4),
          _PhaseCapstone(),
        ],
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.36)),
        gradient: const RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.1,
          colors: [Color(0xFF1A1207), Color(0xFF050505)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Foil sweep overlay.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.8, -0.6),
                  end: const Alignment(0.8, 0.4),
                  colors: [
                    Colors.transparent,
                    const Color(0xFFE9C75D).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Os2.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Os2Text.monoCap(
                  'ATELIER · GLOBE · ID',
                  color: const Color(0xFFD4AF37),
                  size: Os2.textTiny,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Manufactured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.05,
                            ),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                          Text(
                            'credential',
                            style: TextStyle(
                              color: Color(0xFFE9C75D),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.05,
                            ),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 0.6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFD4AF37).withValues(alpha: 0.46),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Os2Text.monoCap(
                            'GLOBE · ID',
                            color: Colors.white.withValues(alpha: 0.32),
                            size: Os2.textTiny,
                          ),
                          const SizedBox(height: 2),
                          Os2Text.monoCap(
                            'N° BRAND-12F',
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.62),
                            size: Os2.textTiny,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  const _SurfaceTile({
    required this.phase,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.tone,
    required this.route,
    required this.cta,
  });

  final String phase;
  final String eyebrow;
  final String title;
  final String description;
  final Color tone;
  final String route;
  final String cta;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: title,
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(Os2.space4),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(color: tone.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: tone.withValues(alpha: 0.10),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: tone.withValues(alpha: 0.42),
                      width: 0.6,
                    ),
                  ),
                  child: Os2Text.monoCap(
                    'PHASE · $phase',
                    color: tone,
                    size: Os2.textTiny,
                  ),
                ),
                const Spacer(),
                Os2Text.monoCap(
                  eyebrow,
                  color: tone.withValues(alpha: 0.78),
                  size: Os2.textTiny,
                ),
              ],
            ),
            const SizedBox(height: Os2.space3),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 13,
                height: 1.4,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: Os2.space3),
            Row(
              children: [
                Os2Text.monoCap(cta, color: tone, size: Os2.textTiny),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: tone,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChronicleStamp extends StatelessWidget {
  const _ChronicleStamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space5,
        vertical: Os2.space4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'PHASE · 12 · CHRONICLE',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          const _ChronicleRow(when: '12a', what: 'GLOBE · ID watermark · AppleSheet'),
          const _ChronicleRow(when: '12b', what: 'GlobeID cold-mount seal · 5-phase'),
          const _ChronicleRow(when: '12c', what: 'Identity signet · 3-tier ladder'),
          const _ChronicleRow(when: '12d', what: 'Camera chrome · 5 scan modes'),
          const _ChronicleRow(when: '12e', what: 'Receipts · 5 share templates'),
          const _ChronicleRow(when: '12f', what: 'Brand surface gallery · capstone', last: true),
        ],
      ),
    );
  }
}

class _ChronicleRow extends StatelessWidget {
  const _ChronicleRow({
    required this.when,
    required this.what,
    this.last = false,
  });
  final String when;
  final String what;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Os2Text.monoCap(
              when,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.82),
              size: Os2.textTiny,
            ),
          ),
          Expanded(
            child: Text(
              what,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCapstone extends StatelessWidget {
  const _PhaseCapstone();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  const Color(0xFFD4AF37).withValues(alpha: 0.46),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Os2Text.monoCap(
            'BRAND · MANUFACTURED · BY · GLOBE · ID',
            color: Colors.white.withValues(alpha: 0.32),
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}
