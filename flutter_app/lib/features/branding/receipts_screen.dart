import 'package:flutter/material.dart';

import '../../cinematic/branding/globe_receipt.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Lab gallery for the [GlobeReceipt] primitive.
///
/// Renders one receipt at a time and lets the operator cycle the
/// five canonical kinds — PAYMENT / TRIP / CREDENTIAL / IMMIGRATION /
/// VISA — so every accent tone, every footer copy, every body-row
/// layout is visible side-by-side. Used as the share-sheet preview
/// template across the app.
class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  ReceiptKind _kind = ReceiptKind.payment;

  static const _picker = <(ReceiptKind, String, IconData)>[
    (ReceiptKind.payment, 'PAYMENT', Icons.payments_outlined),
    (ReceiptKind.trip, 'TRIP', Icons.flight_takeoff_rounded),
    (ReceiptKind.credential, 'CREDENTIAL', Icons.verified_user_outlined),
    (ReceiptKind.immigration, 'IMMIGRATION', Icons.fingerprint_outlined),
    (ReceiptKind.visa, 'VISA', Icons.menu_book_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final spec = ReceiptSpec.of(_kind);
    return PageScaffold(
      title: 'Receipts',
      subtitle: 'Phase 12e · 5 GlobeID-engineered share-sheet templates',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          // Receipt preview.
          Center(child: _buildReceipt(_kind)),
          const SizedBox(height: Os2.space5),
          // Kind picker.
          Os2Text.monoCap(
            'KIND · PICKER',
            color: spec.tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              for (final entry in _picker) ...[
                Expanded(
                  child: _PickerTile(
                    kind: entry.$1,
                    label: entry.$2,
                    icon: entry.$3,
                    selected: _kind == entry.$1,
                    onTap: () => setState(() => _kind = entry.$1),
                  ),
                ),
                if (entry.$1 != _picker.last.$1) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: Os2.space5),
          // Spec card.
          _SpecCard(spec: spec),
        ],
      ),
    );
  }

  Widget _buildReceipt(ReceiptKind kind) {
    switch (kind) {
      case ReceiptKind.payment:
        return const GlobeReceipt(
          kind: ReceiptKind.payment,
          title: 'Confirmed',
          subtitle: 'Café Schiller · Berlin',
          amount: '€ 42.18',
          amountSub: 'EUR · CHARGED · LIVE · RATE',
          rows: [
            ReceiptRow(label: 'METHOD', value: 'Visa · 4282'),
            ReceiptRow(label: 'AUTHORIZED', value: 'Local'),
            ReceiptRow(label: 'FX · SPREAD', value: '+0.08 %'),
            ReceiptRow(
              label: 'TOTAL',
              value: '€ 42.18',
              toneOverride: Color(0xFFE9C75D),
              bold: true,
            ),
          ],
          caseNumber: 'N° PAY-A8C',
          timestamp: '2024 · 09 · 14 · 17:42 · UTC',
        );
      case ReceiptKind.trip:
        return const GlobeReceipt(
          kind: ReceiptKind.trip,
          title: 'Trip archived',
          subtitle: 'Berlin → Lisbon · 6 days',
          amount: '€ 1 248.50',
          amountSub: 'TOTAL · TRIP · COST',
          rows: [
            ReceiptRow(label: 'FLIGHTS', value: '€ 412.00'),
            ReceiptRow(label: 'LODGING', value: '€ 540.50'),
            ReceiptRow(label: 'MEALS', value: '€ 188.00'),
            ReceiptRow(label: 'TRANSIT', value: '€ 108.00'),
            ReceiptRow(
              label: 'SETTLED',
              value: '€ 1 248.50',
              toneOverride: Color(0xFFE9C75D),
              bold: true,
            ),
          ],
          caseNumber: 'N° TRIP-LIS',
          timestamp: '2024 · 09 · 20 · 11:08 · UTC',
        );
      case ReceiptKind.credential:
        return const GlobeReceipt(
          kind: ReceiptKind.credential,
          title: 'Credential issued',
          subtitle: 'IATA · CABIN CREW · MEMBER',
          amount: 'Member · 7Y',
          amountSub: 'ATTESTED · CRYPTOGRAPHIC · SIG',
          rows: [
            ReceiptRow(label: 'ISSUER', value: 'IATA'),
            ReceiptRow(label: 'BLOCK', value: '#198 442 117'),
            ReceiptRow(label: 'EXPIRES', value: '2031 · 06 · 30'),
            ReceiptRow(label: 'DISCLOSURE', value: 'Selective'),
          ],
          caseNumber: 'N° CRED-7Y',
          timestamp: '2024 · 06 · 30 · 09:12 · UTC',
          signatureLabel: 'SIGNED · IATA · BLOCK',
        );
      case ReceiptKind.immigration:
        return const GlobeReceipt(
          kind: ReceiptKind.immigration,
          title: 'Cleared',
          subtitle: 'BERLIN-BRANDENBURG · BER · GATE 14',
          amount: '00:03:48',
          amountSub: 'QUEUE · TIME · LIVE',
          rows: [
            ReceiptRow(label: 'OFFICER', value: 'Bundes · 308'),
            ReceiptRow(label: 'BIOMETRIC', value: 'FACE + IRIS'),
            ReceiptRow(label: 'STAMP', value: 'EU · ENTRY'),
            ReceiptRow(
              label: 'STATUS',
              value: 'CLEARED',
              toneOverride: Color(0xFF3FB68B),
              bold: true,
            ),
          ],
          caseNumber: 'N° IMM-BER',
          timestamp: '2024 · 09 · 14 · 07:18 · CEST',
          signatureLabel: 'SIGNED · BUNDESPOLIZEI',
        );
      case ReceiptKind.visa:
        return const GlobeReceipt(
          kind: ReceiptKind.visa,
          title: 'Visa granted',
          subtitle: 'JAPAN · SHORT · STAY · 90 d',
          amount: '90 · DAYS',
          amountSub: 'MAX · STAY · SINGLE · ENTRY',
          rows: [
            ReceiptRow(label: 'CATEGORY', value: 'Tourist'),
            ReceiptRow(label: 'ISSUED', value: '2024 · 09 · 02'),
            ReceiptRow(label: 'EXPIRES', value: '2025 · 09 · 01'),
            ReceiptRow(label: 'STAMP', value: 'EMBASSY · TKY'),
            ReceiptRow(
              label: 'STATUS',
              value: 'GRANTED',
              toneOverride: Color(0xFF3FB68B),
              bold: true,
            ),
          ],
          caseNumber: 'N° VISA-JPN',
          timestamp: '2024 · 09 · 02 · 14:00 · JST',
          signatureLabel: 'SIGNED · EMBASSY · TOKYO',
        );
    }
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.kind,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final ReceiptKind kind;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = ReceiptSpec.of(kind);
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Switch to $label receipt',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? spec.tone.withValues(alpha: 0.16)
              : const Color(0xFF0E0E12),
          borderRadius: BorderRadius.circular(Os2.rTile),
          border: Border.all(
            color: selected ? spec.tone : spec.tone.withValues(alpha: 0.28),
            width: selected ? 1.2 : 0.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: selected ? spec.tone : Os2.inkMid),
            const SizedBox(height: 6),
            Os2Text.monoCap(
              label,
              color: selected ? spec.tone : Os2.inkMid,
              size: Os2.textTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard({required this.spec});
  final ReceiptSpec spec;

  @override
  Widget build(BuildContext context) {
    final hex = '#${(spec.tone.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'SPEC · RECEIPT',
            color: spec.tone,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          _Row(label: 'EYEBROW', value: spec.eyebrow),
          const SizedBox(height: 6),
          _Row(label: 'FOOTER', value: spec.footer),
          const SizedBox(height: 6),
          _Row(label: 'TONE', value: hex),
          const SizedBox(height: 6),
          _Row(label: 'FRAME', value: '0.8 · HAIRLINE · 46 %'),
          const SizedBox(height: 6),
          _Row(label: 'WIDTH', value: '360 · FIXED'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Os2Text.monoCap(label, color: Os2.inkMid, size: Os2.textTiny),
        ),
        Os2Text.monoCap(value, color: Os2.inkBright, size: Os2.textTiny),
      ],
    );
  }
}
