import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// `LiveActivityPreview` — a cinematic preview surface that shows
/// how a GlobeID iOS Live Activity / Dynamic Island would look for
/// a boarding pass. This widget composes from existing Os2
/// primitives (gold / mono-cap / OLED / hairline) and is intended
/// for the Ambient Brand hub in the app.
///
/// Three forms of a Live Activity (matching iOS's three layouts):
///   1. minimal  — the gold pill (just a glyph)
///   2. compact  — leading icon + trailing countdown (Dynamic Island)
///   3. expanded — full mini boarding pass card
///
/// Native integration lives in the host iOS extension (out of scope
/// for this PR). These previews are the design source-of-truth.
enum LiveActivityForm { minimal, compact, expanded }

class LiveActivityModel {
  const LiveActivityModel({
    required this.flightCode,
    required this.gate,
    required this.boardingIn,
    required this.origin,
    required this.destination,
    required this.seat,
  });

  /// `LH 401`
  final String flightCode;

  /// `B27`
  final String gate;

  /// Time-until-boarding, e.g. `Duration(minutes: 18)`. Renders as
  /// `0:18` in the compact + expanded forms.
  final Duration boardingIn;

  /// `FRA` (3-letter IATA)
  final String origin;

  /// `OSL`
  final String destination;

  /// `12A`
  final String seat;
}

class LiveActivityPreview extends StatelessWidget {
  const LiveActivityPreview({
    super.key,
    required this.model,
    required this.form,
  });

  final LiveActivityModel model;
  final LiveActivityForm form;

  String get _countdown {
    final h = model.boardingIn.inHours;
    final m = model.boardingIn.inMinutes.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}';
    return '0:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    switch (form) {
      case LiveActivityForm.minimal:
        return _MinimalPill();
      case LiveActivityForm.compact:
        return _CompactPill(countdown: _countdown);
      case LiveActivityForm.expanded:
        return _ExpandedCard(model: model, countdown: _countdown);
    }
  }
}

class _MinimalPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Os2.foilGoldHero,
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.42),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.flight_takeoff_rounded,
          size: 14,
          color: Os2.canvas,
        ),
      ),
    );
  }
}

class _CompactPill extends StatelessWidget {
  const _CompactPill({required this.countdown});
  final String countdown;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Os2.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.62)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Os2.goldDeep,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Os2Text.monoCap(
            'BOARDING · $countdown',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}

class _ExpandedCard extends StatelessWidget {
  const _ExpandedCard({required this.model, required this.countdown});
  final LiveActivityModel model;
  final String countdown;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.canvas,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.46)),
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                'GLOBE·ID · BOARDING',
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Os2.goldDeep.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Os2.goldDeep.withValues(alpha: 0.62),
                  ),
                ),
                child: Os2Text.monoCap(
                  countdown,
                  color: Os2.goldDeep,
                  size: Os2.textTiny,
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.credential(
                    model.origin,
                    color: Os2.inkBright,
                    size: 28,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.monoCap(
                    'ORIGIN',
                    color: Os2.inkLow,
                    size: Os2.textTiny,
                  ),
                ],
              ),
              const SizedBox(width: Os2.space3),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Os2.inkLow,
                ),
              ),
              const SizedBox(width: Os2.space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.credential(
                    model.destination,
                    color: Os2.inkBright,
                    size: 28,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.monoCap(
                    'DESTINATION',
                    color: Os2.inkLow,
                    size: Os2.textTiny,
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Os2Text.title(
                    model.gate,
                    color: Os2.goldDeep,
                    size: Os2.textXl,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.monoCap(
                    'GATE',
                    color: Os2.inkLow,
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              Os2Text.monoCap(
                '${model.flightCode} · SEAT ${model.seat}',
                color: Os2.inkMid,
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'TAP TO OPEN',
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

/// `DeviceFrame` — wraps a child to look like the top of an iOS
/// device with a Dynamic Island. Used by the preview screen so the
/// `LiveActivityPreview.compact` form reads as a real ambient
/// surface, not a stray pill.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({
    super.key,
    required this.child,
    this.height = 220,
  });
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        color: Os2.canvas,
        border: Border.all(color: Os2.hairlineSoft),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 14,
            child: child,
          ),
        ],
      ),
    );
  }
}
