import 'package:flutter/material.dart';

import '../../i18n/brand_direction.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// Phase 13b — RTL audit lab.
///
/// Side-by-side LTR vs RTL preview of four hot GlobeID surfaces
/// (wallet pass, trip card, visa receipt, credential signet). Every
/// row exercises the BrandLtr / MirrorAware primitives so the
/// operator can verify that brand chrome (watermark, case number,
/// mono-cap eyebrows) renders identically under both directions.
class RtlAuditScreen extends StatelessWidget {
  const RtlAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'PHASE · 13B',
      title: 'RTL audit',
      subtitle: 'Body copy mirrors · brand chrome stays Latin LTR',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _AuditRow(
            label: 'WALLET · PASS',
            ltrTitle: 'Boarding · BER → LIS',
            rtlTitle: 'صعود · BER → LIS',
            ltrSub: 'GATE B22 · SEAT 12A',
            rtlSub: 'البوابة B22 · المقعد 12A',
            tone: Color(0xFFD4AF37),
          ),
          const SizedBox(height: Os2.space3),
          const _AuditRow(
            label: 'TRIP · CARD',
            ltrTitle: 'Trip · 6 days',
            rtlTitle: 'رحلة · 6 أيام',
            ltrSub: 'BERLIN → LISBON',
            rtlSub: 'برلين → لشبونة',
            tone: Color(0xFFE9C75D),
          ),
          const SizedBox(height: Os2.space3),
          const _AuditRow(
            label: 'VISA · RECEIPT',
            ltrTitle: 'Visa granted',
            rtlTitle: 'تأشيرة مَنحت',
            ltrSub: 'Japan · 90 days',
            rtlSub: 'اليابان · 90 يوم',
            tone: Color(0xFF3FB68B),
          ),
          const SizedBox(height: Os2.space3),
          const _AuditRow(
            label: 'CREDENTIAL · SIGNET',
            ltrTitle: 'IATA member',
            rtlTitle: 'عضو IATA',
            ltrSub: 'Cabin crew · 7 years',
            rtlSub: 'طاقم الطائرة · 7 سنوات',
            tone: Color(0xFFC9A961),
          ),
          const SizedBox(height: Os2.space6),
          _InvariantsCard(),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({
    required this.label,
    required this.ltrTitle,
    required this.rtlTitle,
    required this.ltrSub,
    required this.rtlSub,
    required this.tone,
  });
  final String label;
  final String ltrTitle;
  final String rtlTitle;
  final String ltrSub;
  final String rtlSub;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.monoCap(label, color: tone, size: Os2.textTiny),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PassPreview(
                direction: TextDirection.ltr,
                title: ltrTitle,
                sub: ltrSub,
                tone: tone,
                caseNumber: 'N° LTR-${label.split(' ').first.substring(0, 3)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PassPreview(
                direction: TextDirection.rtl,
                title: rtlTitle,
                sub: rtlSub,
                tone: tone,
                caseNumber: 'N° RTL-${label.split(' ').first.substring(0, 3)}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PassPreview extends StatelessWidget {
  const _PassPreview({
    required this.direction,
    required this.title,
    required this.sub,
    required this.tone,
    required this.caseNumber,
  });
  final TextDirection direction;
  final String title;
  final String sub;
  final Color tone;
  final String caseNumber;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rChip),
          border: Border.all(color: tone.withValues(alpha: 0.42)),
          boxShadow: [
            BoxShadow(
              color: tone.withValues(alpha: 0.08),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — BrandLtr forces LTR Latin for watermark
            // even when the parent is RTL.
            BrandLtr(
              child: Row(
                children: [
                  Os2Text.monoCap(
                    'GLOBE · ID',
                    color: tone,
                    size: Os2.textTiny,
                  ),
                  const Spacer(),
                  Os2Text.monoCap(
                    direction == TextDirection.rtl ? 'RTL' : 'LTR',
                    color: Colors.white.withValues(alpha: 0.42),
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                MirrorAware(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: tone,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: BrandLtr(
                    child: Os2Text.monoCap(
                      caseNumber,
                      color: tone.withValues(alpha: 0.78),
                      size: Os2.textTiny,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvariantsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'RTL · INVARIANTS',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          const _Pair(
            label: 'WATERMARK',
            value: 'GLOBE · ID — locked LTR via BrandLtr',
          ),
          const _Pair(
            label: 'CASE · N°',
            value: 'Latin LTR even under Arabic — BrandLtr',
          ),
          const _Pair(
            label: 'EYEBROW',
            value: 'Mono-cap Latin — BrandLtr',
          ),
          const _Pair(
            label: 'ARROW · CTA',
            value: 'Mirrored under RTL via MirrorAware',
          ),
          const _Pair(
            label: 'HAIRLINE',
            value: 'Symmetric — direction-agnostic',
          ),
          const _Pair(
            label: 'FOIL · TONE',
            value: '#D4AF37 → #E9C75D, locale-invariant',
          ),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Os2Text.monoCap(
              label,
              color: Colors.white.withValues(alpha: 0.42),
              size: Os2.textTiny,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
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
