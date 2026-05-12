import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../chrome/nexus_bottom_nav.dart';
import '../chrome/nexus_chip.dart';
import '../chrome/nexus_kv_row.dart';
import '../chrome/nexus_scaffold.dart';
import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Canonical Passport screen — diplomatic credential in the Nexus
/// language. Restrained hairline cards, dense identity data, mono codes.
class NexusPassportScreen extends StatelessWidget {
  const NexusPassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NScaffold(
      time: '11:08',
      right: 'Passport · Verified',
      bottomNav: NBottomNav(
        items: const [
          NNavItem(
            label: 'Travel OS',
            icon: Icons.public_rounded,
            path: '/nexus/os',
          ),
          NNavItem(
            label: 'Passport',
            icon: Icons.menu_book_rounded,
            path: '/nexus/passport',
          ),
          NNavItem(
            label: 'Wallet',
            icon: Icons.account_balance_wallet_rounded,
            path: '/nexus/wallet',
          ),
        ],
        activeIndex: 1,
        onTap: (i) {
          const paths = ['/nexus/os', '/nexus/passport', '/nexus/wallet'];
          if (i != 1) context.go(paths[i]);
        },
      ),
      children: [
        // ─── Eyebrow + title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NText.eyebrow11('Globe ID · Passport'),
            const SizedBox(height: N.s2),
            Text('Diplomatic Credential', style: NType.title22(color: N.inkHi)),
            const SizedBox(height: N.s2),
            Wrap(
              spacing: N.s2,
              runSpacing: N.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const NChip(
                  label: 'Active',
                  variant: NChipVariant.success,
                  dense: true,
                ),
                const NChip(
                  label: 'Pandion Elite',
                  variant: NChipVariant.active,
                  dense: true,
                ),
                NText.eyebrow10('Tier · 03', color: N.tierGoldHi),
              ],
            ),
          ],
        ),
        const SizedBox(height: N.s7),

        // ─── Identity panel
        NPanel(
          padding: N.cardPadLoose,
          tone: N.tierGold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(N.rSmall),
                      color: N.surfaceInset,
                      border: Border.all(
                        color: N.tierGold.withValues(alpha: 0.45),
                        width: N.strokeHair,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: N.tierGoldHi,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: N.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NText.eyebrow10('Bearer', color: N.inkLow),
                        const SizedBox(height: N.s1),
                        Text(
                          'ALEXANDER V. GRAFF',
                          style: NType.title16(color: N.inkHi),
                        ),
                        const SizedBox(height: N.s1),
                        NText.body12('Swiss Confederation', color: N.inkMid),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: N.s5),
              const NHairline(),
              const SizedBox(height: N.s4),
              Row(
                children: const [
                  Expanded(child: NKv(label: 'Doc no.', value: 'X07A29481', mono: true)),
                  Expanded(child: NKv(label: 'Issued', value: '12 MAR 2022', mono: true)),
                  Expanded(child: NKv(label: 'Expires', value: '11 MAR 2032', mono: true)),
                ],
              ),
              const SizedBox(height: N.s4),
              const NHairline(),
              const SizedBox(height: N.s4),
              Row(
                children: const [
                  Expanded(
                    child: NKv(
                      label: 'Nationality',
                      value: 'CHE',
                      mono: true,
                    ),
                  ),
                  Expanded(child: NKv(label: 'Sex', value: 'M')),
                  Expanded(child: NKv(label: 'DOB', value: '14 AUG 1981', mono: true)),
                ],
              ),
              const SizedBox(height: N.s5),
              const NHairline(),
              const SizedBox(height: N.s3),
              Row(
                children: [
                  NText.eyebrow10('MRZ'),
                  const SizedBox(width: N.s2),
                  Expanded(
                    child: NText.mono12(
                      'P<CHEGRAFF<<ALEXANDER<V<<<<<<<<<<<<<<<<<<<<\nX07A29481<8CHE8108143M3203114<<<<<<<<<<<<<<<8',
                      color: N.inkMid,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: N.s5),

        // ─── Credentials list
        NPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NText.eyebrow11('Credentials'),
                  const Spacer(),
                  NText.eyebrow10('12 issuers', color: N.inkLow),
                ],
              ),
              const SizedBox(height: N.s4),
              for (final c in const [
                ('Swiss Confederation', 'Passport · primary', N.tierGold),
                ('SmartGate · DXB / SIN / NRT', 'Biometric token', N.success),
                ('Schengen Travel Authorisation', 'eTIAS · valid', N.success),
                ('Star Alliance Gold', 'Loyalty · tier 03', N.tierGoldHi),
                ('Diners Club International', 'Membership · sovereign', N.steelHi),
                ('IATA Travel Pass', 'Health · synced', N.info),
              ]) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: N.s3),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: N.s3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.$3,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NText.body14(c.$1, color: N.ink),
                            const SizedBox(height: N.s1),
                            NText.body12(c.$2, color: N.inkLow),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: N.inkFaint,
                      ),
                    ],
                  ),
                ),
                if (c != const ('IATA Travel Pass', 'Health · synced', N.info))
                  const NHairline(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
