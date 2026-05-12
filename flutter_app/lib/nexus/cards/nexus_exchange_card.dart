import 'package:flutter/material.dart';

import '../chrome/nexus_chip.dart';
import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NExchangeCard extends StatelessWidget {
  const NExchangeCard({
    super.key,
    required this.from,
    required this.to,
    required this.sendAmount,
    required this.receiveAmount,
    required this.rate,
    required this.change24h,
  });

  final String from;
  final String to;
  final String sendAmount;
  final String receiveAmount;
  final String rate;
  final double change24h;

  @override
  Widget build(BuildContext context) {
    final positive = change24h >= 0;
    final changeStr =
        '${positive ? '+' : ''}${change24h.toStringAsFixed(2)}%';

    return NPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NText.eyebrow11('Live Exchange'),
              const SizedBox(width: N.s2),
              NText.eyebrow10('$from → $to', color: N.tierGoldHi),
              const Spacer(),
              const NChip(
                label: 'Live',
                variant: NChipVariant.success,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: N.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NText.eyebrow10('You send'),
                    const SizedBox(height: N.s1),
                    Text(
                      sendAmount,
                      style: NType.display28(color: N.inkHi),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: N.s3),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: N.surfaceInset,
                    border: Border.all(
                      color: N.hairline,
                      width: N.strokeHair,
                    ),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: N.inkMid,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    NText.eyebrow10('They receive'),
                    const SizedBox(height: N.s1),
                    Text(
                      receiveAmount,
                      style: NType.display28(color: N.tierGoldHi),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: N.s4),
          const NHairline(),
          const SizedBox(height: N.s3),
          Row(
            children: [
              NText.eyebrow10('1 $from = '),
              NText.mono14(rate, color: N.ink),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: N.s2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(N.rChip),
                  color: positive
                      ? N.success.withValues(alpha: 0.10)
                      : N.critical.withValues(alpha: 0.10),
                ),
                child: NText.mono12(
                  changeStr,
                  color: positive ? N.success : N.critical,
                ),
              ),
              const SizedBox(width: N.s1 + 2),
              NText.eyebrow10('24h'),
            ],
          ),
        ],
      ),
    );
  }
}
