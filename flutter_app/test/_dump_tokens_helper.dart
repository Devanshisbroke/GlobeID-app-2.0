// One-shot helper to regenerate assets/atelier/tokens.json.
//
// Run via:
//   flutter test test/_dump_tokens_helper.dart
//
// The test does NOT pass — it always fails with the freshly dumped
// JSON written to disk, so the asset stays in lock-step with the
// live exporter. This file is intentionally left in the tree so a
// future engineer can regenerate the asset without setting up
// secondary tooling.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/atelier/models/brand_tokens.dart';

void main() {
  test('dump tokens.json', () {
    final cwd = Directory.current.path;
    final out = File('$cwd/assets/atelier/tokens.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync('${BrandTokens.toPrettyJson()}\n');
    expect(out.existsSync(), isTrue);
  }, skip: const bool.fromEnvironment('DUMP_TOKENS') ? false : 'helper · run with --dart-define=DUMP_TOKENS=true');
}
