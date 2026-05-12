import 'package:flutter/material.dart';

import '../chrome/nexus_kv_row.dart';
import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NDestinationCard extends StatelessWidget {
  const NDestinationCard({
    super.key,
    required this.code,
    required this.weather,
    required this.condition,
    required this.arrival,
    required this.prep,
  });

  final String code;
  final String weather;
  final String condition;
  final String arrival;
  final String prep;

  @override
  Widget build(BuildContext context) {
    return NPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NText.eyebrow11('Destination · $code'),
              const Spacer(),
              Text(weather, style: NType.display28(color: N.inkHi)),
            ],
          ),
          const SizedBox(height: N.s1),
          NText.body13(condition, color: N.inkMid),
          const SizedBox(height: N.s4),
          const NHairline(),
          const SizedBox(height: N.s4),
          Row(
            children: [
              Expanded(child: NKv(label: 'Arrival', value: arrival)),
              Expanded(child: NKv(label: 'Prep', value: prep)),
            ],
          ),
        ],
      ),
    );
  }
}
