import 'package:flutter/material.dart';

import '../../i18n/brand_text_scale.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// Phase 13c — Dynamic Type / text scaling audit lab.
///
/// Renders the same GlobeID surface at 100% / 130% / 150% / 200% so
/// the operator can verify that body copy scales while brand chrome
/// stays trademark-stable. Each preview is rendered inside its own
/// MediaQuery override to simulate the iOS Larger Text setting.
class DynamicTypeAuditScreen extends StatelessWidget {
  const DynamicTypeAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'PHASE · 13C',
      title: 'Dynamic Type audit',
      subtitle: 'Body scales · brand chrome capped at 1.35×',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: const [
          _ScalePreview(label: '100%', scale: 1.0),
          SizedBox(height: Os2.space3),
          _ScalePreview(label: '130%', scale: 1.3),
          SizedBox(height: Os2.space3),
          _ScalePreview(label: '150%', scale: 1.5),
          SizedBox(height: Os2.space3),
          _ScalePreview(label: '200%', scale: 2.0),
          SizedBox(height: Os2.space6),
          _PolicyCard(),
        ],
      ),
    );
  }
}

class _ScalePreview extends StatelessWidget {
  const _ScalePreview({required this.label, required this.scale});
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final scaler = TextScaler.linear(scale);
    final mq = MediaQuery.of(context).copyWith(textScaler: scaler);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Os2Text.monoCap(
              'SCALE · $label',
              color: const Color(0xFFD4AF37),
              size: Os2.textTiny,
            ),
            const SizedBox(width: 8),
            _Chip(text: 'BODY', tone: const Color(0xFFE9C75D)),
            const SizedBox(width: 4),
            _Chip(
              text: scale > BrandTextScale.chromeCap
                  ? 'CHROME CAPPED'
                  : 'CHROME ${(scale * 100).round()}%',
              tone: scale > BrandTextScale.chromeCap
                  ? const Color(0xFF6B8FB8)
                  : Colors.white.withValues(alpha: 0.42),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MediaQuery(
          data: mq,
          child: const _MockCredential(),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.tone});
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tone.withValues(alpha: 0.46), width: 0.6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// Mock GlobeID credential — body copy + brand chrome + credential
/// statistic. Each is wrapped in the right scale primitive so the
/// audit screen demonstrates the policy.
class _MockCredential extends StatelessWidget {
  const _MockCredential();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand chrome — capped via ChromeTextScale.
          ChromeTextScale(
            child: Row(
              children: [
                Os2Text.monoCap(
                  'GLOBE · ID · PASS',
                  color: const Color(0xFFD4AF37),
                  size: Os2.textTiny,
                ),
                const Spacer(),
                Os2Text.monoCap(
                  'N° 7F4A9B23',
                  color: Colors.white.withValues(alpha: 0.42),
                  size: Os2.textTiny,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Body — uncapped, full respect for textScaler.
          const Text(
            'Boarding · BER → LIS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Gate B22 · Seat 12A · Boarding 14:32',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // Credential statistic — capped via CredentialTextScale.
          CredentialTextScale(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '847',
                  style: TextStyle(
                    color: const Color(0xFFE9C75D),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 0.95,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'TRUST',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'TYPE · POLICY',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          const _PolicyRow(
            role: 'BODY',
            cap: 'NONE',
            note: 'Display / headline / title / body / label scale freely',
          ),
          const _PolicyRow(
            role: 'CHROME',
            cap: '1.35×',
            note: 'Mono-cap watermark, eyebrow, case N° stay trademark-readable',
          ),
          const _PolicyRow(
            role: 'CREDENTIAL',
            cap: '1.20×',
            note: 'Trust score, queue %, balance preserve hierarchy weight',
          ),
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.role, required this.cap, required this.note});
  final String role;
  final String cap;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Os2Text.monoCap(
              role,
              color: const Color(0xFFE9C75D),
              size: Os2.textTiny,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              cap,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
