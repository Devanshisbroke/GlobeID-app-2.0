import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../core/sensor_fusion.dart';
import '../../motion/haptic_choreography.dart';
import 'magnetic_pressable.dart';

/// Generic stacked-card scroller with sensor-driven parallax,
/// peek depth, fan-out (long-press), and magnetic active-card focus.
///
/// Designed to replace the inline `_PassStack` in wallet so the same
/// experience can be reused for identity credentials, trip stack,
/// and concierge cards. Children must each be the same dominant
/// size — the stack will scale neighbours down to indicate depth.
class KineticCardStack extends StatefulWidget {
  const KineticCardStack({
    super.key,
    required this.itemCount,
    required this.builder,
    this.height = 280,
    this.viewportFraction = 0.90,
    this.peekDepth = 2,
    this.onActiveChanged,
    this.onTap,
    this.heroTagBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext, int index, double t) builder;
  final double height;
  final double viewportFraction;
  final int peekDepth;
  final ValueChanged<int>? onActiveChanged;
  final ValueChanged<int>? onTap;
  final Object Function(int index)? heroTagBuilder;

  @override
  State<KineticCardStack> createState() => _KineticCardStackState();
}

class _KineticCardStackState extends State<KineticCardStack>
    with SingleTickerProviderStateMixin {
  late final PageController _ctrl =
      PageController(viewportFraction: widget.viewportFraction);
  late final AnimationController _fan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  );
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();
  double _page = 0;
  bool _fanOpen = false;
  int _last = 0;

  @override
  void initState() {
    super.initState();
    SensorFusion.instance.acquire();
    _ctrl.addListener(() {
      if (!mounted) return;
      final p = _ctrl.page ?? _page;
      if ((p - _page).abs() < 0.001) return;
      setState(() => _page = p);
      final rounded = p.round();
      if (rounded != _last && rounded >= 0 && rounded < widget.itemCount) {
        _last = rounded;
        widget.onActiveChanged?.call(rounded);
        HapticPatterns.snap.play();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _fan.dispose();
    _ticker.dispose();
    SensorFusion.instance.release();
    super.dispose();
  }

  void _toggleFan() {
    if (widget.itemCount <= 1) return;
    HapticPatterns.pressureBegin.play();
    if (_fanOpen) {
      _fan.reverse();
    } else {
      _fan.forward();
    }
    setState(() => _fanOpen = !_fanOpen);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final current = _page.round().clamp(0, widget.itemCount - 1);
    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onLongPress: _toggleFan,
        child: AnimatedBuilder(
          animation: Listenable.merge([_fan, _ticker]),
          builder: (_, __) {
            final f = Curves.easeOutCubic.transform(_fan.value);
            final sf = SensorFusion.instance;
            final tiltX = reduce ? 0.0 : sf.tiltX;
            final tiltY = reduce ? 0.0 : sf.tiltY;
            return LayoutBuilder(
              builder: (_, c) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (f > 0.001)
                    for (var i = 0; i < widget.itemCount; i++)
                      _FanLayer(
                        delta: i - current,
                        fan: f,
                        tiltX: tiltX,
                        tiltY: tiltY,
                        onTap: () {
                          _toggleFan();
                          _ctrl.animateToPage(
                            i,
                            duration: AppTokens.durationMd,
                            curve: AppTokens.easeOutSoft,
                          );
                        },
                        child: widget.builder(context, i, 1),
                      ),
                  Opacity(
                    opacity: 1 - f,
                    child: IgnorePointer(
                      ignoring: _fanOpen,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          for (var depth = widget.peekDepth;
                              depth >= 1;
                              depth--)
                            if (current + depth < widget.itemCount)
                              _PeekLayer(
                                depth: depth,
                                child: widget.builder(
                                  context,
                                  current + depth,
                                  0,
                                ),
                              ),
                          Positioned.fill(
                            top: 0,
                            child: PageView.builder(
                              controller: _ctrl,
                              clipBehavior: Clip.none,
                              itemCount: widget.itemCount,
                              itemBuilder: (context, i) {
                                final delta = (_page - i).abs();
                                final scale =
                                    (1 - delta * 0.065).clamp(0.86, 1.0);
                                final opacity =
                                    (1 - delta * 0.34).clamp(0.42, 1.0);
                                final y = (delta * 12).clamp(0.0, 22.0);
                                final isActive = delta < 0.5;
                                return Transform.translate(
                                  offset: Offset(0, y),
                                  child: Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.topCenter,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppTokens.space2),
                                        child: MagneticPressable(
                                          haptic: false,
                                          scale: isActive ? 0.985 : 1.0,
                                          tilt: isActive ? 0.04 : 0.0,
                                          magnetism: isActive ? 6 : 0,
                                          onTap: isActive
                                              ? () {
                                                  HapticPatterns.tap.play();
                                                  widget.onTap?.call(i);
                                                }
                                              : null,
                                          child: _SensorTilt(
                                            tiltX: tiltX,
                                            tiltY: tiltY,
                                            active: isActive,
                                            child: widget.heroTagBuilder == null
                                                ? widget.builder(
                                                    context, i, 1 - delta)
                                                : Hero(
                                                    tag: widget
                                                        .heroTagBuilder!(i),
                                                    child: widget.builder(
                                                        context,
                                                        i,
                                                        1 - delta),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PeekLayer extends StatelessWidget {
  const _PeekLayer({
    required this.depth,
    required this.child,
  });
  final int depth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scale = (1 - depth * 0.04).clamp(0.84, 1.0);
    final dy = depth * 12.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Opacity(
              opacity: (1 - depth * 0.32).clamp(0.18, 0.7),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _FanLayer extends StatelessWidget {
  const _FanLayer({
    required this.delta,
    required this.fan,
    required this.tiltX,
    required this.tiltY,
    required this.onTap,
    required this.child,
  });
  final int delta;
  final double fan;
  final double tiltX;
  final double tiltY;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const spread = 110.0;
    final dx = delta * spread * fan;
    final rot = delta * 0.10 * fan + tiltY * 0.6;
    final tilt = -tiltX * 0.6;
    final scale = 0.96 - delta.abs() * 0.04 * fan;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
      child: Transform.translate(
        offset: Offset(dx, delta.abs() * 6.0 * fan),
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateZ(rot)
            ..rotateX(tilt)
            ..scaleByDouble(scale, scale, 1, 1),
          child: GestureDetector(
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SensorTilt extends StatelessWidget {
  const _SensorTilt({
    required this.tiltX,
    required this.tiltY,
    required this.active,
    required this.child,
  });
  final double tiltX;
  final double tiltY;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final rotX = tiltX.clamp(-0.16, 0.16) * 0.5;
    final rotY = tiltY.clamp(-0.16, 0.16) * 0.5;
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0009)
        ..rotateX(-rotX)
        ..rotateY(rotY),
      alignment: Alignment.center,
      child: child,
    );
  }
}

