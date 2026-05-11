import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_chip.dart';
import 'os2_magnetic.dart';
import 'os2_text.dart';

/// OS 2.0 — Info strip.
///
/// A horizontal scrolling rail of compact info chips. Each chip displays
/// a caption + monoCap value, optional leading icon, and an optional tap
/// handler. The rail leaves no chrome; only the chips and the spacing.
///
/// Use under hero headers when you want to surface 3-5 short data
/// points without committing to a full slab.
class Os2InfoStrip extends StatelessWidget {
  const Os2InfoStrip({
    super.key,
    required this.entries,
    this.padding = const EdgeInsets.symmetric(horizontal: Os2.space4),
    this.height = 56,
  });

  final List<Os2InfoEntry> entries;
  final EdgeInsets padding;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemBuilder: (_, i) => _Os2InfoTile(entry: entries[i]),
        separatorBuilder: (_, __) => const SizedBox(width: Os2.space2),
        itemCount: entries.length,
      ),
    );
  }
}

class Os2InfoEntry {
  const Os2InfoEntry({
    required this.label,
    required this.value,
    this.icon,
    this.tone = Os2.pulseTone,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color tone;
  final VoidCallback? onTap;
}

class _Os2InfoTile extends StatelessWidget {
  const _Os2InfoTile({required this.entry});

  final Os2InfoEntry entry;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space3,
        vertical: Os2.space2,
      ),
      decoration: ShapeDecoration(
        color: Os2.floor2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(Os2.rCard),
          side: BorderSide(
            color: entry.tone.withValues(alpha: 0.22),
            width: Os2.strokeFine,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (entry.icon != null) ...[
            _GlyphHalo(icon: entry.icon!, tone: entry.tone),
            const SizedBox(width: Os2.space2),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Os2Text.caption(entry.label, color: Os2.inkLow, size: 10),
              const SizedBox(height: 2),
              Os2Text.monoCap(
                entry.value,
                color: Os2.inkBright,
                size: 12,
              ),
            ],
          ),
        ],
      ),
    );
    if (entry.onTap == null) return body;
    return Os2Magnetic(onTap: entry.onTap!, child: body);
  }
}

class _GlyphHalo extends StatelessWidget {
  const _GlyphHalo({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            tone.withValues(alpha: 0.32),
            tone.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: tone.withValues(alpha: 0.40),
          width: Os2.strokeFine,
        ),
      ),
      child: Icon(icon, size: 14, color: Os2.inkBright),
    );
  }
}

/// Convenience helper to render a stack of [Os2Chip]s as a wrap.
class Os2ChipCluster extends StatelessWidget {
  const Os2ChipCluster({
    super.key,
    required this.chips,
    this.spacing = Os2.space2,
    this.runSpacing = Os2.space2,
  });

  final List<Widget> chips;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: chips,
    );
  }
}
