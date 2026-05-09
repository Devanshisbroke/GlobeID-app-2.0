import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quality tier — dynamically adjusted by [RenderProfileNotifier] based
/// on device capability signals (frame timings, battery, thermals).
enum RenderQuality {
  /// Bare minimum: no blur, no particles, static backgrounds.
  reduced,

  /// Default: moderate blur, limited particles, standard animations.
  normal,

  /// Flagship: full blur stacks, dense particles, cinematic effects.
  max,
}

extension RenderQualityX on RenderQuality {
  /// Blur sigma multiplier: reduced → 0, normal → 1, max → 1.
  double get blurScale => switch (this) {
        RenderQuality.reduced => 0.0,
        RenderQuality.normal => 1.0,
        RenderQuality.max => 1.0,
      };

  /// Particle count multiplier.
  double get particleScale => switch (this) {
        RenderQuality.reduced => 0.0,
        RenderQuality.normal => 0.6,
        RenderQuality.max => 1.0,
      };

  /// Whether to enable cinematic extras (aurora, cloud bands, lens flare).
  bool get cinematicExtras => this == RenderQuality.max;

  /// Number of starfield layers (0–5).
  int get starLayers => switch (this) {
        RenderQuality.reduced => 1,
        RenderQuality.normal => 3,
        RenderQuality.max => 5,
      };
}

/// Manages the current render quality tier.
///
/// For V1 this is a simple user-facing toggle. Phase 2 will add
/// automatic frame-timing analysis to dynamically drop to `reduced`
/// when sustained frame drops are detected.
class RenderProfileNotifier extends StateNotifier<RenderQuality> {
  RenderProfileNotifier() : super(RenderQuality.normal);

  void setQuality(RenderQuality q) => state = q;

  void upgrade() {
    if (state == RenderQuality.reduced) state = RenderQuality.normal;
    if (state == RenderQuality.normal) state = RenderQuality.max;
  }

  void downgrade() {
    if (state == RenderQuality.max) state = RenderQuality.normal;
    if (state == RenderQuality.normal) state = RenderQuality.reduced;
  }
}

final renderProfileProvider =
    StateNotifierProvider<RenderProfileNotifier, RenderQuality>(
  (ref) => RenderProfileNotifier(),
);
