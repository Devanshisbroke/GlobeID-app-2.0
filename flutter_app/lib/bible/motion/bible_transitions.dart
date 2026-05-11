import 'dart:ui';

import 'package:flutter/material.dart';

import '../bible_tokens.dart';

/// GlobeID — **Transition Library** (§5.3).
///
/// Eight named transitions. Every Bible route opts into one
/// explicitly via `pageBuilder: (...)`. Material's defaults are not
/// used anywhere in the Bible layer.
class BibleTransitions {
  BibleTransitions._();

  /// `riseTransition` — slide up 12 %, fade in, scale from 0.94.
  /// Used for sheets, secondary screens.
  static Widget rise(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: B.takeoff,
      reverseCurve: B.descent,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }

  /// `dropTransition` — slide down with bank-curve bounce.
  /// Used for notifications, alerts, kiosk overlays.
  static Widget drop(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: B.bank,
      reverseCurve: B.descent,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.18),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  /// `morphTransition` — cross-fade with scale-down on exit.
  /// Used for tab equivalents.
  static Widget morph(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: B.cruise),
      child: ScaleTransition(
        scale: Tween(begin: 0.985, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: B.takeoff),
        ),
        child: child,
      ),
    );
  }

  /// `blurFadeTransition` — incoming fades in while background blurs
  /// from σ=8 → 0. Used for modal-grade presentations.
  static Widget blurFade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: B.takeoff);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, __) {
        final blur = (1.0 - curved.value) * 8;
        return Stack(
          children: [
            if (blur > 0.5)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: const ColoredBox(color: Color(0x00000000)),
                ),
              ),
            Opacity(opacity: curved.value, child: child),
          ],
        );
      },
    );
  }

  /// `slideLateralTransition` — iOS-classic push from right.
  /// Used for back-navigable detail flows.
  static Widget slideLateral(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final inCurve = CurvedAnimation(parent: animation, curve: B.cruise);
    final outCurve = CurvedAnimation(parent: secondary, curve: B.cruise);
    return SlideTransition(
      position: Tween(
        begin: const Offset(1.0, 0),
        end: Offset.zero,
      ).animate(inCurve),
      child: SlideTransition(
        position: Tween(
          begin: Offset.zero,
          end: const Offset(-0.20, 0),
        ).animate(outCurve),
        child: child,
      ),
    );
  }

  /// `reducedMotionTransition` — pure crossfade. Used for
  /// accessibility opt-out.
  static Widget reducedMotion(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) =>
      FadeTransition(opacity: animation, child: child);

  /// `scaleFromAnchor` — scale from a tapped point. Used for hero
  /// card → detail.
  ///
  /// Pass `anchor` (range `0..1`) via `RouteSettings.arguments`:
  ///   ```dart
  ///   context.push('/bible/passport', extra: const Offset(0.5, 0.4));
  ///   ```
  static Widget scaleFromAnchor(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child, {
    Offset anchor = const Offset(0.5, 0.5),
  }) {
    final curved = CurvedAnimation(parent: animation, curve: B.takeoff);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (_, __) {
          final scale = 0.86 + 0.14 * curved.value;
          return Transform(
            transform: Matrix4.identity()
              ..translateByDouble(
                anchor.dx * (1 - curved.value) * 24,
                anchor.dy * (1 - curved.value) * 24,
                0,
                1,
              )
              ..scaleByDouble(scale, scale, 1, 1),
            alignment: FractionalOffset(anchor.dx, anchor.dy),
            child: child,
          );
        },
      ),
    );
  }

  /// `atmosphericDescent` — descending the altitude stack. Vertical
  /// slide + scale + chromatic-aberration blur lens that resolves on
  /// land. Used only for cross-altitude descents (Globe → Trip →
  /// Boarding).
  static Widget atmosphericDescent(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: B.takeoff,
      reverseCurve: B.descent,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, __) {
        final t = curved.value;
        final blur = (1.0 - t) * 6;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1.0 - t) * 64),
            child: Transform.scale(
              scale: 0.92 + 0.08 * t,
              child: blur > 0.4
                  ? ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: blur,
                        sigmaY: blur,
                      ),
                      child: child,
                    )
                  : child,
            ),
          ),
        );
      },
    );
  }
}

/// `BiblePageRoute` — convenience route that picks the transition
/// based on the `BAltitude` delta between current and target screens.
///
/// Pushing toward `intimate` from `geosynchronous` uses
/// `atmosphericDescent`. Same-altitude pushes use `slideLateral`.
/// Higher-altitude pops use `rise` reversed. The user does not see
/// this rule — they feel it.
class BiblePageRoute<T> extends PageRouteBuilder<T> {
  BiblePageRoute({
    required WidgetBuilder builder,
    BAltitude from = BAltitude.stratospheric,
    BAltitude to = BAltitude.stratospheric,
    Duration duration = B.dSheet,
    Offset anchor = const Offset(0.5, 0.5),
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondary) => builder(context),
          transitionsBuilder: (context, animation, secondary, child) {
            final reduce =
                MediaQuery.maybeOf(context)?.disableAnimations ?? false;
            if (reduce) {
              return BibleTransitions.reducedMotion(
                context,
                animation,
                secondary,
                child,
              );
            }
            if (from.rank == to.rank) {
              return BibleTransitions.slideLateral(
                context,
                animation,
                secondary,
                child,
              );
            }
            if (to.rank > from.rank) {
              return BibleTransitions.atmosphericDescent(
                context,
                animation,
                secondary,
                child,
              );
            }
            return BibleTransitions.rise(
              context,
              animation,
              secondary,
              child,
            );
          },
        );
}
