import 'package:flutter/material.dart';

import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NCurrencyCardData {
  const NCurrencyCardData({
    required this.tier,
    required this.cardName,
    required this.currency,
    required this.balance,
    required this.maskedNumber,
    required this.accent,
  });
  final String tier;
  final String cardName;
  final String currency;
  final String balance;
  final String maskedNumber;
  final Color accent;
}

/// Currency card — large pill displaying NFC chip, tier name, balance,
/// masked card number, brand wordmark. Each card has its own accent.
class NCurrencyCard extends StatelessWidget {
  const NCurrencyCard({
    super.key,
    required this.data,
  });
  final NCurrencyCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(N.s5),
      decoration: BoxDecoration(
        color: N.surfaceRaised,
        borderRadius: BorderRadius.circular(N.rCardLg),
        border: Border.all(
          color: data.accent.withValues(alpha: 0.32),
          width: N.strokeHair,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.accent.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Top row: tier · card name · NFC chip
          Row(
            children: [
              Container(
                width: 32,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.6),
                    width: N.strokeHair,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      data.accent.withValues(alpha: 0.35),
                      data.accent.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: N.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NText.eyebrow10(data.tier, color: N.inkLow),
                    const SizedBox(height: N.s1),
                    Text(
                      data.cardName,
                      style: NType.title16(color: N.inkHi),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.wifi_rounded,
                size: 18,
                color: N.inkLow,
              ),
              const SizedBox(width: N.s1),
              NText.eyebrow10('NFC', color: N.inkLow),
            ],
          ),
          const SizedBox(height: N.s5),
          NText.eyebrow10('Available · ${data.currency}'),
          const SizedBox(height: N.s2),
          Text(data.balance, style: NType.display40(color: N.inkHi)),
          const SizedBox(height: N.s5),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: NText.mono14(data.maskedNumber, color: N.inkMid),
                ),
              ),
              const SizedBox(width: N.s2),
              Text(
                'GLOBEID',
                style: NType.eyebrow11(color: data.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
