/// Credential-access event — one row in the per-credential audit
/// trail. Distinct from `AuditEntry` (which tracks app-level
/// security events like vault opens) — these events are the
/// disclosure ledger: every time a credential was *handed over* to
/// an audience, what fields were revealed, and the outcome.
enum AccessAction {
  revealed('REVEALED', 'Bearer revealed fields'),
  scanned('SCANNED', 'Audience NFC-scanned the credential'),
  verified('VERIFIED', 'Attestation chain re-verified'),
  declined('DECLINED', 'Bearer declined the request'),
  exported('EXPORTED', 'Bearer exported a copy');

  const AccessAction(this.handle, this.description);
  final String handle;
  final String description;
}

enum AccessOutcome {
  committed('COMMITTED'),
  declined('DECLINED'),
  pending('PENDING'),
  failed('FAILED');

  const AccessOutcome(this.handle);
  final String handle;
}

class CredentialAccessEvent {
  const CredentialAccessEvent({
    required this.id,
    required this.timestamp,
    required this.audienceHandle,
    required this.audienceLabel,
    required this.action,
    required this.outcome,
    required this.fieldHandles,
    this.location,
    this.deltaTrust = 0,
  });

  final String id;
  final DateTime timestamp;

  /// Mono-cap handle of the audience, e.g. `AIRLINE` / `HOTEL`.
  final String audienceHandle;

  /// Human-readable audience label, e.g. `Lufthansa Frankfurt`.
  final String audienceLabel;

  final AccessAction action;
  final AccessOutcome outcome;

  /// Mono-cap handles of the fields touched, e.g. `['NAME',
  /// 'DOB', 'PASS#']`. Empty for events with no per-field
  /// disclosure (scans, verifications).
  final List<String> fieldHandles;

  /// Optional location string, e.g. `Frankfurt · FRA Terminal 1`.
  final String? location;

  /// Optional change to the bearer's trust score. Positive for
  /// successful + verified interactions, negative for declines.
  final int deltaTrust;
}

/// Deterministic seed of recent access events for a credential id.
/// Same input → same timeline, so the viewer is stable across
/// rebuilds without persistence wired.
List<CredentialAccessEvent> seedAccessEvents({
  required String credentialId,
  int count = 12,
  DateTime? now,
}) {
  final base = now ?? DateTime.now();
  final seed = credentialId.hashCode.abs();

  const audiences = [
    ('AIRLINE', 'Lufthansa · Frankfurt', 'Frankfurt · FRA T1'),
    ('HOTEL', 'Ritz · Paris', 'Paris · 1er'),
    ('CONSULATE', 'JP Consulate · London', 'London · Mayfair'),
    ('BANK', 'HSBC Premier · Singapore', 'Singapore · MBFC'),
    ('IMMIGRATION', 'Norway Border · OSL', 'Oslo · OSL Arrivals'),
  ];

  const actions = [
    AccessAction.revealed,
    AccessAction.scanned,
    AccessAction.verified,
    AccessAction.declined,
  ];

  const fieldGroups = [
    ['NAME', 'PASS#', 'EXP'],
    ['NAME', 'AGE', 'NAT'],
    ['NAME', 'DOB', 'PASS#', 'PHOTO'],
    ['NAME', 'NAT', 'PHOTO'],
    ['NAME', 'PASS#', 'EXP', 'PHOTO', 'NAT'],
    <String>[],
  ];

  final events = <CredentialAccessEvent>[];
  for (var i = 0; i < count; i++) {
    final salt = seed + i * 17;
    final audience = audiences[salt % audiences.length];
    final action = actions[(salt ~/ 3) % actions.length];
    final fields = fieldGroups[salt % fieldGroups.length];
    final hoursBack = i * 7 + (salt % 11);
    final outcome = action == AccessAction.declined
        ? AccessOutcome.declined
        : action == AccessAction.verified || action == AccessAction.scanned
            ? AccessOutcome.committed
            : AccessOutcome.committed;
    final delta = action == AccessAction.declined
        ? 0
        : action == AccessAction.verified
            ? 4
            : 1;
    events.add(
      CredentialAccessEvent(
        id: '$credentialId-$i',
        timestamp: base.subtract(Duration(hours: hoursBack)),
        audienceHandle: audience.$1,
        audienceLabel: audience.$2,
        location: audience.$3,
        action: action,
        outcome: outcome,
        fieldHandles: fields,
        deltaTrust: delta,
      ),
    );
  }
  events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return events;
}

/// Compact `2h ago` / `3d ago` formatter for the audit trail rows.
String relativeAge(DateTime then, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final delta = n.difference(then);
  if (delta.inMinutes < 1) return 'just now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  if (delta.inDays < 30) return '${(delta.inDays / 7).floor()}w ago';
  return '${(delta.inDays / 30).floor()}mo ago';
}
