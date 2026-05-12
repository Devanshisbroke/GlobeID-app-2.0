import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import '../../nexus/nexus_tokens.dart';

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
    final accent = widget.tone ?? N.tierGold;

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
              top: Radius.circular(N.rCardLg),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: N.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(N.rCardLg),
                ),
                border: Border(
                  top: BorderSide(
                    color: N.hairlineHi,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: N.inkLow,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusFull),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                                  style: TextStyle(
                                    color: accent,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: N.inkHi,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: N.inkMid,
                            size: 20,
                          ),
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
        );
      },
    );
  }
}
