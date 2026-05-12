import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Nexus bottom sheet — the canonical container for modal content.
///
///   showNexusSheet(
///     context: context,
///     title: 'Authorize',
///     child: ...,
///   );
///
/// Flat `N.surface` substrate, 0.5pt hairline border, no blur, no
/// shadow, drag-handle pill above the header. Slides up over
/// [N.dSheet] with the Nexus ease curve.
Future<T?> showNexusSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? eyebrow,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
}) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    elevation: 0,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: N.dSheet,
      reverseDuration: N.dQuick,
    ),
    builder: (ctx) => _NexusSheetShell(
      title: title,
      eyebrow: eyebrow,
      child: child,
    ),
  );
}

class _NexusSheetShell extends StatelessWidget {
  const _NexusSheetShell({
    required this.child,
    this.title,
    this.eyebrow,
  });

  final Widget child;
  final String? title;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(N.rSheet),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: N.surface,
            border: Border(
              top: BorderSide(color: N.hairline, width: N.strokeHair),
              left: BorderSide(color: N.hairline, width: N.strokeHair),
              right: BorderSide(color: N.hairline, width: N.strokeHair),
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(N.rSheet),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: N.s3),
                // Drag handle pill
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: N.hairlineHi,
                      borderRadius: BorderRadius.circular(N.rPill),
                    ),
                  ),
                ),
                if (title != null || eyebrow != null) ...[
                  const SizedBox(height: N.s4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: N.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (eyebrow != null) ...[
                          Text(
                            eyebrow!.toUpperCase(),
                            style: NType.eyebrow10(color: N.tierGold),
                          ),
                          const SizedBox(height: N.s2),
                        ],
                        if (title != null)
                          Text(title!, style: NType.title22(color: N.inkHi)),
                      ],
                    ),
                  ),
                  const SizedBox(height: N.s3),
                  const Divider(
                    color: N.hairline,
                    height: 1,
                    thickness: N.strokeHair,
                  ),
                ],
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
