import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:licenta/domain/apply_edits.dart';
import 'package:licenta/domain/color_grading_operations.dart' as grading_ops;
import 'package:licenta/domain/color_operations.dart' as color_ops;
import 'package:licenta/model/color_edit.dart';
import 'package:licenta/model/color_grading_edit.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/rgba_image_frame.dart';

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

List<Scenario> buildSelectiveColorScenarios() {
  return [
    Scenario(
      'selective_single_range',
      colorEdits: [
        ColorEdit(range: ColorRange.blue, hue: 20, saturation: 25, luminance: 15),
      ],
    ),
    Scenario(
      'selective_hue_only',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, hue: 20),
      ],
    ),
    Scenario(
      'selective_saturation_only',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, saturation: 25),
      ],
    ),
    Scenario(
      'selective_luminance_only',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, luminance: 15),
      ],
    ),
    Scenario(
      'selective_hue_sat_only',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, hue: 20, saturation: 25),
      ],
    ),
    Scenario(
      'selective_all_ranges_heavy',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, hue: 20, saturation: 25, luminance: 15),
      ],
    ),
  ];
}

List<Scenario> buildCachedSelectiveColorScenarios() {
  return [
    Scenario(
      'cached_selective_hue_only',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, hue: 20),
      ],
    ),
    Scenario(
      'cached_selective_saturation_only',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, saturation: 25),
      ],
    ),
    Scenario(
      'cached_selective_hue_sat_only',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, hue: 20, saturation: 25),
      ],
    ),
    Scenario(
      'cached_selective_luminance_only',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, luminance: 15),
      ],
    ),
    Scenario(
      'cached_selective_all_ranges_heavy',
      colorEdits: [
        for (final range in ColorRange.values)
          ColorEdit(range: range, hue: 20, saturation: 25, luminance: 15),
      ],
    ),
  ];
}

List<Scenario> buildColorGradingScenarios() {
  return [
    Scenario(
      'grading_global_only',
      gradingEdits: [
        ColorGradingEdit(
          zone: ColorGradingZone.global,
          hue: 180,
          strength: 40,
          luminance: 20,
        ),
      ],
    ),
    Scenario(
      'grading_shadows_only',
      gradingEdits: [
        ColorGradingEdit(
          zone: ColorGradingZone.shadows,
          hue: 180,
          strength: 40,
          luminance: 20,
        ),
      ],
    ),
    Scenario(
      'grading_midtones_only',
      gradingEdits: [
        ColorGradingEdit(
          zone: ColorGradingZone.midtones,
          hue: 180,
          strength: 40,
          luminance: 20,
        ),
      ],
    ),
    Scenario(
      'grading_highlights_only',
      gradingEdits: [
        ColorGradingEdit(
          zone: ColorGradingZone.highlights,
          hue: 180,
          strength: 40,
          luminance: 20,
        ),
      ],
    ),
    Scenario(
      'grading_luminance_only',
      gradingEdits: [
        for (final zone in ColorGradingZone.values)
          ColorGradingEdit(zone: zone, luminance: 20),
      ],
    ),
    Scenario(
      'grading_hue_strength_only',
      gradingEdits: [
        for (final zone in ColorGradingZone.values)
          ColorGradingEdit(zone: zone, hue: 180, strength: 40),
      ],
    ),
    Scenario(
      'grading_all_zones_heavy',
      gradingEdits: [
        for (final zone in ColorGradingZone.values)
          ColorGradingEdit(
            zone: zone,
            hue: 180,
            strength: 40,
            luminance: 20,
          ),
      ],
    ),
  ];
}

List<Scenario> buildIndividualOperationScenarios() {
  return [
    for (final type in OperationType.values)
      Scenario(
        type.name,
        edits: [Edit(type: type, value: type.minValue == 0 ? 50 : 30)],
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
  final fixtureFrame = decodeRgbaImageFrame(fixtureBytes);

  for (final scenario in scenarios) {
    for (var i = 0; i < warmup; i++) {
      applyEditsToRgbaSync(
        originalFrame: fixtureFrame,
        edits: scenario.edits,
        colorEdits: scenario.colorEdits,
        colorGradingEdits: scenario.gradingEdits,
      );
    }

    final samples = <int>[];
    for (var i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      applyEditsToRgbaSync(
        originalFrame: fixtureFrame,
        edits: scenario.edits,
        colorEdits: scenario.colorEdits,
        colorGradingEdits: scenario.gradingEdits,
      );
      sw.stop();
      samples.add(sw.elapsedMicroseconds);
    }

    samples.sort();
    final average = samples.reduce((a, b) => a + b) / samples.length / 1000.0;
    results[scenario.name] = {
      'average_ms': average,
      'median_ms': samples[samples.length ~/ 2] / 1000.0,
      'min_ms': samples.first / 1000.0,
      'max_ms': samples.last / 1000.0,
      'all_ms': [for (final s in samples) s / 1000.0],
    };
  }

  return results;
}

Map<String, Map<String, Object>> runSelectiveColorPrepCacheBenchmark({
  required Uint8List fixtureBytes,
  required List<Scenario> scenarios,
  int warmup = defaultWarmup,
  int iterations = defaultIterations,
}) {
  final results = <String, Map<String, Object>>{};
  final fixtureFrame = decodeRgbaImageFrame(fixtureBytes);
  final sourceBytes = Uint8List.fromList(fixtureFrame.rgbaBytes);

  for (final scenario in scenarios) {
    final cache = color_ops.SelectiveColorPrepCache();
    final cacheKey = 'fixture:${scenario.name}';

    for (var i = 0; i < warmup; i++) {
      _applySelectiveColorWithPrepCache(
        sourceBytes: sourceBytes,
        width: fixtureFrame.width,
        height: fixtureFrame.height,
        scenario: scenario,
        cache: cache,
        cacheKey: cacheKey,
      );
    }

    final samples = <int>[];
    for (var i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      _applySelectiveColorWithPrepCache(
        sourceBytes: sourceBytes,
        width: fixtureFrame.width,
        height: fixtureFrame.height,
        scenario: scenario,
        cache: cache,
        cacheKey: cacheKey,
      );
      sw.stop();
      samples.add(sw.elapsedMicroseconds);
    }

    samples.sort();
    final average = samples.reduce((a, b) => a + b) / samples.length / 1000.0;
    results[scenario.name] = {
      'average_ms': average,
      'median_ms': samples[samples.length ~/ 2] / 1000.0,
      'min_ms': samples.first / 1000.0,
      'max_ms': samples.last / 1000.0,
      'all_ms': [for (final s in samples) s / 1000.0],
      'prep_build_count': cache.debugHueSatBuildCount,
      'mask_build_count': cache.debugHueSatMaskBuildCount,
      'luminance_prep_build_count': cache.debugLuminanceBuildCount,
      'luminance_mask_build_count': cache.debugLuminanceMaskBuildCount,
    };
  }

  return results;
}

Map<String, Map<String, Object>> runColorGradingPrepCacheBenchmark({
  required Uint8List fixtureBytes,
  required List<Scenario> scenarios,
  int warmup = defaultWarmup,
  int iterations = defaultIterations,
}) {
  final results = <String, Map<String, Object>>{};
  final fixtureFrame = decodeRgbaImageFrame(fixtureBytes);
  final sourceBytes = Uint8List.fromList(fixtureFrame.rgbaBytes);

  for (final scenario in scenarios) {
    final cache = grading_ops.ColorGradingPrepCache();
    final cacheKey = 'fixture:${scenario.name}';

    for (var i = 0; i < warmup; i++) {
      _applyColorGradingWithPrepCache(
        sourceBytes: sourceBytes,
        width: fixtureFrame.width,
        height: fixtureFrame.height,
        scenario: scenario,
        cache: cache,
        cacheKey: cacheKey,
      );
    }

    final samples = <int>[];
    for (var i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      _applyColorGradingWithPrepCache(
        sourceBytes: sourceBytes,
        width: fixtureFrame.width,
        height: fixtureFrame.height,
        scenario: scenario,
        cache: cache,
        cacheKey: cacheKey,
      );
      sw.stop();
      samples.add(sw.elapsedMicroseconds);
    }

    samples.sort();
    final average = samples.reduce((a, b) => a + b) / samples.length / 1000.0;
    results[scenario.name] = {
      'average_ms': average,
      'median_ms': samples[samples.length ~/ 2] / 1000.0,
      'min_ms': samples.first / 1000.0,
      'max_ms': samples.last / 1000.0,
      'all_ms': [for (final s in samples) s / 1000.0],
      'prep_build_count': cache.debugBuildCount,
    };
  }

  return results;
}

Map<String, Map<String, Object>> runStageCacheBenchmark({
  required Uint8List fixtureBytes,
  int warmup = defaultWarmup,
  int iterations = defaultIterations,
}) {
  final results = <String, Map<String, Object>>{};
  final fixtureFrame = decodeRgbaImageFrame(fixtureBytes);

  void recordScenario(
    String name, {
    required void Function() setUp,
    required void Function(int iteration) run,
  }) {
    setUp();
    for (var i = 0; i < warmup; i++) {
      run(-warmup + i);
    }

    final samples = <int>[];
    for (var i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      run(i);
      sw.stop();
      samples.add(sw.elapsedMicroseconds);
    }

    samples.sort();
    final average = samples.reduce((a, b) => a + b) / samples.length / 1000.0;
    results[name] = {
      'average_ms': average,
      'median_ms': samples[samples.length ~/ 2] / 1000.0,
      'min_ms': samples.first / 1000.0,
      'max_ms': samples.last / 1000.0,
      'all_ms': [for (final s in samples) s / 1000.0],
    };
  }

  final stageCache = EditPipelineStageCache();
  final selectivePrepCache = color_ops.SelectiveColorPrepCache();
  final gradingPrepCache = grading_ops.ColorGradingPrepCache();
  const stableBasicKey = 'fixture:basic:stable';
  const stableSelectiveKey = '$stableBasicKey|selective:stable';
  final stableBasicEdits = _stageCacheBasicEdits(0);
  final stableSelectiveEdits = _stageCacheSelectiveEdits(0);

  void resetCaches() {
    stageCache.clear();
    selectivePrepCache.clear();
    gradingPrepCache.clear();
  }

  recordScenario(
    'stage_cache_grading_update',
    setUp: () {
      resetCaches();
      applyEditsToRgbaWithStageCacheSync(
        originalFrame: fixtureFrame,
        edits: stableBasicEdits,
        colorEdits: stableSelectiveEdits,
        colorGradingEdits: _stageCacheGradingEdits(0),
        stageCache: stageCache,
        basicStageCacheKey: stableBasicKey,
        selectiveStageCacheKey: stableSelectiveKey,
        selectiveColorPrepCache: selectivePrepCache,
        selectiveColorPrepCacheKey: stableBasicKey,
        colorGradingPrepCache: gradingPrepCache,
        colorGradingPrepCacheKey: stableSelectiveKey,
      );
    },
    run: (i) {
      applyEditsToRgbaWithStageCacheSync(
        originalFrame: fixtureFrame,
        edits: stableBasicEdits,
        colorEdits: stableSelectiveEdits,
        colorGradingEdits: _stageCacheGradingEdits(i),
        stageCache: stageCache,
        basicStageCacheKey: stableBasicKey,
        selectiveStageCacheKey: stableSelectiveKey,
        selectiveColorPrepCache: selectivePrepCache,
        selectiveColorPrepCacheKey: stableBasicKey,
        colorGradingPrepCache: gradingPrepCache,
        colorGradingPrepCacheKey: stableSelectiveKey,
      );
    },
  );

  recordScenario(
    'stage_cache_selective_update',
    setUp: () {
      resetCaches();
      applyEditsToRgbaWithStageCacheSync(
        originalFrame: fixtureFrame,
        edits: stableBasicEdits,
        colorEdits: const [],
        colorGradingEdits: const [],
        stageCache: stageCache,
        basicStageCacheKey: stableBasicKey,
        selectiveStageCacheKey: '$stableBasicKey|selective:empty',
        selectiveColorPrepCache: selectivePrepCache,
        selectiveColorPrepCacheKey: stableBasicKey,
        colorGradingPrepCache: gradingPrepCache,
        colorGradingPrepCacheKey: '$stableBasicKey|selective:empty',
      );
    },
    run: (i) {
      final selectiveKey = '$stableBasicKey|selective:$i';
      applyEditsToRgbaWithStageCacheSync(
        originalFrame: fixtureFrame,
        edits: stableBasicEdits,
        colorEdits: _stageCacheSelectiveEdits(i),
        colorGradingEdits: _stageCacheGradingEdits(0),
        stageCache: stageCache,
        basicStageCacheKey: stableBasicKey,
        selectiveStageCacheKey: selectiveKey,
        selectiveColorPrepCache: selectivePrepCache,
        selectiveColorPrepCacheKey: stableBasicKey,
        colorGradingPrepCache: gradingPrepCache,
        colorGradingPrepCacheKey: selectiveKey,
      );
    },
  );

  recordScenario(
    'stage_cache_basic_update',
    setUp: resetCaches,
    run: (i) {
      final basicKey = 'fixture:basic:$i';
      final selectiveKey = '$basicKey|selective:stable';
      applyEditsToRgbaWithStageCacheSync(
        originalFrame: fixtureFrame,
        edits: _stageCacheBasicEdits(i),
        colorEdits: stableSelectiveEdits,
        colorGradingEdits: _stageCacheGradingEdits(0),
        stageCache: stageCache,
        basicStageCacheKey: basicKey,
        selectiveStageCacheKey: selectiveKey,
        selectiveColorPrepCache: selectivePrepCache,
        selectiveColorPrepCacheKey: basicKey,
        colorGradingPrepCache: gradingPrepCache,
        colorGradingPrepCacheKey: selectiveKey,
      );
    },
  );

  return results;
}

void _applySelectiveColorWithPrepCache({
  required Uint8List sourceBytes,
  required int width,
  required int height,
  required Scenario scenario,
  required color_ops.SelectiveColorPrepCache cache,
  required Object cacheKey,
}) {
  final image = imageFromRgbaFrame(RgbaImageFrame(
    rgbaBytes: Uint8List.fromList(sourceBytes),
    width: width,
    height: height,
  ));
  color_ops.applyAllColorEdits(
    image,
    scenario.colorEdits,
    prepCache: cache,
    prepCacheKey: cacheKey,
  );
}

List<Edit> _stageCacheBasicEdits(int variant) {
  final delta = (variant % 5).toDouble();
  return [
    Edit(type: OperationType.exposure, value: 30 + delta),
    Edit(type: OperationType.brightness, value: 20),
    Edit(type: OperationType.contrast, value: 25),
    Edit(type: OperationType.warmth, value: -15),
    Edit(type: OperationType.tint, value: 10),
  ];
}

List<ColorEdit> _stageCacheSelectiveEdits(int variant) {
  final delta = (variant % 5).toDouble();
  return [
    for (final range in ColorRange.values)
      ColorEdit(
        range: range,
        hue: 20 + delta,
        saturation: 25,
        luminance: 15,
      ),
  ];
}

List<ColorGradingEdit> _stageCacheGradingEdits(int variant) {
  final delta = (variant % 5).toDouble();
  return [
    for (final zone in ColorGradingZone.values)
      ColorGradingEdit(
        zone: zone,
        hue: 180 + delta,
        strength: 40,
        luminance: 20,
      ),
  ];
}

void _applyColorGradingWithPrepCache({
  required Uint8List sourceBytes,
  required int width,
  required int height,
  required Scenario scenario,
  required grading_ops.ColorGradingPrepCache cache,
  required Object cacheKey,
}) {
  final image = imageFromRgbaFrame(RgbaImageFrame(
    rgbaBytes: Uint8List.fromList(sourceBytes),
    width: width,
    height: height,
  ));
  grading_ops.applyColorGrading(
    image,
    scenario.gradingEdits,
    prepCache: cache,
    prepCacheKey: cacheKey,
  );
}

void printResults(String title, Map<String, Map<String, Object>> results) {
  // ignore: avoid_print
  print('\n=== $title ===');
  for (final entry in results.entries) {
    final r = entry.value;
    final average = (r['average_ms'] as double).toStringAsFixed(1).padLeft(9);
    final median = (r['median_ms'] as double).toStringAsFixed(1).padLeft(9);
    final min = (r['min_ms'] as double).toStringAsFixed(1);
    final max = (r['max_ms'] as double).toStringAsFixed(1);
    // ignore: avoid_print
    print(
      '${entry.key.padRight(24)} avg $average ms  '
      '(median $median, min $min, max $max)',
    );
  }
}
