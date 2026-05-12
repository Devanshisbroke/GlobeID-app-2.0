import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../cards/nexus_activity_row.dart';
import '../cards/nexus_currency_card.dart';
import '../cards/nexus_exchange_card.dart';
import '../cards/nexus_spend_bars.dart';
import '../chrome/nexus_authorize_sheet.dart';
import '../chrome/nexus_bottom_nav.dart';
import '../chrome/nexus_chip.dart';
import '../chrome/nexus_quick_actions.dart';
import '../chrome/nexus_scaffold.dart';
import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Canonical Global Wallet screen.
class NexusWalletScreen extends StatelessWidget {
  const NexusWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NScaffold(
      time: '11:08',
      right: 'Wallet · Online',
      bottomAuth: NAuthorizeSheet(
        title: 'Hold to pay · Face ID',
        subtitle: 'Pre-authorized at gate B34 · 2 of 2 factors',
        onAuthorize: () {},
      ),
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
        activeIndex: 2,
        onTap: (i) {
          const paths = ['/nexus/os', '/nexus/passport', '/nexus/wallet'];
          if (i != 2) context.go(paths[i]);
        },
      ),
      children: [
        // ─── Eyebrow + Net Liquid hero
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NText.eyebrow11('Globe ID · Wallet'),
            const SizedBox(height: N.s2),
            Text('Global Reserve', style: NType.title22(color: N.inkHi)),
            const SizedBox(height: N.s5),
            NText.eyebrow10('Net liquid'),
            const SizedBox(height: N.s1),
            Text('\$237,031', style: NType.display56(color: N.inkHi)),
          ],
        ),
        const SizedBox(height: N.s7),

        // ─── Currency card stack
        const NCurrencyCard(
          data: NCurrencyCardData(
            tier: 'Sovereign Reserve',
            cardName: 'Obsidian',
            currency: 'USD',
            balance: '\$184,320.55',
            maskedNumber: '•••• •••• •••• 0042',
            accent: N.tierGold,
          ),
        ),
        const SizedBox(height: N.s3),
        const NCurrencyCard(
          data: NCurrencyCardData(
            tier: 'Pandion Elite',
            cardName: 'Aurum',
            currency: 'EUR',
            balance: '€42,890.12',
            maskedNumber: '•••• •••• •••• 0118',
            accent: N.tierGoldHi,
          ),
        ),
        const SizedBox(height: N.s3),
        const NCurrencyCard(
          data: NCurrencyCardData(
            tier: 'Travel Metal',
            cardName: 'Arctic Steel',
            currency: 'SGD',
            balance: 'S\$9,820.40',
            maskedNumber: '•••• •••• •••• 0721',
            accent: N.steelHi,
          ),
        ),
        const SizedBox(height: N.s5),

        // ─── Quick actions
        NQuickActionsRow(
          actions: [
            NQuickAction(
              icon: Icons.nfc_rounded,
              label: 'Tap NFC',
              onTap: () {},
            ),
            NQuickAction(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan Pay',
              onTap: () {},
            ),
            NQuickAction(
              icon: Icons.swap_horiz_rounded,
              label: 'Convert',
              onTap: () {},
            ),
            NQuickAction(
              icon: Icons.north_east_rounded,
              label: 'Transfer',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: N.s5),

        // ─── Live exchange
        const NExchangeCard(
          from: 'USD',
          to: 'JPY',
          sendAmount: '\$1,000',
          receiveAmount: '¥151,420',
          rate: '¥151.42',
          change24h: 0.42,
        ),
        const SizedBox(height: N.s3),

        // ─── Travel spend
        const NSpendBars(
          title: 'Travel Spend · This trip',
          subtitle: 'ZRH → SIN',
          total: '\$4,820.17',
          delta: '+ \$312 today',
          categories: [
            NSpendCategory(
              label: 'Lounge',
              percent: 0.42,
              tone: N.tierGold,
            ),
            NSpendCategory(
              label: 'Dining',
              percent: 0.28,
              tone: N.steelHi,
            ),
            NSpendCategory(
              label: 'Transit',
              percent: 0.18,
              tone: N.info,
            ),
            NSpendCategory(
              label: 'Other',
              percent: 0.12,
              tone: N.inkLow,
            ),
          ],
        ),
        const SizedBox(height: N.s3),

        // ─── Global activity
        NPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NText.eyebrow11('Global Activity'),
                  const Spacer(),
                  const NChip(
                    label: 'Live',
                    variant: NChipVariant.success,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: N.s2),
              const NHairline(),
              const NActivityRow(
                country: 'CH',
                merchant: 'The Concorde Room',
                amount: '−CHF 0',
                caption: 'ZRH · T2',
                subCaption: 'Lounge · complimentary',
              ),
              const NHairline(),
              const NActivityRow(
                country: 'CH',
                merchant: 'Swiss · LX 402',
                amount: '−CHF 14,820.00',
                caption: 'Seat 1A · Boarding',
                subCaption: 'First · Sovereign',
              ),
              const NHairline(),
              const NActivityRow(
                country: 'EU',
                merchant: 'Burberry',
                amount: '−€ 1,290.00',
                caption: 'ZRH Duty Free',
                subCaption: 'FX 1.04 · instant',
              ),
              const NHairline(),
              const NActivityRow(
                country: 'SG',
                merchant: 'Marina Bay Sands',
                amount: '−S\$ 4,400.00',
                caption: 'SIN · Pre-auth',
                subCaption: 'Reserved · Jun 12–16',
              ),
              const NHairline(),
              const NActivityRow(
                country: 'SG',
                merchant: 'Singapore Airlines',
                amount: '+S\$ 312.40',
                caption: 'Refund · seat upgrade',
                subCaption: 'Settled',
                isCredit: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
