// GlobeID UI/UX Bible — flagship hero-card surface.
//
// Bible §4 "Materials" + §7 "Elevation" — every flagship hero card
// (passport, wallet balance, boarding pass, services fast-path) lands
// on a [BibleHeroCard] base surface. Implements the four-layer
// premium-card recipe described in the bible:
//
//   1. Inner gradient body (substrate-aware: honey→amber for foil,
//      ink-blue for jet, paper-white for paper, etc.)
//   2. Specular highlight band along the top edge (light catching the
//      lacquer)
//   3. Soft inner-glow that tints the lower half toward the bible
//      tone (foil gold, treasury green, jet cyan, honey amber, etc.)
//   4. Multi-layer ambient shadow (cinematic three-tier — close
//      grounded shadow + mid ambient + brand-tinted volumetric).
//
// Typography rhythm matches Apple HIG: 32-pt corners, 16-pt internal
// padding, 24-pt vertical for tall heroes. Defaults can be overridden
// per-screen.
//
// Usage:
//   BibleHeroCard(
//     tone: BibleTone.foilGold,
//     material: BibleMaterial.foil,
//     child: ...,
//   );

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/ux_bible.dart';

/// A flagship hero-card surface with cinematic depth, layered
/// translucency, and a specular highlight band along the top edge.
///
/// On press, the card briefly compresses (scale 0.985) and emits a
/// `lightImpact` haptic — Apple HIG-style tactile response.
class BibleHeroCard extends StatefulWidget {
  const BibleHeroCard({
    super.key,
    required this.child,
    this.tone,
    this.material = BibleMaterial.glass,
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 22),
    this.radius = 28,
    this.height,
    this.minHeight,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.density = BibleHeroDensity.spacious,
    this.elevation = BibleHeroElevation.cinematic,
  });

  final Widget child;

  /// Optional bible tone for the inner glow / specular tint
  /// (foil gold, treasury green, jet cyan, etc.). Falls back to the
  /// theme's primary if null.
  final Color? tone;

  /// Bible material — selects which gradient body and edge treatment
  /// the card uses.
  final BibleMaterial material;

  final EdgeInsets padding;

  /// Corner radius. Bible default is 28-pt for hero cards, 32-pt for
  /// "passport-grade" surfaces (foil/identity).
  final double radius;

  /// Optional fixed height. If null, the card sizes to its content.
  final double? height;
  final double? minHeight;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final BibleHeroDensity density;
  final BibleHeroElevation elevation;

  @override
  State<BibleHeroCard> createState() => _BibleHeroCardState();
}

enum BibleHeroDensity { compact, spacious }

enum BibleHeroElevation { resting, cinematic, floating }

class _BibleHeroCardState extends State<BibleHeroCard>
    with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 220),
    lowerBound: 0,
    upperBound: 1,
  );

  // Long-period shimmer that sweeps a soft specular highlight across
  // the card every ~6 s. Foil / glass materials use it to feel "alive";
  // paper / metal / atmosphere skip it so they read as matte.
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6200),
  )..repeat();

  @override
  void dispose() {
    _press.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _onPressDown(_) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _press.forward();
    HapticFeedback.lightImpact();
  }

  void _onPressUp(_) {
    if (!_press.isAnimating && _press.value == 0) return;
    _press.reverse();
  }

  void _onPressCancel() {
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = GlassExtension.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.tone ?? theme.colorScheme.primary;

    final bg = _bodyGradient(theme, isDark, accent, widget.material);
    final shadows = _shadows(widget.elevation, accent, isDark);
    final innerStrokeColor = _strokeColor(isDark, widget.material);

    final card = AnimatedBuilder(
      animation: _press,
      builder: (context, child) {
        final t = _press.value;
        final scale = 1.0 - 0.018 * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: bg,
          boxShadow: shadows,
          border: Border.all(
            color: innerStrokeColor,
            width: 0.6,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: Stack(
            children: [
              // Layer 2 — top specular highlight band. A faint linear
              // gradient that lands in the top ~28% of the card,
              // simulating light catching the lacquered surface.
              if (!glass.reduceTransparency)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 80,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _specularColors(isDark, widget.material),
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              // Layer 2.5 — living foil shimmer. A soft diagonal
              // specular sweep that traverses across the card every
              // ~6 s, simulating light catching foil. Skipped on
              // reduce-transparency, paper, and metal so the effect
              // is reserved for the materials it makes sense on.
              if (!glass.reduceTransparency &&
                  (widget.material == BibleMaterial.foil ||
                      widget.material == BibleMaterial.glass))
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shimmer,
                      builder: (context, _) {
                        final t = _shimmer.value;
                        // Map t∈[0,1] to position ∈[-1.4, 1.4] so the
                        // sweep enters from off-screen left, crosses,
                        // and exits off-screen right before looping.
                        final pos = -1.4 + 2.8 * t;
                        final highlight = isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.22);
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(pos - 0.5, -1),
                              end: Alignment(pos + 0.5, 1),
                              colors: [
                                Colors.transparent,
                                highlight,
                                Colors.transparent,
                              ],
                              stops: const [0.35, 0.5, 0.65],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Layer 3 — soft inner glow tinted toward the bible
              // tone, lands in the bottom ~50% of the card. This is
              // what gives the foil / treasury / jet / honey accent
              // its emotional weight.
              if (!glass.reduceTransparency)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, 0.9),
                          radius: 1.2,
                          colors: [
                            accent.withValues(alpha: isDark ? 0.18 : 0.10),
                            accent.withValues(alpha: 0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              // Layer 4 — content.
              Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );

    final wrapped = Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onPressDown,
        onTapUp: _onPressUp,
        onTapCancel: _onPressCancel,
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              },
        child: card,
      ),
    );

    return wrapped;
  }

  LinearGradient _bodyGradient(
    ThemeData theme,
    bool isDark,
    Color accent,
    BibleMaterial mat,
  ) {
    switch (mat) {
      case BibleMaterial.paper:
        // Paper — clean substrate with the slightest tonal shift.
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF111623),
                  const Color(0xFF0B0F1A),
                ]
              : [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF6F8FC),
                ],
        );
      case BibleMaterial.glass:
        // Glass — frosted translucent body with brand wash. The body
        // colour is intentionally darker in dark mode so the
        // specular highlight has somewhere to land.
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.06),
                    const Color(0xFF111623),
                  ),
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.02),
                    const Color(0xFF080B14),
                  ),
                ]
              : [
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.05),
                    const Color(0xFFFFFFFF),
                  ),
                  Color.alphaBlend(
                    accent.withValues(alpha: 0.02),
                    const Color(0xFFF4F6FB),
                  ),
                ],
        );
      case BibleMaterial.foil:
        // Foil — passport / identity. Champagne gold body in light,
        // deep midnight body with gold rim in dark.
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.alphaBlend(
                    BibleTone.foilGold.withValues(alpha: 0.18),
                    const Color(0xFF0E1320),
                  ),
                  Color.alphaBlend(
                    BibleTone.foilGold.withValues(alpha: 0.06),
                    const Color(0xFF06080F),
                  ),
                ]
              : [
                  Color.alphaBlend(
                    BibleTone.foilGold.withValues(alpha: 0.18),
                    const Color(0xFFFFFBF2),
                  ),
                  Color.alphaBlend(
                    BibleTone.foilGold.withValues(alpha: 0.06),
                    const Color(0xFFFFF4DD),
                  ),
                ],
        );
      case BibleMaterial.metal:
        // Metal — gunmetal / brushed body for premium fintech (e.g.
        // Apple-Card style cards). Deep neutral with a hint of cool
        // accent.
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1F2E),
                  const Color(0xFF0E1320),
                ]
              : [
                  const Color(0xFFEDEFF5),
                  const Color(0xFFD8DCE6),
                ],
        );
      case BibleMaterial.atmosphere:
        // Atmosphere — globe / cosmic. Deep ink-blue body with a
        // hint of equator teal at the bottom.
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF06080F),
                  Color.alphaBlend(
                    BibleTone.equatorTeal.withValues(alpha: 0.10),
                    const Color(0xFF030509),
                  ),
                ]
              : [
                  Color.alphaBlend(
                    const Color(0xFF1B274D).withValues(alpha: 0.06),
                    const Color(0xFFEEF2FB),
                  ),
                  Color.alphaBlend(
                    BibleTone.equatorTeal.withValues(alpha: 0.10),
                    const Color(0xFFE3EAF6),
                  ),
                ],
        );
    }
  }

  List<Color> _specularColors(bool isDark, BibleMaterial mat) {
    if (mat == BibleMaterial.foil) {
      // Foil — warm champagne glint.
      return isDark
          ? [
              const Color(0xFFFFE9B0).withValues(alpha: 0.16),
              const Color(0xFFFFE9B0).withValues(alpha: 0),
            ]
          : [
              const Color(0xFFFFFAEA).withValues(alpha: 0.95),
              const Color(0xFFFFFAEA).withValues(alpha: 0),
            ];
    }
    return isDark
        ? [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0),
          ]
        : [
            Colors.white.withValues(alpha: 0.78),
            Colors.white.withValues(alpha: 0),
          ];
  }

  Color _strokeColor(bool isDark, BibleMaterial mat) {
    if (mat == BibleMaterial.foil) {
      return isDark
          ? const Color(0xFFFFE9B0).withValues(alpha: 0.24)
          : const Color(0xFFB58A2A).withValues(alpha: 0.30);
    }
    if (mat == BibleMaterial.atmosphere) {
      return isDark
          ? BibleTone.equatorTeal.withValues(alpha: 0.20)
          : BibleTone.equatorTeal.withValues(alpha: 0.18);
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
  }

  List<BoxShadow> _shadows(
    BibleHeroElevation elevation,
    Color tint,
    bool isDark,
  ) {
    switch (elevation) {
      case BibleHeroElevation.resting:
        return AppTokens.shadowMd(tint: isDark ? Colors.black : tint);
      case BibleHeroElevation.cinematic:
        return AppTokens.shadowCinematic(
          tint: isDark ? Colors.black : tint,
        );
      case BibleHeroElevation.floating:
        return [
          ...AppTokens.shadowXl(tint: isDark ? Colors.black : tint),
          BoxShadow(
            color: tint.withValues(alpha: isDark ? 0.10 : 0.18),
            blurRadius: 80,
            spreadRadius: -10,
            offset: const Offset(0, 36),
          ),
        ];
    }
  }
}

/// A glass-style chip used inside hero cards (e.g. "BOARDING SOON",
/// "AVIATOR", "CONCIERGE TIER"). Sits on top of the parent gradient
/// so it should be a translucent capsule, not an opaque pill.
class BibleHeroChip extends StatelessWidget {
  const BibleHeroChip({
    super.key,
    required this.label,
    this.icon,
    this.tone,
    this.material = BibleMaterial.glass,
  });

  final String label;
  final IconData? icon;
  final Color? tone;
  final BibleMaterial material;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = GlassExtension.of(context);
    final accent = tone ?? theme.colorScheme.primary;

    Color fg;
    Color bg;
    if (material == BibleMaterial.foil) {
      fg = isDark ? const Color(0xFFFFE9B0) : const Color(0xFF8A6512);
      bg = isDark
          ? const Color(0xFFFFE9B0).withValues(alpha: 0.10)
          : const Color(0xFFFFE9B0).withValues(alpha: 0.45);
    } else {
      fg = isDark
          ? Colors.white.withValues(alpha: 0.92)
          : theme.colorScheme.onSurface;
      bg = isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.white.withValues(alpha: 0.78);
    }

    final core = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );

    if (glass.reduceTransparency) return core;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: core,
      ),
    );
  }
}
