import 'package:dio/dio.dart';

import 'visa_adapter.dart';
import 'visa_models.dart';

/// `PassportIndexVisaAdapter` — adapter against the
/// PassportIndex dataset hosted on GitHub.
///
/// Endpoint:
///   `https://raw.githubusercontent.com/ilyankou/passport-index-dataset/master/passport-index-matrix-iso2.csv`
///
/// The matrix is a CSV where the first row + column are ISO 3166
/// alpha-2 country codes and each cell is one of:
///   • `visa free`, `visa on arrival`, `e-visa`, `eta`,
///   • integer (days visa-free), `-1` (home country), `no admission`,
///   • `visa required`.
///
/// The adapter fetches the whole matrix once, caches it
/// in-memory, and looks up rows lazily.
class PassportIndexVisaAdapter extends VisaAdapter {
  PassportIndexVisaAdapter({
    Dio? dio,
    this.endpoint =
        'https://raw.githubusercontent.com/ilyankou/passport-index-dataset/master/passport-index-matrix-iso2.csv',
  }) : _dio = dio ?? _defaultDio();

  static Dio _defaultDio() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 6),
        responseType: ResponseType.plain,
      ));

  final Dio _dio;
  final String endpoint;

  Map<String, Map<String, String>>? _matrix;

  @override
  String get source => 'passportindex';

  @override
  Future<VisaRule> rule(VisaCorridor corridor) async {
    final matrix = await _load();
    final passportRow = matrix[corridor.passport];
    if (passportRow == null) {
      throw VisaAdapterException(
        'Unknown passport ISO ${corridor.passport}',
      );
    }
    final raw = passportRow[corridor.destination];
    if (raw == null) {
      throw VisaAdapterException(
        'Unknown destination ISO ${corridor.destination}',
      );
    }
    return _parse(corridor, raw);
  }

  @override
  Future<List<VisaRule>> rulesFor(String passport) async {
    final matrix = await _load();
    final row = matrix[passport];
    if (row == null) {
      throw VisaAdapterException('Unknown passport ISO $passport');
    }
    final destinations = row.keys.toList()..sort();
    return [
      for (final dst in destinations)
        _parse(
          VisaCorridor(passport: passport, destination: dst),
          row[dst] ?? '',
        ),
    ];
  }

  Future<Map<String, Map<String, String>>> _load() async {
    final cached = _matrix;
    if (cached != null) return cached;
    final res = await _dio.get<String>(endpoint);
    final body = res.data;
    if (body == null || body.isEmpty) {
      throw VisaAdapterException('Empty matrix response');
    }
    _matrix = parseMatrix(body);
    return _matrix!;
  }

  /// Parser exposed for tests — no network required.
  static Map<String, Map<String, String>> parseMatrix(String csv) {
    final lines =
        csv.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return {};
    final header = _splitCsv(lines.first);
    final destinations = header.sublist(1);
    final out = <String, Map<String, String>>{};
    for (var i = 1; i < lines.length; i++) {
      final row = _splitCsv(lines[i]);
      if (row.length < 2) continue;
      final passport = row.first;
      final cells = <String, String>{};
      for (var j = 0; j < destinations.length; j++) {
        final dst = destinations[j];
        if (j + 1 >= row.length) break;
        cells[dst] = row[j + 1];
      }
      out[passport] = cells;
    }
    return out;
  }

  /// Tiny CSV splitter — the PassportIndex matrix uses plain
  /// commas, no quoted commas. Avoid pulling in a CSV package.
  static List<String> _splitCsv(String line) =>
      line.split(',').map((c) => c.trim()).toList();

  /// Public so tests can verify the cell→rule mapping without
  /// hitting the network.
  VisaRule _parse(VisaCorridor corridor, String raw) {
    final cell = raw.toLowerCase().trim();
    if (cell == 'visa free' || cell == 'visa-free') {
      return VisaRule(
        corridor: corridor,
        category: VisaCategory.visaFree,
        fetchedAt: DateTime.now(),
        source: source,
      );
    }
    if (cell == 'visa on arrival') {
      return VisaRule(
        corridor: corridor,
        category: VisaCategory.visaOnArrival,
        fetchedAt: DateTime.now(),
        source: source,
      );
    }
    if (cell == 'e-visa' || cell == 'evisa') {
      return VisaRule(
        corridor: corridor,
        category: VisaCategory.eVisa,
        fetchedAt: DateTime.now(),
        source: source,
      );
    }
    if (cell == 'eta') {
      return VisaRule(
        corridor: corridor,
        category: VisaCategory.eta,
        fetchedAt: DateTime.now(),
        source: source,
      );
    }
    if (cell == 'no admission' || cell == 'not admitted') {
      return VisaRule(
        corridor: corridor,
        category: VisaCategory.notAdmitted,
        fetchedAt: DateTime.now(),
        source: source,
      );
    }
    if (cell == '-1') {
      return VisaRule(
        corridor: corridor,
        category: VisaCategory.home,
        fetchedAt: DateTime.now(),
        source: source,
      );
    }
    final days = int.tryParse(cell);
    if (days != null && days > 0) {
      return VisaRule(
        corridor: corridor,
        category: VisaCategory.visaFree,
        maxStayDays: days,
        fetchedAt: DateTime.now(),
        source: source,
      );
    }
    return VisaRule(
      corridor: corridor,
      category: VisaCategory.visaRequired,
      fetchedAt: DateTime.now(),
      source: source,
    );
  }

  /// Public mapper for tests.
  VisaRule mapCell(VisaCorridor corridor, String raw) => _parse(corridor, raw);
}
