import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/emotional_palette.dart';
import '../../nexus/nexus_tokens.dart';
import '../../widgets/premium/premium.dart';

/// Wallet hero card — **Nexus-aligned, modeled on the Lovable
/// canonical Wallet hero.**
///
/// Was a `BibleHeroCard(material: glass)` with a treasury-green tone,
/// specular highlight, multi-tier ambient shadow, and a tinted
/// departure-board balance over a deep ink background. The new
/// language drops the lacquered hero recipe in favour of the same
/// flat hairline panel used everywhere else in the app — depth comes
/// from contrast (champagne / white-on-black), not from lighting.
///
/// Anatomy:
///   • flat `N.surface` body, 0.5pt hairline border
///   • "TOTAL BALANCE" eyebrow + inverted currency pill
///   • DepartureBoardFlap balance, white on the substrate
///   • LiquidWaveSurface progress, but the wave is now tone-restrained
///   • 4-up CTA row — primary "Send" is the champagne pill, the rest
///     are flat hairline buttons (cinematic compact size)
class WalletHeroCard extends StatelessWidget {
  const WalletHeroCard({
    super.key,
    required this.balance,
    required this.currency,
    this.emotion,
    this.subtitle,
    this.progress = 0.65,
    this.onSend,
    this.onReceive,
    this.onConvert,
    this.onScanPay,
  });

  final double balance;
  final String currency;
  final EmotionalContext? emotion;
  final String? subtitle;
  final double progress;
  final VoidCallback? onSend;
  final VoidCallback? onReceive;
  final VoidCallback? onConvert;
  final VoidCallback? onScanPay;

  @override
  Widget build(BuildContext build) {
    final shift = emotion == null
        ? const EmotionalShift()
        : EmotionalPalette.shiftFor(emotion!);
    final tone = shift.accentOverride ?? N.tierGold;
    final balanceText = balance
        .toStringAsFixed(balance >= 1000 ? 0 : 2)
        .padLeft(balance >= 1000 ? 5 : 6, ' ');

    return Container(
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rCardLg),
        border: Border.all(
          color: N.hairline,
          width: N.strokeHair,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space5,
        AppTokens.space5,
        AppTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TOTAL BALANCE',
                style: TextStyle(
                  color: N.inkLow,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space2 + 2,
                  vertical: AppTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(N.rPill),
                  border: Border.all(
                    color: tone.withValues(alpha: 0.32),
                    width: N.strokeHair,
                  ),
                ),
                child: Text(
                  currency.toUpperCase(),
                  style: AirportFontStack.gate(build, size: 11)
                      .copyWith(color: tone),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: DepartureBoardText(
                text: balanceText,
                charWidth: 24,
                style: AirportFontStack.board(build, size: 32),
                tone: N.inkHi,
                background: N.bg,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.space1),
            Text(
              subtitle!,
              style: const TextStyle(
                color: N.inkMid,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.space4),
          LiquidWaveSurface(
            progress: progress.clamp(0.0, 1.0),
            tone: tone,
            height: 22,
            radius: AppTokens.radiusFull,
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            children: [
              Expanded(
                child: MagneticButton(
                  label: 'Send',
                  icon: Icons.arrow_outward_rounded,
                  onPressed: onSend,
                  compact: true,
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(child: _SecondaryAction(
                label: 'Receive',
                icon: Icons.arrow_downward_rounded,
                onTap: onReceive,
              )),
              const SizedBox(width: AppTokens.space2),
              Expanded(child: _SecondaryAction(
                label: 'Convert',
                icon: Icons.swap_horiz_rounded,
                onTap: onConvert,
              )),
              const SizedBox(width: AppTokens.space2),
              Expanded(child: _SecondaryAction(
                label: 'Scan',
                icon: Icons.qr_code_scanner_rounded,
                onTap: onScanPay,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

/// Secondary CTA — flat hairline pill, ink-on-black, used for the
/// receive / convert / scan slots next to the champagne Send pill.
class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(N.rPill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space2 + 2,
          vertical: AppTokens.space2 + 2,
        ),
        decoration: BoxDecoration(
          color: N.bg,
          borderRadius: BorderRadius.circular(N.rPill),
          border: Border.all(
            color: N.hairlineHi,
            width: N.strokeHair,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: N.inkHi, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: N.inkHi,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
