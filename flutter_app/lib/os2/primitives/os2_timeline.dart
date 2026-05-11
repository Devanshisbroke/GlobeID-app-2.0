import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Timeline.
///
/// A vertical rail of nodes. Each node has:
///   • a 12pt squircle dot (active = tone, settled = settled-signal,
///     pending = floor3);
///   • a hairline rail connecting dots (live = tone, otherwise hairline);
///   • a title + optional caption.
///
/// Used for trip pipelines, identity audits, boarding stages, etc.
class Os2Timeline extends StatelessWidget {
  const Os2Timeline({
    super.key,
    required this.nodes,
    this.tone = Os2.pulseTone,
    this.dense = false,
  });

  final List<Os2TimelineNode> nodes;
  final Color tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < nodes.length; i++) {
      rows.add(_Row(
        node: nodes[i],
        tone: tone,
        isFirst: i == 0,
        isLast: i == nodes.length - 1,
        dense: dense,
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class Os2TimelineNode {
  const Os2TimelineNode({
    required this.title,
    this.caption,
    this.trailing,
    this.state = Os2NodeState.pending,
  });

  final String title;
  final String? caption;
  final String? trailing;
  final Os2NodeState state;
}

enum Os2NodeState { settled, active, pending }

class _Row extends StatelessWidget {
  const _Row({
    required this.node,
    required this.tone,
    required this.isFirst,
    required this.isLast,
    required this.dense,
  });

  final Os2TimelineNode node;
  final Color tone;
  final bool isFirst;
  final bool isLast;
  final bool dense;

  Color get _dotColor {
    switch (node.state) {
      case Os2NodeState.settled:
        return Os2.signalSettled;
      case Os2NodeState.active:
        return tone;
      case Os2NodeState.pending:
        return Os2.floor3;
    }
  }

  Color get _railColor {
    switch (node.state) {
      case Os2NodeState.active:
        return tone.withValues(alpha: 0.6);
      case Os2NodeState.settled:
        return Os2.signalSettled.withValues(alpha: 0.4);
      case Os2NodeState.pending:
        return Os2.hairline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = dense ? Os2.space2 : Os2.space3;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 1,
                    color: isFirst ? Colors.transparent : _railColor,
                  ),
                ),
                _Dot(color: _dotColor, active: node.state == Os2NodeState.active),
                Expanded(
                  child: Container(
                    width: 1,
                    color: isLast ? Colors.transparent : _railColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Os2.space2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Os2Text.title(
                          node.title,
                          color: node.state == Os2NodeState.pending
                              ? Os2.inkMid
                              : Os2.inkBright,
                          size: dense ? 15 : 17,
                          weight: FontWeight.w700,
                          maxLines: 1,
                        ),
                      ),
                      if (node.trailing != null)
                        Os2Text.monoCap(node.trailing!,
                            color: tone, size: 10),
                    ],
                  ),
                  if (node.caption != null) ...[
                    const SizedBox(height: 2),
                    Os2Text.body(node.caption!,
                        color: Os2.inkMid,
                        size: dense ? 12 : 13,
                        maxLines: 2),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Os2.mBreathFast,
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Dot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    if (!widget.active && _pulse.isAnimating) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final t = widget.active ? Os2.cCruise.transform(_pulse.value) : 0.0;
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.25 + t * 0.25),
                      blurRadius: 10 + t * 6,
                      spreadRadius: t * 1.5,
                    ),
                  ]
                : null,
            border: Border.all(color: Os2.canvas, width: 2),
          ),
        );
      },
    );
  }
}
