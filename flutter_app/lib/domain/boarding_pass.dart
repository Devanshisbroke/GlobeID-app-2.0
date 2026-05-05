import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Dart port of `src/lib/boardingPass.ts`. Real HMAC-SHA256 sign +
/// constant-time verify with a base64url signature envelope.
const _kind = 'globeid.bp.v1';
const _defaultSecret = String.fromEnvironment(
  'BOARDING_PASS_SECRET',
  defaultValue: 'globe-dev-bp-secret-change-me',
);

class BoardingPassPayload {
  BoardingPassPayload({
    required this.passenger,
    required this.passportLast4,
    required this.flightNumber,
    required this.airline,
    required this.fromIata,
    required this.toIata,
    required this.scheduledDate,
    required this.legId,
    required this.tripId,
    required this.iat,
    required this.exp,
    required this.appOrigin,
  });

  final String passenger;
  final String? passportLast4;
  final String flightNumber;
  final String airline;
  final String fromIata;
  final String toIata;
  final String scheduledDate;
  final String legId;
  final String? tripId;
  final int iat;
  final int exp;
  final String appOrigin;

  Map<String, dynamic> toJson() => {
        'kind': _kind,
        'isDemoData': true,
        'passenger': passenger,
        'passportLast4': passportLast4,
        'flightNumber': flightNumber,
        'airline': airline,
        'fromIata': fromIata,
        'toIata': toIata,
        'scheduledDate': scheduledDate,
        'legId': legId,
        'tripId': tripId,
        'iat': iat,
        'exp': exp,
        'appOrigin': appOrigin,
      };

  factory BoardingPassPayload.fromJson(Map<String, dynamic> j) =>
      BoardingPassPayload(
        passenger: j['passenger'] as String,
        passportLast4: j['passportLast4'] as String?,
        flightNumber: (j['flightNumber'] as String?) ?? 'TBD',
        airline: j['airline'] as String,
        fromIata: j['fromIata'] as String,
        toIata: j['toIata'] as String,
        scheduledDate: j['scheduledDate'] as String,
        legId: j['legId'] as String,
        tripId: j['tripId'] as String?,
        iat: (j['iat'] as num).toInt(),
        exp: (j['exp'] as num).toInt(),
        appOrigin: j['appOrigin'] as String,
      );
}

class SignedBoardingPass {
  SignedBoardingPass({required this.payload, required this.qrText});
  final BoardingPassPayload payload;
  final String qrText;
}

class BoardingPassVerification {
  BoardingPassVerification.ok(this.payload)
      : valid = true,
        error = null;
  BoardingPassVerification.fail(this.error, [this.payload]) : valid = false;
  final bool valid;
  final BoardingPassPayload? payload;
  final String? error;
}

String _canonicalize(Map<String, dynamic> payload) {
  final keys = payload.keys.toList()..sort();
  final ordered = <String, dynamic>{for (final k in keys) k: payload[k]};
  return jsonEncode(ordered);
}

String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

int _deriveExp(String scheduledDate) {
  try {
    final t =
        DateTime.parse('${scheduledDate}T12:00:00Z').millisecondsSinceEpoch;
    return t + 24 * 3600 * 1000;
  } catch (_) {
    return DateTime.now().millisecondsSinceEpoch + 7 * 24 * 3600 * 1000;
  }
}

SignedBoardingPass issueBoardingPass({
  required String passenger,
  String? passportNo,
  String? flightNumber,
  required String airline,
  required String fromIata,
  required String toIata,
  required String scheduledDate,
  required String legId,
  String? tripId,
  int? iat,
  int? exp,
  String? secretOverride,
  String appOrigin = 'globeid',
}) {
  final last4 = (passportNo != null && passportNo.length >= 4)
      ? passportNo.substring(passportNo.length - 4)
      : null;
  final payload = BoardingPassPayload(
    passenger: passenger,
    passportLast4: last4,
    flightNumber: flightNumber ?? 'TBD',
    airline: airline,
    fromIata: fromIata,
    toIata: toIata,
    scheduledDate: scheduledDate,
    legId: legId,
    tripId: tripId,
    iat: iat ?? DateTime.now().millisecondsSinceEpoch,
    exp: exp ?? _deriveExp(scheduledDate),
    appOrigin: appOrigin,
  );
  final canonical = _canonicalize(payload.toJson());
  final secret = secretOverride ?? _defaultSecret;
  final sig = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(canonical));
  final envelope = {'p': payload.toJson(), 's': _base64Url(sig.bytes)};
  return SignedBoardingPass(payload: payload, qrText: jsonEncode(envelope));
}

BoardingPassVerification verifyBoardingPass(String qrText,
    {String? secretOverride}) {
  Map<String, dynamic> envelope;
  try {
    final decoded = jsonDecode(qrText);
    if (decoded is! Map<String, dynamic>) {
      return BoardingPassVerification.fail('Malformed QR payload');
    }
    envelope = decoded;
  } catch (_) {
    return BoardingPassVerification.fail('Malformed QR payload');
  }
  final sig = envelope['s'];
  final candidate = envelope['p'];
  if (sig is! String || candidate is! Map<String, dynamic>) {
    return BoardingPassVerification.fail('Missing signature');
  }
  if (candidate['kind'] != _kind) {
    return BoardingPassVerification.fail('Not a GlobeID boarding pass');
  }
  for (final k in const [
    'kind',
    'isDemoData',
    'passenger',
    'flightNumber',
    'airline',
    'fromIata',
    'toIata',
    'scheduledDate',
    'legId',
    'iat',
    'exp',
    'appOrigin',
  ]) {
    if (!candidate.containsKey(k)) {
      return BoardingPassVerification.fail('Missing field: $k');
    }
  }
  final payload = BoardingPassPayload.fromJson(candidate);
  final canonical = _canonicalize(payload.toJson());
  final secret = secretOverride ?? _defaultSecret;
  final expected =
      Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(canonical));
  final expectedSig = _base64Url(expected.bytes);
  // Constant-time string comparison.
  if (expectedSig.length != sig.length) {
    return BoardingPassVerification.fail('Signature mismatch', payload);
  }
  var diff = 0;
  for (var i = 0; i < expectedSig.length; i++) {
    diff |= expectedSig.codeUnitAt(i) ^ sig.codeUnitAt(i);
  }
  if (diff != 0) {
    return BoardingPassVerification.fail('Signature mismatch', payload);
  }
  if (DateTime.now().millisecondsSinceEpoch > payload.exp) {
    return BoardingPassVerification.fail('Pass expired', payload);
  }
  return BoardingPassVerification.ok(payload);
}
