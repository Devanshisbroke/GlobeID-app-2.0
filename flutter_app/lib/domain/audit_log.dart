// Dart port of `src/lib/auditLog.ts`. Append-only audit ledger for
// vault opens, biometric attempts, currency changes, etc.
import 'dart:convert';

import '../core/storage/preferences.dart';

class AuditEntry {
  AuditEntry({
    required this.id,
    required this.kind,
    required this.subject,
    required this.detail,
    required this.at,
  });

  final String id;
  final String kind;
  final String subject;
  final String detail;
  final int at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'subject': subject,
        'detail': detail,
        'at': at,
      };

  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
        id: j['id'] as String,
        kind: j['kind'] as String,
        subject: j['subject'] as String,
        detail: j['detail'] as String,
        at: (j['at'] as num).toInt(),
      );
}

class AuditLog {
  static const _key = 'auditLog';

  static List<AuditEntry> all() {
    final raw = Preferences.instance.readString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));
    } catch (_) {
      return const [];
    }
  }

  static Future<void> append(AuditEntry entry) async {
    final existing = all();
    final next = [...existing, entry];
    if (next.length > 200) {
      next.removeRange(0, next.length - 200);
    }
    await Preferences.instance.writeString(
      _key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }
}
