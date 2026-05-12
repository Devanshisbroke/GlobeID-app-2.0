import 'package:flutter/material.dart';

import '../chrome/nexus_kv_row.dart';
import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NBaggageCard extends StatelessWidget {
  const NBaggageCard({
    super.key,
    required this.rfid,
    required this.drop,
    required this.loading,
  });

  final String rfid;
  final String drop;
  final String loading;

  @override
  Widget build(BuildContext context) {
    return NPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.luggage_rounded,
                size: 18,
                color: N.inkMid,
              ),
              const SizedBox(width: N.s2),
              NText.eyebrow11('Baggage · Synchronized'),
              const Spacer(),
              NText.mono12('RFID $rfid', color: N.inkLow),
            ],
          ),
          const SizedBox(height: N.s4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NText.eyebrow10('Drop'),
                    const SizedBox(height: N.s1),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: N.success,
                        ),
                        const SizedBox(width: N.s1 + 2),
                        NText.body13(drop, color: N.ink),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: NKv(label: 'Loading', value: loading),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
