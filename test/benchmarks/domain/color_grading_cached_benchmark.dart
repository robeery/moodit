import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../shared/benchmark_core.dart';

const _fixturePath = 'test/fixtures/synthetic_2mp.jpg';
const _resultsPath = 'color_grading_cached_benchmark_results.json';

void main() {
  test('color grading cached prep benchmark (host)', () async {
    final bytes = await _loadOrGenerateFixture();
    final results = runColorGradingPrepCacheBenchmark(
      fixtureBytes: bytes,
      scenarios: buildColorGradingScenarios(),
    );

    await File(_resultsPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(results),
    );

    printResults('Color grading cached prep benchmark (host)', results);
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
