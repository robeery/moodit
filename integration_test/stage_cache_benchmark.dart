import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/benchmarks/shared/benchmark_core.dart';

//device profile
//flutter drive --driver=test_driver/integration_test.dart --target=integration_test/stage_cache_benchmark.dart -d RF8N90T3EGK --profile
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stage cache benchmark (device)', (tester) async {
    final fixtureBytes = generateSyntheticFixture();
    final results = runStageCacheBenchmark(fixtureBytes: fixtureBytes);

    printResults('Stage cache benchmark (device)', results);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
