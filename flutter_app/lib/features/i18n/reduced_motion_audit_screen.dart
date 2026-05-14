import 'package:flutter/material.dart';

import '../../i18n/brand_motion_policy.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Phase 13d — Reduced motion audit lab.
///
/// Side-by-side comparison of three motion roles (structural /
/// ambient / signature) under the policy. The right column flips
/// reduced motion ON locally via MediaQuery override so the
/// operator can A/B the policy without leaving GlobeID.
class ReducedMotionAuditScreen extends StatefulWidget {
  const ReducedMotionAuditScreen({super.key});

  @override
  State<ReducedMotionAuditScreen> createState() =>
      _ReducedMotionAuditScreenState();
}

class _ReducedMotionAuditScreenState extends State<ReducedMotionAuditScreen> {
  int _seed = 0;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'PHASE · 13D',
      title: 'Reduced motion audit',
      subtitle: 'Structural · ambient · signature each adapt differently',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _RoleRow(
            label: 'STRUCTURAL · PAGE TRANSITION',
            description: 'Reduced → 100 ms crossfade',
            seed: _seed,
            builder: (ctx, key) => _StructuralPreview(seed: _seed, key: key),
            tone: const Color(0xFFD4AF37),
          ),
          const SizedBox(height: Os2.space3),
          _RoleRow(
            label: 'AMBIENT · BREATHING HALO',
            description: 'Reduced → frozen at frame 0',
            seed: _seed,
            builder: (ctx, key) => _AmbientPreview(seed: _seed, key: key),
            tone: const Color(0xFFE9C75D),
          ),
          const SizedBox(height: Os2.space3),
          _RoleRow(
            label: 'SIGNATURE · SEAL COMMIT',
            description: 'Reduced → 50% duration',
            seed: _seed,
            builder: (ctx, key) => _SignaturePreview(seed: _seed, key: key),
            tone: const Color(0xFFC9A961),
          ),
          const SizedBox(height: Os2.space6),
          Pressable(
            semanticLabel: 'Replay all previews',
            onTap: () => setState(() => _seed += 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Os2.rChip),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.62),
                ),
              ),
              alignment: Alignment.center,
              child: Os2Text.monoCap(
                'REPLAY · ALL',
                color: const Color(0xFFD4AF37),
                size: Os2.textXs,
              ),
            ),
          ),
          const SizedBox(height: Os2.space6),
          const _PolicyCard(),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.label,
    required this.description,
    required this.seed,
    required this.builder,
    required this.tone,
  });

  final String label;
  final String description;
  final int seed;
  final Widget Function(BuildContext, Key) builder;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.monoCap(label, color: tone, size: Os2.textTiny),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledColumn(
                label: 'MOTION · ON',
                tone: const Color(0xFFE9C75D),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(disableAnimations: false),
                  child: builder(context, ValueKey('on-$seed')),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LabeledColumn(
                label: 'REDUCED',
                tone: const Color(0xFF6B8FB8),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(disableAnimations: true),
                  child: builder(context, ValueKey('off-$seed')),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabeledColumn extends StatelessWidget {
  const _LabeledColumn({required this.label, required this.child, required this.tone});
  final String label;
  final Widget child;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tone.withValues(alpha: 0.46), width: 0.6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 110, child: child),
      ],
    );
  }
}

class _StructuralPreview extends StatefulWidget {
  const _StructuralPreview({required this.seed, super.key});
  final int seed;

  @override
  State<_StructuralPreview> createState() => _StructuralPreviewState();
}

class _StructuralPreviewState extends State<_StructuralPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = BrandMotionPolicy.adaptDuration(
      context,
      const Duration(milliseconds: 460),
      role: BrandMotionRole.structural,
    );
    _ctrl.duration = duration == Duration.zero
        ? const Duration(milliseconds: 1)
        : duration;
    _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _StructuralPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = BrandMotionPolicy.adaptCurve(context, Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = curve.transform(_ctrl.value);
        return ClipRRect(
          borderRadius: BorderRadius.circular(Os2.rChip),
          child: Stack(
            children: [
              Container(
                color: const Color(0xFF02040A),
                alignment: Alignment.center,
                child: Os2Text.monoCap(
                  'PAGE · A',
                  color: Colors.white.withValues(alpha: 0.32),
                  size: Os2.textTiny,
                ),
              ),
              Transform.translate(
                offset: Offset(0, (1 - t) * 110),
                child: Container(
                  decoration: BoxDecoration(
                    color: Os2.floor1,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.42),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Os2Text.monoCap(
                    'PAGE · B',
                    color: const Color(0xFFD4AF37),
                    size: Os2.textXs,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AmbientPreview extends StatefulWidget {
  const _AmbientPreview({required this.seed, super.key});
  final int seed;

  @override
  State<_AmbientPreview> createState() => _AmbientPreviewState();
}

class _AmbientPreviewState extends State<_AmbientPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use ReducedMotionGate so ambient ornaments don't render at all
    // when reduced motion is active.
    return ReducedMotionGate(
      role: BrandMotionRole.ambient,
      // ignore: sort_child_properties_last
      placeholder: Container(
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rChip),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        alignment: Alignment.center,
        child: Os2Text.monoCap(
          'AMBIENT · OFF',
          color: Colors.white.withValues(alpha: 0.42),
          size: Os2.textTiny,
        ),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final glow = 0.18 + _ctrl.value * 0.46;
          return Container(
            decoration: BoxDecoration(
              color: Os2.floor1,
              borderRadius: BorderRadius.circular(Os2.rChip),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: glow),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: glow * 0.46),
                  blurRadius: 18 + _ctrl.value * 12,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Os2Text.monoCap(
              'BREATHING',
              color: const Color(0xFFD4AF37).withValues(alpha: glow + 0.32),
              size: Os2.textXs,
            ),
          );
        },
      ),
    );
  }
}

class _SignaturePreview extends StatefulWidget {
  const _SignaturePreview({required this.seed, super.key});
  final int seed;

  @override
  State<_SignaturePreview> createState() => _SignaturePreviewState();
}

class _SignaturePreviewState extends State<_SignaturePreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl.duration = BrandMotionPolicy.adaptDuration(
      context,
      const Duration(milliseconds: 1400),
      role: BrandMotionRole.signature,
    );
    _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _SignaturePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final pressed = t < 0.35
            ? (t / 0.35)
            : (t < 0.5
                ? 1.0
                : 1.0 - ((t - 0.5) / 0.5) * 0.04);
        return Container(
          decoration: BoxDecoration(
            color: Os2.floor1,
            borderRadius: BorderRadius.circular(Os2.rChip),
            border: Border.all(
              color: const Color(0xFFC9A961).withValues(alpha: 0.42),
            ),
          ),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: 0.65 + pressed * 0.42,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE9C75D).withValues(alpha: 0.92),
                    const Color(0xFFD4AF37).withValues(alpha: 0.62),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: pressed * 0.62),
                    blurRadius: 18,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Os2Text.monoCap(
                'SEAL',
                color: Colors.black,
                size: Os2.textTiny,
              ),
            ),
          ),
        );
      },
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
            'MOTION · POLICY',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          const _PolicyRow(
            role: 'STRUCTURAL',
            adapt: '100 ms',
            note: 'Page slide, modal slide-up, drawer reveal → crossfade',
          ),
          const _PolicyRow(
            role: 'AMBIENT',
            adapt: 'OFF',
            note: 'Breathing halo, particle drift, foil shimmer, parallax',
          ),
          const _PolicyRow(
            role: 'SIGNATURE',
            adapt: '50%',
            note: 'Seal commit, stamp drop, ink bleed (ceremony preserved)',
          ),
          const _PolicyRow(
            role: 'HAPTICS',
            adapt: 'KEEP',
            note: 'Haptic signatures always preserved (not motion)',
          ),
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.role, required this.adapt, required this.note});
  final String role;
  final String adapt;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Os2Text.monoCap(
              role,
              color: const Color(0xFFE9C75D),
              size: Os2.textTiny,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              adapt,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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
                fontSize: 11,
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
