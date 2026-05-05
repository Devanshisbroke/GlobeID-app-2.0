import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_tokens.dart';

/// Premium toast / snackbar system. Renders into the app overlay so
/// it survives navigation. Uses backdrop blur, accent gradient border,
/// slide-up + fade in. Stacks multiple toasts vertically.
enum AppToastTone { neutral, info, success, warning, danger }

class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static final List<_ToastData> _queue = [];

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    IconData? icon,
    AppToastTone tone = AppToastTone.neutral,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    HapticFeedback.lightImpact();
    final overlay = Overlay.of(context, rootOverlay: true);
    final id = UniqueKey();
    _queue.add(_ToastData(
      id: id,
      title: title,
      message: message,
      icon: icon ?? _iconFor(tone),
      tone: tone,
      expiresAt: DateTime.now().add(duration),
    ));
    _ensureEntry(overlay);
    _refresh();
    Future.delayed(duration, () {
      _queue.removeWhere((d) => d.id == id);
      _refresh();
      if (_queue.isEmpty) {
        _entry?.remove();
        _entry = null;
      }
    });
  }

  static IconData _iconFor(AppToastTone t) {
    switch (t) {
      case AppToastTone.success:
        return Icons.check_circle_rounded;
      case AppToastTone.warning:
        return Icons.warning_amber_rounded;
      case AppToastTone.danger:
        return Icons.error_outline_rounded;
      case AppToastTone.info:
        return Icons.info_outline_rounded;
      case AppToastTone.neutral:
        return Icons.bolt_rounded;
    }
  }

  static void _ensureEntry(OverlayState overlay) {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: (_) => const _ToastStack());
    overlay.insert(_entry!);
  }

  static void _refresh() => _entry?.markNeedsBuild();
}

class _ToastData {
  _ToastData({
    required this.id,
    required this.title,
    this.message,
    required this.icon,
    required this.tone,
    required this.expiresAt,
  });
  final Key id;
  final String title;
  final String? message;
  final IconData icon;
  final AppToastTone tone;
  final DateTime expiresAt;
}

class _ToastStack extends StatelessWidget {
  const _ToastStack();
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: mq.padding.bottom + 100,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in AppToast._queue)
                Padding(
                  key: d.id,
                  padding: const EdgeInsets.only(top: AppTokens.space2),
                  child: _ToastCard(data: d),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.data});
  final _ToastData data;
  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: AppTokens.durationMd,
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _toneColor(widget.data.tone, theme);
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space4, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.62)
                  : Colors.white.withValues(alpha: 0.78),
              border: Border.all(
                color: tone.withValues(alpha: 0.40),
              ),
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: 0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        tone.withValues(alpha: 0.36),
                        tone.withValues(alpha: 0.10),
                      ],
                    ),
                  ),
                  child: Icon(widget.data.icon, color: tone, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.data.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      if (widget.data.message != null)
                        Text(widget.data.message!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _toneColor(AppToastTone t, ThemeData theme) {
    switch (t) {
      case AppToastTone.success:
        return const Color(0xFF10B981);
      case AppToastTone.warning:
        return const Color(0xFFF59E0B);
      case AppToastTone.danger:
        return const Color(0xFFEF4444);
      case AppToastTone.info:
        return const Color(0xFF3B82F6);
      case AppToastTone.neutral:
        return theme.colorScheme.primary;
    }
  }
}
