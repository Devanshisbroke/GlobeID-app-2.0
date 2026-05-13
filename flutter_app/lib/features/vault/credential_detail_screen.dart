import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cinematic/identity/biometric_reveal_gate.dart';
import '../../data/models/travel_document.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../user/user_provider.dart';

/// Credential detail surface — opens from a Vault card. Renders
/// every credential field grouped by sensitivity tier, with
/// biometric reveal gates on every HIGH-sensitivity row.
class CredentialDetailScreen extends ConsumerWidget {
  const CredentialDetailScreen({super.key, required this.credentialId});

  final String credentialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final doc = user.documents.firstWhere(
      (d) => d.id == credentialId,
      orElse: () => TravelDocument(
        id: credentialId,
        type: 'unknown',
        label: 'Credential',
        country: 'Unknown',
        countryFlag: '🌐',
        number: '— — — —',
        issueDate: '— — — —',
        expiryDate: '— — — —',
        status: 'pending',
      ),
    );
    return PageScaffold(
      title: doc.label,
      subtitle: '${doc.countryFlag} ${doc.country}',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _SectionEyebrow(title: 'PUBLIC · LOW SENSITIVITY'),
          const SizedBox(height: Os2.space2),
          _FieldRow(
            label: 'Full name',
            value: user.profile.name,
            tone: _toneLow,
          ),
          const SizedBox(height: Os2.space2),
          _FieldRow(
            label: 'Nationality',
            value: doc.country,
            tone: _toneLow,
          ),
          const SizedBox(height: Os2.space2),
          _FieldRow(
            label: 'Issuing country',
            value: doc.country,
            tone: _toneLow,
          ),
          const SizedBox(height: Os2.space5),
          const _SectionEyebrow(title: 'STANDARD · MEDIUM SENSITIVITY'),
          const SizedBox(height: Os2.space2),
          _FieldRow(
            label: 'Expiry date',
            value: doc.expiryDate,
            tone: _toneMed,
          ),
          const SizedBox(height: Os2.space2),
          _FieldRow(
            label: 'Issued',
            value: doc.issueDate,
            tone: _toneMed,
          ),
          const SizedBox(height: Os2.space5),
          const _SectionEyebrow(title: 'SENSITIVE · BIOMETRIC GATED'),
          const SizedBox(height: Os2.space2),
          BiometricRevealGate(
            label: 'Passport number',
            value: doc.number,
          ),
          const SizedBox(height: Os2.space2),
          const BiometricRevealGate(
            label: 'Date of birth',
            value: '1992-04-17',
          ),
          const SizedBox(height: Os2.space2),
          const BiometricRevealGate(
            label: 'Home address',
            value: '17 Linden Crescent · London · NW1 4LB',
          ),
        ],
      ),
    );
  }
}

const _toneLow = Color(0xFF10B981); // emerald
const _toneMed = Color(0xFFE9C75D); // gold light

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Os2Text.monoCap(
      title,
      color: Os2.goldDeep,
      size: Os2.textTiny,
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    required this.tone,
  });
  final String label;
  final String value;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space4,
        vertical: Os2.space3,
      ),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Row(
        children: [
          _SensitivityChip(tone: tone),
          const SizedBox(width: Os2.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Os2Text.monoCap(
                  label.toUpperCase(),
                  color: Os2.inkLow,
                  size: Os2.textTiny,
                ),
                const SizedBox(height: 4),
                Os2Text.title(
                  value,
                  color: Os2.inkBright,
                  size: Os2.textRg,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensitivityChip extends StatelessWidget {
  const _SensitivityChip({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 36,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
