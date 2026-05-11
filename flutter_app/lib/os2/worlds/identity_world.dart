import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/identity_tier.dart';
import '../../features/user/user_provider.dart';
import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_meter.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_solari.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_world_header.dart';

/// OS 2.0 — Identity world.
///
/// "Foil sanctum" — the most jewel-like surface in the app. Hierarchy:
///   1. World header (Identity · GMT · LIVE).
///   2. Holographic passport hero (foil edge, document chip, photo
///      shimmer column on the right).
///   3. Score constellation (giant meter, tier ladder, "+12 this week").
///   4. Credential gallery — three full-bleed vertical slabs:
///        a. Passport (book number, country, expiry)
///        b. Trusted-traveler / KYC programs
///        c. Issuer cross-signs (verifiable claims count).
///   5. Audit timeline strip (last verification event).
class IdentityWorld extends ConsumerWidget {
  const IdentityWorld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final profile = user.profile;
    final tier = IdentityTier.forScore(profile.identityScore);
    final pct = (profile.identityScore / 1000).clamp(0.0, 1.0);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Os2WorldHeader(
              world: Os2World.identity,
              title: 'Identity',
              subtitle: 'Sovereign credentials \u00b7 foil sanctum',
              beacon: 'VERIFIED',
            ),
            const SizedBox(height: Os2.space4),
            // 1. Holographic passport hero.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _PassportHero(
                name: profile.name,
                passportNumber: profile.passportNumber,
                flag: profile.nationalityFlag,
                nationality: profile.nationality,
                verifiedStatus: profile.verifiedStatus,
              ),
            ),
            const SizedBox(height: Os2.space5),
            // 2. Score constellation.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _ScoreConstellation(
                score: profile.identityScore,
                pct: pct,
                tier: tier,
              ),
            ),
            const SizedBox(height: Os2.space5),
            // 3. Section heading.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
              child: _SectionLabel(label: 'CREDENTIAL GALLERY'),
            ),
            const SizedBox(height: Os2.space3),
            // 4. Credential gallery — vertical full-bleed slabs.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Column(
                children: [
                  _CredentialSlab(
                    icon: Icons.menu_book_rounded,
                    label: 'PASSPORT BOOK',
                    title: profile.passportNumber.isEmpty
                        ? 'Republic of India'
                        : profile.passportNumber,
                    sub: '${profile.nationalityFlag}  ${profile.nationality} \u00b7 active',
                    tone: Os2.identityTone,
                    onTap: () =>
                        GoRouter.of(context).push('/passport-live'),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.verified_user_rounded,
                    label: 'TRUSTED PROGRAMS',
                    title: 'Global Entry \u00b7 PreCheck \u00b7 TSA',
                    sub: '3 enrolled \u00b7 1 pending renewal',
                    tone: Os2.identityTone,
                    onTap: () =>
                        GoRouter.of(context).push('/passport-live'),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.fingerprint_rounded,
                    label: 'ISSUER CROSS-SIGNS',
                    title: '12 verifiable claims',
                    sub: 'Aadhaar \u00b7 Schengen \u00b7 EU citizen \u00b7 +9',
                    tone: Os2.identityTone,
                    onTap: () => GoRouter.of(context).push('/vault'),
                  ),
                  const SizedBox(height: Os2.space3),
                  _CredentialSlab(
                    icon: Icons.shield_rounded,
                    label: 'AUDIT LOG',
                    title: 'Last verification \u00b7 12 min ago',
                    sub: 'KIOSK \u00b7 FRA T1 \u00b7 success',
                    tone: Os2.identityTone,
                    onTap: () => GoRouter.of(context).push('/audit-log'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 1,
          color: Os2.identityTone.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 8),
        Os2Text.caption(label, color: Os2.identityTone),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── Holographic passport

class _PassportHero extends StatefulWidget {
  const _PassportHero({
    required this.name,
    required this.passportNumber,
    required this.flag,
    required this.nationality,
    required this.verifiedStatus,
  });

  final String name;
  final String passportNumber;
  final String flag;
  final String nationality;
  final String verifiedStatus;

  @override
  State<_PassportHero> createState() => _PassportHeroState();
}

class _PassportHeroState extends State<_PassportHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: () => GoRouter.of(context).push('/passport-live'),
      child: Os2Slab(
        tone: Os2.identityTone,
        tier: Os2SlabTier.floor2,
        radius: Os2.rHero,
        halo: Os2SlabHalo.full,
        elevation: Os2SlabElevation.cinematic,
        padding: EdgeInsets.zero,
        breath: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Os2.rHero),
          child: Stack(
            children: [
              // Shimmer sweep.
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  final v = _shimmer.value;
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _FoilShimmerPainter(
                          progress: v,
                          tone: Os2.identityTone,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(Os2.space5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Os2Chip(
                          label: 'GLOBEID PASSPORT',
                          tone: Os2.identityTone,
                          icon: Icons.workspace_premium_rounded,
                          intensity: Os2ChipIntensity.solid,
                        ),
                        const Spacer(),
                        Os2Beacon(
                          label: widget.verifiedStatus.toUpperCase(),
                          tone: Os2.signalSettled,
                        ),
                      ],
                    ),
                    const SizedBox(height: Os2.space6),
                    Row(
                      children: [
                        Text(
                          widget.flag,
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(width: Os2.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Os2Text.caption('BEARER',
                                  color: Os2.inkLow),
                              const SizedBox(height: 2),
                              Os2Text.headline(
                                widget.name,
                                color: Os2.inkBright,
                                size: 22,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Os2.space4),
                    Container(height: 0.6, color: Os2.hairline),
                    const SizedBox(height: Os2.space4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Os2Text.caption('PASSPORT NO',
                                  color: Os2.inkLow),
                              const SizedBox(height: 4),
                              Os2Solari(
                                text: widget.passportNumber.isEmpty
                                    ? 'GID0000'
                                    : widget.passportNumber,
                                tone: Os2.identityTone,
                                cellWidth: 18,
                                cellHeight: 26,
                                fontSize: 18,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Os2Text.caption('TIER', color: Os2.inkLow),
                            const SizedBox(height: 4),
                            Os2Text.title(
                              IdentityTier.forScore(826).label,
                              color: Os2.identityTone,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoilShimmerPainter extends CustomPainter {
  _FoilShimmerPainter({required this.progress, required this.tone});
  final double progress;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final bandWidth = size.width * 0.35;
    final start = -bandWidth + (size.width + bandWidth * 2) * progress;
    final rect = Rect.fromLTWH(start, 0, bandWidth, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          tone.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.06),
          tone.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.plus;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _FoilShimmerPainter old) =>
      old.progress != progress || old.tone != tone;
}

// ─────────────────────────────────────────────────────── Score constellation

class _ScoreConstellation extends StatelessWidget {
  const _ScoreConstellation({
    required this.score,
    required this.pct,
    required this.tier,
  });
  final int score;
  final double pct;
  final IdentityTier tier;

  @override
  Widget build(BuildContext context) {
    final nextThreshold = IdentityTier.tiers
        .firstWhere(
          (t) => t.threshold > score,
          orElse: () => IdentityTier.tiers.last,
        )
        .threshold;
    final ptsToNext = (nextThreshold - score).clamp(0, 1000);
    return Os2Slab(
      tone: Os2.identityTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rSlab,
      halo: Os2SlabHalo.corner,
      elevation: Os2SlabElevation.raised,
      padding: const EdgeInsets.all(Os2.space5),
      breath: true,
      child: Row(
        children: [
          Os2Meter(
            value: pct,
            tone: Os2.identityTone,
            diameter: 140,
            strokeWidth: 6,
            ticks: const [0.5, 0.75, 0.9],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Os2Text.display(
                  '$score',
                  color: Os2.inkBright,
                  size: 38,
                  weight: FontWeight.w900,
                ),
                Os2Text.caption('/1000', color: Os2.inkLow),
              ],
            ),
          ),
          const SizedBox(width: Os2.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Os2Chip(
                  label: tier.label.toUpperCase(),
                  tone: Os2.identityTone,
                  icon: Icons.workspace_premium_rounded,
                  intensity: Os2ChipIntensity.solid,
                ),
                const SizedBox(height: Os2.space3),
                Os2Text.title(
                  'Trust score',
                  color: Os2.inkBright,
                  size: 16,
                ),
                const SizedBox(height: 4),
                Os2Text.body(
                  '$ptsToNext pts to next tier',
                  color: Os2.inkMid,
                  size: 12,
                ),
                const SizedBox(height: Os2.space3),
                Row(
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 14, color: Os2.signalSettled),
                    const SizedBox(width: 4),
                    Os2Text.caption(
                      '+12 THIS WEEK',
                      color: Os2.signalSettled,
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

// ─────────────────────────────────────────────────────── Credential slab

class _CredentialSlab extends StatelessWidget {
  const _CredentialSlab({
    required this.icon,
    required this.label,
    required this.title,
    required this.sub,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String title;
  final String sub;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: onTap,
      child: Os2Slab(
        tone: tone,
        radius: Os2.rCard,
        halo: Os2SlabHalo.corner,
        elevation: Os2SlabElevation.resting,
        padding: const EdgeInsets.symmetric(
          horizontal: Os2.space4,
          vertical: Os2.space4,
        ),
        breath: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tone.withValues(alpha: 0.32),
                  width: Os2.strokeFine,
                ),
              ),
              child: Icon(icon, color: tone, size: 19),
            ),
            const SizedBox(width: Os2.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Os2Text.caption(label, color: tone),
                  const SizedBox(height: 4),
                  Os2Text.title(
                    title,
                    color: Os2.inkBright,
                    size: 16,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.body(
                    sub,
                    color: Os2.inkMid,
                    size: 12,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
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
