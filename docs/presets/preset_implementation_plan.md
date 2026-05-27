# Preset Implementation Plan

## Purpose

Moodit presets are global reusable editing recipes. A preset stores only the
active values from `EditorEditState`:

```json
{
  "edits": [],
  "colorEdits": [],
  "colorGradingEdits": []
}
```

It does not store project data, image bytes, versions, undo/redo stacks, or AI
history.

## Behavior

- Presets remain available across saved projects and drafts.
- Empty recipes cannot be saved.
- Names are trimmed, case-insensitively unique, and limited to 32 characters.
- Duplicate names report an error; they are never overwritten automatically.
- The presets list is ordered by `updated_at DESC`.
- Applying a preset always asks for `CANCEL`, `MERGE`, or `REPLACE`.
- `MERGE` overlays active preset values while preserving unrelated edits.
- `REPLACE` clears current edits and reproduces the saved recipe exactly.
- Save and apply actions are disabled while processing, waiting for AI, or
  while an AI proposal is pending.
- Applying a preset is one atomic history entry named `Preset <name>`.
- A no-op application does not add history.

## Phase 1: Domain And Persistence

- Add `EditorPreset` and `PresetApplyMode`.
- Add `EditorEditState.activeOnly()` and `EditorEditState.mergedWith()`.
- Add `preset` to `EditorEditSource`.
- Add the global `editor_presets` Drift table and bump schema version to `6`.
- Add a dedicated `PresetRepository`; keep it separate from project storage.

## Phase 2: Editor Logic

- Add a focused `PresetsViewModel` for list management.
- Inject the preset repository into `EditorViewModel`.
- Implement preset naming, saving, merge application, and replace application.
- Reuse the preview worker, version persistence, project preview persistence,
  and atomic history mechanisms already owned by `EditorViewModel`.

## Phase 3: UI Integration

- Enable the existing `Save as preset` export-menu option as a naming flow.
- Add `MyPresetsScreen` with management and editor-selection modes.
- Add `MY PRESETS` entry points on Home and in the editor drawer.
- Confirm the apply mode before changing editor state.
- Reuse the animated editor action banner for save, apply, undo, and redo
  feedback.

## Verification

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
git diff --check
```

Do not run a formatter during this increment.

## Out Of Scope

- thumbnails;
- categories, favorites, or search;
- preset import/export or cloud sync;
- recipe overwrite/update;
- AI-created preset commands;
- usage analytics.
