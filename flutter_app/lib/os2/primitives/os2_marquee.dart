import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Marquee.
///
/// A typographic scrolling marquee. The text scrolls horizontally at a
/// constant velocity and softly fades at both edges. Used for live
/// system status, ambient AI whispers, FX tickers.
///
/// One [items] list, duplicated to give a seamless loop. Items are
/// joined by a centered separator dot.
class Os2Marquee extends StatefulWidget {
  const Os2Marquee({
    super.key,
    required this.items,
    this.tone = Os2.inkMid,
    this.duration = const Duration(seconds: 28),
    this.height = 26,
    this.size = 11,
  });

  final List<String> items;
  final Color tone;
  final Duration duration;
  final double height;
  final double size;

  @override
  State<Os2Marquee> createState() => _Os2MarqueeState();
}

class _Os2MarqueeState extends State<Os2Marquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final joined = widget.items.join('   ·   ');
    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.06, 0.94, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, box) {
                  return Transform.translate(
                    offset: Offset(-_c.value * box.maxWidth, 0),
                    child: SizedBox(
                      width: box.maxWidth * 2,
                      child: Row(
                        children: [
                          SizedBox(
                            width: box.maxWidth,
                            child: Center(
                              child: Os2Text.monoCap(
                                joined,
                                color: widget.tone,
                                size: widget.size,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: box.maxWidth,
                            child: Center(
                              child: Os2Text.monoCap(
                                joined,
                                color: widget.tone,
                                size: widget.size,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
