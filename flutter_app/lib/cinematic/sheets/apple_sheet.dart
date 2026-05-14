import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple-Wallet-grade modal bottom sheet substrate.
///
/// Designed to feel like a real physical card being pulled up from
/// the bottom of the screen — soft magnetic snap to three detents
/// (peek / mid / full), a gaussian-blur backdrop, a drag handle that
/// emits a selection haptic on grab + a light impact when it
/// crosses a detent boundary, and rubber-band overscroll behaviour
/// on the inner scroll view so the sheet always feels like a real
/// material rather than a UI panel.
///
/// Brand DNA — the drag handle sits on a faint gold hairline so
/// every Apple sheet still reads as "engineered by GlobeID", even
/// before any content paints. This is the GlobeID counterpart to
/// the standard Apple Wallet pull-up: the gestures + physics match
/// Cupertino expectations, but the chrome is unmistakably ours.
///
/// Usage:
/// ```dart
/// final result = await showAppleSheet<MyResult>(
///   context: context,
///   tone: theme.colorScheme.primary,
///   title: 'Confirm payment',
///   builder: (controller) => ListView(controller: controller, ...),
/// );
/// ```
Future<T?> showAppleSheet<T>({
  required BuildContext context,
  required Widget Function(ScrollController controller) builder,
  String? title,
  String? eyebrow,
  Color? tone,
  List<double> detents = const [0.30, 0.55, 0.92],
  Color? backdropTint,
  double backdropBlur = 24,
  bool isDismissible = true,
  bool enableDrag = true,
  Widget? leading,
  Widget? trailing,
  String? caseNumber,
  bool showWatermark = true,
}) {
  assert(detents.length >= 2, 'AppleSheet needs at least two detents');
  final sortedDetents = [...detents]..sort();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    builder: (sheetContext) {
      return _AppleSheet(
        title: title,
        eyebrow: eyebrow,
        tone: tone,
        leading: leading,
        trailing: trailing,
        detents: sortedDetents,
        backdropTint:
            backdropTint ?? const Color(0x55050505),
        backdropBlur: backdropBlur,
        caseNumber: caseNumber ?? defaultCaseNumber(title, eyebrow),
        showWatermark: showWatermark,
        builder: builder,
      );
    },
  );
}

class _AppleSheet extends StatefulWidget {
  const _AppleSheet({
    required this.detents,
    required this.builder,
    required this.backdropTint,
    required this.backdropBlur,
    required this.caseNumber,
    required this.showWatermark,
    this.title,
    this.eyebrow,
    this.tone,
    this.leading,
    this.trailing,
  });
  final List<double> detents;
  final Widget Function(ScrollController controller) builder;
  final Color backdropTint;
  final double backdropBlur;
  final String? title;
  final String? eyebrow;
  final Color? tone;
  final Widget? leading;
  final Widget? trailing;
  final String caseNumber;
  final bool showWatermark;

  @override
  State<_AppleSheet> createState() => _AppleSheetState();
}

class _AppleSheetState extends State<_AppleSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  int _lastSnap = -1;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _onExtentChange(double size) {
    int idx = 0;
    var best = double.infinity;
    for (var i = 0; i < widget.detents.length; i++) {
      final d = (widget.detents[i] - size).abs();
      if (d < best) {
        best = d;
        idx = i;
      }
    }
    // Tight tolerance so the haptic only fires near a real snap
    // point — otherwise mid-drag the user would feel a constant
    // chatter as the closest-detent index flips on every frame.
    if (best > 0.020) return;
    if (idx != _lastSnap) {
      _lastSnap = idx;
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.tone ?? const Color(0xFFD4AF37);
    return Stack(
      children: [
        // Gaussian-blur backdrop. The blur fades in with the
        // entrance curve so the sheet feels like it pulls reality
        // out of focus behind it rather than the backdrop snapping
        // in on frame zero.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (_, __) {
                final t = Curves.easeOutCubic.transform(_entrance.value);
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.backdropBlur * t,
                    sigmaY: widget.backdropBlur * t,
                  ),
                  child: Container(
                    color: Color.lerp(
                      Colors.transparent,
                      widget.backdropTint,
                      t,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: widget.detents[1],
          minChildSize: widget.detents.first * 0.40,
          maxChildSize: widget.detents.last,
          expand: false,
          snap: true,
          snapSizes: widget.detents,
          snapAnimationDuration: const Duration(milliseconds: 320),
          builder: (ctx, controller) {
            return NotificationListener<DraggableScrollableNotification>(
              onNotification: (n) {
                _onExtentChange(n.extent);
                return false;
              },
              child: AnimatedBuilder(
                animation: _entrance,
                builder: (_, child) {
                  // Slide-up entrance — sheet body climbs from
                  // 24 px below its rest position into place,
                  // matching the Apple Wallet pull-up feel.
                  final t = Curves.easeOutCubic.transform(_entrance.value);
                  return Transform.translate(
                    offset: Offset(0, 24 * (1 - t)),
                    child: Opacity(opacity: t, child: child),
                  );
                },
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xF21A1A1F),
                            Color(0xF20E0E12),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          // Drag handle — selection haptic on grab.
                          // Listener catches the pointerDown so the
                          // user feels the substrate "pick up" the
                          // moment they touch the handle, exactly
                          // like a real card you can pinch.
                          Listener(
                            onPointerDown: (_) {
                              HapticFeedback.selectionClick();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 60,
                              ),
                              child: Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.32),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Brand hairline — quiet gold thread that
                          // tells the user this isn't a vanilla
                          // Material sheet; it's a GlobeID sheet.
                          Container(
                            height: 0.6,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  accent.withValues(alpha: 0.42),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          if (widget.title != null ||
                              widget.eyebrow != null ||
                              widget.leading != null ||
                              widget.trailing != null) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                children: [
                                  if (widget.leading != null) ...[
                                    widget.leading!,
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.eyebrow != null)
                                          Text(
                                            widget.eyebrow!.toUpperCase(),
                                            style: TextStyle(
                                              color: accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.6,
                                            ),
                                          ),
                                        if (widget.title != null)
                                          Text(
                                            widget.title!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (widget.trailing != null) widget.trailing!,
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Inner scrollable body — wraps the
                          // provided controller in
                          // BouncingScrollPhysics so overscroll has
                          // the rubber-band feel of a real surface
                          // rather than a hard stop at the edges.
                          Expanded(
                            child: Stack(
                              children: [
                                ScrollConfiguration(
                                  behavior:
                                      const _AppleSheetScrollBehavior(),
                                  child: widget.builder(controller),
                                ),
                                if (widget.showWatermark)
                                  Positioned(
                                    right: 14,
                                    bottom: 10,
                                    child: IgnorePointer(
                                      child: AppleSheetWatermark(
                                        tone: accent,
                                        caseNumber: widget.caseNumber,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AppleSheetScrollBehavior extends ScrollBehavior {
  const _AppleSheetScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Bouncing-on-top-of-clamping so the inner ListView can
    // overshoot at both ends (rubber band) but never decouple
    // from the parent DraggableScrollableSheet's snap behaviour.
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Apple sheets never show the Material glow indicator; the
    // rubber-band bounce is the entire feedback channel.
    return child;
  }
}

/// Deterministic case-number generator for the watermark.
///
/// Same `(title, eyebrow)` pair always resolves to the same number,
/// so a given sheet reads as a recurring "case file" across
/// sessions rather than churning every mount.
String defaultCaseNumber(String? title, String? eyebrow) {
  final seed = '${eyebrow ?? ''}|${title ?? ''}';
  // FNV-1a 32-bit hash for stability across platforms.
  var hash = 0x811C9DC5;
  for (final code in seed.codeUnits) {
    hash ^= code;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final body = hash.toRadixString(16).toUpperCase().padLeft(8, '0');
  return 'N° $body';
}

/// Mono-cap GLOBE · ID watermark painted at the bottom-right of
/// every Apple sheet. Reads as the brand thread on every modal —
/// the same logic as a stamped serial on a luxury good. Low alpha
/// (12 % white + 32 % tone) keeps it from competing with content;
/// the foil-gold tone hairline above ties it to the sheet handle.
class AppleSheetWatermark extends StatelessWidget {
  const AppleSheetWatermark({
    super.key,
    required this.tone,
    required this.caseNumber,
  });
  final Color tone;
  final String caseNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 80,
          height: 0.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                tone.withValues(alpha: 0.36),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'GLOBE · ID',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.18),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.4,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 1),
        Text(
          caseNumber,
          style: TextStyle(
            color: tone.withValues(alpha: 0.42),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
