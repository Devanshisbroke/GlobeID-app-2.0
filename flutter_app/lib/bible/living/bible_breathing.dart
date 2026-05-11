import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bible_tokens.dart';

/// GlobeID — slow ambient breathing wrapper.
///
/// Animates the child's scale between [minScale] and [maxScale] using
/// a sinusoidal cycle of [period]. Reduce-motion users see a static
/// child (no scale, no rebuild).
class BibleBreathing extends StatefulWidget {
  const BibleBreathing({
    super.key,
    required this.child,
    this.minScale = 0.985,
    this.maxScale = 1.015,
    this.period = B.substrateBreath,
    this.opacityRange = 0,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration period;

  /// Optional opacity modulation amplitude (0..0.20).
  final double opacityRange;

  @override
  State<BibleBreathing> createState() => _BibleBreathingState();
}

class _BibleBreathingState extends State<BibleBreathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period);
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.maybeOf(context);
    final r = mq?.disableAnimations ?? false;
    if (r != _reduce) {
      _reduce = r;
      _start();
    }
  }

  void _start() {
    if (_reduce) {
      _ctrl.stop();
      _ctrl.value = 0.5;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final phase = math.sin(_ctrl.value * 2 * math.pi) * 0.5 + 0.5;
        final scale = widget.minScale +
            (widget.maxScale - widget.minScale) * phase;
        final opacity = widget.opacityRange <= 0
            ? 1.0
            : 1.0 - widget.opacityRange + widget.opacityRange * phase;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}
