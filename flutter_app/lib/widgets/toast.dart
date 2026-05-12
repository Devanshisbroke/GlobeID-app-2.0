import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../nexus/nexus_tokens.dart';
import '../nexus/nexus_typography.dart';

/// Nexus notification system. Renders into the app overlay so it
/// survives navigation. Flat OLED surface + 0.5pt hairline border +
/// 3px severity rail on the left edge. No blur, no shadow, no
/// saturated gradient — pure Travel-OS language.
///
/// Use [AppToast.show] anywhere you previously used a `SnackBar`.
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
    HapticFeedback.selectionClick();
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
        return Icons.check_circle_outline_rounded;
      case AppToastTone.warning:
        return Icons.warning_amber_rounded;
      case AppToastTone.danger:
        return Icons.error_outline_rounded;
      case AppToastTone.info:
        return Icons.info_outline_rounded;
      case AppToastTone.neutral:
        return Icons.bolt_outlined;
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
          padding: const EdgeInsets.symmetric(horizontal: N.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in AppToast._queue)
                Padding(
                  key: d.id,
                  padding: const EdgeInsets.only(top: N.s2),
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
    duration: N.dBanner,
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneColor(widget.data.tone);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = N.ease.transform(_ctrl.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(N.rCard),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: N.surface,
            border: Border.all(
              color: N.hairline,
              width: N.strokeHair,
            ),
            borderRadius: BorderRadius.circular(N.rCard),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  color: tone,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: N.s4, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(widget.data.icon, color: tone, size: N.iconMd),
                        const SizedBox(width: N.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.data.title,
                                style: NType.title16(color: N.inkHi),
                              ),
                              if (widget.data.message != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.data.message!,
                                  style: NType.body13(color: N.inkMid),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _toneColor(AppToastTone t) {
    switch (t) {
      case AppToastTone.success:
        return N.success;
      case AppToastTone.warning:
        return N.warning;
      case AppToastTone.danger:
        return N.critical;
      case AppToastTone.info:
        return N.info;
      case AppToastTone.neutral:
        return N.tierGold;
    }
  }
}
