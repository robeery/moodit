import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../shared/benchmark_core.dart';

const _fixturePath = 'test/fixtures/synthetic_2mp.jpg';
const _resultsPath = 'benchmark_results.json';
const _baselinePath = 'benchmark_baseline.json';
const _regressionThreshold = 1.15;


void main() {
  test('pipeline benchmark (host)', () async {
    final bytes = await _loadOrGenerateFixture();
    final scenarios = buildScenarios();

    final results = runBenchmark(
      fixtureBytes: bytes,
      scenarios: scenarios,
    );

    await File(_resultsPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(results),
    );

    printResults('Pipeline benchmark (host)', results);
    _checkRegressions(results);
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

void _checkRegressions(Map<String, Map<String, Object>> results) {
  final baselineFile = File(_baselinePath);
  if (!baselineFile.existsSync()) return;

  final baseline =
      jsonDecode(baselineFile.readAsStringSync()) as Map<String, dynamic>;
  final regressions = <String>[];

  for (final entry in results.entries) {
    final current = entry.value['median_ms'] as double;
    final prior = (baseline[entry.key] as Map?)?['median_ms'] as num?;
    if (prior == null) continue;
    final ratio = current / prior.toDouble();
    if (ratio > _regressionThreshold) {
      regressions.add(
        '  ${entry.key}: ${prior.toDouble().toStringAsFixed(1)} -> '
        '${current.toStringAsFixed(1)} ms '
        '(${((ratio - 1) * 100).toStringAsFixed(0)}% slower)',
      );
    }
  }

  if (regressions.isNotEmpty) {
    final pct = ((_regressionThreshold - 1) * 100).toStringAsFixed(0);
    fail('Benchmark regression(s) exceeding $pct%:\n${regressions.join('\n')}');
  }
}
