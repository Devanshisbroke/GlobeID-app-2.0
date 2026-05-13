import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_glyph_halo.dart';
import 'os2_magnetic.dart';
import 'os2_text.dart';

/// OS 2.0 — Action card.
///
/// A tappable hero tile composed of a glyph halo + title + optional
/// caption + optional trailing monoCap. Used in services grids and
/// inside hero CTAs.
class Os2ActionCard extends StatelessWidget {
  const Os2ActionCard({
    super.key,
    required this.title,
    required this.icon,
    this.caption,
    this.tone = Os2.pulseTone,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final String title;
  final IconData icon;
  final String? caption;
  final Color tone;
  final String? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: EdgeInsets.all(dense ? Os2.space3 : Os2.space4),
      decoration: ShapeDecoration(
        color: Os2.floor2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(Os2.rCard),
          side: BorderSide(
            color: tone.withValues(alpha: 0.20),
            width: Os2.strokeFine,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Os2GlyphHalo(icon: icon, tone: tone, size: dense ? 30 : 36),
              const Spacer(),
              if (trailing != null)
                Os2Text.monoCap(trailing!, color: tone, size: Os2.textMicro),
            ],
          ),
          SizedBox(height: dense ? Os2.space2 : Os2.space3),
          Os2Text.title(
            title,
            color: Os2.inkBright,
            size: dense ? 15 : 17,
            maxLines: 1,
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Os2Text.body(
              caption!,
              color: Os2.inkMid,
              size: dense ? 12 : 13,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return body;
    return Os2Magnetic(onTap: onTap!, child: body);
  }
}
