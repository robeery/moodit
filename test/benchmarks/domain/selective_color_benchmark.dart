import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../shared/benchmark_core.dart';

const _fixturePath = 'test/fixtures/synthetic_2mp.jpg';
const _resultsPath = 'selective_color_benchmark_results.json';

void main() {
  test('selective color benchmark (host)', () async {
    final bytes = await _loadOrGenerateFixture();
    final results = runBenchmark(
      fixtureBytes: bytes,
      scenarios: buildSelectiveColorScenarios(),
    );

    await File(_resultsPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(results),
    );

    printResults('Selective color benchmark (host)', results);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

Future<Uint8List> _loadOrGenerateFixture() async {
  final file = File(_fixturePath);
  if (await file.exists()) {
    return file.readAsBytes();
  }
  await file.parent.create(recursive: true);
  final bytes = generateSyntheticFixture();
  await file.writeAsBytes(bytes);
  return bytes;
}
