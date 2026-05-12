import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/airport_typography.dart';
import '../../nexus/nexus_tokens.dart';

/// Premium HUD overlay — a glass pill that floats above the current
/// surface and broadcasts live system state. Used on cinematic/full-
/// bleed screens that don't have a regular AppBar (boarding pass,
/// arrival cinematic, kiosk, globe, route reveal).
///
/// Renders as a single horizontal capsule:
///   ▸ leading chevron / system pulse dot
///   ▸ DepartureBoardText label
///   ▸ trailing accessory (icon + value)
///
/// Deterministic. No animation drives state — caller decides when
/// to mount/unmount.
class PremiumHud extends StatelessWidget {
  const PremiumHud({
    super.key,
    required this.label,
    this.tone,
    this.trailing,
    this.leadingPulse = true,
    this.dense = false,
  });

  final String label;
  final Color? tone;
  final Widget? trailing;
  final bool leadingPulse;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? N.tierGold;
    final hPad = dense ? 10.0 : AppTokens.space3;
    final vPad = dense ? 5.0 : 7.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rPill),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: N.strokeHair,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingPulse) ...[
            _Pulse(tone: accent),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AirportFontStack.caption(context).copyWith(
              color: N.inkHi,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              fontSize: dense ? 9.6 : 10.4,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            DefaultTextStyle.merge(
              style: AirportFontStack.flightNumber(
                context,
                size: dense ? 11 : 12,
              ).copyWith(color: accent),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.tone});
  final Color tone;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = reduce ? 0.0 : _c.value;
        final opacity = (0.55 + (1 - t) * 0.45).clamp(0.0, 1.0);
        final size = 7.0 + (reduce ? 0 : t * 4);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.tone.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}
