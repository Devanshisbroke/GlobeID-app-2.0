import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bible_tokens.dart';

/// GlobeID — **Pressable** (§10).
///
/// Every tappable surface in the Bible layer is wrapped in this. Built-in:
///   * scale-on-press (0.985 default per Bible),
///   * selection-click haptic on tap,
///   * subtle dimming ripple via ColorFilter.
///
/// **No raw `GestureDetector` ever.** If you find yourself using
/// `GestureDetector` for a tap action, replace it with `BiblePressable`.
class BiblePressable extends StatefulWidget {
  const BiblePressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.985,
    this.haptic = true,
    this.opacityOnPress = 0.88,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final double opacityOnPress;
  final HitTestBehavior behavior;

  @override
  State<BiblePressable> createState() => _BiblePressableState();
}

class _BiblePressableState extends State<BiblePressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null && widget.onLongPress == null
          ? null
          : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress!();
            },
      child: AnimatedScale(
        duration: B.dQuick,
        curve: B.bank,
        scale: _down ? widget.scale : 1.0,
        child: AnimatedOpacity(
          duration: B.dQuick,
          opacity: _down ? widget.opacityOnPress : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
