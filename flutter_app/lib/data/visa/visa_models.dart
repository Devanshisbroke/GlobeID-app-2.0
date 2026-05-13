/// Foundation models for the GlobeID visa rules stack.
///
/// `VisaRule` — single (passport, destination) entry from a
/// visa-requirements dataset such as PassportIndex.
class VisaCorridor {
  const VisaCorridor({required this.passport, required this.destination});

  /// ISO 3166-1 alpha-2 passport country (e.g. `IN`, `US`, `DE`).
  final String passport;

  /// ISO 3166-1 alpha-2 destination country.
  final String destination;

  String get handle => '$passport→$destination';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisaCorridor &&
          other.passport == passport &&
          other.destination == destination);

  @override
  int get hashCode => Object.hash(passport, destination);

  @override
  String toString() => 'VisaCorridor($handle)';
}

/// Canonical visa requirement categories used across every UI
/// surface. Maps cleanly to the PassportIndex `visa` codes:
///   • `visa_free`      → `visaFree`
///   • `visa_on_arrival`→ `visaOnArrival`
///   • `e_visa`         → `eVisa`
///   • `eta`            → `eta`
///   • `visa_required`  → `visaRequired`
///   • `not_admitted`   → `notAdmitted`
///   • `home`           → `home` (same-country)
enum VisaCategory {
  visaFree,
  visaOnArrival,
  eVisa,
  eta,
  visaRequired,
  notAdmitted,
  home,
}

extension VisaCategoryX on VisaCategory {
  String get handle => switch (this) {
        VisaCategory.visaFree => 'VISA · FREE',
        VisaCategory.visaOnArrival => 'VISA · ON · ARRIVAL',
        VisaCategory.eVisa => 'eVISA',
        VisaCategory.eta => 'ETA',
        VisaCategory.visaRequired => 'VISA · REQUIRED',
        VisaCategory.notAdmitted => 'NOT · ADMITTED',
        VisaCategory.home => 'HOME · COUNTRY',
      };

  /// Tone hex — green for permissive, gold for streamlined, red
  /// for restricted. Aligns with existing Live Visa palette.
  int get tone => switch (this) {
        VisaCategory.visaFree => 0xFF6CE0A8, // emerald
        VisaCategory.visaOnArrival => 0xFFD4AF37, // gold
        VisaCategory.eVisa => 0xFFD4AF37,
        VisaCategory.eta => 0xFFD4AF37,
        VisaCategory.visaRequired => 0xFFFFB347, // amber
        VisaCategory.notAdmitted => 0xFFFF6A6A, // red
        VisaCategory.home => 0xFFA1A4AA, // grey
      };

  /// True for categories that require advance paperwork.
  bool get requiresAction =>
      this == VisaCategory.eVisa ||
      this == VisaCategory.eta ||
      this == VisaCategory.visaRequired;
}

/// A single visa requirement quote. Anatomy:
///   • `corridor`      — passport → destination
///   • `category`      — VisaCategory
///   • `maxStayDays`   — allowed stay in days (null = unspecified)
///   • `notes`         — free-form policy note (e.g. "extendable
///     once on arrival")
///   • `fetchedAt`     — when the rule was acquired
///   • `source`        — provider handle (`passportindex`, `demo`)
class VisaRule {
  const VisaRule({
    required this.corridor,
    required this.category,
    required this.fetchedAt,
    required this.source,
    this.maxStayDays,
    this.notes,
  });

  final VisaCorridor corridor;
  final VisaCategory category;
  final int? maxStayDays;
  final String? notes;
  final DateTime fetchedAt;
  final String source;

  bool isStale({Duration threshold = const Duration(days: 7)}) =>
      DateTime.now().difference(fetchedAt) > threshold;

  VisaRule copyWith({
    VisaCategory? category,
    int? maxStayDays,
    String? notes,
    DateTime? fetchedAt,
    String? source,
  }) =>
      VisaRule(
        corridor: corridor,
        category: category ?? this.category,
        maxStayDays: maxStayDays ?? this.maxStayDays,
        notes: notes ?? this.notes,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        source: source ?? this.source,
      );

  @override
  String toString() =>
      'VisaRule(${corridor.handle} ${category.handle} '
      'stay=${maxStayDays ?? '—'}d @ $source)';
}
