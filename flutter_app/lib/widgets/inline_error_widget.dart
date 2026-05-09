import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// A compact, theme-aware replacement for Flutter's default red-box
/// `ErrorWidget`.
///
/// Flutter's stock error widget paints a giant red rectangle that
/// dominates whatever surface it lands on; in production builds it also
/// silently *swallows* the rest of the surrounding subtree because the
/// red box claims all available space. This widget instead paints a
/// quiet, glassy diagnostic tile so:
///
///   * a single broken card never blanks an entire screen,
///   * the engineer (or QA) sees the exception text inline,
///   * the surrounding cards continue to render normally.
///
/// Wired into the framework via:
/// ```dart
/// ErrorWidget.builder = (details) => InlineErrorWidget(details: details);
/// ```
/// in `main.dart`.
class InlineErrorWidget extends StatelessWidget {
  const InlineErrorWidget({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    // ErrorWidget can be invoked very early (before the MaterialApp
    // theme is in scope) so every Theme.of() call must tolerate a
    // missing theme. We construct a defensive default.
    ThemeData? theme;
    try {
      theme = Theme.of(context);
    } catch (_) {
      theme = null;
    }
    final isDark = theme?.brightness == Brightness.dark;
    final scheme = theme?.colorScheme;

    final surface = isDark
        ? const Color(0xFF1F1217).withValues(alpha: 0.62)
        : const Color(0xFFFFF1F2).withValues(alpha: 0.94);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0x33B91C1C);
    final accent = scheme?.error ?? const Color(0xFFB91C1C);
    final onSurface = scheme?.onSurface ??
        (isDark ? Colors.white : const Color(0xFF111827));

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64, minWidth: 0),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTokens.space2,
            vertical: AppTokens.space1,
          ),
          padding: const EdgeInsets.all(AppTokens.space3),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: border, width: 0.6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 18, color: accent),
              const SizedBox(width: AppTokens.space2),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Render error',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shorten(details.exceptionAsString()),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.35,
                        color: onSurface.withValues(alpha: 0.86),
                      ),
                    ),
                    if (kDebugMode && details.library != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        details.library ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shorten(String message) {
    final firstLine = message.split('\n').first;
    if (firstLine.length <= 240) return firstLine;
    return '${firstLine.substring(0, 240)}…';
  }
}
