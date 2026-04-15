import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/benchmarks/shared/benchmark_core.dart';
//host, ~3 min
//flutter test test/benchmarks/domain/pipeline_benchmark.dart
//device, ~7 min
//flutter test integration_test/pipeline_benchmark.dart -d RF8N90T3EGK   
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pipeline benchmark (device)', (tester) async {
    final fixtureBytes = generateSyntheticFixture();
    final scenarios = buildScenarios();

    final results = runBenchmark(
      fixtureBytes: fixtureBytes,
      scenarios: scenarios,
    );

    printResults('Pipeline benchmark (device)', results);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
