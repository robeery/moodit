import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/benchmarks/shared/benchmark_core.dart';

//device profile
//flutter drive --driver=test_driver/integration_test.dart --target=integration_test/color_grading_cached_benchmark.dart -d RF8N90T3EGK --profile
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('color grading cached prep benchmark (device)', (tester) async {
    final fixtureBytes = generateSyntheticFixture();
    final results = runColorGradingPrepCacheBenchmark(
      fixtureBytes: fixtureBytes,
      scenarios: buildColorGradingScenarios(),
    );

    printResults('Color grading cached prep benchmark (device)', results);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
