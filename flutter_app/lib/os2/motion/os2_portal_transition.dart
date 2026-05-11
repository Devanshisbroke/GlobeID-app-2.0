import 'package:flutter/material.dart';

import '../os2_tokens.dart';

/// OS 2.0 — Portal transition.
///
/// Cinematic page transition between worlds. The outgoing page scales
/// slightly down (0.96) and dims under a vignette while the incoming
/// page rises from below with a parallaxed translate and a soft fade.
/// Faster on the outgoing curve than the incoming so the new world
/// feels like it "lands" rather than slides.
class Os2PortalTransition extends StatelessWidget {
  const Os2PortalTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fwd = CurvedAnimation(parent: animation, curve: Os2.cTakeoff);
    final rev = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Os2.cDescent,
      reverseCurve: Os2.cTakeoff,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([fwd, rev]),
      builder: (context, child) {
        final t = fwd.value;
        final tRev = rev.value;
        // Outgoing — slight scale down + dim vignette.
        // Incoming — rise from 18px below + fade in.
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(0.96 + 0.04 * t, 0.96 + 0.04 * t, 1.0, 1.0)
            ..translateByDouble(0.0, (1.0 - t) * 18.0 + tRev * -10.0, 0.0, 1.0),
          child: Opacity(
            opacity: (t * (1.0 - tRev * 0.4)).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
