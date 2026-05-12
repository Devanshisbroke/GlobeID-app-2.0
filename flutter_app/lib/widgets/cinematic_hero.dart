import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app/theme/app_tokens.dart';
import '../nexus/nexus_tokens.dart';

/// Cinematic hero — **Nexus-aligned tall edge-to-edge banner.**
///
/// Was a triple-layer aurora + star-dust + blur-badge surface with
/// saturated tone-as-background and heavy MaskFilter blurs. After
/// the Travel-OS / Wallet migration this primitive renders the
/// Lovable canonical hero language across all 18 callers:
///
///   • Dark-to-black gradient backdrop (tone is used at low alpha
///     as a subtle tonal bleed, not as a saturated fill)
///   • Accelerometer-driven parallax on the optional glyph (clamped)
///   • Champagne eyebrow pill (N.tierGold tint, hairline border)
///   • Flat hairline badge pills (no BackdropFilter blur)
///   • White title (no text shadow) + ink-mid subtitle
///   • No aurora wash, no star dust — depth is conveyed by the
///     tonal gradient alone (Nothing-OS / Linear restraint)
///
/// Public API preserved 1:1.
class CinematicHero extends StatefulWidget {
  const CinematicHero({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.badges = const [],
    this.gradient,
    this.icon,
    this.height = 252,
    this.flag,
    this.tone,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<HeroBadge> badges;
  final Gradient? gradient;
  final IconData? icon;
  final double height;
  final String? flag;
  final Color? tone;

  @override
  State<CinematicHero> createState() => _CinematicHeroState();
}

class _CinematicHeroState extends State<CinematicHero> {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _tx = 0;
  double _ty = 0;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).handleError((_) {}).listen((e) {
      if (!mounted) return;
      final tx = (e.x.clamp(-3, 3) / 3) * 8;
      final ty = (e.y.clamp(-3, 3) / 3) * 8;
      setState(() {
        _tx = _tx * 0.82 + tx * 0.18;
        _ty = _ty * 0.82 + ty * 0.18;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone ?? N.tierGold;
    final gradient = widget.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.22),
            N.bg,
          ],
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(N.rCardLg),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient (subtle tonal bleed, not saturated fill).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                border: Border.all(
                  color: N.hairline,
                  width: N.strokeHair,
                ),
                borderRadius: BorderRadius.circular(N.rCardLg),
              ),
            ),

            // Parallax glyph.
            if (widget.icon != null)
              Positioned(
                right: -20 + _tx,
                top: -20 + _ty,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(
                    widget.icon,
                    size: 260,
                    color: Colors.white,
                  ),
                ),
              ),

            // Bottom dim for legibility.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        N.bg.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content.
            Padding(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.flag != null) ...[
                        Text(widget.flag!,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: AppTokens.space2),
                      ],
                      if (widget.eyebrow != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(N.rPill),
                            border: Border.all(
                              color: tone.withValues(alpha: 0.28),
                              width: N.strokeHair,
                            ),
                          ),
                          child: Text(
                            widget.eyebrow!.toUpperCase(),
                            style: TextStyle(
                              color: tone,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          height: 1.08,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          widget.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (widget.badges.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.space3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final b in widget.badges) _Badge(badge: b),
                          ],
                        ),
                      ],
                    ],
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

class HeroBadge {
  const HeroBadge({required this.label, this.icon});
  final String label;
  final IconData? icon;
}

/// Badge pill — flat hairline, no BackdropFilter blur.
class _Badge extends StatelessWidget {
  const _Badge({required this.badge});
  final HeroBadge badge;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(N.rPill),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: N.strokeHair,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.icon != null) ...[
            Icon(badge.icon, size: 13, color: N.inkHi),
            const SizedBox(width: 4),
          ],
          Text(
            badge.label,
            style: const TextStyle(
              color: N.inkHi,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
