import 'package:flutter/material.dart';

import 'nexus_haptics.dart';
import 'nexus_tokens.dart';

/// Pressable scale wrapper — 0.97 scale on press, 160 ms tight curve,
/// optional haptic tap. Used everywhere tappable.
class NPressable extends StatefulWidget {
  const NPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final double scale;

  @override
  State<NPressable> createState() => _NPressableState();
}

class _NPressableState extends State<NPressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapCancel: widget.onTap == null ? null : () => _set(false),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) NHaptics.tap();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: N.dTap,
        curve: N.ease,
        child: AnimatedOpacity(
          opacity: _down ? 0.88 : 1.0,
          duration: N.dTap,
          curve: N.ease,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Subtle breath wrapper — a slow opacity oscillation, used for "live"
/// status pills. Avoids any geometric movement.
class NBreath extends StatefulWidget {
  const NBreath({
    super.key,
    required this.child,
    this.minOpacity = 0.55,
    this.maxOpacity = 1.0,
    this.duration = const Duration(milliseconds: 2400),
  });
  final Widget child;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  @override
  State<NBreath> createState() => _NBreathState();
}

class _NBreathState extends State<NBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
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
        final t = Curves.easeInOut.transform(_ctrl.value);
        final alpha = widget.minOpacity +
            (widget.maxOpacity - widget.minOpacity) * t;
        return Opacity(opacity: alpha, child: child);
      },
      child: widget.child,
    );
  }
}

/// Status-pill fade-in. Used when a pipeline state changes — 240 ms
/// ease-out fade with no movement.
PageRouteBuilder<T> nexusFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: N.dPage,
    reverseTransitionDuration: N.dQuick,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      final fade = CurvedAnimation(parent: anim, curve: N.ease);
      return FadeTransition(opacity: fade, child: child);
    },
  );
}
