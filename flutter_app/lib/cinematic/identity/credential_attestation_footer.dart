import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../live/live_primitives.dart';

/// `CredentialAttestation` — what the footer renders.
///
/// In production these come from the issuer/verifier layer; for the
/// demo they're derived deterministically from the credential id so
/// the same passport always reads the same block + signer.
class CredentialAttestation {
  const CredentialAttestation({
    required this.verified,
    required this.revoked,
    required this.blockHeight,
    required this.signer,
    required this.signerHandle,
  });

  /// True when the credential's signature passes verification.
  final bool verified;

  /// True when the issuer has explicitly revoked the credential.
  /// Takes precedence over [verified] in the footer chrome.
  final bool revoked;

  /// On-chain block height at which the credential was anchored.
  /// Rendered in mono-cap as `BLOCK ##,###,###`.
  final int blockHeight;

  /// Human-readable issuer name (e.g. `Republic of Schengen`).
  final String signer;

  /// Short issuer handle for the mono-cap chip
  /// (e.g. `EUR-CONSULATE`).
  final String signerHandle;

  /// Builds a deterministic attestation from a credential id +
  /// status string. Used by the demo / vault surfaces. The id seeds
  /// the block height; the status string drives [revoked] /
  /// [verified].
  factory CredentialAttestation.derive({
    required String credentialId,
    required String credentialStatus,
    String signer = 'GlobeID Atelier',
    String signerHandle = 'GID-ATELIER',
  }) {
    final seed = credentialId.hashCode.abs();
    // Stable, demo-friendly block heights in the 12 000 000 –
    // 13 000 000 range (mirrors current Ethereum mainnet scale).
    final block = 12000000 + (seed % 1000000);
    final lower = credentialStatus.toLowerCase();
    final revoked = lower.contains('revok') || lower.contains('expired');
    final verified = !revoked &&
        (lower.contains('valid') ||
            lower.contains('active') ||
            lower.contains('current') ||
            lower.contains('issued'));
    return CredentialAttestation(
      verified: verified,
      revoked: revoked,
      blockHeight: block,
      signer: signer,
      signerHandle: signerHandle,
    );
  }
}

/// `CredentialAttestationFooter` — the mono-cap "this credential is
/// real and not revoked" hairline strip that sits underneath every
/// credential card in the Vault.
///
/// Composes existing GlobeID primitives:
///   • [NfcPulse] for the alive verification glyph
///   • [Os2Text.monoCap] for the chip rail
///   • Gold hairline rule above the strip
///   • Tone keyed to verified / revoked / pending state
///
/// The whole strip is non-interactive — it's a passive attestation
/// readout, not a button.
class CredentialAttestationFooter extends StatelessWidget {
  const CredentialAttestationFooter({
    super.key,
    required this.attestation,
    this.dense = false,
  });

  final CredentialAttestation attestation;

  /// When true, the footer collapses inner vertical padding for use
  /// inside tight cards.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tone = _tone();
    final stateLabel = _stateLabel();
    final blockText =
        'BLOCK ${_formatBlock(attestation.blockHeight)}';
    final v = dense ? Os2.space2 : Os2.space3;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Champagne hairline above the chip strip — ties the
          // attestation to the GlobeID gold thread.
          Container(
            height: Os2.strokeFine,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00D4AF37),
                  Os2.goldHairline,
                  Color(0x00D4AF37),
                ],
              ),
            ),
          ),
          SizedBox(height: dense ? Os2.space2 : Os2.space3),
          Row(
            children: [
              _AttestationGlyph(tone: tone, alive: !attestation.revoked),
              const SizedBox(width: Os2.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Os2.space2,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Chip(label: stateLabel, tone: tone, filled: true),
                        _Chip(
                          label: blockText,
                          tone: Os2.inkMid,
                        ),
                        _Chip(
                          label: attestation.signerHandle,
                          tone: Os2.inkMid,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Os2Text.monoCap(
                      'SIGNED BY  ${attestation.signer.toUpperCase()}',
                      color: Os2.inkLow,
                      size: Os2.textTiny,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _tone() {
    if (attestation.revoked) return const Color(0xFFE11D48);
    if (attestation.verified) return Os2.goldDeep;
    return Os2.inkMid;
  }

  String _stateLabel() {
    if (attestation.revoked) return 'REVOKED';
    if (attestation.verified) return 'VERIFIED · NOT REVOKED';
    return 'PENDING ATTESTATION';
  }

  static String _formatBlock(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _AttestationGlyph extends StatelessWidget {
  const _AttestationGlyph({required this.tone, required this.alive});
  final Color tone;
  final bool alive;
  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: 0.14),
        border: Border.all(color: tone.withValues(alpha: 0.42)),
      ),
      child: Icon(
        alive
            ? Icons.verified_rounded
            : Icons.warning_amber_rounded,
        size: 14,
        color: tone,
      ),
    );
    if (!alive) return inner;
    return NfcPulse(
      tone: tone,
      size: 36,
      rings: 2,
      maxAlpha: 0.36,
      period: const Duration(milliseconds: 1600),
      child: inner,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.tone,
    this.filled = false,
  });
  final String label;
  final Color tone;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: filled ? 0.16 : 0.0),
        borderRadius: BorderRadius.circular(Os2.rChip),
        border: Border.all(
          color: tone.withValues(alpha: filled ? 0.42 : 0.24),
        ),
      ),
      child: Os2Text.monoCap(
        label,
        color: tone,
        size: Os2.textTiny,
      ),
    );
  }
}
