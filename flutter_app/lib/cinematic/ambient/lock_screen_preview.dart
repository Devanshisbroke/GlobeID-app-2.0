import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// `LockScreenWidgetPreview` — design previews for GlobeID lock
/// screen widgets and Always-On surfaces.
///
/// iOS lock-screen widgets ship as four families (WidgetKit):
///   • accessoryCircular — 38pt round badge above the time
///   • accessoryRectangular — 158x66 rectangle below the time
///   • accessoryInline — single line above the time (date row)
///   • alwaysOnDim — same geometry as accessoryRectangular but
///     desaturated to the watch's Always-On vocabulary
///
/// Each form composes from existing Os2 primitives (gold pill,
/// mono-cap chrome, watermark).

enum LockWidgetForm {
  accessoryCircular,
  accessoryRectangular,
  accessoryInline,
  alwaysOnDim,
}

class LockWidgetModel {
  const LockWidgetModel({
    required this.headline,
    required this.subline,
    required this.tickerDigit,
  });

  /// `LH 401 · B27` — primary monocap chrome.
  final String headline;

  /// `BOARDING · 0:18` — secondary chrome.
  final String subline;

  /// `0:18` — the 4-character digit drawn in the circular form.
  final String tickerDigit;
}

class LockWidgetPreview extends StatelessWidget {
  const LockWidgetPreview({
    super.key,
    required this.model,
    required this.form,
  });
  final LockWidgetModel model;
  final LockWidgetForm form;

  @override
  Widget build(BuildContext context) {
    switch (form) {
      case LockWidgetForm.accessoryCircular:
        return _CircularBadge(digit: model.tickerDigit);
      case LockWidgetForm.accessoryRectangular:
        return _RectangularRow(model: model, dim: false);
      case LockWidgetForm.accessoryInline:
        return _InlineRow(model: model);
      case LockWidgetForm.alwaysOnDim:
        return _RectangularRow(model: model, dim: true);
    }
  }
}

class _CircularBadge extends StatelessWidget {
  const _CircularBadge({required this.digit});
  final String digit;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Os2.foilGoldHero,
      ),
      child: Center(
        child: Os2Text.monoCap(
          digit,
          color: Os2.canvas,
          size: Os2.textTiny,
        ),
      ),
    );
  }
}

class _RectangularRow extends StatelessWidget {
  const _RectangularRow({required this.model, required this.dim});
  final LockWidgetModel model;
  final bool dim;

  Color get _headlineColor =>
      dim ? Os2.inkMid.withValues(alpha: 0.72) : Os2.goldDeep;
  Color get _sublineColor =>
      dim ? Os2.inkLow.withValues(alpha: 0.66) : Os2.inkBright;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158,
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dim ? Os2.canvas : Os2.canvas.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dim
              ? Os2.hairlineSoft
              : Os2.goldDeep.withValues(alpha: 0.46),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.flight_takeoff_rounded,
                color: _headlineColor,
                size: 12,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Os2Text.monoCap(
                  model.headline,
                  color: _headlineColor,
                  size: Os2.textTiny,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Os2Text.monoCap(
            model.subline,
            color: _sublineColor,
            size: Os2.textTiny,
            maxLines: 1,
          ),
          Os2Text.monoCap(
            'GLOBE·ID',
            color: dim
                ? Os2.inkLow.withValues(alpha: 0.56)
                : Os2.inkLow,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}

class _InlineRow extends StatelessWidget {
  const _InlineRow({required this.model});
  final LockWidgetModel model;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.flight_takeoff_rounded,
          color: Os2.goldDeep,
          size: 12,
        ),
        const SizedBox(width: 6),
        Os2Text.monoCap(
          '${model.headline} · ${model.subline}',
          color: Os2.goldDeep,
          size: Os2.textTiny,
        ),
      ],
    );
  }
}

/// `LockScreenStencil` — a full phone-shaped surface that frames
/// a clock + a single widget at one of the standard slots so the
/// preview reads like a real lock screen.
enum LockSlot { aboveTime, belowTime, inline }

class LockScreenStencil extends StatelessWidget {
  const LockScreenStencil({
    super.key,
    required this.widget,
    required this.slot,
    this.dim = false,
  });
  final Widget widget;
  final LockSlot slot;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: dim
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF050505), Color(0xFF050505)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0E1A), Color(0xFF050505)],
              ),
        border: Border.all(color: Os2.hairlineSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Status eyebrow ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Os2Text.monoCap(
                  '09:24',
                  color: dim
                      ? Os2.inkLow.withValues(alpha: 0.66)
                      : Os2.inkBright,
                  size: Os2.textTiny,
                ),
                Os2Text.monoCap(
                  dim ? '...' : 'WIFI · 5G',
                  color: dim
                      ? Os2.inkLow.withValues(alpha: 0.66)
                      : Os2.inkLow,
                  size: Os2.textTiny,
                ),
              ],
            ),
            const Spacer(),
            if (slot == LockSlot.inline) widget,
            const SizedBox(height: 4),
            if (slot == LockSlot.aboveTime) ...[
              widget,
              const SizedBox(height: 6),
            ],
            // ── Clock ──
            Text(
              '09:24',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w200,
                letterSpacing: -2,
                color: dim
                    ? Os2.inkLow.withValues(alpha: 0.72)
                    : Os2.inkBright,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            if (slot == LockSlot.belowTime) widget,
            const Spacer(),
            Os2Text.monoCap(
              'GLOBE·ID',
              color: dim
                  ? Os2.inkLow.withValues(alpha: 0.42)
                  : Os2.inkLow,
              size: Os2.textTiny,
            ),
          ],
        ),
      ),
    );
  }
}
