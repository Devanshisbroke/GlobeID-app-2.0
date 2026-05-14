import 'visa_models.dart';

/// Contract every visa rules source must satisfy.
abstract class VisaAdapter {
  String get source;
  Future<VisaRule> rule(VisaCorridor corridor);
  Future<List<VisaRule>> rulesFor(String passport);
}

class VisaAdapterException implements Exception {
  VisaAdapterException(this.message);
  final String message;
  @override
  String toString() => 'VisaAdapterException: $message';
}
