import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:licenta/main.dart';
import 'package:licenta/model/chat_message.dart';
import 'package:licenta/model/editor_edit_state.dart';
import 'package:licenta/model/edit.dart';
import 'package:licenta/model/editor_preset.dart';
import 'package:licenta/model/editor_project.dart';
import 'package:licenta/model/editor_version.dart';
import 'package:licenta/model/export_option.dart';
import 'package:licenta/model/export_settings.dart';
import 'package:licenta/repositories/editor_project_repository.dart';
import 'package:licenta/repositories/preset_repository.dart';
import 'package:licenta/view/home/home_screen.dart';
import 'package:licenta/view/projects/project_details_screen.dart';
import 'package:licenta/view/projects/projects_screen.dart';
import 'package:licenta/view/presets/my_presets_screen.dart';
import 'package:licenta/view/editor/widgets/editor_drawer.dart';
import 'package:licenta/viewmodel/home_viewmodel.dart';
import 'package:licenta/viewmodel/project_details_viewmodel.dart';
import 'package:licenta/viewmodel/projects_viewmodel.dart';
import 'package:licenta/viewmodel/presets_viewmodel.dart';

void main() {
  testWidgets('app starts on the home actions', (WidgetTester tester) async {
    final homeViewModel = HomeViewModel(
      projectRepository: _NoDraftProjectRepository(),
      presetRepository: _FakePresetRepository(),
    );
    addTearDown(homeViewModel.dispose);

    await tester.pumpWidget(MyApp(homeViewModel: homeViewModel));
    await tester.pumpAndSettle();

    expect(find.text('MOOD-DRIVEN PHOTO EDITING'), findsOneWidget);
    expect(find.text('IMPORT PHOTO'), findsOneWidget);
    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('PRESETS'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(
      tester.getCenter(find.text('PROJECTS')).dy,
      greaterThan(tester.getCenter(find.text('IMPORT PHOTO')).dy),
    );
    // projects and presets cards sit side by side
    expect(
      tester.getCenter(find.text('PROJECTS')).dy,
      closeTo(tester.getCenter(find.text('PRESETS')).dy, 1),
    );
    // empty database renders zero counts and the empty recent state
    expect(find.text('0 saved'), findsOneWidget);
    expect(find.text('0 looks'), findsOneWidget);
    expect(find.text('NO PROJECTS YET'), findsOneWidget);
  });

  testWidgets('discarding a draft asks for confirmation', (tester) async {
    final repository = _NoDraftProjectRepository();
    repository.projects.add(_project(id: 7, status: EditorProjectStatus.draft));
    final homeViewModel = HomeViewModel(projectRepository: repository);
    addTearDown(homeViewModel.dispose);

    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(viewModel: homeViewModel),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('UNSAVED PROJECT'), findsOneWidget);

    await tester.tap(find.text('DISCARD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('DISCARD PROJECT'), findsOneWidget);
    expect(find.text('Are you sure? This is irreversible.'), findsOneWidget);

    await tester.tap(find.text('YES'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.deletedProjectIds, [7]);
  });

  testWidgets('projects screen shows empty state', (tester) async {
    final repository = _NoDraftProjectRepository();
    final projectsViewModel = ProjectsViewModel(projectRepository: repository);
    addTearDown(projectsViewModel.dispose);

    await tester.pumpWidget(MaterialApp(
      home: ProjectsScreen(viewModel: projectsViewModel),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('NO PROJECTS YET'), findsOneWidget);
  });

  testWidgets('projects screen lists saved projects', (tester) async {
    final repository = _NoDraftProjectRepository();
    repository.projects
      ..add(_project(id: 1, status: EditorProjectStatus.draft))
      ..add(_project(
        id: 2,
        status: EditorProjectStatus.saved,
        name: 'Saved portrait',
      ));
    final projectsViewModel = ProjectsViewModel(projectRepository: repository);
    addTearDown(projectsViewModel.dispose);

    await tester.pumpWidget(MaterialApp(
      home: ProjectsScreen(viewModel: projectsViewModel),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Saved portrait'), findsOneWidget);
    expect(find.text('PROJECT 1'), findsNothing);
  });

  testWidgets('project details shows actions and metadata', (tester) async {
    final repository = _NoDraftProjectRepository();
    repository.projects.add(_project(
      id: 2,
      status: EditorProjectStatus.saved,
      name: 'Saved portrait',
    ));
    final viewModel = ProjectDetailsViewModel(
      projectId: 2,
      projectRepository: repository,
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(MaterialApp(
      home: ProjectDetailsScreen(projectId: 2, viewModel: viewModel),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('PROJECT DETAILS'), findsOneWidget);
    expect(find.text('Saved portrait'), findsOneWidget);
    expect(find.text('RENAME'), findsOneWidget);
    expect(find.text('DELETE'), findsOneWidget);
    expect(find.text('PROJECT INFO'), findsOneWidget);
    expect(find.text('ORIGINAL SIZE'), findsOneWidget);
  });

  testWidgets('editor drawer exposes project settings when project is loaded',
      (tester) async {
    var openedProjectSettings = false;
    var openedPresets = false;
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        endDrawer: EditorDrawer(
          onOpenAiSettings: () {},
          onOpenProjectSettings: () {
            openedProjectSettings = true;
          },
          onOpenPresets: () {
            openedPresets = true;
          },
          showProjectSettings: true,
          canOpenProjectSettings: true,
          canOpenPresets: true,
          canSavePreset: true,
          onExport: (ExportOption option) {},
          exportSettings: const ExportSettings(),
          onExportSettingsChanged: (ExportSettings settings) {},
        ),
      ),
    ));
    scaffoldKey.currentState!.openEndDrawer();
    await tester.pumpAndSettle();

    expect(find.text('AI SETTINGS'), findsOneWidget);
    expect(find.text('PROJECT SETTINGS'), findsOneWidget);
    expect(find.text('MY PRESETS'), findsOneWidget);

    await tester.tap(find.text('PROJECT SETTINGS'));
    await tester.pumpAndSettle();

    expect(openedProjectSettings, isTrue);

    scaffoldKey.currentState!.openEndDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('MY PRESETS'));
    await tester.pumpAndSettle();

    expect(openedPresets, isTrue);
  });

  testWidgets('presets screen shows empty state', (tester) async {
    final repository = _FakePresetRepository();
    final presetsViewModel = PresetsViewModel(presetRepository: repository);
    addTearDown(presetsViewModel.dispose);

    await tester.pumpWidget(MaterialApp(
      home: MyPresetsScreen(viewModel: presetsViewModel),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('NO PRESETS YET'), findsOneWidget);
  });

  testWidgets('presets screen lists presets and confirms deletion', (tester) async {
    final repository = _FakePresetRepository()
      ..presets.add(_preset(id: 1, name: 'Portrait'));
    final presetsViewModel = PresetsViewModel(presetRepository: repository);
    addTearDown(presetsViewModel.dispose);

    await tester.pumpWidget(MaterialApp(
      home: MyPresetsScreen(viewModel: presetsViewModel),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Portrait'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete preset'));
    await tester.pump();

    expect(find.text('DELETE PRESET'), findsOneWidget);
    expect(find.textContaining('Are you sure? This cannot be restored.'), findsOneWidget);

    await tester.tap(find.text('DELETE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.presets, isEmpty);
  });
}

class _FakePresetRepository implements PresetRepository {
  final List<EditorPreset> presets = [];

  @override
  Future<EditorPreset> createPreset({
    required String name,
    required EditorEditState state,
    required DateTime createdAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePreset(int id) async {
    presets.removeWhere((preset) => preset.id == id);
  }

  @override
  Future<List<EditorPreset>> loadPresets() async => List.of(presets);

  @override
  Future<EditorPreset> renamePreset({
    required int id,
    required String name,
    required DateTime updatedAt,
  }) async {
    final index = presets.indexWhere((preset) => preset.id == id);
    final current = presets[index];
    final renamed = EditorPreset(
      id: current.id,
      name: name,
      state: current.state,
      createdAt: current.createdAt,
      updatedAt: updatedAt,
    );
    presets[index] = renamed;
    return renamed;
  }
}

EditorPreset _preset({
  required int id,
  required String name,
}) {
  final now = DateTime.utc(2026, 6, 1);
  return EditorPreset(
    id: id,
    name: name,
    state: EditorEditState(
      edits: [Edit(type: OperationType.contrast, value: 12)],
      colorEdits: const [],
      colorGradingEdits: const [],
    ),
    createdAt: now,
    updatedAt: now,
  );
}

class _NoDraftProjectRepository implements EditorProjectRepository {
  final List<EditorProject> projects = [];
  final List<int> deletedProjectIds = [];

  @override
  Future<void> deleteProject(int id) async {
    deletedProjectIds.add(id);
    projects.removeWhere((project) => project.id == id);
  }

  @override
  Future<List<ChatMessage>> loadAiMessagesForProject(int projectId) async {
    return const [];
  }

  @override
  Future<void> saveAiMessageForProject({
    required int projectId,
    required ChatMessage message,
  }) async {}

  @override
  Future<void> clearAiMessagesForProject(int projectId) async {}

  @override
  Future<List<ChatMessage>> loadAiMessagesForVersion({
    required int projectId,
    required String versionId,
  }) async {
    return const [];
  }

  @override
  Future<void> saveAiMessageForVersion({
    required int projectId,
    required String versionId,
    required ChatMessage message,
  }) async {}

  @override
  Future<void> cloneAiMessagesForVersion({
    required int projectId,
    required String sourceVersionId,
    required String targetVersionId,
  }) async {}

  @override
  Future<void> moveProjectAiMessagesToVersion({
    required int projectId,
    required String versionId,
  }) async {}

  @override
  Future<void> clearAiMessagesForVersion({
    required int projectId,
    required String versionId,
  }) async {}

  @override
  Future<void> deleteVersion(String id) async {}

  @override
  Future<EditorProject?> loadProject(int id) async {
    return projects.where((project) => project.id == id).firstOrNull;
  }

  @override
  Future<List<EditorProject>> loadRecentProjects({int limit = 20}) async {
    return projects
        .where((project) => project.status == EditorProjectStatus.saved)
        .take(limit)
        .toList();
  }

  @override
  Future<List<EditorProject>> loadRecoverableDrafts({int limit = 20}) async {
    return projects
        .where((project) => project.status == EditorProjectStatus.draft)
        .take(limit)
        .toList();
  }

  @override
  Future<EditorVersion?> loadVersion(String id) async => null;

  @override
  Future<List<EditorVersion>> loadVersions(int projectId) async => [];

  @override
  Future<void> markProjectOpened({
    required int projectId,
    required DateTime openedAt,
  }) async {}

  @override
  Future<void> promoteDraftToSaved({
    required int projectId,
    required String name,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    projects[index] = projects[index].copyWith(
      name: name,
      status: EditorProjectStatus.saved,
      currentState: state,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> renameProject({
    required int projectId,
    required String name,
    required DateTime updatedAt,
  }) async {
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    projects[index] = projects[index].copyWith(
      name: name,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> saveCurrentState({
    required int projectId,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {}

  @override
  Future<void> updateProjectPreviewPath({
    required int projectId,
    required String previewImagePath,
    required DateTime updatedAt,
  }) async {
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    projects[index] = projects[index].copyWith(
      previewImagePath: previewImagePath,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<EditorProject> saveProject(EditorProject project) async => project;

  @override
  Future<void> saveVersion(EditorVersion version) async {}

  @override
  Future<void> setActiveVersion({
    required int projectId,
    required String? versionId,
    required EditorEditState state,
    required DateTime updatedAt,
  }) async {}
}

EditorProject _project({
  required int id,
  required EditorProjectStatus status,
  String? name,
}) {
  final createdAt = DateTime.utc(2026, 5, 17, 9);
  return EditorProject(
    id: id,
    name: name ?? 'Project $id',
    status: status,
    originalImagePath: '/tmp/project_$id.jpg',
    currentState: EditorEditState.empty(),
    originalWidth: 16,
    originalHeight: 16,
    previewWidth: 16,
    previewHeight: 16,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
