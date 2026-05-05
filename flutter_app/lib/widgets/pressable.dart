import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_tokens.dart';

/// Premium press affordance — scale-down + light haptic on tap.
/// Mirrors Apple-style `UIButton.Configuration` rebound.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: AppTokens.durationXs,
    reverseDuration: AppTokens.durationSm,
  );

  late final _anim = Tween<double>(begin: 1.0, end: widget.scale)
      .chain(CurveTween(curve: AppTokens.easeOutSoft))
      .animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) => _ctrl.forward();
  void _up(_) => _ctrl.reverse();
  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : _down,
      onTapUp: widget.onTap == null
          ? null
          : (d) {
              _up(d);
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap?.call();
            },
      onTapCancel: widget.onTap == null ? null : _cancel,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: ScaleTransition(scale: _anim, child: widget.child),
    );
  }
}
