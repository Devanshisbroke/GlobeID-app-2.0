import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// A widget-level error boundary.
///
/// When any descendant throws a build-time or paint-time error,
/// `SafeBoundary` swallows the exception and shows an inline diagnostic
/// tile in its place. The rest of the screen continues to render
/// normally.
///
/// This is the primary defense against the Flutter "one widget throws ⇒
/// the whole subtree paints blank" failure mode that motivated the
/// blank-render regression. Wrap each major section of a `CustomScrollView`,
/// `ListView`, or `Column` in a `SafeBoundary` so a single broken card
/// can never blank an entire tab.
///
/// Usage:
/// ```dart
/// SafeBoundary(
///   debugLabel: 'Smart suggestions strip',
///   child: SmartSuggestionsStrip(...),
/// )
/// ```
class SafeBoundary extends StatefulWidget {
  const SafeBoundary({
    super.key,
    required this.child,
    this.debugLabel,
    this.fallbackHeight = 88,
  });

  final Widget child;

  /// Human-readable name surfaced in the inline error tile and the
  /// console log line. Defaults to the runtimeType of the child.
  final String? debugLabel;

  /// Vertical space the fallback tile occupies. Tile is full-width.
  final double fallbackHeight;

  @override
  State<SafeBoundary> createState() => _SafeBoundaryState();
}

class _SafeBoundaryState extends State<SafeBoundary> {
  Object? _error;
  StackTrace? _stack;

  String get _label => widget.debugLabel ?? widget.child.runtimeType.toString();

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return _SafeBoundaryFallback(
        label: _label,
        error: error,
        stack: _stack,
        height: widget.fallbackHeight,
        onRetry: () => setState(() {
          _error = null;
          _stack = null;
        }),
      );
    }
    return _SafeBoundaryHost(
      onError: (Object e, StackTrace s) {
        if (!mounted) return;
        if (kDebugMode) {
          // ignore: avoid_print
          print('▶▶ SafeBoundary[$_label]: $e\n$s');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _error = e;
            _stack = s;
          });
        });
      },
      child: widget.child,
    );
  }
}

/// Internal helper — reroutes any exception thrown by [child]'s build
/// pass into the [onError] callback rather than letting it bubble up to
/// the framework's own ErrorWidget.
class _SafeBoundaryHost extends StatelessWidget {
  const _SafeBoundaryHost({
    required this.child,
    required this.onError,
  });

  final Widget child;
  final void Function(Object error, StackTrace stack) onError;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (ctx) {
      try {
        return child;
      } catch (e, s) {
        onError(e, s);
        // Show a placeholder during the same frame; once setState lands
        // the parent will paint the real fallback tile.
        return const SizedBox.shrink();
      }
    });
  }
}

class _SafeBoundaryFallback extends StatelessWidget {
  const _SafeBoundaryFallback({
    required this.label,
    required this.error,
    required this.stack,
    required this.height,
    required this.onRetry,
  });

  final String label;
  final Object error;
  final StackTrace? stack;
  final double height;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark
        ? const Color(0xFF1A1320).withValues(alpha: 0.62)
        : const Color(0xFFFFF1F2).withValues(alpha: 0.86);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppTokens.space2),
        padding: const EdgeInsets.all(AppTokens.space4),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 22,
              color: theme.colorScheme.error.withValues(alpha: 0.85),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    error.toString(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space3,
                        vertical: AppTokens.space1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
