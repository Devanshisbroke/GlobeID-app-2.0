import 'package:flutter/material.dart';

import '../../motion/motion_tokens.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';
import '../models/motion_catalog.dart';

/// Phase 14b — Motion choreography lab.
///
/// Live preview of every named [Motion] duration + curve. Each row
/// fires a synchronized preview (a hairline puck that travels left
/// → right with the duration + curve under test). The operator
/// sees the actual timing on screen, not just the milliseconds.
class MotionLabScreen extends StatefulWidget {
  const MotionLabScreen({super.key});

  @override
  State<MotionLabScreen> createState() => _MotionLabScreenState();
}

class _MotionLabScreenState extends State<MotionLabScreen> {
  // The currently-previewing entry. When set, the preview slot
  // animates from 0 → 1 with the configured duration / curve, then
  // resets after a short hold.
  String? _activeId;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'ATELIER · 14B',
      title: 'Motion Choreography',
      subtitle: '10 durations · 6 curves · live preview',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _MotionIntro(),
          const SizedBox(height: Os2.space5),
          _SectionHeader(
            label: 'DURATIONS · 10',
            tone: const Color(0xFFD4AF37),
          ),
          const SizedBox(height: Os2.space2),
          for (final d in MotionCatalog.durations) ...[
            _DurationCard(
              entry: d,
              active: _activeId == d.id,
              onPreview: () => _preview(d.id),
            ),
            const SizedBox(height: Os2.space2),
          ],
          const SizedBox(height: Os2.space5),
          _SectionHeader(
            label: 'CURVES · 6',
            tone: const Color(0xFF6B8FB8),
          ),
          const SizedBox(height: Os2.space2),
          for (final c in MotionCatalog.curves) ...[
            _CurveCard(
              entry: c,
              active: _activeId == c.id,
              onPreview: () => _preview(c.id, fixedDuration: Motion.dCruise),
            ),
            const SizedBox(height: Os2.space2),
          ],
        ],
      ),
    );
  }

  Future<void> _preview(String id, {Duration? fixedDuration}) async {
    final d = MotionCatalog.durationById(id)?.duration ??
        fixedDuration ??
        Motion.dCruise;
    setState(() => _activeId = id);
    // Hold the active state for the duration of the animation, then
    // give the eye a 200 ms breath before clearing so the user sees
    // the puck land before it resets.
    await Future<void>.delayed(d + const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _activeId = null);
  }
}

class _MotionIntro extends StatelessWidget {
  const _MotionIntro();

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
                'MOTION · MANIFEST',
                color: const Color(0xFFD4AF37),
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'N° 14B.00',
                color: Colors.white.withValues(alpha: 0.42),
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          const Text(
            'Every duration + curve, previewable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: Os2.space2),
          Text(
            'Tap PREVIEW on any row to fire the timing under test. A '
            'hairline puck travels left → right with the configured '
            'duration + curve so you see the actual feel, not just '
            'the numbers.',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.tone});
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: tone,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: tone.withValues(alpha: 0.62),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        Os2Text.monoCap(label, color: tone, size: Os2.textTiny),
      ],
    );
  }
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({
    required this.entry,
    required this.active,
    required this.onPreview,
  });

  final MotionDurationEntry entry;
  final bool active;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: active ? 0.62 : 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.62),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  entry.readable,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Text(
            entry.role,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Os2.space2),
          _PreviewTrack(
            active: active,
            duration: entry.duration,
            curve: Motion.cStandard,
            tone: const Color(0xFFD4AF37),
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.usage,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: Os2.space2),
              Pressable(
                onTap: onPreview,
                semanticLabel: 'Preview ${entry.name}',
                semanticHint: 'fires the duration under test',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.62),
                      width: 0.6,
                    ),
                  ),
                  child: Os2Text.monoCap(
                    'PREVIEW',
                    color: const Color(0xFFD4AF37),
                    size: Os2.textTiny,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurveCard extends StatelessWidget {
  const _CurveCard({
    required this.entry,
    required this.active,
    required this.onPreview,
  });

  final MotionCurveEntry entry;
  final bool active;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFF6B8FB8).withValues(alpha: active ? 0.62 : 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8FB8).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF6B8FB8).withValues(alpha: 0.62),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  entry.formula,
                  style: const TextStyle(
                    color: Color(0xFF6B8FB8),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Text(
            entry.role,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Os2.space2),
          _PreviewTrack(
            active: active,
            duration: Motion.dCruise,
            curve: entry.curve,
            tone: const Color(0xFF6B8FB8),
          ),
          const SizedBox(height: Os2.space2),
          Align(
            alignment: Alignment.centerRight,
            child: Pressable(
              onTap: onPreview,
              semanticLabel: 'Preview ${entry.name}',
              semanticHint: 'fires the curve under test',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8FB8).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6B8FB8).withValues(alpha: 0.62),
                    width: 0.6,
                  ),
                ),
                child: Os2Text.monoCap(
                  'PREVIEW',
                  color: const Color(0xFF6B8FB8),
                  size: Os2.textTiny,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline puck that travels left → right when [active] flips true.
class _PreviewTrack extends StatelessWidget {
  const _PreviewTrack({
    required this.active,
    required this.duration,
    required this.curve,
    required this.tone,
  });

  final bool active;
  final Duration duration;
  final Curve curve;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Container(
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              children: [
                AnimatedAlign(
                  alignment: active
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  duration: duration,
                  curve: curve,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: tone,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tone.withValues(alpha: 0.62),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
