/// Dart port of `src/lib/visaRequirements.ts`. Pure-function visa policy
/// summary based on a small canonical table.
enum VisaPolicy { visaFree, eta, voa, eVisa, embassy }

class VisaSummary {
  const VisaSummary({
    required this.citizenship,
    required this.destination,
    required this.policy,
    required this.maxStayDays,
  });

  final String citizenship;
  final String destination;
  final VisaPolicy policy;
  final int maxStayDays;

  String get label {
    switch (policy) {
      case VisaPolicy.visaFree:
        return 'Visa-free • $maxStayDays days';
      case VisaPolicy.eta:
        return 'eTA required • $maxStayDays days';
      case VisaPolicy.voa:
        return 'Visa on arrival • $maxStayDays days';
      case VisaPolicy.eVisa:
        return 'eVisa required';
      case VisaPolicy.embassy:
        return 'Embassy visa required';
    }
  }
}

const _table = <String, Map<String, _Row>>{
  'US': {
    'JP': _Row(VisaPolicy.visaFree, 90),
    'GB': _Row(VisaPolicy.visaFree, 180),
    'SG': _Row(VisaPolicy.visaFree, 90),
    'AE': _Row(VisaPolicy.visaFree, 30),
    'IN': _Row(VisaPolicy.eVisa, 60),
    'CN': _Row(VisaPolicy.embassy, 0),
    'TH': _Row(VisaPolicy.visaFree, 30),
  },
  'IN': {
    'JP': _Row(VisaPolicy.eVisa, 90),
    'GB': _Row(VisaPolicy.embassy, 0),
    'SG': _Row(VisaPolicy.visaFree, 30),
    'AE': _Row(VisaPolicy.voa, 14),
    'TH': _Row(VisaPolicy.voa, 15),
    'US': _Row(VisaPolicy.embassy, 0),
  },
  'GB': {
    'JP': _Row(VisaPolicy.visaFree, 90),
    'US': _Row(VisaPolicy.eta, 90),
    'SG': _Row(VisaPolicy.visaFree, 90),
    'IN': _Row(VisaPolicy.eVisa, 60),
    'AE': _Row(VisaPolicy.visaFree, 30),
  },
};

class _Row {
  const _Row(this.policy, this.days);
  final VisaPolicy policy;
  final int days;
}

VisaSummary visaSummary(String citizenship, String destination) {
  final c = citizenship.toUpperCase();
  final d = destination.toUpperCase();
  final row = _table[c]?[d];
  if (row == null) {
    return VisaSummary(
      citizenship: c,
      destination: d,
      policy: VisaPolicy.embassy,
      maxStayDays: 0,
    );
  }
  return VisaSummary(
    citizenship: c,
    destination: d,
    policy: row.policy,
    maxStayDays: row.days,
  );
}
