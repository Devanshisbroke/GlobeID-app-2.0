import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_tokens.dart';

/// Pull-down gesture overlay that summons a contextual sheet.
///
/// Wraps a child and detects a vertical pull-down gesture from
/// the top region. When triggered, shows a blurred overlay with
/// context-dependent content (command palette, FX board, etc).
class PullDownSummoner extends StatefulWidget {
  const PullDownSummoner({
    super.key,
    required this.child,
    required this.overlayBuilder,
    this.triggerDistance = 80,
    this.enabled = true,
  });

  final Widget child;
  final WidgetBuilder overlayBuilder;
  final double triggerDistance;
  final bool enabled;

  @override
  State<PullDownSummoner> createState() => _PullDownSummonerState();
}

class _PullDownSummonerState extends State<PullDownSummoner>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _triggered = false;
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (!widget.enabled || _triggered) return;
    setState(() {
      _dragOffset = (_dragOffset + d.delta.dy).clamp(0, 200);
    });
    if (_dragOffset >= widget.triggerDistance && !_triggered) {
      _triggered = true;
      HapticFeedback.mediumImpact();
      _showOverlay();
    }
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (!_triggered) {
      setState(() => _dragOffset = 0);
    }
  }

  void _showOverlay() {
    _reveal.forward();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 340),
      transitionBuilder: (ctx, a1, a2, child) {
        final curve = CurvedAnimation(
          parent: a1,
          curve: AppTokens.easeOutSoft,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.15),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space5),
            child: Material(
              color: Colors.transparent,
              child: widget.overlayBuilder(ctx),
            ),
          ),
        );
      },
    ).then((_) {
      _reveal.reset();
      setState(() {
        _triggered = false;
        _dragOffset = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Stack(
        children: [
          widget.child,
          // Visual pull indicator
          if (_dragOffset > 10 && !_triggered)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: (_dragOffset / widget.triggerDistance).clamp(0, 1),
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    margin: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pull to summon',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
