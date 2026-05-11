import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/sensor_fusion.dart';
import '../bible_tokens.dart';

/// GlobeID — **Foil** material (§4.3, §8.2 _Depth-reactive shaders_).
///
/// Gyro-reactive specular surface used on passport bio pages, premium
/// wallet cards, identity hero, loyalty cards.
///
/// Foil renders three composited effects:
///   1. A base gradient (tone-tinted) for the foil "metal".
///   2. A moving hot-spot of brightness (Gaussian falloff) that
///      tracks the device tilt vector.
///   3. Optional chromatic separation at the hot-spot edge for true
///      hologram materials (R/G/B offset).
///
/// Render fall-backs:
///   * `reduced` → static gradient only (no animation, no sensor).
///   * `normal`  → moving hot-spot, no chromatic separation.
///   * `max`     → moving hot-spot + chromatic separation + rainbow
///                 band (hologram tier).
class BibleFoil extends StatefulWidget {
  const BibleFoil({
    super.key,
    required this.child,
    this.radius = B.rCard,
    this.padding = const EdgeInsets.all(B.space5),
    this.tone = B.foilGold,
    this.hologram = false,
    this.quality = BRenderQuality.normal,
    this.lightAngleDeg = 45, // upper-left, museum lighting (Bible §4.4)
    this.intensity = 1.0,
  });

  /// Subject placed on the foil.
  final Widget child;

  /// Continuous-curve radius.
  final double radius;

  /// Inset between foil edge and subject.
  final EdgeInsets padding;

  /// Foil base tone (foil gold, diplomatic garnet, mint glass, etc.).
  final Color tone;

  /// If true, a rainbow band is rendered for the holographic tier.
  final bool hologram;

  /// Render quality. `reduced` collapses to a static gradient.
  final BRenderQuality quality;

  /// Virtual light source angle in degrees (0 = right, 90 = up).
  final double lightAngleDeg;

  /// Effect intensity multiplier (0..1.4).
  final double intensity;

  @override
  State<BibleFoil> createState() => _BibleFoilState();
}

class _BibleFoilState extends State<BibleFoil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _attached = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );
    if (widget.quality != BRenderQuality.reduced) {
      SensorFusion.instance.acquire();
      _attached = true;
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    if (_attached) SensorFusion.instance.release();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final tiltX = widget.quality == BRenderQuality.reduced
            ? 0.0
            : SensorFusion.instance.tiltX;
        final tiltY = widget.quality == BRenderQuality.reduced
            ? 0.0
            : SensorFusion.instance.tiltY;

        // Hot-spot anchor in [-1..1] driven by tilt. Combined with the
        // virtual light source (so when the device is flat, the
        // highlight sits at the screen-space light angle).
        final lightRad = widget.lightAngleDeg * math.pi / 180.0;
        final lightAnchor = Alignment(
          math.cos(lightRad),
          -math.sin(lightRad),
        );
        final tiltAnchor = Alignment(
          (tiltY / (math.pi / 18)).clamp(-1.0, 1.0),
          (tiltX / (math.pi / 18)).clamp(-1.0, 1.0),
        );
        final spot = Alignment(
          (lightAnchor.x + tiltAnchor.x * 0.6).clamp(-1.0, 1.0),
          (lightAnchor.y - tiltAnchor.y * 0.6).clamp(-1.0, 1.0),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: const Color(0x66000000),
                blurRadius: 32,
                spreadRadius: 0,
                offset: Offset(
                  -tiltAnchor.x * 8 + 0,
                  -tiltAnchor.y * 8 + 14,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Base foil gradient — tone tint with luminous mid.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _shade(widget.tone, -0.30),
                        widget.tone,
                        _shade(widget.tone, 0.18),
                        _shade(widget.tone, -0.20),
                      ],
                      stops: const [0.0, 0.40, 0.65, 1.0],
                    ),
                  ),
                ),
                // 2. Moving specular hot-spot.
                if (widget.quality != BRenderQuality.reduced)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: spot,
                            radius: 1.0,
                            stops: const [0.0, 0.35, 0.75, 1.0],
                            colors: [
                              Colors.white.withValues(
                                alpha: 0.55 * widget.intensity,
                              ),
                              Colors.white.withValues(
                                alpha: 0.18 * widget.intensity,
                              ),
                              Colors.white.withValues(alpha: 0.04),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // 3. Optional hologram rainbow band.
                if (widget.hologram &&
                    widget.quality == BRenderQuality.max)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.25 * widget.intensity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(spot.x - 0.6, spot.y - 0.4),
                              end: Alignment(spot.x + 0.6, spot.y + 0.4),
                              colors: const [
                                Color(0xFF7C3AED), // violet
                                Color(0xFF0EA5E9), // cyan
                                Color(0xFF10B981), // teal
                                Color(0xFFF59E0B), // amber
                                Color(0xFFFB7185), // coral
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // 4. Hairline inner border (foil edge).
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                // 5. Subject.
                Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _shade(Color base, double delta) {
    // delta < 0 darkens, delta > 0 lightens.
    final hsl = HSLColor.fromColor(base);
    final l = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }
}
