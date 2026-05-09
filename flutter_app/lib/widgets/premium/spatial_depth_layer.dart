import 'package:flutter/material.dart';

import '../../core/sensor_fusion.dart';

/// Z-depth simulator — renders a stack of children with parallax
/// driven by accelerometer + scroll position so the surface feels
/// genuinely three-dimensional.
///
/// Each [SpatialLayer] specifies its own depth (0 = far back,
/// 1 = at-camera). On tilt, deeper layers move less (parallax) and
/// are rendered with slightly more atmospheric haze.
class SpatialLayer {
  const SpatialLayer({
    required this.child,
    this.depth = 0.5,
    this.haze = true,
  });
  final Widget child;
  final double depth;
  final bool haze;
}

class SpatialDepthLayer extends StatefulWidget {
  const SpatialDepthLayer({
    super.key,
    required this.layers,
    this.maxParallax = 18.0,
    this.scroll,
  });

  final List<SpatialLayer> layers;
  final double maxParallax;

  /// Optional scroll controller — when provided, the deepest layers
  /// also drift as the page scrolls.
  final ScrollController? scroll;

  @override
  State<SpatialDepthLayer> createState() => _SpatialDepthLayerState();
}

class _SpatialDepthLayerState extends State<SpatialDepthLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  double _scroll = 0;

  @override
  void initState() {
    super.initState();
    SensorFusion.instance.acquire();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    widget.scroll?.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    final v = widget.scroll!.hasClients ? widget.scroll!.offset : 0.0;
    if ((v - _scroll).abs() > 1) {
      setState(() => _scroll = v);
    }
  }

  @override
  void dispose() {
    widget.scroll?.removeListener(_onScroll);
    _ticker.dispose();
    SensorFusion.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _ticker,
      builder: (_, __) {
        final sf = SensorFusion.instance;
        return Stack(
          children: [
            for (final layer in widget.layers)
              _build(layer, sf.tiltX, sf.tiltY, reduce),
          ],
        );
      },
    );
  }

  Widget _build(SpatialLayer layer, double tiltX, double tiltY, bool reduce) {
    final depth = layer.depth.clamp(0.0, 1.0);
    final mult = (1.0 - depth) * widget.maxParallax;
    final tx = reduce ? 0.0 : (tiltY / 0.18).clamp(-1.0, 1.0) * mult;
    final ty = reduce ? 0.0 : (tiltX / 0.18).clamp(-1.0, 1.0) * mult;
    final scrollDrift = reduce ? 0.0 : -_scroll * (1.0 - depth) * 0.18;
    final hazed = layer.haze && depth < 0.45
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: (0.45 - depth) * 0.45),
              BlendMode.srcATop,
            ),
            child: layer.child,
          )
        : layer.child;
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(tx, ty + scrollDrift),
        child: hazed,
      ),
    );
  }
}
