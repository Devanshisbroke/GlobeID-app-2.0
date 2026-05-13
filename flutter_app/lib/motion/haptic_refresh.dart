// GlobeID Refinement — pull-to-refresh with semantic haptics.
//
// Wraps RefreshIndicator.adaptive with the [Haptics] vocabulary so
// every world feels the same when the user pulls down:
//
//   pullArmed     — fires once when the gesture crosses the armed
//                   threshold (you can pull further; releasing now
//                   would trigger a refresh).
//   pullCommitted — fires when the user releases an armed pull and
//                   the refresh begins.
//
// On Android (Material) this maps onto the spinner color matching
// the world's tone. On iOS (Cupertino) the adaptive indicator wraps
// the system pull-to-refresh.

import 'package:flutter/material.dart';

import 'motion.dart';

/// Pull-to-refresh wrapper that adds semantic haptics + tonal color.
///
/// Drop-in replacement for `RefreshIndicator.adaptive`. Designed for
/// the slivers inside the OS2 worlds (Wallet, Identity, Trip, etc.)
/// so every "pull down to refresh" gesture feels the same across the
/// app.
class HapticRefresh extends StatefulWidget {
  const HapticRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Color of the spinner (Material side). Defaults to the ambient
  /// `IconTheme` color.
  final Color? color;

  /// Background of the spinner pill (Material side).
  final Color? backgroundColor;

  /// Distance below the top edge at which the spinner sits when
  /// fully revealed.
  final double displacement;

  /// Optional edge offset (e.g. when stacked under a sliver app bar).
  final double edgeOffset;

  @override
  State<HapticRefresh> createState() => _HapticRefreshState();
}

class _HapticRefreshState extends State<HapticRefresh> {
  bool _armed = false;

  Future<void> _handleRefresh() async {
    Haptics.pullCommitted();
    _armed = false;
    await widget.onRefresh();
  }

  bool _onNotification(ScrollNotification n) {
    // The OverscrollIndicator notifications expose the live drag
    // metrics. We treat anything pulling > 60 px past the start as
    // "armed" — close to the default RefreshIndicator threshold of
    // 64 px.
    if (n is OverscrollNotification ||
        n is ScrollUpdateNotification ||
        n is ScrollStartNotification) {
      final metrics = n.metrics;
      if (metrics.pixels < -60 && !_armed) {
        _armed = true;
        Haptics.pullArmed();
      } else if (metrics.pixels >= -10 && _armed) {
        _armed = false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: RefreshIndicator.adaptive(
        onRefresh: _handleRefresh,
        color: widget.color,
        backgroundColor: widget.backgroundColor,
        displacement: widget.displacement,
        edgeOffset: widget.edgeOffset,
        child: widget.child,
      ),
    );
  }
}
