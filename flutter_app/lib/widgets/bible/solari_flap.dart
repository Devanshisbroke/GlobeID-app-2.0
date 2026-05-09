// Solari split-flap board widget.
//
// The bible (§4.2): "Numerals don't fade or slide when they change.
// They flap, like a Solari board at Frankfurt Hbf. This is GlobeID's
// most distinctive type behavior and must appear on every screen
// that displays a changing number (FX, countdown, balance, gate,
// time)."
//
// SolariFlap renders a sequence of character cells, each animating
// independently from its previous glyph to the new glyph by rolling
// through an alphabet. Cells respect the user's reduce-motion
// setting (they instantly cut on opt-out).

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/ux_bible.dart';

class SolariFlap extends StatelessWidget {
  /// The text to display. Whitespace is rendered as a static gap.
  final String text;

  /// Cell width — narrower for ticker boards, wider for hero gate
  /// codes / departure boards.
  final double cellWidth;

  /// Cell height. Defaults to ~1.4 × cellWidth for a Solari ratio.
  final double? cellHeight;

  /// Text style for each glyph. Color and font come from this style.
  final TextStyle? style;

  /// Background color of each cell. Defaults to a deep cabin
  /// charcoal so the foil glyphs read like a real flapboard.
  final Color? cellColor;

  /// Color of the divider between top and bottom halves of each
  /// cell. Adds the Solari "seam".
  final Color? seamColor;

  /// Optional highlight color flashed when the cell finishes flapping
  /// to its new glyph. Pulses for 320 ms per cell.
  final Color? settleHighlight;

  /// Stagger between adjacent cells beginning their flap, in ms.
  final int staggerMs;

  /// Per-cell flap duration.
  final Duration cellDuration;

  const SolariFlap({
    super.key,
    required this.text,
    this.cellWidth = 22,
    this.cellHeight,
    this.style,
    this.cellColor,
    this.seamColor,
    this.settleHighlight,
    this.staggerMs = 40,
    this.cellDuration = const Duration(milliseconds: 460),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    final h = cellHeight ?? cellWidth * 1.4;
    final cells = <Widget>[];
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == ' ') {
        cells.add(SizedBox(width: cellWidth * 0.6, height: h));
        continue;
      }
      cells.add(_FlapCell(
        glyph: ch,
        width: cellWidth,
        height: h,
        style: style ??
            theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Departure Mono',
              fontWeight: FontWeight.w800,
              color: BibleTone.runwayAmber,
            ),
        cellColor: cellColor ?? BibleSubstrate.cabinCharcoal,
        seamColor: seamColor ?? Colors.black.withValues(alpha: 0.5),
        settleHighlight:
            settleHighlight ?? BibleTone.foilGold.withValues(alpha: 0.30),
        delay: Duration(milliseconds: i * staggerMs),
        duration: cellDuration,
        reduceMotion: reduce,
      ));
    }
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: cells,
    );
  }
}

class _FlapCell extends StatefulWidget {
  final String glyph;
  final double width;
  final double height;
  final TextStyle? style;
  final Color cellColor;
  final Color seamColor;
  final Color settleHighlight;
  final Duration delay;
  final Duration duration;
  final bool reduceMotion;

  const _FlapCell({
    required this.glyph,
    required this.width,
    required this.height,
    required this.style,
    required this.cellColor,
    required this.seamColor,
    required this.settleHighlight,
    required this.delay,
    required this.duration,
    required this.reduceMotion,
  });

  @override
  State<_FlapCell> createState() => _FlapCellState();
}

class _FlapCellState extends State<_FlapCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);
  static const _alphabet =
      ' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.,:/-+₹€\$¥£%';
  String _current = ' ';

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _current = widget.glyph;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (!mounted) return;
        _ctrl.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _FlapCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.glyph != widget.glyph && !widget.reduceMotion) {
      _ctrl.forward(from: 0);
    } else if (widget.reduceMotion) {
      _current = widget.glyph;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _glyphAt(double t) {
    // Fast roll through the alphabet between current and target.
    final start = _alphabet.indexOf(_current.toUpperCase());
    final end = _alphabet.indexOf(widget.glyph.toUpperCase());
    if (start < 0 || end < 0) return widget.glyph;
    final dist = ((end - start) % _alphabet.length + _alphabet.length) %
        _alphabet.length;
    final i = (start + (dist * t).floor()) % _alphabet.length;
    return _alphabet[i];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = BibleCurves.cruise.transform(_ctrl.value);
        final glyph = widget.reduceMotion
            ? widget.glyph
            : (t >= 1.0 ? widget.glyph : _glyphAt(t));
        if (t >= 1.0) _current = widget.glyph;
        final settleAlpha = (1 - t).clamp(0.0, 1.0);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.cellColor,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm * 0.6),
            boxShadow: [
              BoxShadow(
                color: widget.settleHighlight
                    .withValues(alpha: settleAlpha * 0.4),
                blurRadius: 12,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Stack(
            children: [
              // Glyph
              Center(
                child: Text(
                  glyph,
                  style: widget.style?.copyWith(
                    fontSize: widget.height * 0.55,
                    height: 1,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
              // Solari seam.
              Positioned(
                left: 0,
                right: 0,
                top: widget.height * 0.5 - 0.5,
                child: Container(
                  height: 1,
                  color: widget.seamColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
