import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Solari-board character flap — the airport split-flap board.
///
/// Renders a single character as a hinged tile that flips through
/// the alphabet/digits to settle on the new value. Used to display
/// flight numbers, gate codes, IATA codes, prices, identity scores,
/// and balances with a luxury-tech flair.
class DepartureBoardFlap extends StatefulWidget {
  const DepartureBoardFlap({
    super.key,
    required this.character,
    this.duration = const Duration(milliseconds: 520),
    this.style,
    this.tone,
    this.background,
    this.fixedWidth,
  });

  final String character;
  final Duration duration;
  final TextStyle? style;
  final Color? tone;
  final Color? background;
  final double? fixedWidth;

  @override
  State<DepartureBoardFlap> createState() => _DepartureBoardFlapState();
}

class _DepartureBoardFlapState extends State<DepartureBoardFlap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  String _shown = '';
  String _next = '';

  @override
  void initState() {
    super.initState();
    _shown = widget.character;
    _next = widget.character;
  }

  @override
  void didUpdateWidget(DepartureBoardFlap old) {
    super.didUpdateWidget(old);
    if (old.character != widget.character) {
      _next = widget.character;
      _ctrl.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() => _shown = _next);
        _ctrl.reset();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduce = MediaQuery.of(context).disableAnimations;
    final style = (widget.style ??
            theme.textTheme.headlineLarge?.copyWith(
              fontFamily: 'Inter',
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ))
        ?.copyWith(color: widget.tone ?? Colors.white);

    final bg = widget.background ??
        (isDark ? const Color(0xFF06080F) : const Color(0xFF0B1120));

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return SizedBox(
          width: widget.fixedWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space2,
                    vertical: AppTokens.space2 + 2,
                  ),
                  child:
                      Text(_shown, style: style, textAlign: TextAlign.center),
                ),
                if (!reduce && t > 0)
                  Positioned.fill(
                    child: _FlapOverlay(
                      from: _shown,
                      to: _next,
                      progress: t,
                      style: style!,
                      background: bg,
                    ),
                  ),
                // hinge line
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlapOverlay extends StatelessWidget {
  const _FlapOverlay({
    required this.from,
    required this.to,
    required this.progress,
    required this.style,
    required this.background,
  });
  final String from;
  final String to;
  final double progress;
  final TextStyle style;
  final Color background;

  @override
  Widget build(BuildContext context) {
    // First half: top flap of `from` rotates down to flat.
    // Second half: bottom flap of `to` rotates up from flat.
    final t = progress;
    final firstHalf = t < 0.5;
    final char = firstHalf ? from : to;
    final localT = firstHalf ? t * 2 : (t - 0.5) * 2;
    final angle =
        firstHalf ? -math.pi / 2 * localT : math.pi / 2 * (1 - localT);
    final flapAlign = firstHalf ? Alignment.bottomCenter : Alignment.topCenter;
    final clipAlign = firstHalf ? Alignment.topCenter : Alignment.bottomCenter;

    return ClipRect(
      clipper: _HalfRectClipper(top: firstHalf),
      child: Container(
        alignment: clipAlign,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        child: Transform(
          alignment: flapAlign,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0011)
            ..rotateX(angle),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space2,
              vertical: AppTokens.space2 + 2,
            ),
            child: Text(char, style: style, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _HalfRectClipper extends CustomClipper<Rect> {
  _HalfRectClipper({required this.top});
  final bool top;

  @override
  Rect getClip(Size size) => top
      ? Rect.fromLTWH(0, 0, size.width, size.height / 2)
      : Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2);

  @override
  bool shouldReclip(covariant _HalfRectClipper old) => old.top != top;
}

/// Convenience: a row of [DepartureBoardFlap]s for a string.
class DepartureBoardText extends StatelessWidget {
  const DepartureBoardText({
    super.key,
    required this.text,
    this.style,
    this.tone,
    this.background,
    this.charWidth = 26,
    this.gap = 2,
    this.staggerStep = const Duration(milliseconds: 35),
  });

  final String text;
  final TextStyle? style;
  final Color? tone;
  final Color? background;
  final double charWidth;
  final double gap;
  final Duration staggerStep;

  @override
  Widget build(BuildContext context) {
    final chars = text.toUpperCase();
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          DepartureBoardFlap(
            character: chars[i] == ' ' ? ' ' : chars[i],
            style: style,
            tone: tone,
            background: background,
            fixedWidth: charWidth,
            duration: Duration(
              milliseconds: 360 + (i * staggerStep.inMilliseconds),
            ),
          ),
        ],
      ],
    );
    // FittedBox.scaleDown lets the row keep its intrinsic size when
    // the parent provides enough width, but shrinks proportionally if
    // the parent is narrower than the natural cell-row width. This is
    // what prevents airport-mode glyphs (FX rates, callsign codes,
    // gate numbers, ETAs) from spilling outside their cards on
    // Pixel-class viewports without forcing every callsite to pick a
    // smaller `charWidth`.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: row,
    );
  }
}
