import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Divider rule.
///
/// A typographic section divider. Renders:
///   • a left-aligned eyebrow (monoCap, tone-tinted);
///   • an inline hairline rule taking remaining width;
///   • an optional trailing monoCap value.
///
/// Used to introduce sub-sections inside large slabs without committing
/// to a full headline.
class Os2DividerRule extends StatelessWidget {
  const Os2DividerRule({
    super.key,
    required this.eyebrow,
    this.tone = Os2.pulseTone,
    this.trailing,
    this.dense = false,
  });

  final String eyebrow;
  final Color tone;
  final String? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? Os2.space1 : Os2.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Os2Text.monoCap(
            eyebrow,
            color: tone,
            size: dense ? 9 : 10,
          ),
          const SizedBox(width: Os2.space2),
          Expanded(
            child: Container(
              height: Os2.strokeFine,
              color: Os2.hairline,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Os2.space2),
            Os2Text.monoCap(
              trailing!,
              color: Os2.inkMid,
              size: dense ? 9 : 10,
            ),
          ],
        ],
      ),
    );
  }
}
