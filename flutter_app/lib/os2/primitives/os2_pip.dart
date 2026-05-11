import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Pip stack.
///
/// A row of milestone pips. Each pip is a 10pt squircle with an inner
/// dot. Settled pips render in tone; pending pips render in floor3; the
/// active pip glows. Used for boarding stages, identity audit streaks,
/// score milestones.
class Os2PipStack extends StatelessWidget {
  const Os2PipStack({
    super.key,
    required this.pips,
    this.tone = Os2.pulseTone,
    this.gap = Os2.space2,
    this.size = 10,
  });

  final List<Os2PipState> pips;
  final Color tone;
  final double gap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < pips.length; i++) {
      if (i > 0) children.add(SizedBox(width: gap));
      children.add(_Pip(state: pips[i], tone: tone, size: size));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

enum Os2PipState { settled, active, pending }

class _Pip extends StatefulWidget {
  const _Pip({required this.state, required this.tone, required this.size});

  final Os2PipState state;
  final Color tone;
  final double size;

  @override
  State<_Pip> createState() => _PipState();
}

class _PipState extends State<_Pip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Os2.mBreathFast,
  );

  @override
  void initState() {
    super.initState();
    if (widget.state == Os2PipState.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Pip old) {
    super.didUpdateWidget(old);
    if (widget.state == Os2PipState.active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.state != Os2PipState.active && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.state == Os2PipState.settled
        ? widget.tone
        : widget.state == Os2PipState.active
            ? widget.tone
            : Os2.floor3;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final t = widget.state == Os2PipState.active
            ? Os2.cCruise.transform(_pulse.value)
            : 0.0;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: widget.state == Os2PipState.active
                ? [
                    BoxShadow(
                      color: widget.tone.withValues(alpha: 0.30 + t * 0.30),
                      blurRadius: 6 + t * 4,
                      spreadRadius: t,
                    ),
                  ]
                : null,
            border: Border.all(
              color: Os2.canvas,
              width: 1.4,
            ),
          ),
        );
      },
    );
  }
}

/// Labelled variant: caption above a row of pips.
class Os2LabelledPipStack extends StatelessWidget {
  const Os2LabelledPipStack({
    super.key,
    required this.label,
    required this.pips,
    this.tone = Os2.pulseTone,
    this.trailing,
  });

  final String label;
  final List<Os2PipState> pips;
  final Color tone;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Os2Text.caption(label, color: Os2.inkMid)),
            if (trailing != null)
              Os2Text.monoCap(trailing!, color: Os2.inkBright, size: 11),
          ],
        ),
        const SizedBox(height: Os2.space2),
        Os2PipStack(pips: pips, tone: tone),
      ],
    );
  }
}
