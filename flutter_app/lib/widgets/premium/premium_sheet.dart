import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';

/// Magnetic premium bottom sheet.
///
/// A `DraggableScrollableSheet` with three magnetic snap points (peek,
/// half, full), a glass header, a haptic-tick whenever the user
/// crosses a snap boundary, and a tinted ring + soft shadow
/// for depth. The provided [child] is the scrollable body — pass it a
/// [ScrollController] from the builder.
///
/// Usage:
///   showPremiumSheet(
///     context: context,
///     tone: theme.colorScheme.primary,
///     title: 'Boarding',
///     builder: (controller) => ListView(controller: controller, ...),
///   );
Future<T?> showPremiumSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(ScrollController) builder,
  Color? tone,
  String? eyebrow,
  List<double> snaps = const [0.32, 0.6, 0.92],
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (_) => _PremiumSheet(
      title: title,
      tone: tone,
      eyebrow: eyebrow,
      snaps: snaps,
      builder: builder,
    ),
  );
}

class _PremiumSheet extends StatefulWidget {
  const _PremiumSheet({
    required this.title,
    required this.builder,
    required this.snaps,
    this.tone,
    this.eyebrow,
  });
  final String title;
  final String? eyebrow;
  final Color? tone;
  final List<double> snaps;
  final Widget Function(ScrollController) builder;

  @override
  State<_PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<_PremiumSheet> {
  int _lastSnap = -1;

  void _onSnapChanged(double size) {
    int idx = 0;
    var bestDelta = double.infinity;
    for (var i = 0; i < widget.snaps.length; i++) {
      final d = (widget.snaps[i] - size).abs();
      if (d < bestDelta) {
        bestDelta = d;
        idx = i;
      }
    }
    if (idx != _lastSnap) {
      _lastSnap = idx;
      HapticPatterns.magneticSnap.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.tone ?? theme.colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: widget.snaps[1],
      minChildSize: widget.snaps.first,
      maxChildSize: widget.snaps.last,
      expand: false,
      snap: true,
      snapSizes: widget.snaps,
      builder: (ctx, controller) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            _onSnapChanged(n.extent);
            return false;
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.radius3xl),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xCC0B0F1A)
                      : const Color(0xF2FFFFFF),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTokens.radius3xl),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: accent.withValues(alpha: 0.32),
                      width: 0.8,
                    ),
                  ),
                  boxShadow: AppTokens.shadowCinematic(tint: accent),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // Drag handle.
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.28),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space5,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.eyebrow != null)
                                  Text(
                                    widget.eyebrow!.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: accent,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                Text(
                                  widget.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(ctx).maybePop();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Expanded(child: widget.builder(controller)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
