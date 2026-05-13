import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../live/live_primitives.dart';

/// Cinematic empty / error / loading states — engineered by GlobeID.
///
/// Every "nothing here yet" / "we couldn't reach the ledger" / "reading
/// your records…" surface in the app should mount one of these instead
/// of a hand-rolled column of generic text. They share one chrome
/// language so an empty Wallet feels like the same product as an empty
/// Trip Timeline, an empty Inbox, or an empty Search.
///
/// Brand DNA every state carries:
///   • Mono-cap [eyebrow] above the hero glyph (e.g. WALLET · LEDGER)
///   • Hero halo orb keyed to the surface tone (gold by default)
///   • [Os2Text.title] headline + [Os2Text.body] message
///   • Optional CTA / retry / dismiss row
///   • Gold hairline rule + GLOBE·ID watermark in the bottom corner
///   • OLED-black substrate; nothing reaches outside its own slab
class CinematicStateChrome extends StatelessWidget {
  const CinematicStateChrome({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.tone,
    required this.glyph,
    this.cta,
    this.onCta,
    this.tertiary,
    this.onTertiary,
    this.footer,
    this.compact = false,
  });

  /// Mono-cap eyebrow rendered above the hero glyph. Conventionally
  /// reads `<WORLD> · <ROLE>` (e.g. `WALLET · LEDGER`,
  /// `TRIP · PLAN`, `IDENTITY · CREDENTIAL`).
  final String eyebrow;

  /// The headline (`Os2Text.title`) — terse, one short sentence.
  final String title;

  /// The body explanation — `Os2Text.body`, mid ink, 1–3 sentences.
  final String message;

  /// The surface tone — drives halo glow + hairline + eyebrow ink.
  /// Defaults to GlobeID gold when used via the convenience wrappers.
  final Color tone;

  /// The hero illustration mounted inside the breathing halo. Usually
  /// an `Icon`, sometimes a custom widget (animated orb, lock glyph).
  final Widget glyph;

  /// Optional primary action label (e.g. "Add credential").
  final String? cta;
  final VoidCallback? onCta;

  /// Optional secondary action label (e.g. "Why am I seeing this?").
  final String? tertiary;
  final VoidCallback? onTertiary;

  /// Optional micro-footer rendered just above the GLOBE·ID
  /// watermark — error codes, hashes, last-sync timestamps.
  final Widget? footer;

  /// Compact mode shrinks the halo + spacing for inline (in-list)
  /// empty states. Full mode is for whole-screen substrates.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final haloSize = compact ? 96.0 : 132.0;
    final iconSize = compact ? 46.0 : 64.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Os2.space7,
          vertical: compact ? Os2.space5 : Os2.space9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mono-cap eyebrow — sits above the hero so the user reads
            // the role of the surface before the empty message lands.
            Os2Text.monoCap(eyebrow, color: tone, size: Os2.textXs),
            SizedBox(height: compact ? Os2.space3 : Os2.space4),
            // Hero halo — breathing orb behind the glyph icon.
            SizedBox(
              width: haloSize,
              height: haloSize,
              child: BreathingHalo(
                tone: tone,
                state: LiveSurfaceState.idle,
                maxAlpha: 0.30,
                expand: 10,
                child: Center(
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tone.withValues(alpha: 0.16),
                      border: Border.all(
                        color: tone.withValues(alpha: 0.36),
                        width: 0.8,
                      ),
                    ),
                    child: Center(child: glyph),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? Os2.space4 : Os2.space6),
            Os2Text.title(title, color: Os2.inkBright, align: TextAlign.center),
            const SizedBox(height: Os2.space2),
            Os2Text.body(
              message,
              color: Os2.inkMid,
              align: TextAlign.center,
              maxLines: 4,
            ),
            if (cta != null) ...[
              const SizedBox(height: Os2.space5),
              FilledButton(
                onPressed: onCta,
                style: FilledButton.styleFrom(
                  backgroundColor: tone.withValues(alpha: 0.92),
                  foregroundColor: Os2.canvas,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Os2.space6, vertical: Os2.space3),
                  shape: const StadiumBorder(),
                ),
                child: Os2Text.monoCap(cta!, color: Os2.canvas, size: Os2.textXs),
              ),
            ],
            if (tertiary != null) ...[
              const SizedBox(height: Os2.space2),
              TextButton(
                onPressed: onTertiary,
                child: Os2Text.monoCap(
                  tertiary!,
                  color: Os2.inkMid,
                  size: Os2.textXs,
                ),
              ),
            ],
            const SizedBox(height: Os2.space5),
            // Brand thread — quiet gold hairline + GLOBE·ID watermark
            // share the same alpha the AppleSheet substrate uses.
            Container(
              width: 56,
              height: 0.6,
              color: Os2.goldHairline,
            ),
            const SizedBox(height: Os2.space2),
            if (footer != null) ...[
              footer!,
              const SizedBox(height: Os2.space2),
            ],
            const Os2Text.watermark('GLOBE·ID'),
          ],
        ),
      ),
    );
  }
}

/// Empty state — "nothing here yet". Defaults to GlobeID gold tone.
class Os2EmptyState extends StatelessWidget {
  const Os2EmptyState({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.icon = Icons.auto_awesome_rounded,
    this.tone,
    this.cta,
    this.onCta,
    this.tertiary,
    this.onTertiary,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String message;
  final IconData icon;
  final Color? tone;
  final String? cta;
  final VoidCallback? onCta;
  final String? tertiary;
  final VoidCallback? onTertiary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? Os2.goldDeep;
    return CinematicStateChrome(
      eyebrow: eyebrow,
      title: title,
      message: message,
      tone: accent,
      compact: compact,
      cta: cta,
      onCta: onCta,
      tertiary: tertiary,
      onTertiary: onTertiary,
      glyph: Icon(icon, color: accent, size: compact ? 22 : 28),
    );
  }
}

/// Error state — something went wrong. Defaults to critical tone.
/// Optional [errorCode] renders in mono just above the watermark.
class Os2ErrorState extends StatelessWidget {
  const Os2ErrorState({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.icon = Icons.report_gmailerrorred_rounded,
    this.tone,
    this.errorCode,
    this.cta = 'RETRY',
    this.onCta,
    this.tertiary,
    this.onTertiary,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String message;
  final IconData icon;
  final Color? tone;

  /// Optional mono-format error code (e.g. `WT-403`, `LEDGER/NET·TX`).
  final String? errorCode;
  final String? cta;
  final VoidCallback? onCta;
  final String? tertiary;
  final VoidCallback? onTertiary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? Os2.signalCritical;
    return CinematicStateChrome(
      eyebrow: eyebrow,
      title: title,
      message: message,
      tone: accent,
      compact: compact,
      cta: cta,
      onCta: onCta,
      tertiary: tertiary,
      onTertiary: onTertiary,
      glyph: Icon(icon, color: accent, size: compact ? 22 : 28),
      footer: errorCode == null
          ? null
          : Os2Text.monoCap(
              errorCode!,
              color: Os2.inkLow,
              size: Os2.textXs,
            ),
    );
  }
}

/// Loading state — a single source of truth for "reading your data".
/// Halo orb sweeps a scanning beam across the glyph while the breath
/// cadence pulls toward the active state — same DNA the Live surfaces
/// use when they hand-off from idle → armed.
class Os2LoadingState extends StatefulWidget {
  const Os2LoadingState({
    super.key,
    required this.eyebrow,
    required this.title,
    this.message,
    this.icon = Icons.sync_rounded,
    this.tone,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String? message;
  final IconData icon;
  final Color? tone;
  final bool compact;

  @override
  State<Os2LoadingState> createState() => _Os2LoadingStateState();
}

class _Os2LoadingStateState extends State<Os2LoadingState>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.tone ?? Os2.goldDeep;
    return CinematicStateChrome(
      eyebrow: widget.eyebrow,
      title: widget.title,
      message: widget.message ?? '',
      tone: accent,
      compact: widget.compact,
      glyph: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          // Hero icon rotates one revolution per cycle, just slow
          // enough to read as "scanning" rather than "spinner".
          return Transform.rotate(
            angle: _ctrl.value * 2 * math.pi,
            child: Icon(
              widget.icon,
              color: accent,
              size: widget.compact ? 22 : 28,
            ),
          );
        },
      ),
    );
  }
}
