import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Chip.
///
/// Compact info pill. Renders as a thin continuous-curve capsule with
/// a 0.5px tone-tinted hairline, optional leading icon, and one of
/// three intensity tiers. Used as stage badges, world tags, status
/// indicators, and metadata pills throughout `lib/os2/`.
class Os2Chip extends StatelessWidget {
  const Os2Chip({
    super.key,
    required this.label,
    this.icon,
    this.tone = Os2.pulseTone,
    this.intensity = Os2ChipIntensity.subtle,
    this.size = Os2ChipSize.regular,
  });

  final String label;
  final IconData? icon;
  final Color tone;
  final Os2ChipIntensity intensity;
  final Os2ChipSize size;

  double get _height {
    switch (size) {
      case Os2ChipSize.compact:
        return 22;
      case Os2ChipSize.regular:
        return 28;
      case Os2ChipSize.large:
        return 36;
    }
  }

  double get _fontSize {
    switch (size) {
      case Os2ChipSize.compact:
        return 10;
      case Os2ChipSize.regular:
        return 11;
      case Os2ChipSize.large:
        return 12;
    }
  }

  double get _iconSize {
    switch (size) {
      case Os2ChipSize.compact:
        return 11;
      case Os2ChipSize.regular:
        return 13;
      case Os2ChipSize.large:
        return 15;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case Os2ChipSize.compact:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 0);
      case Os2ChipSize.regular:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 0);
      case Os2ChipSize.large:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = tone.withValues(
      alpha: intensity == Os2ChipIntensity.solid
          ? 0.28
          : intensity == Os2ChipIntensity.subtle
              ? 0.10
              : 0.04,
    );
    final stroke = tone.withValues(
      alpha: intensity == Os2ChipIntensity.solid ? 0.55 : 0.30,
    );
    final ink = intensity == Os2ChipIntensity.ghost
        ? Os2.inkMid
        : tone;
    return Container(
      height: _height,
      padding: _padding,
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(
          side: BorderSide(color: stroke, width: Os2.strokeFine),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _iconSize, color: ink),
            const SizedBox(width: 5),
          ],
          Os2Text.caption(
            label,
            color: ink,
            size: _fontSize,
            weight: FontWeight.w800,
          ),
        ],
      ),
    );
  }
}

enum Os2ChipIntensity { ghost, subtle, solid }

enum Os2ChipSize { compact, regular, large }
