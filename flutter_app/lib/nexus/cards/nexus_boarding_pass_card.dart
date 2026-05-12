import 'package:flutter/material.dart';

import '../chrome/nexus_kv_row.dart';
import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NBoardingPassData {
  const NBoardingPassData({
    required this.passenger,
    required this.cabin,
    required this.fromCode,
    required this.fromCity,
    required this.fromTerm,
    required this.toCode,
    required this.toCity,
    required this.toTerm,
    required this.gate,
    required this.seat,
    required this.group,
    required this.board,
    required this.token,
  });
  final String passenger;
  final String cabin;
  final String fromCode;
  final String fromCity;
  final String fromTerm;
  final String toCode;
  final String toCity;
  final String toTerm;
  final String gate;
  final String seat;
  final String group;
  final String board;
  final String token;
}

/// Dense data grid mimicking a boarding pass — eyebrow + value pairs
/// arranged in two rows that fit comfortably on a 390 px screen.
class NBoardingPassCard extends StatelessWidget {
  const NBoardingPassCard({super.key, required this.data});
  final NBoardingPassData data;

  @override
  Widget build(BuildContext context) {
    return NPanel(
      padding: N.cardPadLoose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Row 1: passenger · cabin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NKv(label: 'Passenger', value: data.passenger),
              ),
              const SizedBox(width: N.s3),
              Expanded(
                child: NKv(label: 'Cabin', value: data.cabin),
              ),
            ],
          ),
          const SizedBox(height: N.s5),
          // ─── Row 2: route
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.fromCode,
                      style: NType.display40(color: N.inkHi),
                    ),
                    NText.body12('${data.fromCity} · ${data.fromTerm}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: N.s3),
                child: NText.mono12('────→', color: N.inkLow),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.toCode,
                      style: NType.display40(color: N.inkHi),
                    ),
                    NText.body12('${data.toCity} · ${data.toTerm}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: N.s5),
          const NHairline(),
          const SizedBox(height: N.s4),
          // ─── Row 3: gate · seat · group · board
          Row(
            children: [
              Expanded(child: NKv(label: 'Gate', value: data.gate)),
              Expanded(child: NKv(label: 'Seat', value: data.seat)),
              Expanded(child: NKv(label: 'Group', value: data.group)),
              Expanded(child: NKv(label: 'Board', value: data.board)),
            ],
          ),
          const SizedBox(height: N.s4),
          const NHairline(),
          const SizedBox(height: N.s4),
          // ─── Row 4: pass token (mono)
          Row(
            children: [
              NText.eyebrow10('Pass token', color: N.inkLow),
              const SizedBox(width: N.s2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: NText.mono14(data.token, color: N.tierGoldHi),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
