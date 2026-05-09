import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Cinematic page reveal — wraps a screen body in a layered staggered
/// reveal: outer mask scale-in, inner content fade-up, brand sheen
/// sweep. Used by hero / arrival / premium-showcase surfaces.
///
/// Plays once per mount. Honors `disableAnimations`. Pure stateful
/// widget; no external state.
class CinematicReveal extends StatefulWidget {
  const CinematicReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.tone,
  });
  final Widget child;
  final Duration delay;
  final Color? tone;

  @override
  State<CinematicReveal> createState() => _CinematicRevealState();
}

class _CinematicRevealState extends State<CinematicReveal>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _ctrl.forward();
      _sheen.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) return widget.child;
    final tone = widget.tone ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl, _sheen]),
      builder: (_, __) {
        final t = AppSprings.softCurve.transform(_ctrl.value);
        final scale = 0.97 + 0.03 * t;
        final fade = t;
        final sheen = _sheen.value;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: fade,
            child: Stack(
              children: [
                widget.child,
                if (sheen > 0 && sheen < 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ShaderMask(
                        shaderCallback: (rect) => LinearGradient(
                          begin: Alignment(-1 + sheen * 2, -1),
                          end: Alignment(1 + sheen * 2, 1),
                          colors: [
                            Colors.transparent,
                            tone.withValues(alpha: 0.16 * (1 - sheen)),
                            Colors.transparent,
                          ],
                          stops: const [0.4, 0.5, 0.6],
                        ).createShader(rect),
                        blendMode: BlendMode.plus,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Lightweight extension lookup for a soft easing reused by reveal /
/// pendulum widgets. Falls back to easeOutSoft in the tokens.
class AppSprings {
  AppSprings._();
  static const Curve softCurve = AppTokens.easeOutSoft;
}
