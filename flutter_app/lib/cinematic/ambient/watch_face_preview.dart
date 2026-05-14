import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// `WatchFacePreview` — design previews for GlobeID watchOS &
/// Wear OS face complications.
///
/// Four forms matching the WatchKit / Wear OS complication
/// stencils (geometry chosen for visual parity, not pixel-perfect
/// device sizing):
///   • circular  — 50×50, single glyph + a 1-line label
///   • inline    — 240×24, monocap row that lives in the bezel
///   • modularSmall — 84×84, a square stack
///   • modularLarge — 280×88, full mini-card with origin/destination
///
/// All four compose from existing Os2 primitives.
enum WatchComplicationForm {
  circular,
  inline,
  modularSmall,
  modularLarge,
}

class WatchComplicationModel {
  const WatchComplicationModel({
    required this.flightCode,
    required this.gate,
    required this.boardingIn,
    required this.origin,
    required this.destination,
    required this.trustScore,
  });
  final String flightCode;
  final String gate;
  final Duration boardingIn;
  final String origin;
  final String destination;
  final int trustScore;
}

class WatchComplicationPreview extends StatelessWidget {
  const WatchComplicationPreview({
    super.key,
    required this.model,
    required this.form,
  });
  final WatchComplicationModel model;
  final WatchComplicationForm form;

  String get _countdown {
    final h = model.boardingIn.inHours;
    final m = model.boardingIn.inMinutes.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}';
    return '0:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    switch (form) {
      case WatchComplicationForm.circular:
        return _CircularComplication(countdown: _countdown);
      case WatchComplicationForm.inline:
        return _InlineComplication(model: model, countdown: _countdown);
      case WatchComplicationForm.modularSmall:
        return _ModularSmallComplication(
          model: model,
          countdown: _countdown,
        );
      case WatchComplicationForm.modularLarge:
        return _ModularLargeComplication(
          model: model,
          countdown: _countdown,
        );
    }
  }
}

class _CircularComplication extends StatelessWidget {
  const _CircularComplication({required this.countdown});
  final String countdown;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Os2.foilGoldHero,
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.42),
            blurRadius: 14,
          ),
        ],
      ),
      child: Center(
        child: Os2Text.monoCap(
          countdown,
          color: Os2.canvas,
          size: Os2.textTiny,
        ),
      ),
    );
  }
}

class _InlineComplication extends StatelessWidget {
  const _InlineComplication({required this.model, required this.countdown});
  final WatchComplicationModel model;
  final String countdown;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Os2.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.62)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flight_takeoff_rounded,
            size: 12,
            color: Os2.goldDeep,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Os2Text.monoCap(
              '${model.flightCode} · GATE ${model.gate}',
              color: Os2.goldDeep,
              size: Os2.textTiny,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          Os2Text.monoCap(
            countdown,
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}

class _ModularSmallComplication extends StatelessWidget {
  const _ModularSmallComplication({
    required this.model,
    required this.countdown,
  });
  final WatchComplicationModel model;
  final String countdown;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Os2.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.46)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'BOARDING',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: 2),
          Os2Text.credential(
            countdown,
            color: Os2.inkBright,
            size: 20,
          ),
          const SizedBox(height: 2),
          Os2Text.monoCap(
            'GATE ${model.gate}',
            color: Os2.inkLow,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}

class _ModularLargeComplication extends StatelessWidget {
  const _ModularLargeComplication({
    required this.model,
    required this.countdown,
  });
  final WatchComplicationModel model;
  final String countdown;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Os2.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                'GLOBE·ID',
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                countdown,
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Os2Text.credential(
                model.origin,
                color: Os2.inkBright,
                size: 22,
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: Os2.inkLow,
                ),
              ),
              const SizedBox(width: 4),
              Os2Text.credential(
                model.destination,
                color: Os2.inkBright,
                size: 22,
              ),
              const Spacer(),
              Os2Text.monoCap(
                model.flightCode,
                color: Os2.inkLow,
                size: Os2.textTiny,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `WatchFaceStencil` — round watch case wrapping a complication
/// at a specified anchor (12 / 3 / 6 / 9 o'clock). Used by the
/// preview screen to show how a complication looks on a real face.
enum WatchAnchor { top, right, bottom, left, center }

class WatchFaceStencil extends StatelessWidget {
  const WatchFaceStencil({
    super.key,
    required this.complication,
    this.anchor = WatchAnchor.center,
    this.diameter = 240,
  });
  final Widget complication;
  final WatchAnchor anchor;
  final double diameter;

  Alignment get _alignment {
    switch (anchor) {
      case WatchAnchor.top:
        return const Alignment(0, -0.6);
      case WatchAnchor.right:
        return const Alignment(0.6, 0);
      case WatchAnchor.bottom:
        return const Alignment(0, 0.6);
      case WatchAnchor.left:
        return const Alignment(-0.6, 0);
      case WatchAnchor.center:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          radius: 0.7,
          colors: [Color(0xFF0E0E12), Color(0xFF050505)],
        ),
        border: Border.all(color: Os2.hairlineSoft, width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.6),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Tick marks every 30 degrees (12 marks around the face).
          for (int i = 0; i < 12; i++)
            Align(
              alignment: Alignment(
                math.sin(i * math.pi / 6) * 0.92,
                -math.cos(i * math.pi / 6) * 0.92,
              ),
              child: Container(
                width: 2,
                height: 6,
                color: Os2.inkLow.withValues(alpha: 0.42),
              ),
            ),
          Align(alignment: _alignment, child: complication),
        ],
      ),
    );
  }
}
