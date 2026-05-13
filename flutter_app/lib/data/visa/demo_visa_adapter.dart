import 'visa_adapter.dart';
import 'visa_models.dart';

/// `DemoVisaAdapter` — seeded with a realistic Indian-passport
/// snapshot (PassportIndex 2024 reference) plus a small set of
/// US / German / Singapore / Emirati corridors so the demo
/// surface can render any of them without network.
///
/// Any corridor not present falls back to `visaRequired` with a
/// `30 days, single entry` template so the UI always has
/// something to render.
class DemoVisaAdapter extends VisaAdapter {
  DemoVisaAdapter({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static final _rules = <VisaCorridor, _Rule>{
    // ── IN passport ──
    const VisaCorridor(passport: 'IN', destination: 'AE'): _Rule(
      category: VisaCategory.visaOnArrival,
      maxStayDays: 14,
      notes: 'Visa on arrival · extendable to 60 days',
    ),
    const VisaCorridor(passport: 'IN', destination: 'TH'): _Rule(
      category: VisaCategory.visaFree,
      maxStayDays: 30,
      notes: 'e-Visa option for stays > 30 days',
    ),
    const VisaCorridor(passport: 'IN', destination: 'SG'): _Rule(
      category: VisaCategory.visaFree,
      maxStayDays: 30,
      notes: 'Visa-free for tourism',
    ),
    const VisaCorridor(passport: 'IN', destination: 'US'): _Rule(
      category: VisaCategory.visaRequired,
      maxStayDays: 180,
      notes: 'B1/B2 visitor visa required · interview at consulate',
    ),
    const VisaCorridor(passport: 'IN', destination: 'GB'): _Rule(
      category: VisaCategory.visaRequired,
      maxStayDays: 180,
      notes: 'Standard Visitor visa required',
    ),
    const VisaCorridor(passport: 'IN', destination: 'DE'): _Rule(
      category: VisaCategory.visaRequired,
      maxStayDays: 90,
      notes: 'Schengen short-stay visa · biometrics at VFS',
    ),
    const VisaCorridor(passport: 'IN', destination: 'AU'): _Rule(
      category: VisaCategory.eVisa,
      maxStayDays: 90,
      notes: 'Visitor (subclass 600) e-Visa',
    ),
    const VisaCorridor(passport: 'IN', destination: 'JP'): _Rule(
      category: VisaCategory.eVisa,
      maxStayDays: 90,
      notes: 'eVisa available · processing 5 days',
    ),
    const VisaCorridor(passport: 'IN', destination: 'IN'): _Rule(
      category: VisaCategory.home,
    ),
    // ── US passport ──
    const VisaCorridor(passport: 'US', destination: 'DE'): _Rule(
      category: VisaCategory.visaFree,
      maxStayDays: 90,
      notes: 'Schengen 90/180 rule applies',
    ),
    const VisaCorridor(passport: 'US', destination: 'GB'): _Rule(
      category: VisaCategory.eta,
      maxStayDays: 180,
      notes: 'UK ETA from Jan 2025',
    ),
    const VisaCorridor(passport: 'US', destination: 'AE'): _Rule(
      category: VisaCategory.visaOnArrival,
      maxStayDays: 30,
      notes: 'Visa on arrival · free',
    ),
    const VisaCorridor(passport: 'US', destination: 'US'): _Rule(
      category: VisaCategory.home,
    ),
    // ── DE passport ──
    const VisaCorridor(passport: 'DE', destination: 'US'): _Rule(
      category: VisaCategory.eta,
      maxStayDays: 90,
      notes: 'ESTA required · 72-hour processing',
    ),
    const VisaCorridor(passport: 'DE', destination: 'AE'): _Rule(
      category: VisaCategory.visaOnArrival,
      maxStayDays: 30,
      notes: 'Visa on arrival · free',
    ),
    const VisaCorridor(passport: 'DE', destination: 'DE'): _Rule(
      category: VisaCategory.home,
    ),
  };

  @override
  String get source => 'demo';

  @override
  Future<VisaRule> rule(VisaCorridor corridor) async {
    final r = _rules[corridor];
    if (r == null) {
      return VisaRule(
        corridor: corridor,
        category: VisaCategory.visaRequired,
        maxStayDays: 30,
        notes: 'Default policy · verify with consulate',
        fetchedAt: _now(),
        source: source,
      );
    }
    return VisaRule(
      corridor: corridor,
      category: r.category,
      maxStayDays: r.maxStayDays,
      notes: r.notes,
      fetchedAt: _now(),
      source: source,
    );
  }

  @override
  Future<List<VisaRule>> rulesFor(String passport) async {
    final rows = _rules.entries
        .where((e) => e.key.passport == passport)
        .toList()
      ..sort((a, b) => a.key.destination.compareTo(b.key.destination));
    final fetched = _now();
    return [
      for (final row in rows)
        VisaRule(
          corridor: row.key,
          category: row.value.category,
          maxStayDays: row.value.maxStayDays,
          notes: row.value.notes,
          fetchedAt: fetched,
          source: source,
        ),
    ];
  }
}

class _Rule {
  const _Rule({required this.category, this.maxStayDays, this.notes});
  final VisaCategory category;
  final int? maxStayDays;
  final String? notes;
}
