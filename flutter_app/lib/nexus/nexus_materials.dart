import 'package:flutter/material.dart';

import 'nexus_tokens.dart';

/// Nexus panel — the canonical card. Pure dark surface with a single
/// hairline border. No drop shadow, no backdrop blur. Restraint over
/// flourish.
class NPanel extends StatelessWidget {
  const NPanel({
    super.key,
    required this.child,
    this.padding = N.cardPad,
    this.radius = N.rCard,
    this.tone,
    this.borderTone,
    this.inset = false,
  });

  /// Optional surface tint — applied at very low opacity over the base
  /// surface (e.g. champagne for tier-bearing cards).
  final Color? tone;

  /// Optional border accent — used to lift the card without adding
  /// shadow (e.g. active state).
  final Color? borderTone;

  /// If true, use `surfaceInset` instead of `surface` — for cards
  /// nested inside cards.
  final bool inset;

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = inset ? N.surfaceInset : N.surface;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderTone ?? N.hairline,
          width: N.strokeHair,
        ),
      ),
      child: tone == null
          ? child
          : Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tone!.withValues(alpha: 0.045),
                            tone!.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
    );
  }
}

/// Thin horizontal hairline divider.
class NHairline extends StatelessWidget {
  const NHairline({super.key, this.color, this.inset = 0});
  final Color? color;
  final double inset;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: SizedBox(
        height: N.strokeHair,
        child: ColoredBox(color: color ?? N.hairline),
      ),
    );
  }
}

/// Vertical hairline (for inline separators).
class NVHairline extends StatelessWidget {
  const NVHairline({super.key, this.color, this.height = 16});
  final Color? color;
  final double height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: N.strokeHair,
      height: height,
      child: ColoredBox(color: color ?? N.hairline),
    );
  }
}

/// Tiny dot separator — used in eyebrows: "GLOBE ID · TRAVEL OS".
class NDot extends StatelessWidget {
  const NDot({super.key, this.color = N.inkFaint, this.size = 2});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: N.s2),
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Subtle dim overlay — used for the substrate vignette at page edges.
class NVignette extends StatelessWidget {
  const NVignette({super.key, this.intensity = 0.45});
  final double intensity;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: intensity),
            ],
            stops: const [0.7, 1.0],
          ),
        ),
      ),
    );
  }
}
