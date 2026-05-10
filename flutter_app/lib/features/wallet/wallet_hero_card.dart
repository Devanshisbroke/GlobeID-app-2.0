import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/emotional_palette.dart';
import '../../widgets/bible/bible.dart';
import '../../widgets/premium/premium.dart';

/// Premium wallet hero — replaces the old plain balance row.
///
/// Anatomy:
///   • LiquidWaveSurface body, tinted to the active accent
///   • DepartureBoardFlap balance — flips when the value changes
///   • currency code in [AirportFontStack.iata] tracking
///   • magnetic CTA row (Send / Convert / Pay)
///   • optional emotional context that warms the wash
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
    final theme = Theme.of(build);
    final isDark = theme.brightness == Brightness.dark;
    final shift = emotion == null
        ? const EmotionalShift()
        : EmotionalPalette.shiftFor(emotion!);
    final tone = shift.accentOverride ?? theme.colorScheme.primary;
    final balanceText = balance
        .toStringAsFixed(balance >= 1000 ? 0 : 2)
        .padLeft(balance >= 1000 ? 5 : 6, ' ');

    return BibleHeroCard(
      material: BibleMaterial.glass,
      tone: BibleTone.treasuryGreen,
      elevation: BibleHeroElevation.cinematic,
      radius: 32,
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
              Text(
                'TOTAL BALANCE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space2 + 2,
                  vertical: AppTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  border: Border.all(
                    color: tone.withValues(alpha: 0.4),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  currency.toUpperCase(),
                  style: AirportFontStack.gate(build, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
            // Hero balance is wrapped in `FittedBox` so very long
            // balances (e.g. "$ 1,234,567.89") shrink to fit instead
            // of overflowing the card. This is a defensive guard —
            // we don't expect long balances in demo data, but
            // production users in JPY / VND will have many digits.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: DepartureBoardText(
                text: balanceText,
                charWidth: 24,
                style: AirportFontStack.board(build, size: 32),
                tone: tone,
                background: isDark
                    ? const Color(0xFF06080F)
                    : const Color(0xFF0D1322),
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.space1),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: AppTokens.space4),
          LiquidWaveSurface(
            progress: progress.clamp(0.0, 1.0),
            tone: tone,
            height: 26,
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
              Expanded(
                child: MagneticButton(
                  label: 'Receive',
                  icon: Icons.arrow_downward_rounded,
                  onPressed: onReceive,
                  compact: true,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tone.withValues(alpha: 0.30),
                      tone.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: MagneticButton(
                  label: 'Convert',
                  icon: Icons.swap_horiz_rounded,
                  onPressed: onConvert,
                  compact: true,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tone.withValues(alpha: 0.30),
                      tone.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: MagneticButton(
                  label: 'Scan',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: onScanPay,
                  compact: true,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tone.withValues(alpha: 0.30),
                      tone.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
