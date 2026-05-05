/// Dart port of `src/lib/mrzParser.ts`. Parses ICAO 9303 TD1/TD3
/// machine-readable zones with the 7-3-1 check-digit algorithm.
class MrzFields {
  MrzFields({
    required this.documentType,
    required this.issuingCountry,
    required this.documentNumber,
    required this.surname,
    required this.givenNames,
    required this.nationality,
    required this.dateOfBirth,
    required this.sex,
    required this.dateOfExpiry,
    this.personalNumber,
  });

  final String documentType;
  final String issuingCountry;
  final String documentNumber;
  final String surname;
  final String givenNames;
  final String nationality;
  final String dateOfBirth;
  final String sex;
  final String dateOfExpiry;
  final String? personalNumber;

  Map<String, dynamic> toJson() => {
        'documentType': documentType,
        'issuingCountry': issuingCountry,
        'documentNumber': documentNumber,
        'surname': surname,
        'givenNames': givenNames,
        'nationality': nationality,
        'dateOfBirth': dateOfBirth,
        'sex': sex,
        'dateOfExpiry': dateOfExpiry,
        if (personalNumber != null) 'personalNumber': personalNumber,
      };
}

class MrzResult {
  MrzResult({
    required this.kind,
    required this.ok,
    required this.checksumFailures,
    this.fields,
  });

  final String kind; // td1 | td3 | unknown
  final bool ok;
  final List<String> checksumFailures;
  final MrzFields? fields;
}

int _checkDigit(String input) {
  const weights = [7, 3, 1];
  var total = 0;
  for (var i = 0; i < input.length; i++) {
    final c = input.codeUnitAt(i);
    int v;
    if (c >= 0x30 && c <= 0x39) {
      v = c - 0x30;
    } else if (c >= 0x41 && c <= 0x5A) {
      v = c - 0x41 + 10;
    } else {
      v = 0; // filler `<`
    }
    total += v * weights[i % 3];
  }
  return total % 10;
}

String _normLine(String raw) => raw
    .toUpperCase()
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(RegExp('[«»]'), '<');

MrzResult parseMrz(String raw) {
  final lines = raw
      .split(RegExp(r'\r?\n'))
      .map(_normLine)
      .where((l) => l.length >= 30)
      .toList();

  for (var i = 0; i < lines.length - 1; i++) {
    final a = lines[i];
    final b = lines[i + 1];
    if (a.length == 44 && b.length == 44 && a.startsWith('P')) {
      return _parseTD3(a, b);
    }
  }

  for (var i = 0; i < lines.length - 2; i++) {
    final a = lines[i];
    final b = lines[i + 1];
    final c = lines[i + 2];
    if (a.length == 30 && b.length == 30 && c.length == 30) {
      return _parseTD1(a, b, c);
    }
  }

  return MrzResult(kind: 'unknown', ok: false, checksumFailures: const []);
}

MrzResult _parseTD3(String l1, String l2) {
  final docType = l1.substring(0, 2).replaceAll('<', '').trim();
  final issuingCountry = l1.substring(2, 5);
  final nameField = l1.substring(5, 44);
  final parts = nameField.split('<<');
  final surname =
      (parts.isNotEmpty ? parts[0] : '').replaceAll('<', ' ').trim();
  final given = (parts.length > 1 ? parts[1] : '').replaceAll('<', ' ').trim();

  final docNum = l2.substring(0, 9).replaceAll('<', '');
  final docCheck = l2[9];
  final nationality = l2.substring(10, 13);
  final dob = l2.substring(13, 19);
  final dobCheck = l2[19];
  final sex = l2[20];
  final exp = l2.substring(21, 27);
  final expCheck = l2[27];

  final fails = <String>[];
  if (_checkDigit(l2.substring(0, 9)).toString() != docCheck) {
    fails.add('docNum');
  }
  if (_checkDigit(dob).toString() != dobCheck) fails.add('dob');
  if (_checkDigit(exp).toString() != expCheck) fails.add('expiry');

  return MrzResult(
    kind: 'td3',
    ok: fails.isEmpty,
    checksumFailures: fails,
    fields: MrzFields(
      documentType: docType,
      issuingCountry: issuingCountry,
      documentNumber: docNum,
      surname: surname,
      givenNames: given,
      nationality: nationality,
      dateOfBirth: dob,
      sex: sex,
      dateOfExpiry: exp,
    ),
  );
}

MrzResult _parseTD1(String l1, String l2, String l3) {
  final docType = l1.substring(0, 2).replaceAll('<', '').trim();
  final issuingCountry = l1.substring(2, 5);
  final docNum = l1.substring(5, 14).replaceAll('<', '');
  final docCheck = l1[14];

  final dob = l2.substring(0, 6);
  final dobCheck = l2[6];
  final sex = l2[7];
  final exp = l2.substring(8, 14);
  final expCheck = l2[14];
  final nationality = l2.substring(15, 18);

  final nameField = l3.substring(0, 30);
  final parts = nameField.split('<<');
  final surname =
      (parts.isNotEmpty ? parts[0] : '').replaceAll('<', ' ').trim();
  final given = (parts.length > 1 ? parts[1] : '').replaceAll('<', ' ').trim();

  final fails = <String>[];
  if (_checkDigit(l1.substring(5, 14)).toString() != docCheck) {
    fails.add('docNum');
  }
  if (_checkDigit(dob).toString() != dobCheck) fails.add('dob');
  if (_checkDigit(exp).toString() != expCheck) fails.add('expiry');

  return MrzResult(
    kind: 'td1',
    ok: fails.isEmpty,
    checksumFailures: fails,
    fields: MrzFields(
      documentType: docType,
      issuingCountry: issuingCountry,
      documentNumber: docNum,
      surname: surname,
      givenNames: given,
      nationality: nationality,
      dateOfBirth: dob,
      sex: sex,
      dateOfExpiry: exp,
    ),
  );
}
