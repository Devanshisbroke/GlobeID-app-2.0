import 'package:flutter/material.dart';

import '../os2_tokens.dart';

/// OS 2.0 — Breathing motion wrapper.
///
/// Wraps a child in a slow sine-driven scale + opacity modulation.
/// Useful for any "this surface is alive" cue — system status indicators,
/// orbit badges, hub glyphs. Respects [MediaQuery.disableAnimations].
class Os2Breathing extends StatefulWidget {
  const Os2Breathing({
    super.key,
    required this.child,
    this.minScale = 0.985,
    this.maxScale = 1.015,
    this.minOpacity = 0.82,
    this.maxOpacity = 1.0,
    this.duration = Os2.mBreathSlow,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  @override
  State<Os2Breathing> createState() => _Os2BreathingState();
}

class _Os2BreathingState extends State<Os2Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views
                    .first)
                .disableAnimations ==
            false &&
        mounted) {
      _c.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disable = MediaQuery.of(context).disableAnimations;
    if (disable) {
      _c.stop();
      return widget.child;
    }
    if (!_c.isAnimating) _c.repeat(reverse: true);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Os2.cCruise.transform(_c.value);
        final scale = widget.minScale + (widget.maxScale - widget.minScale) * t;
        final op = widget.minOpacity + (widget.maxOpacity - widget.minOpacity) * t;
        return Opacity(
          opacity: op.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}
