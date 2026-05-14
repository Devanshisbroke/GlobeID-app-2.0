import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../motion/motion.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/pressable.dart';
import '../sheets/apple_sheet.dart';
import 'selective_disclosure.dart';

/// Opens the Selective Disclosure sheet for a credential.
///
/// Returns the (possibly modified) policy when the bearer commits,
/// or `null` if they dismiss the sheet.
Future<DisclosurePolicy?> showSelectiveDisclosureSheet({
  required BuildContext context,
  required DisclosurePolicy initial,
  required String credentialLabel,
}) {
  return showAppleSheet<DisclosurePolicy>(
    context: context,
    eyebrow: 'IDENTITY · DISCLOSURE',
    title: credentialLabel,
    tone: Os2.goldDeep,
    detents: const [0.55, 0.92],
    builder: (controller) => _SelectiveDisclosureBody(
      initial: initial,
      controller: controller,
    ),
  );
}

class _SelectiveDisclosureBody extends StatefulWidget {
  const _SelectiveDisclosureBody({
    required this.initial,
    required this.controller,
  });
  final DisclosurePolicy initial;
  final ScrollController controller;

  @override
  State<_SelectiveDisclosureBody> createState() =>
      _SelectiveDisclosureBodyState();
}

class _SelectiveDisclosureBodyState
    extends State<_SelectiveDisclosureBody> {
  late DisclosurePolicy _policy = widget.initial;
  DisclosureAudience _audience = DisclosureAudience.airline;

  @override
  Widget build(BuildContext context) {
    final revealed = _policy.revealedCount(_audience);
    final total = DisclosurePolicy.totalFields;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Os2.space5,
              0,
              Os2.space5,
              Os2.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AudienceRail(
                  selected: _audience,
                  onSelected: (a) {
                    Haptics.tap();
                    setState(() => _audience = a);
                  },
                  policy: _policy,
                ),
                const SizedBox(height: Os2.space3),
                _RevealCounter(revealed: revealed, total: total),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: widget.controller,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                Os2.space5,
                Os2.space2,
                Os2.space5,
                Os2.space5,
              ),
              itemCount: DisclosureField.values.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: Os2.space2),
              itemBuilder: (context, i) {
                final field = DisclosureField.values[i];
                final visible = _policy.isVisible(_audience, field);
                return _FieldRow(
                  field: field,
                  visible: visible,
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _policy = _policy.toggle(_audience, field);
                    });
                  },
                );
              },
            ),
          ),
          _Footer(
            onLockSensitive: () {
              Haptics.tap();
              setState(() => _policy = _policy.lockSensitive());
            },
            onCommit: () {
              Haptics.signature();
              Navigator.of(context).pop(_policy);
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Audience rail
// ─────────────────────────────────────────────────────────────────

class _AudienceRail extends StatelessWidget {
  const _AudienceRail({
    required this.selected,
    required this.onSelected,
    required this.policy,
  });
  final DisclosureAudience selected;
  final ValueChanged<DisclosureAudience> onSelected;
  final DisclosurePolicy policy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: DisclosureAudience.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: Os2.space2),
        itemBuilder: (context, i) {
          final a = DisclosureAudience.values[i];
          final isSelected = a == selected;
          final revealed = policy.revealedCount(a);
          return Pressable(
            scale: 0.96,
            semanticLabel: 'Select ${a.label} audience',
            semanticHint:
                '$revealed of ${DisclosurePolicy.totalFields} '
                'fields revealed',
            onTap: () => onSelected(a),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Os2.space3,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Os2.goldDeep.withValues(alpha: 0.18)
                    : Os2.floor2,
                borderRadius: BorderRadius.circular(Os2.rChip),
                border: Border.all(
                  color: isSelected
                      ? Os2.goldDeep.withValues(alpha: 0.46)
                      : Os2.hairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Os2Text.monoCap(
                    a.handle,
                    color: isSelected ? Os2.goldDeep : Os2.inkHigh,
                    size: Os2.textTiny,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius:
                          BorderRadius.circular(Os2.rChip),
                      color: isSelected
                          ? Os2.goldDeep
                          : Os2.inkMid.withValues(alpha: 0.30),
                    ),
                    child: Text(
                      '$revealed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Os2.canvas
                            : Os2.canvas,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RevealCounter extends StatelessWidget {
  const _RevealCounter({required this.revealed, required this.total});
  final int revealed;
  final int total;
  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : revealed / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Os2Text.monoCap(
              'REVEALING  $revealed / $total',
              color: Os2.goldDeep,
              size: Os2.textTiny,
            ),
            const Spacer(),
            Os2Text.monoCap(
              '${(pct * 100).round()} %',
              color: Os2.inkMid,
              size: Os2.textTiny,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) {
              return Stack(children: [
                Container(
                  height: 3,
                  color: Os2.floor2,
                ),
                FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: Os2.foilGoldHero,
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Field row
// ─────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.visible,
    required this.onToggle,
  });
  final DisclosureField field;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final sTone = sensitivityTone(field);
    final sTag = sensitivityTag(field);
    return Pressable(
      scale: 0.99,
      semanticLabel: '${field.label} ${visible ? 'visible' : 'hidden'}',
      semanticHint: 'tap to toggle visibility',
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Os2.space4,
          vertical: Os2.space3,
        ),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(
            color: visible
                ? Os2.goldDeep.withValues(alpha: 0.34)
                : Os2.hairline,
          ),
        ),
        child: Row(
          children: [
            _SensitivityDot(tone: sTone, alive: visible),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.title(
                    field.label,
                    color: visible ? Os2.inkBright : Os2.inkMid,
                    size: Os2.textRg,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Os2Text.monoCap(
                        field.handle,
                        color: Os2.inkLow,
                        size: Os2.textTiny,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sTone.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(Os2.rChip),
                          border: Border.all(
                            color: sTone.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Os2Text.monoCap(
                          'SENS · $sTag',
                          color: sTone,
                          size: Os2.textTiny,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Toggle(visible: visible),
          ],
        ),
      ),
    );
  }
}

class _SensitivityDot extends StatelessWidget {
  const _SensitivityDot({required this.tone, required this.alive});
  final Color tone;
  final bool alive;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: alive ? 0.16 : 0.06),
        border: Border.all(
          color: tone.withValues(alpha: alive ? 0.42 : 0.18),
        ),
      ),
      child: Icon(
        alive
            ? Icons.visibility_rounded
            : Icons.visibility_off_rounded,
        size: 16,
        color: tone.withValues(alpha: alive ? 1.0 : 0.55),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.visible});
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: visible
            ? Os2.goldDeep.withValues(alpha: 0.86)
            : Os2.floor2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: visible
              ? Os2.goldDeep.withValues(alpha: 0.46)
              : Os2.hairline,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment:
            visible ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: visible ? Os2.canvas : Os2.inkMid,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Footer — quick actions
// ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onLockSensitive,
    required this.onCommit,
  });
  final VoidCallback onLockSensitive;
  final VoidCallback onCommit;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Os2.space5,
        Os2.space3,
        Os2.space5,
        Os2.space5,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Os2.hairline),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              scale: 0.98,
              semanticLabel: 'Lock all sensitive fields',
              semanticHint: 'hides high-sensitivity fields from every audience',
              onTap: onLockSensitive,
              child: Container(
                height: Os2.touchMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Os2.floor2,
                  borderRadius: BorderRadius.circular(Os2.rChip),
                  border: Border.all(color: Os2.hairline),
                ),
                child: const Os2Text.monoCap(
                  'LOCK SENSITIVE',
                  color: Os2.inkHigh,
                  size: Os2.textSm,
                ),
              ),
            ),
          ),
          const SizedBox(width: Os2.space3),
          Expanded(
            flex: 2,
            child: Pressable(
              scale: 0.97,
              semanticLabel: 'Save disclosure policy',
              semanticHint: 'commits this disclosure policy for the credential',
              onTap: onCommit,
              child: Container(
                height: Os2.touchMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: Os2.foilGoldHero,
                  borderRadius: BorderRadius.circular(Os2.rChip),
                ),
                child: const Os2Text.monoCap(
                  'SAVE DISCLOSURE',
                  color: Os2.canvas,
                  size: Os2.textSm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
