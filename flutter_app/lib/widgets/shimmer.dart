import 'package:flutter/material.dart';

/// Single-ticker shimmer that sweeps a translucent highlight across
/// [child]. Reduce-motion aware — collapses to no-op when the user
/// has enabled reduce-transparency or platform reduce-motion.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1800),
    this.highlightColor,
    this.angle = 0.4,
  });

  final Widget child;
  final Duration duration;
  final Color? highlightColor;
  final double angle;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (reduce) return widget.child;

    final highlight = widget.highlightColor ??
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.55);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final offset = _ctrl.value;
            return LinearGradient(
              begin: Alignment(-1 - offset * 2, -1 + widget.angle),
              end: Alignment(1 + offset * 2, 1 - widget.angle),
              colors: [
                Colors.transparent,
                highlight,
                Colors.transparent,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
