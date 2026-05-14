import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../models/brand_dna_timeline.dart';

/// Phase 14e — Brand DNA timeline.
///
/// Authoritative phase history surfaced in-app. Each chapter is a
/// shipped brand decision: title, headline, summary, invariant.
/// Append-only — existing chapters are the record.
class DnaTimelineScreen extends StatelessWidget {
  const DnaTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'ATELIER · 14E',
      title: 'Brand DNA Timeline',
      subtitle:
          '${BrandDnaTimeline.chapters.length} chapters · append-only',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _TimelineIntro(),
          const SizedBox(height: Os2.space5),
          for (var i = 0; i < BrandDnaTimeline.chapters.length; i++) ...[
            _ChapterRow(
              chapter: BrandDnaTimeline.chapters[i],
              isFirst: i == 0,
              isLast: i == BrandDnaTimeline.chapters.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineIntro extends StatelessWidget {
  const _TimelineIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                'DNA · TIMELINE',
                color: const Color(0xFFD4AF37),
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'N° 14E.00',
                color: Colors.white.withValues(alpha: 0.42),
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          const Text(
            'Authoritative history of every brand decision',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: Os2.space2),
          Text(
            'Each phase shipped a chapter. Each chapter codified a '
            'brand invariant. The timeline is append-only — '
            'existing chapters are the record, not a draft.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.isFirst,
    required this.isLast,
  });

  final DnaChapter chapter;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Os2.space3),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rail with dot.
            _Rail(
              tone: chapter.tone,
              isFirst: isFirst,
              isLast: isLast,
            ),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: _ChapterCard(chapter: chapter),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.tone,
    required this.isFirst,
    required this.isLast,
  });

  final Color tone;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      child: Column(
        children: [
          // Top extension.
          Expanded(
            child: Container(
              width: 1,
              color: isFirst
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          // Dot.
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              shape: BoxShape.circle,
              border: Border.all(
                color: tone,
                width: 1.4,
              ),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Bottom extension.
          Expanded(
            child: Container(
              width: 1,
              color: isLast
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter});
  final DnaChapter chapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: chapter.tone.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                chapter.phaseLabel,
                color: chapter.tone,
                size: Os2.textTiny,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Text(
            chapter.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: Os2.space1),
          Text(
            chapter.headline,
            style: TextStyle(
              color: chapter.tone,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              height: 1.35,
            ),
          ),
          const SizedBox(height: Os2.space3),
          Text(
            chapter.summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: Os2.space3),
          Container(
            padding: const EdgeInsets.all(Os2.space3),
            decoration: BoxDecoration(
              color: chapter.tone.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Os2.rTile),
              border: Border.all(
                color: chapter.tone.withValues(alpha: 0.42),
                width: 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Os2Text.monoCap(
                  'INVARIANT',
                  color: chapter.tone,
                  size: Os2.textTiny,
                ),
                const SizedBox(height: Os2.space1),
                Text(
                  chapter.brandInvariant,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
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
