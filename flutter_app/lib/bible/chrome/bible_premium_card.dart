import 'package:flutter/material.dart';

import '../bible_tokens.dart';
import '../materials/bible_glass.dart';

/// GlobeID — **PremiumCard** (§10).
///
/// Glass surface with a hairline border and a 4-stop ambient
/// tone-gradient overlay. The Bible's most reused container.
class BiblePremiumCard extends StatelessWidget {
  const BiblePremiumCard({
    super.key,
    required this.child,
    this.tone,
    this.padding = const EdgeInsets.all(B.space5),
    this.radius = B.rCard,
    this.elevation = 0.6,
    this.blurSigma = B.glassBlurSigma,
    this.quality = BRenderQuality.normal,
  });

  final Widget child;

  /// Tone-tinted overlay (≤6 % alpha). Pulls from the current screen's
  /// tone palette by convention.
  final Color? tone;

  final EdgeInsets padding;
  final double radius;
  final double elevation;
  final double blurSigma;
  final BRenderQuality quality;

  @override
  Widget build(BuildContext context) {
    return BibleGlass(
      radius: radius,
      padding: EdgeInsets.zero,
      blurSigma: blurSigma,
      elevation: elevation,
      quality: quality,
      child: Stack(
        children: [
          if (tone != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tone!.withValues(alpha: 0.08),
                        tone!.withValues(alpha: 0.0),
                        tone!.withValues(alpha: 0.03),
                        tone!.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.40, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
