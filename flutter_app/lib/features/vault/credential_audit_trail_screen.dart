import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../cinematic/identity/credential_access_event.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Audit trail viewer — opens from a credential detail. Renders
/// the disclosure ledger (who saw the credential, when, what was
/// revealed, what changed) in reverse-chronological order.
///
/// Apple Wallet has no audit trail. GlobeID surfaces every prior
/// disclosure to its bearer so they can spot a pattern, file a
/// dispute, or revoke an audience.
class CredentialAuditTrailScreen extends StatefulWidget {
  const CredentialAuditTrailScreen({
    super.key,
    required this.credentialId,
    required this.credentialLabel,
  });

  final String credentialId;
  final String credentialLabel;

  @override
  State<CredentialAuditTrailScreen> createState() =>
      _CredentialAuditTrailScreenState();
}

class _CredentialAuditTrailScreenState
    extends State<CredentialAuditTrailScreen> {
  String? _audienceFilter; // null = all audiences
  AccessOutcome? _outcomeFilter;

  late final List<CredentialAccessEvent> _events =
      seedAccessEvents(credentialId: widget.credentialId);

  List<CredentialAccessEvent> get _filtered {
    return _events.where((e) {
      if (_audienceFilter != null && e.audienceHandle != _audienceFilter) {
        return false;
      }
      if (_outcomeFilter != null && e.outcome != _outcomeFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Set<String> get _knownAudiences =>
      _events.map((e) => e.audienceHandle).toSet();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return PageScaffold(
      title: 'Audit trail',
      subtitle: widget.credentialLabel,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _SummaryStrip(events: _events),
          const SizedBox(height: Os2.space5),
          _FilterRail(
            audiences: _knownAudiences.toList()..sort(),
            selectedAudience: _audienceFilter,
            onAudience: (next) {
              HapticFeedback.selectionClick();
              setState(() => _audienceFilter = next);
            },
            selectedOutcome: _outcomeFilter,
            onOutcome: (next) {
              HapticFeedback.selectionClick();
              setState(() => _outcomeFilter = next);
            },
          ),
          const SizedBox(height: Os2.space5),
          Os2Text.monoCap(
            'LEDGER · ${filtered.length} ENTRIES',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          if (filtered.isEmpty)
            const _EmptyRow()
          else
            for (final event in filtered) ...[
              _EventCard(event: event),
              const SizedBox(height: Os2.space3),
            ],
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.events});
  final List<CredentialAccessEvent> events;
  @override
  Widget build(BuildContext context) {
    final reveals = events
        .where((e) => e.action == AccessAction.revealed)
        .length;
    final scans = events
        .where((e) => e.action == AccessAction.scanned)
        .length;
    final declines = events
        .where((e) => e.outcome == AccessOutcome.declined)
        .length;
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Row(
        children: [
          Expanded(child: _Stat(label: 'REVEALS', value: '$reveals')),
          Container(width: 1, height: 40, color: Os2.hairline),
          Expanded(child: _Stat(label: 'SCANS', value: '$scans')),
          Container(width: 1, height: 40, color: Os2.hairline),
          Expanded(
            child: _Stat(
              label: 'DECLINES',
              value: '$declines',
              valueTone: declines > 0 ? const Color(0xFFE05A52) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.valueTone});
  final String label;
  final String value;
  final Color? valueTone;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Os2Text.credential(
          value,
          color: valueTone ?? Os2.inkBright,
          size: 28,
        ),
        const SizedBox(height: 2),
        Os2Text.monoCap(
          label,
          color: Os2.inkLow,
          size: Os2.textTiny,
        ),
      ],
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.audiences,
    required this.selectedAudience,
    required this.onAudience,
    required this.selectedOutcome,
    required this.onOutcome,
  });
  final List<String> audiences;
  final String? selectedAudience;
  final ValueChanged<String?> onAudience;
  final AccessOutcome? selectedOutcome;
  final ValueChanged<AccessOutcome?> onOutcome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.monoCap(
          'FILTER · AUDIENCE',
          color: Os2.inkLow,
          size: Os2.textTiny,
        ),
        const SizedBox(height: Os2.space2),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _Chip(
                label: 'ALL',
                selected: selectedAudience == null,
                onTap: () => onAudience(null),
              ),
              const SizedBox(width: Os2.space2),
              for (final aud in audiences) ...[
                _Chip(
                  label: aud,
                  selected: selectedAudience == aud,
                  onTap: () =>
                      onAudience(selectedAudience == aud ? null : aud),
                ),
                const SizedBox(width: Os2.space2),
              ],
            ],
          ),
        ),
        const SizedBox(height: Os2.space3),
        Os2Text.monoCap(
          'FILTER · OUTCOME',
          color: Os2.inkLow,
          size: Os2.textTiny,
        ),
        const SizedBox(height: Os2.space2),
        Wrap(
          spacing: Os2.space2,
          runSpacing: Os2.space2,
          children: [
            _Chip(
              label: 'ALL',
              selected: selectedOutcome == null,
              onTap: () => onOutcome(null),
            ),
            for (final outcome in AccessOutcome.values)
              _Chip(
                label: outcome.handle,
                selected: selectedOutcome == outcome,
                onTap: () => onOutcome(
                  selectedOutcome == outcome ? null : outcome,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Filter $label',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Os2.space3,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Os2.goldDeep.withValues(alpha: 0.18)
              : Os2.floor1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Os2.goldDeep.withValues(alpha: 0.62)
                : Os2.hairline,
          ),
        ),
        child: Os2Text.monoCap(
          label,
          color: selected ? Os2.goldDeep : Os2.inkMid,
          size: Os2.textTiny,
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final CredentialAccessEvent event;
  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(event);
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
          Wrap(
            spacing: Os2.space2,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ActionDot(tone: tone),
              Os2Text.monoCap(
                event.action.handle,
                color: tone,
                size: Os2.textTiny,
              ),
              Os2Text.monoCap(
                '· ${event.audienceHandle}',
                color: Os2.inkLow,
                size: Os2.textTiny,
              ),
              Os2Text.monoCap(
                '· ${relativeAge(event.timestamp)}',
                color: Os2.inkLow,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.title(
            event.audienceLabel,
            color: Os2.inkBright,
            size: Os2.textRg,
            maxLines: 1,
          ),
          if (event.location != null) ...[
            const SizedBox(height: 2),
            Os2Text.monoCap(
              event.location!.toUpperCase(),
              color: Os2.inkLow,
              size: Os2.textTiny,
            ),
          ],
          if (event.fieldHandles.isNotEmpty) ...[
            const SizedBox(height: Os2.space3),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final h in event.fieldHandles)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Os2.floor2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Os2.hairline),
                    ),
                    child: Os2Text.monoCap(
                      h,
                      color: Os2.inkMid,
                      size: Os2.textTiny,
                    ),
                  ),
              ],
            ),
          ],
          if (event.deltaTrust != 0) ...[
            const SizedBox(height: Os2.space3),
            Os2Text.monoCap(
              event.deltaTrust > 0
                  ? 'TRUST · +${event.deltaTrust}'
                  : 'TRUST · ${event.deltaTrust}',
              color: event.deltaTrust > 0
                  ? const Color(0xFF10B981)
                  : const Color(0xFFE05A52),
              size: Os2.textTiny,
            ),
          ],
        ],
      ),
    );
  }

  Color _toneFor(CredentialAccessEvent e) {
    switch (e.action) {
      case AccessAction.revealed:
        return Os2.goldDeep;
      case AccessAction.scanned:
        return const Color(0xFF6B8FB8); // signal steel
      case AccessAction.verified:
        return const Color(0xFF10B981); // emerald
      case AccessAction.declined:
        return const Color(0xFFE05A52); // crimson
      case AccessAction.exported:
        return Os2.goldLight;
    }
  }
}

class _ActionDot extends StatelessWidget {
  const _ActionDot({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.86),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space5),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Center(
        child: Os2Text.monoCap(
          'NO ENTRIES MATCH FILTER',
          color: Os2.inkLow,
          size: Os2.textTiny,
        ),
      ),
    );
  }
}
