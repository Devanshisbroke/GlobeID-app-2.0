import 'package:flutter/material.dart';

/// `DisclosureAudience` — who is allowed to see what.
///
/// Each audience carries a sensible default reveal set so the
/// bearer can flip the whole policy at once with one tap, then
/// tune individual fields from there.
enum DisclosureAudience {
  airline('Airline', 'AIRLINE'),
  hotel('Hotel', 'HOTEL'),
  consulate('Consulate', 'CONSULATE'),
  bank('Bank', 'BANK'),
  immigration('Immigration', 'IMMIGRATION');

  const DisclosureAudience(this.label, this.handle);

  /// Human-readable label (used in headlines and toggle rows).
  final String label;

  /// Mono-cap handle used in chip rails (e.g. `AIRLINE`).
  final String handle;
}

/// `DisclosureField` — atomic credential fields that can be
/// individually toggled per audience.
///
/// Modelled coarsely on the most common travel-credential fields.
/// Each field carries a default sensitivity tier (used for the
/// auto-reveal heuristic below).
enum DisclosureField {
  fullName('Full name', 'NAME', DisclosureSensitivity.low),
  dateOfBirth('Date of birth', 'DOB', DisclosureSensitivity.high),
  age('Age (computed)', 'AGE', DisclosureSensitivity.low),
  nationality('Nationality', 'NAT', DisclosureSensitivity.low),
  passportNumber('Passport number', 'PASS#', DisclosureSensitivity.high),
  expiryDate('Expiry date', 'EXP', DisclosureSensitivity.medium),
  issuingCountry('Issuing country', 'ISSUER', DisclosureSensitivity.low),
  photo('Photo', 'PHOTO', DisclosureSensitivity.medium),
  signature('Signature', 'SIG', DisclosureSensitivity.high),
  address('Home address', 'ADDR', DisclosureSensitivity.high),
  taxResidence('Tax residence', 'TAX', DisclosureSensitivity.high),
  trustScore('Trust score', 'TRUST', DisclosureSensitivity.medium);

  const DisclosureField(this.label, this.handle, this.sensitivity);
  final String label;
  final String handle;
  final DisclosureSensitivity sensitivity;
}

enum DisclosureSensitivity { low, medium, high }

/// `DisclosurePolicy` — immutable per-audience reveal map.
///
/// `visibility[audience]` is the set of fields the audience is
/// allowed to see. The default constructor seeds the canonical
/// reveal sets per audience (the "what would a thoughtful bearer
/// pick" baseline).
class DisclosurePolicy {
  const DisclosurePolicy(this.visibility);

  /// Seeds the canonical reveal sets per audience.
  factory DisclosurePolicy.defaults() {
    return DisclosurePolicy({
      DisclosureAudience.airline: {
        DisclosureField.fullName,
        DisclosureField.dateOfBirth,
        DisclosureField.nationality,
        DisclosureField.passportNumber,
        DisclosureField.expiryDate,
        DisclosureField.photo,
      },
      DisclosureAudience.hotel: {
        DisclosureField.fullName,
        DisclosureField.age,
        DisclosureField.nationality,
        DisclosureField.photo,
      },
      DisclosureAudience.consulate: {
        DisclosureField.fullName,
        DisclosureField.dateOfBirth,
        DisclosureField.nationality,
        DisclosureField.passportNumber,
        DisclosureField.expiryDate,
        DisclosureField.issuingCountry,
        DisclosureField.photo,
        DisclosureField.signature,
        DisclosureField.address,
      },
      DisclosureAudience.bank: {
        DisclosureField.fullName,
        DisclosureField.dateOfBirth,
        DisclosureField.nationality,
        DisclosureField.address,
        DisclosureField.taxResidence,
        DisclosureField.trustScore,
      },
      DisclosureAudience.immigration: {
        DisclosureField.fullName,
        DisclosureField.dateOfBirth,
        DisclosureField.nationality,
        DisclosureField.passportNumber,
        DisclosureField.expiryDate,
        DisclosureField.issuingCountry,
        DisclosureField.photo,
      },
    });
  }

  final Map<DisclosureAudience, Set<DisclosureField>> visibility;

  /// Whether [field] is visible to [audience] under this policy.
  bool isVisible(DisclosureAudience audience, DisclosureField field) {
    return visibility[audience]?.contains(field) ?? false;
  }

  /// Returns a new policy with [field] toggled for [audience].
  DisclosurePolicy toggle(
    DisclosureAudience audience,
    DisclosureField field,
  ) {
    final next = <DisclosureAudience, Set<DisclosureField>>{};
    for (final entry in visibility.entries) {
      next[entry.key] = {...entry.value};
    }
    final set = next.putIfAbsent(audience, () => <DisclosureField>{});
    if (set.contains(field)) {
      set.remove(field);
    } else {
      set.add(field);
    }
    return DisclosurePolicy(next);
  }

  /// Count of fields revealed to [audience] under this policy.
  int revealedCount(DisclosureAudience audience) {
    return visibility[audience]?.length ?? 0;
  }

  /// Total possible field count (matches [DisclosureField.values]).
  static int get totalFields => DisclosureField.values.length;

  /// Returns the "lock everything" policy — no fields visible to
  /// any audience.
  factory DisclosurePolicy.locked() {
    return DisclosurePolicy({
      for (final a in DisclosureAudience.values) a: <DisclosureField>{},
    });
  }

  /// Returns the "lock high-sensitivity" policy — every audience
  /// loses access to high-sensitivity fields.
  DisclosurePolicy lockSensitive() {
    final next = <DisclosureAudience, Set<DisclosureField>>{};
    for (final entry in visibility.entries) {
      next[entry.key] = {
        for (final f in entry.value)
          if (f.sensitivity != DisclosureSensitivity.high) f,
      };
    }
    return DisclosurePolicy(next);
  }
}

/// Internal helper used by the sheet UI to colour-code sensitivity.
Color sensitivityTone(DisclosureField field) {
  switch (field.sensitivity) {
    case DisclosureSensitivity.low:
      return const Color(0xFF10B981); // emerald
    case DisclosureSensitivity.medium:
      return const Color(0xFFE9C75D); // gold light
    case DisclosureSensitivity.high:
      return const Color(0xFFE11D48); // crimson
  }
}

/// Internal helper — short uppercase tag for the chip rail.
String sensitivityTag(DisclosureField field) {
  switch (field.sensitivity) {
    case DisclosureSensitivity.low:
      return 'LOW';
    case DisclosureSensitivity.medium:
      return 'MED';
    case DisclosureSensitivity.high:
      return 'HIGH';
  }
}
