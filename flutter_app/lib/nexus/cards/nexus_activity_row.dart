import 'package:flutter/material.dart';

import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NActivityRow extends StatelessWidget {
  const NActivityRow({
    super.key,
    required this.country,
    required this.merchant,
    required this.amount,
    required this.caption,
    required this.subCaption,
    this.isCredit = false,
  });

  final String country;
  final String merchant;
  final String amount;
  final String caption;
  final String subCaption;
  final bool isCredit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: N.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: N.surfaceInset,
              border: Border.all(
                color: N.hairline,
                width: N.strokeHair,
              ),
            ),
            child: Center(
              child: NText.monoCap10(country, color: N.inkMid),
            ),
          ),
          const SizedBox(width: N.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NText.body14(merchant, color: N.ink),
                const SizedBox(height: N.s1),
                NText.body12(caption, color: N.inkLow),
              ],
            ),
          ),
          const SizedBox(width: N.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: NType.mono14(
                  color: isCredit ? N.success : N.ink,
                ),
              ),
              const SizedBox(height: N.s1),
              NText.body12(subCaption, color: N.inkLow),
            ],
          ),
        ],
      ),
    );
  }
}
