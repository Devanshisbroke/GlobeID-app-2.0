import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_tokens.dart';

/// Premium press affordance — scale-down + light haptic on tap.
/// Mirrors Apple-style `UIButton.Configuration` rebound.
///
/// When [semanticLabel] is provided, the affordance is wrapped in a
/// `Semantics(button: true, label: …)` node so screen readers (VoiceOver,
/// TalkBack) announce the role + label even when the visible child is
/// icon-only chrome (e.g. a hairline glyph button on a Live credential).
/// Leave [semanticLabel] null when the child already exposes meaningful
/// text content — Flutter's default semantics will surface it.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
    this.semanticHint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final HitTestBehavior behavior;

  /// Accessibility label announced by screen readers. Required when the
  /// child is icon-only or otherwise lacks readable text content.
  final String? semanticLabel;

  /// Optional accessibility hint — short description of what activating
  /// the affordance will do (e.g. "opens passport bearer page").
  final String? semanticHint;

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
    final Widget gesture = GestureDetector(
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
    final label = widget.semanticLabel;
    if (label == null || label.isEmpty) return gesture;
    return Semantics(
      button: true,
      enabled: widget.onTap != null || widget.onLongPress != null,
      label: label,
      hint: widget.semanticHint,
      child: ExcludeSemantics(child: gesture),
    );
  }
}
