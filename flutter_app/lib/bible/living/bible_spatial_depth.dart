import 'package:flutter/material.dart';

import '../../core/sensor_fusion.dart';
import '../bible_tokens.dart';

/// GlobeID — **Spatial Depth** (§8.1).
///
/// Wraps a child in a multi-slot parallax stack. Each `slot` in the
/// list nudges proportional to the device tilt vector:
///   * slot 0 → background gradient   (0.05× tilt)
///   * slot 1 → substrate / paper     (0.15× tilt)
///   * slot 2 → content / text / photo (0.30× tilt)
///   * slot 3 → foil sheen / specular  (0.65× tilt)
///   * slot 4 → chip / hologram        (0.85× tilt)
///
/// When `RenderQuality.reduced` or the user has reduce-motion turned
/// on, the stack collapses to a flat z-order with no parallax.
///
/// The widget acquires/releases SensorFusion automatically — safe to
/// nest or duplicate.
class BibleSpatialDepth extends StatefulWidget {
  const BibleSpatialDepth({
    super.key,
    required this.slots,
    this.maxTravelPx = 12,
    this.quality = BRenderQuality.normal,
  });

  /// Ordered list of widget slots. Index = depth slot (0..4 typical).
  /// More than 5 entries continues with progressively heavier weights.
  final List<Widget> slots;

  /// Maximum pixels of travel for the deepest slot. Slot offsets are
  /// `slotWeight * (tilt / maxTilt) * maxTravelPx`.
  final double maxTravelPx;

  final BRenderQuality quality;

  @override
  State<BibleSpatialDepth> createState() => _BibleSpatialDepthState();
}

class _BibleSpatialDepthState extends State<BibleSpatialDepth>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _attached = false;

  static const _slotWeights = <double>[
    B.slot0,
    B.slot1,
    B.slot2,
    B.slot3,
    B.slot4,
  ];

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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        final tx = (reduce || widget.quality == BRenderQuality.reduced)
            ? 0.0
            : SensorFusion.instance.tiltY;
        final ty = (reduce || widget.quality == BRenderQuality.reduced)
            ? 0.0
            : SensorFusion.instance.tiltX;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.slots.length; i++)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(
                    -tx * _weight(i) * widget.maxTravelPx /
                        (3.141592653589793 / 18),
                    -ty * _weight(i) * widget.maxTravelPx /
                        (3.141592653589793 / 18),
                  ),
                  child: widget.slots[i],
                ),
              ),
          ],
        );
      },
    );
  }

  double _weight(int i) {
    if (i < _slotWeights.length) return _slotWeights[i];
    // Beyond slot 4, keep adding 0.10 per slot.
    return _slotWeights.last + (i - _slotWeights.length + 1) * 0.10;
  }
}
