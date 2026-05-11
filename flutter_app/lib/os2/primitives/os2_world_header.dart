import 'dart:async';

import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_beacon.dart';
import 'os2_solari.dart';
import 'os2_text.dart';

/// OS 2.0 — World header.
///
/// Every world (Pulse, Identity, Wallet, Travel, Discover, Services)
/// opens with this. A live, breathing strip that anchors the viewer:
///   • the world label (uppercase, restrained caption)
///   • a giant display headline (the title)
///   • a meta strip with the current local time (Solari flap), the
///     timezone tag, and a breathing LIVE beacon
///   • optional trailing action (icon button)
///
/// The header is intentionally large and quiet — it does NOT compete
/// with the focal slab below it. It just establishes "you are here,
/// the system is awake".
class Os2WorldHeader extends StatefulWidget {
  const Os2WorldHeader({
    super.key,
    required this.world,
    required this.title,
    this.subtitle,
    this.beacon = 'LIVE',
    this.trailing,
    this.zoneLabel,
  });

  final Os2World world;
  final String title;
  final String? subtitle;
  final String beacon;
  final Widget? trailing;
  final String? zoneLabel;

  @override
  State<Os2WorldHeader> createState() => _Os2WorldHeaderState();
}

class _Os2WorldHeaderState extends State<Os2WorldHeader> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');
  String get _hhmm => '${_twoDigit(_now.hour)}${_twoDigit(_now.minute)}';
  String get _zone {
    if (widget.zoneLabel != null) return widget.zoneLabel!;
    final off = _now.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final h = off.inHours.abs();
    final m = off.inMinutes.abs() - h * 60;
    if (m == 0) return 'GMT$sign$h';
    return 'GMT$sign$h:${_twoDigit(m)}';
  }

  String get _weekday {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[_now.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.world.tone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Os2.space5,
        Os2.space4,
        Os2.space5,
        Os2.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 — meta caption + LIVE beacon.
          Row(
            children: [
              Os2Text.caption(widget.world.label, color: tone, size: 11),
              const SizedBox(width: 10),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Os2.inkLow,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 10),
              Os2Text.caption(_weekday, color: Os2.inkLow),
              const Spacer(),
              Os2Beacon(label: widget.beacon, tone: tone),
            ],
          ),
          const SizedBox(height: Os2.space3),
          // Row 2 — display title.
          Os2Text.display(
            widget.title,
            color: Os2.inkBright,
            size: 38,
            height: 1.0,
            maxLines: 2,
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: Os2.space2),
            Os2Text.body(
              widget.subtitle!,
              color: Os2.inkMid,
              size: 14,
            ),
          ],
          const SizedBox(height: Os2.space4),
          // Row 3 — Solari time + zone + optional trailing.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Os2Solari(
                text: _hhmm,
                tone: tone,
                cellWidth: 18,
                cellHeight: 26,
                fontSize: 18,
              ),
              const SizedBox(width: Os2.space3),
              Container(
                width: 1,
                height: 18,
                color: Os2.hairline,
              ),
              const SizedBox(width: Os2.space3),
              Os2Text.monoCap(_zone, color: Os2.inkMid),
              const Spacer(),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ],
      ),
    );
  }
}
