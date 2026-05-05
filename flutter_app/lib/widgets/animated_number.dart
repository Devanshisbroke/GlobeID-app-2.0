import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Animated number ticker. Tweens between value updates with a soft
/// curve. Supports prefix (e.g. currency symbol) and decimals.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 2,
    this.duration = AppTokens.durationLg,
    this.style,
  });

  final double value;
  final String prefix;
  final String suffix;
  final int decimals;
  final Duration duration;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: AppTokens.easeOutSoft,
      builder: (_, v, __) {
        return Text(
          '$prefix${v.toStringAsFixed(decimals)}$suffix',
          style: (style ?? const TextStyle()).copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
