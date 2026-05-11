import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Bar.
///
/// A single labelled horizontal bar used for category breakdowns:
///   • a hairline track running the full width;
///   • a tone-tinted fill animating from 0 → value over [Os2.mCruise];
///   • caption-cased label + monoCap value above the track.
///
/// Compose several inside an [Os2BarStack] for category breakdowns.
class Os2Bar extends StatefulWidget {
  const Os2Bar({
    super.key,
    required this.label,
    required this.value, // 0..1
    required this.tone,
    this.trailing,
    this.height = 6,
    this.dense = false,
  });

  final String label;
  final double value;
  final Color tone;
  final String? trailing;
  final double height;
  final bool dense;

  @override
  State<Os2Bar> createState() => _Os2BarState();
}

class _Os2BarState extends State<Os2Bar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Os2.mCruise,
  )..forward();

  late double _from = 0;
  late double _to = widget.value.clamp(0.0, 1.0);

  @override
  void didUpdateWidget(covariant Os2Bar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _current;
      _to = widget.value.clamp(0.0, 1.0);
      _c.forward(from: 0);
    }
  }

  double get _current {
    final t = Os2.cBank.transform(_c.value);
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Os2Text.caption(
                widget.label,
                color: Os2.inkMid,
              ),
            ),
            if (widget.trailing != null)
              Os2Text.monoCap(
                widget.trailing!,
                color: Os2.inkHigh,
                size: widget.dense ? 10 : 11,
              ),
          ],
        ),
        const SizedBox(height: Os2.space1),
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.height),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Os2.hairlineSoft),
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => FractionallySizedBox(
                    widthFactor: _current,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.tone.withValues(alpha: 0.65),
                            widget.tone,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.tone.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Vertical stack of [Os2Bar]s. Each bar receives a constant tone unless
/// the entry supplies its own.
class Os2BarStack extends StatelessWidget {
  const Os2BarStack({
    super.key,
    required this.entries,
    this.tone = Os2.walletTone,
    this.spacing = Os2.space3,
    this.dense = false,
  });

  final List<Os2BarEntry> entries;
  final Color tone;
  final double spacing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) children.add(SizedBox(height: spacing));
      final e = entries[i];
      children.add(Os2Bar(
        label: e.label,
        value: e.value,
        tone: e.tone ?? tone,
        trailing: e.trailing,
        dense: dense,
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class Os2BarEntry {
  const Os2BarEntry({
    required this.label,
    required this.value,
    this.trailing,
    this.tone,
  });

  final String label;
  final double value;
  final String? trailing;
  final Color? tone;
}
