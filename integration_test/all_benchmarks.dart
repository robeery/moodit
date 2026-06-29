import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/benchmarks/shared/benchmark_core.dart';

// Device profile for tables 4.1-4.4:
// flutter drive --driver=test_driver/integration_test.dart --target=integration_test/all_benchmarks.dart -d RF8N90T3EGK --profile
//
// Stage cache is intentionally run through integration_test/stage_cache_benchmark.dart
// because that benchmark blocks the UI isolate long enough to make the combined
// Flutter driver run fragile
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all performance benchmarks (device)', (tester) async {
    final fixtureBytes = generateSyntheticFixture();

    await _runScenarioBenchmark(
      tester,
      title: 'Individual basic operation benchmark (device)',
      scenarios: buildIndividualOperationScenarios(),
      run: (scenarios) => runBenchmark(
        fixtureBytes: fixtureBytes,
        scenarios: scenarios,
      ),
    );

    await _runScenarioBenchmark(
      tester,
      title: 'Pipeline benchmark (device)',
      scenarios: buildScenarios(),
      run: (scenarios) => runBenchmark(
        fixtureBytes: fixtureBytes,
        scenarios: scenarios,
      ),
    );

    await _runScenarioBenchmark(
      tester,
      title: 'Selective color benchmark (device)',
      scenarios: buildSelectiveColorScenarios(),
      run: (scenarios) => runBenchmark(
        fixtureBytes: fixtureBytes,
        scenarios: scenarios,
      ),
    );

    await _runScenarioBenchmark(
      tester,
      title: 'Selective color cached prep benchmark (device)',
      scenarios: buildCachedSelectiveColorScenarios(),
      run: (scenarios) => runSelectiveColorPrepCacheBenchmark(
        fixtureBytes: fixtureBytes,
        scenarios: scenarios,
      ),
    );

    await _runScenarioBenchmark(
      tester,
      title: 'Color grading benchmark (device)',
      scenarios: buildColorGradingScenarios(),
      run: (scenarios) => runBenchmark(
        fixtureBytes: fixtureBytes,
        scenarios: scenarios,
      ),
    );

    await _runScenarioBenchmark(
      tester,
      title: 'Color grading cached prep benchmark (device)',
      scenarios: buildColorGradingScenarios(),
      run: (scenarios) => runColorGradingPrepCacheBenchmark(
        fixtureBytes: fixtureBytes,
        scenarios: scenarios,
      ),
    );

  }, timeout: const Timeout(Duration(minutes: 35)));
}

typedef _ScenarioRunner = Map<String, Map<String, Object>> Function(
  List<Scenario> scenarios,
);

Future<void> _runScenarioBenchmark(
  WidgetTester tester, {
  required String title,
  required List<Scenario> scenarios,
  required _ScenarioRunner run,
}) async {
  final results = <String, Map<String, Object>>{};

  for (final scenario in scenarios) {
    results.addAll(run([scenario]));
    await tester.pump(const Duration(milliseconds: 1));
  }

  printResults(title, results);
  await tester.pump(const Duration(milliseconds: 1));
}
