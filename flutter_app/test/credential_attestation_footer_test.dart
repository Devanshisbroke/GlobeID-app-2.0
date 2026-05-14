import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/cinematic/identity/credential_attestation_footer.dart';

void main() {
  group('CredentialAttestation.derive', () {
    test('valid status maps to verified, not revoked', () {
      final a = CredentialAttestation.derive(
        credentialId: 'doc_passport_us_001',
        credentialStatus: 'Active · Valid',
      );
      expect(a.verified, isTrue);
      expect(a.revoked, isFalse);
    });

    test('revoked status takes precedence over valid', () {
      final a = CredentialAttestation.derive(
        credentialId: 'doc_visa_xyz',
        credentialStatus: 'Revoked by issuer',
      );
      expect(a.verified, isFalse);
      expect(a.revoked, isTrue);
    });

    test('expired status is treated as revoked', () {
      final a = CredentialAttestation.derive(
        credentialId: 'doc_old',
        credentialStatus: 'Expired',
      );
      expect(a.revoked, isTrue);
      expect(a.verified, isFalse);
    });

    test('pending status leaves verified false but not revoked', () {
      final a = CredentialAttestation.derive(
        credentialId: 'doc_pending',
        credentialStatus: 'Pending review',
      );
      expect(a.verified, isFalse);
      expect(a.revoked, isFalse);
    });

    test('block height is deterministic for the same id', () {
      final a = CredentialAttestation.derive(
        credentialId: 'doc_stable',
        credentialStatus: 'Active',
      );
      final b = CredentialAttestation.derive(
        credentialId: 'doc_stable',
        credentialStatus: 'Active',
      );
      expect(a.blockHeight, b.blockHeight);
      expect(a.blockHeight, greaterThanOrEqualTo(12000000));
      expect(a.blockHeight, lessThan(13000000));
    });

    test('block height differs for different ids', () {
      final a = CredentialAttestation.derive(
        credentialId: 'doc_a',
        credentialStatus: 'Active',
      );
      final b = CredentialAttestation.derive(
        credentialId: 'doc_b',
        credentialStatus: 'Active',
      );
      expect(a.blockHeight, isNot(b.blockHeight));
    });
  });

  group('CredentialAttestationFooter — rendering', () {
    testWidgets('verified credential renders VERIFIED · NOT REVOKED chip',
        (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CredentialAttestationFooter(
              attestation: CredentialAttestation.derive(
                credentialId: 'doc_x',
                credentialStatus: 'Active · Valid',
                signer: 'Republic of Schengen',
                signerHandle: 'EUR-CONSULATE',
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('VERIFIED · NOT REVOKED'), findsOneWidget);
      expect(find.text('EUR-CONSULATE'), findsOneWidget);
      // Signer line carries the issuer name in uppercase.
      expect(
        find.textContaining('SIGNED BY  REPUBLIC OF SCHENGEN'),
        findsOneWidget,
      );
      // Block chip is formatted as BLOCK ##,###,###.
      expect(find.textContaining('BLOCK '), findsOneWidget);
    });

    testWidgets('revoked credential renders REVOKED chip', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CredentialAttestationFooter(
              attestation: CredentialAttestation.derive(
                credentialId: 'doc_revoked',
                credentialStatus: 'Revoked',
                signer: 'GlobeID Atelier',
                signerHandle: 'GID-ATELIER',
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('REVOKED'), findsOneWidget);
    });

    testWidgets('pending credential renders PENDING ATTESTATION chip',
        (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CredentialAttestationFooter(
              attestation: CredentialAttestation.derive(
                credentialId: 'doc_pending',
                credentialStatus: 'Pending',
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('PENDING ATTESTATION'), findsOneWidget);
    });
  });
}
