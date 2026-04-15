import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:licenta/domain/apply_edits.dart';
import 'package:licenta/model/color_edit.dart';
import 'package:licenta/model/color_grading_edit.dart';
import 'package:licenta/model/edit.dart';

const int defaultWarmup = 2;
const int defaultIterations = 7;

class Scenario {
  const Scenario(
    this.name, {
    this.edits = const [],
    this.colorEdits = const [],
    this.gradingEdits = const [],
  });

  final String name;
  final List<Edit> edits;
  final List<ColorEdit> colorEdits;
  final List<ColorGradingEdit> gradingEdits;
}

List<Scenario> buildScenarios() {
  final basicFive = [
    Edit(type: OperationType.exposure, value: 30),
    Edit(type: OperationType.brightness, value: 20),
    Edit(type: OperationType.contrast, value: 25),
    Edit(type: OperationType.warmth, value: -15),
    Edit(type: OperationType.tint, value: 10),
  ];

  final fullBasic = [
    for (final op in OperationType.values)
      Edit(type: op, value: op.minValue == 0 ? 50 : 30),
  ];

  final selectiveHeavy = [
    for (final range in ColorRange.values)
      ColorEdit(range: range, hue: 20, saturation: 25, luminance: 15),
  ];

  final gradingHeavy = [
    for (final zone in ColorGradingZone.values)
      ColorGradingEdit(zone: zone, hue: 180, strength: 40, luminance: 20),
  ];

  return [
    Scenario(
      'single_exposure',
      edits: [Edit(type: OperationType.exposure, value: 50)],
    ),
    Scenario('basic_stack_5', edits: basicFive),
    Scenario('full_basic_stack', edits: fullBasic),
    Scenario('selective_color_heavy', colorEdits: selectiveHeavy),
    Scenario('color_grading_heavy', gradingEdits: gradingHeavy),
    Scenario(
      'everything',
      edits: basicFive,
      colorEdits: selectiveHeavy,
      gradingEdits: gradingHeavy,
    ),
  ];
}

Uint8List generateSyntheticFixture({int width = 1600, int height = 1200}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    final l = 0.15 + 0.7 * (y / (height - 1));
    for (var x = 0; x < width; x++) {
      final hue = (x / (width - 1)) * 360.0;
      final rgb = _hsvToRgb(hue, 0.65, l);
      image.setPixelRgba(x, y, rgb[0], rgb[1], rgb[2], 255);
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

List<int> _hsvToRgb(double h, double s, double v) {
  final c = v * s;
  final hp = h / 60.0;
  final x = c * (1 - ((hp % 2) - 1).abs());
  final m = v - c;
  double r = 0, g = 0, b = 0;
  if (hp < 1) {
    r = c;
    g = x;
  } else if (hp < 2) {
    r = x;
    g = c;
  } else if (hp < 3) {
    g = c;
    b = x;
  } else if (hp < 4) {
    g = x;
    b = c;
  } else if (hp < 5) {
    r = x;
    b = c;
  } else {
    r = c;
    b = x;
  }
  return [
    ((r + m) * 255).round().clamp(0, 255),
    ((g + m) * 255).round().clamp(0, 255),
    ((b + m) * 255).round().clamp(0, 255),
  ];
}

Map<String, Map<String, Object>> runBenchmark({
  required Uint8List fixtureBytes,
  required List<Scenario> scenarios,
  int warmup = defaultWarmup,
  int iterations = defaultIterations,
}) {
  final results = <String, Map<String, Object>>{};

  for (final scenario in scenarios) {
    for (var i = 0; i < warmup; i++) {
      applyEditsSync(
        originalBytes: fixtureBytes,
        edits: scenario.edits,
        colorEdits: scenario.colorEdits,
        colorGradingEdits: scenario.gradingEdits,
      );
    }

    final samples = <int>[];
    for (var i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      applyEditsSync(
        originalBytes: fixtureBytes,
        edits: scenario.edits,
        colorEdits: scenario.colorEdits,
        colorGradingEdits: scenario.gradingEdits,
      );
      sw.stop();
      samples.add(sw.elapsedMicroseconds);
    }

    samples.sort();
    results[scenario.name] = {
      'median_ms': samples[samples.length ~/ 2] / 1000.0,
      'min_ms': samples.first / 1000.0,
      'max_ms': samples.last / 1000.0,
      'all_ms': [for (final s in samples) s / 1000.0],
    };
  }

  return results;
}

void printResults(String title, Map<String, Map<String, Object>> results) {
  // ignore: avoid_print
  print('\n=== $title ===');
  for (final entry in results.entries) {
    final r = entry.value;
    final median = (r['median_ms'] as double).toStringAsFixed(1).padLeft(9);
    final min = (r['min_ms'] as double).toStringAsFixed(1);
    final max = (r['max_ms'] as double).toStringAsFixed(1);
    // ignore: avoid_print
    print('${entry.key.padRight(24)} $median ms  (min $min, max $max)');
  }
}
