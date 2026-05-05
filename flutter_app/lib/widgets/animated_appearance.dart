import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Staggered fade-up that runs once on first build. Respects
/// `MediaQuery.disableAnimations` (Reduce Motion).
class AnimatedAppearance extends StatefulWidget {
  const AnimatedAppearance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppTokens.durationMd,
    this.offset = 24,
    this.curve = AppTokens.easeOutSoft,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final Curve curve;

  @override
  State<AnimatedAppearance> createState() => _AnimatedAppearanceState();
}

class _AnimatedAppearanceState extends State<AnimatedAppearance>
    with SingleTickerProviderStateMixin {
  late final _ctrl =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = widget.curve.transform(_ctrl.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offset),
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Staggered list helper — wraps each child with an AnimatedAppearance
/// whose delay scales linearly with index.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.gap = AppTokens.space3,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.staggerMs = 40,
    this.startDelayMs = 0,
  });

  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final int staggerMs;
  final int startDelayMs;

  @override
  Widget build(BuildContext context) {
    final wrapped = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      wrapped.add(AnimatedAppearance(
        delay: Duration(milliseconds: startDelayMs + i * staggerMs),
        child: children[i],
      ));
      if (i != children.length - 1) wrapped.add(SizedBox(height: gap));
    }
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: wrapped,
    );
  }
}
