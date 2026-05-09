import 'package:flutter/material.dart';

/// Density categories — used by [AdaptiveDensity] to scale spacing
/// and component sizes between phones, foldables, and tablets.
enum DensityClass { compact, regular, spacious }

extension DensityClassX on DensityClass {
  /// Multiplier applied to base spacing tokens.
  double get spacing => switch (this) {
        DensityClass.compact => 0.92,
        DensityClass.regular => 1.0,
        DensityClass.spacious => 1.12,
      };

  /// Multiplier applied to typography size.
  double get typography => switch (this) {
        DensityClass.compact => 0.96,
        DensityClass.regular => 1.0,
        DensityClass.spacious => 1.04,
      };
}

/// Returns the density class for the current viewport.
DensityClass adaptiveDensityOf(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final shortest = size.shortestSide;
  if (shortest >= 600) return DensityClass.spacious;
  if (size.height < 720) return DensityClass.compact;
  return DensityClass.regular;
}

/// Wraps a builder in adaptive density context. Most widgets will
/// call [adaptiveDensityOf] directly; this helper is convenient when
/// composing complex trees that need the value injected.
class AdaptiveDensity extends StatelessWidget {
  const AdaptiveDensity({super.key, required this.builder});

  final Widget Function(BuildContext, DensityClass density) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, adaptiveDensityOf(context));
  }
}
