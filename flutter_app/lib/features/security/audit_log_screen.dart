import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/audit_log.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';

/// Audit log — append-only ledger of security-sensitive actions.
///
/// Reads from [AuditLog] which mirrors `src/lib/auditLog.ts` and is
/// kept in `SharedPreferences`. Renders newest first, grouped by day,
/// with quick filters across kinds.
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String? _filter;

  static const _kinds = <String, _KindMeta>{
    'all': _KindMeta(
      label: 'All',
      icon: Icons.layers_rounded,
      accent: Color(0xFF7C3AED),
    ),
    'vault_open': _KindMeta(
      label: 'Vault open',
      icon: Icons.lock_open_rounded,
      accent: Color(0xFF22C55E),
    ),
    'vault_lock': _KindMeta(
      label: 'Vault lock',
      icon: Icons.lock_rounded,
      accent: Color(0xFF06B6D4),
    ),
    'biometric_pass': _KindMeta(
      label: 'Biometric',
      icon: Icons.fingerprint_rounded,
      accent: Color(0xFF3B82F6),
    ),
    'currency_change': _KindMeta(
      label: 'Currency',
      icon: Icons.currency_exchange_rounded,
      accent: Color(0xFFF59E0B),
    ),
    'document_view': _KindMeta(
      label: 'Documents',
      icon: Icons.book_rounded,
      accent: Color(0xFFEC4899),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final all = AuditLog.all();
    final filtered =
        _filter == null ? all : all.where((e) => e.kind == _filter).toList();
    final byDay = <String, List<AuditEntry>>{};
    for (final e in filtered) {
      final dt = DateTime.fromMillisecondsSinceEpoch(e.at);
      final key = _dayKey(dt);
      byDay.putIfAbsent(key, () => []).add(e);
    }
    final orderedKeys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return PageScaffold(
      title: 'Audit log',
      subtitle: 'Append-only · ${all.length} entries',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppTokens.space8),
        children: [
          // ── Filter chips ─────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                for (final entry in _kinds.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: entry.value.label,
                      icon: entry.value.icon,
                      accent: entry.value.accent,
                      selected: _filter ==
                          (entry.key == 'all' ? null : entry.key),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _filter =
                              entry.key == 'all' ? null : entry.key;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),

          if (filtered.isEmpty)
            const EmptyState(
              title: 'No entries',
              message:
                  'Open the vault, scan a document, or convert currency to start the trail.',
              icon: Icons.history_rounded,
            )
          else
            for (var i = 0; i < orderedKeys.length; i++) ...[
              SectionHeader(
                title: _humanDay(
                    DateTime.parse('${orderedKeys[i]}T00:00:00')),
                dense: i == 0,
              ),
              for (var j = 0; j < byDay[orderedKeys[i]]!.length; j++)
                AnimatedAppearance(
                  delay: Duration(milliseconds: 60 + j * 30),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AuditRow(
                      entry: byDay[orderedKeys[i]]![j],
                      meta: _kinds[byDay[orderedKeys[i]]![j].kind] ??
                          _kinds['all']!,
                    ),
                  ),
                ),
            ],

          const SizedBox(height: AppTokens.space5),
          PremiumCard(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Text(
                    'Audit log is append-only. Entries persist locally and never leave the device unless you explicitly export them.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _humanDay(DateTime dt) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (_dayKey(dt) == _dayKey(today)) return 'Today';
    if (_dayKey(dt) == _dayKey(yesterday)) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', // ignore: prefer_const_literals_to_create_immutables
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _KindMeta {
  const _KindMeta({
    required this.label,
    required this.icon,
    required this.accent,
  });
  final String label;
  final IconData icon;
  final Color accent;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.24)
              : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: accent.withValues(alpha: selected ? 0.55 : 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry, required this.meta});
  final AuditEntry entry;
  final _KindMeta meta;

  String _shortTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = DateTime.fromMillisecondsSinceEpoch(entry.at);
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4, vertical: AppTokens.space3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: meta.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            ),
            child: Icon(meta.icon, color: meta.accent, size: 18),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subject,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _shortTime(dt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
