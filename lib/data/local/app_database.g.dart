// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EditorProjectRecordsTable extends EditorProjectRecords
    with TableInfo<$EditorProjectRecordsTable, EditorProjectRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EditorProjectRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _activeVersionIdMeta = const VerificationMeta(
    'activeVersionId',
  );
  @override
  late final GeneratedColumn<String> activeVersionId = GeneratedColumn<String>(
    'active_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalImagePathMeta = const VerificationMeta(
    'originalImagePath',
  );
  @override
  late final GeneratedColumn<String> originalImagePath =
      GeneratedColumn<String>(
        'original_image_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _previewImagePathMeta = const VerificationMeta(
    'previewImagePath',
  );
  @override
  late final GeneratedColumn<String> previewImagePath = GeneratedColumn<String>(
    'preview_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentStateJsonMeta = const VerificationMeta(
    'currentStateJson',
  );
  @override
  late final GeneratedColumn<String> currentStateJson = GeneratedColumn<String>(
    'current_state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalWidthMeta = const VerificationMeta(
    'originalWidth',
  );
  @override
  late final GeneratedColumn<int> originalWidth = GeneratedColumn<int>(
    'original_width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalHeightMeta = const VerificationMeta(
    'originalHeight',
  );
  @override
  late final GeneratedColumn<int> originalHeight = GeneratedColumn<int>(
    'original_height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previewWidthMeta = const VerificationMeta(
    'previewWidth',
  );
  @override
  late final GeneratedColumn<int> previewWidth = GeneratedColumn<int>(
    'preview_width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previewHeightMeta = const VerificationMeta(
    'previewHeight',
  );
  @override
  late final GeneratedColumn<int> previewHeight = GeneratedColumn<int>(
    'preview_height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    status,
    activeVersionId,
    originalImagePath,
    previewImagePath,
    currentStateJson,
    originalWidth,
    originalHeight,
    previewWidth,
    previewHeight,
    createdAt,
    updatedAt,
    lastOpenedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'editor_projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<EditorProjectRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('active_version_id')) {
      context.handle(
        _activeVersionIdMeta,
        activeVersionId.isAcceptableOrUnknown(
          data['active_version_id']!,
          _activeVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('original_image_path')) {
      context.handle(
        _originalImagePathMeta,
        originalImagePath.isAcceptableOrUnknown(
          data['original_image_path']!,
          _originalImagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalImagePathMeta);
    }
    if (data.containsKey('preview_image_path')) {
      context.handle(
        _previewImagePathMeta,
        previewImagePath.isAcceptableOrUnknown(
          data['preview_image_path']!,
          _previewImagePathMeta,
        ),
      );
    }
    if (data.containsKey('current_state_json')) {
      context.handle(
        _currentStateJsonMeta,
        currentStateJson.isAcceptableOrUnknown(
          data['current_state_json']!,
          _currentStateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentStateJsonMeta);
    }
    if (data.containsKey('original_width')) {
      context.handle(
        _originalWidthMeta,
        originalWidth.isAcceptableOrUnknown(
          data['original_width']!,
          _originalWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalWidthMeta);
    }
    if (data.containsKey('original_height')) {
      context.handle(
        _originalHeightMeta,
        originalHeight.isAcceptableOrUnknown(
          data['original_height']!,
          _originalHeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalHeightMeta);
    }
    if (data.containsKey('preview_width')) {
      context.handle(
        _previewWidthMeta,
        previewWidth.isAcceptableOrUnknown(
          data['preview_width']!,
          _previewWidthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previewWidthMeta);
    }
    if (data.containsKey('preview_height')) {
      context.handle(
        _previewHeightMeta,
        previewHeight.isAcceptableOrUnknown(
          data['preview_height']!,
          _previewHeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previewHeightMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EditorProjectRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EditorProjectRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      activeVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_version_id'],
      ),
      originalImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_image_path'],
      )!,
      previewImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_image_path'],
      ),
      currentStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_state_json'],
      )!,
      originalWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_width'],
      )!,
      originalHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_height'],
      )!,
      previewWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preview_width'],
      )!,
      previewHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preview_height'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
    );
  }

  @override
  $EditorProjectRecordsTable createAlias(String alias) {
    return $EditorProjectRecordsTable(attachedDatabase, alias);
  }
}

class EditorProjectRecord extends DataClass
    implements Insertable<EditorProjectRecord> {
  final int id;
  final String name;
  final String status;
  final String? activeVersionId;
  final String originalImagePath;
  final String? previewImagePath;
  final String currentStateJson;
  final int originalWidth;
  final int originalHeight;
  final int previewWidth;
  final int previewHeight;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;
  const EditorProjectRecord({
    required this.id,
    required this.name,
    required this.status,
    this.activeVersionId,
    required this.originalImagePath,
    this.previewImagePath,
    required this.currentStateJson,
    required this.originalWidth,
    required this.originalHeight,
    required this.previewWidth,
    required this.previewHeight,
    required this.createdAt,
    required this.updatedAt,
    this.lastOpenedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || activeVersionId != null) {
      map['active_version_id'] = Variable<String>(activeVersionId);
    }
    map['original_image_path'] = Variable<String>(originalImagePath);
    if (!nullToAbsent || previewImagePath != null) {
      map['preview_image_path'] = Variable<String>(previewImagePath);
    }
    map['current_state_json'] = Variable<String>(currentStateJson);
    map['original_width'] = Variable<int>(originalWidth);
    map['original_height'] = Variable<int>(originalHeight);
    map['preview_width'] = Variable<int>(previewWidth);
    map['preview_height'] = Variable<int>(previewHeight);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    return map;
  }

  EditorProjectRecordsCompanion toCompanion(bool nullToAbsent) {
    return EditorProjectRecordsCompanion(
      id: Value(id),
      name: Value(name),
      status: Value(status),
      activeVersionId: activeVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeVersionId),
      originalImagePath: Value(originalImagePath),
      previewImagePath: previewImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(previewImagePath),
      currentStateJson: Value(currentStateJson),
      originalWidth: Value(originalWidth),
      originalHeight: Value(originalHeight),
      previewWidth: Value(previewWidth),
      previewHeight: Value(previewHeight),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
    );
  }

  factory EditorProjectRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EditorProjectRecord(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      status: serializer.fromJson<String>(json['status']),
      activeVersionId: serializer.fromJson<String?>(json['activeVersionId']),
      originalImagePath: serializer.fromJson<String>(json['originalImagePath']),
      previewImagePath: serializer.fromJson<String?>(json['previewImagePath']),
      currentStateJson: serializer.fromJson<String>(json['currentStateJson']),
      originalWidth: serializer.fromJson<int>(json['originalWidth']),
      originalHeight: serializer.fromJson<int>(json['originalHeight']),
      previewWidth: serializer.fromJson<int>(json['previewWidth']),
      previewHeight: serializer.fromJson<int>(json['previewHeight']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(status),
      'activeVersionId': serializer.toJson<String?>(activeVersionId),
      'originalImagePath': serializer.toJson<String>(originalImagePath),
      'previewImagePath': serializer.toJson<String?>(previewImagePath),
      'currentStateJson': serializer.toJson<String>(currentStateJson),
      'originalWidth': serializer.toJson<int>(originalWidth),
      'originalHeight': serializer.toJson<int>(originalHeight),
      'previewWidth': serializer.toJson<int>(previewWidth),
      'previewHeight': serializer.toJson<int>(previewHeight),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
    };
  }

  EditorProjectRecord copyWith({
    int? id,
    String? name,
    String? status,
    Value<String?> activeVersionId = const Value.absent(),
    String? originalImagePath,
    Value<String?> previewImagePath = const Value.absent(),
    String? currentStateJson,
    int? originalWidth,
    int? originalHeight,
    int? previewWidth,
    int? previewHeight,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
  }) => EditorProjectRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    status: status ?? this.status,
    activeVersionId: activeVersionId.present
        ? activeVersionId.value
        : this.activeVersionId,
    originalImagePath: originalImagePath ?? this.originalImagePath,
    previewImagePath: previewImagePath.present
        ? previewImagePath.value
        : this.previewImagePath,
    currentStateJson: currentStateJson ?? this.currentStateJson,
    originalWidth: originalWidth ?? this.originalWidth,
    originalHeight: originalHeight ?? this.originalHeight,
    previewWidth: previewWidth ?? this.previewWidth,
    previewHeight: previewHeight ?? this.previewHeight,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
  );
  EditorProjectRecord copyWithCompanion(EditorProjectRecordsCompanion data) {
    return EditorProjectRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      activeVersionId: data.activeVersionId.present
          ? data.activeVersionId.value
          : this.activeVersionId,
      originalImagePath: data.originalImagePath.present
          ? data.originalImagePath.value
          : this.originalImagePath,
      previewImagePath: data.previewImagePath.present
          ? data.previewImagePath.value
          : this.previewImagePath,
      currentStateJson: data.currentStateJson.present
          ? data.currentStateJson.value
          : this.currentStateJson,
      originalWidth: data.originalWidth.present
          ? data.originalWidth.value
          : this.originalWidth,
      originalHeight: data.originalHeight.present
          ? data.originalHeight.value
          : this.originalHeight,
      previewWidth: data.previewWidth.present
          ? data.previewWidth.value
          : this.previewWidth,
      previewHeight: data.previewHeight.present
          ? data.previewHeight.value
          : this.previewHeight,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EditorProjectRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('activeVersionId: $activeVersionId, ')
          ..write('originalImagePath: $originalImagePath, ')
          ..write('previewImagePath: $previewImagePath, ')
          ..write('currentStateJson: $currentStateJson, ')
          ..write('originalWidth: $originalWidth, ')
          ..write('originalHeight: $originalHeight, ')
          ..write('previewWidth: $previewWidth, ')
          ..write('previewHeight: $previewHeight, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    status,
    activeVersionId,
    originalImagePath,
    previewImagePath,
    currentStateJson,
    originalWidth,
    originalHeight,
    previewWidth,
    previewHeight,
    createdAt,
    updatedAt,
    lastOpenedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EditorProjectRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.status == this.status &&
          other.activeVersionId == this.activeVersionId &&
          other.originalImagePath == this.originalImagePath &&
          other.previewImagePath == this.previewImagePath &&
          other.currentStateJson == this.currentStateJson &&
          other.originalWidth == this.originalWidth &&
          other.originalHeight == this.originalHeight &&
          other.previewWidth == this.previewWidth &&
          other.previewHeight == this.previewHeight &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastOpenedAt == this.lastOpenedAt);
}

class EditorProjectRecordsCompanion
    extends UpdateCompanion<EditorProjectRecord> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> status;
  final Value<String?> activeVersionId;
  final Value<String> originalImagePath;
  final Value<String?> previewImagePath;
  final Value<String> currentStateJson;
  final Value<int> originalWidth;
  final Value<int> originalHeight;
  final Value<int> previewWidth;
  final Value<int> previewHeight;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastOpenedAt;
  const EditorProjectRecordsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.activeVersionId = const Value.absent(),
    this.originalImagePath = const Value.absent(),
    this.previewImagePath = const Value.absent(),
    this.currentStateJson = const Value.absent(),
    this.originalWidth = const Value.absent(),
    this.originalHeight = const Value.absent(),
    this.previewWidth = const Value.absent(),
    this.previewHeight = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
  });
  EditorProjectRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.status = const Value.absent(),
    this.activeVersionId = const Value.absent(),
    required String originalImagePath,
    this.previewImagePath = const Value.absent(),
    required String currentStateJson,
    required int originalWidth,
    required int originalHeight,
    required int previewWidth,
    required int previewHeight,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastOpenedAt = const Value.absent(),
  }) : name = Value(name),
       originalImagePath = Value(originalImagePath),
       currentStateJson = Value(currentStateJson),
       originalWidth = Value(originalWidth),
       originalHeight = Value(originalHeight),
       previewWidth = Value(previewWidth),
       previewHeight = Value(previewHeight),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EditorProjectRecord> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? status,
    Expression<String>? activeVersionId,
    Expression<String>? originalImagePath,
    Expression<String>? previewImagePath,
    Expression<String>? currentStateJson,
    Expression<int>? originalWidth,
    Expression<int>? originalHeight,
    Expression<int>? previewWidth,
    Expression<int>? previewHeight,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastOpenedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (activeVersionId != null) 'active_version_id': activeVersionId,
      if (originalImagePath != null) 'original_image_path': originalImagePath,
      if (previewImagePath != null) 'preview_image_path': previewImagePath,
      if (currentStateJson != null) 'current_state_json': currentStateJson,
      if (originalWidth != null) 'original_width': originalWidth,
      if (originalHeight != null) 'original_height': originalHeight,
      if (previewWidth != null) 'preview_width': previewWidth,
      if (previewHeight != null) 'preview_height': previewHeight,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
    });
  }

  EditorProjectRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? status,
    Value<String?>? activeVersionId,
    Value<String>? originalImagePath,
    Value<String?>? previewImagePath,
    Value<String>? currentStateJson,
    Value<int>? originalWidth,
    Value<int>? originalHeight,
    Value<int>? previewWidth,
    Value<int>? previewHeight,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastOpenedAt,
  }) {
    return EditorProjectRecordsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      activeVersionId: activeVersionId ?? this.activeVersionId,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      previewImagePath: previewImagePath ?? this.previewImagePath,
      currentStateJson: currentStateJson ?? this.currentStateJson,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
      previewWidth: previewWidth ?? this.previewWidth,
      previewHeight: previewHeight ?? this.previewHeight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (activeVersionId.present) {
      map['active_version_id'] = Variable<String>(activeVersionId.value);
    }
    if (originalImagePath.present) {
      map['original_image_path'] = Variable<String>(originalImagePath.value);
    }
    if (previewImagePath.present) {
      map['preview_image_path'] = Variable<String>(previewImagePath.value);
    }
    if (currentStateJson.present) {
      map['current_state_json'] = Variable<String>(currentStateJson.value);
    }
    if (originalWidth.present) {
      map['original_width'] = Variable<int>(originalWidth.value);
    }
    if (originalHeight.present) {
      map['original_height'] = Variable<int>(originalHeight.value);
    }
    if (previewWidth.present) {
      map['preview_width'] = Variable<int>(previewWidth.value);
    }
    if (previewHeight.present) {
      map['preview_height'] = Variable<int>(previewHeight.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EditorProjectRecordsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('activeVersionId: $activeVersionId, ')
          ..write('originalImagePath: $originalImagePath, ')
          ..write('previewImagePath: $previewImagePath, ')
          ..write('currentStateJson: $currentStateJson, ')
          ..write('originalWidth: $originalWidth, ')
          ..write('originalHeight: $originalHeight, ')
          ..write('previewWidth: $previewWidth, ')
          ..write('previewHeight: $previewHeight, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }
}

class $EditorVersionRecordsTable extends EditorVersionRecords
    with TableInfo<$EditorVersionRecordsTable, EditorVersionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EditorVersionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES editor_projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentVersionIdMeta = const VerificationMeta(
    'parentVersionId',
  );
  @override
  late final GeneratedColumn<String> parentVersionId = GeneratedColumn<String>(
    'parent_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _historyJsonMeta = const VerificationMeta(
    'historyJson',
  );
  @override
  late final GeneratedColumn<String> historyJson = GeneratedColumn<String>(
    'history_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(EditorHistorySnapshot.emptyJson),
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiReferenceImagePathMeta =
      const VerificationMeta('aiReferenceImagePath');
  @override
  late final GeneratedColumn<String> aiReferenceImagePath =
      GeneratedColumn<String>(
        'ai_reference_image_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    name,
    parentVersionId,
    stateJson,
    historyJson,
    thumbnailPath,
    aiReferenceImagePath,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'editor_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<EditorVersionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_version_id')) {
      context.handle(
        _parentVersionIdMeta,
        parentVersionId.isAcceptableOrUnknown(
          data['parent_version_id']!,
          _parentVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    if (data.containsKey('history_json')) {
      context.handle(
        _historyJsonMeta,
        historyJson.isAcceptableOrUnknown(
          data['history_json']!,
          _historyJsonMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('ai_reference_image_path')) {
      context.handle(
        _aiReferenceImagePathMeta,
        aiReferenceImagePath.isAcceptableOrUnknown(
          data['ai_reference_image_path']!,
          _aiReferenceImagePathMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EditorVersionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EditorVersionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_version_id'],
      ),
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
      historyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}history_json'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      aiReferenceImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_reference_image_path'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EditorVersionRecordsTable createAlias(String alias) {
    return $EditorVersionRecordsTable(attachedDatabase, alias);
  }
}

class EditorVersionRecord extends DataClass
    implements Insertable<EditorVersionRecord> {
  final String id;
  final int projectId;
  final String name;
  final String? parentVersionId;
  final String stateJson;
  final String historyJson;
  final String? thumbnailPath;
  final String? aiReferenceImagePath;
  final int sortOrder;
  final DateTime createdAt;
  const EditorVersionRecord({
    required this.id,
    required this.projectId,
    required this.name,
    this.parentVersionId,
    required this.stateJson,
    required this.historyJson,
    this.thumbnailPath,
    this.aiReferenceImagePath,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<int>(projectId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentVersionId != null) {
      map['parent_version_id'] = Variable<String>(parentVersionId);
    }
    map['state_json'] = Variable<String>(stateJson);
    map['history_json'] = Variable<String>(historyJson);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || aiReferenceImagePath != null) {
      map['ai_reference_image_path'] = Variable<String>(aiReferenceImagePath);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EditorVersionRecordsCompanion toCompanion(bool nullToAbsent) {
    return EditorVersionRecordsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      parentVersionId: parentVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentVersionId),
      stateJson: Value(stateJson),
      historyJson: Value(historyJson),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      aiReferenceImagePath: aiReferenceImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(aiReferenceImagePath),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory EditorVersionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EditorVersionRecord(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      parentVersionId: serializer.fromJson<String?>(json['parentVersionId']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
      historyJson: serializer.fromJson<String>(json['historyJson']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      aiReferenceImagePath: serializer.fromJson<String?>(
        json['aiReferenceImagePath'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<int>(projectId),
      'name': serializer.toJson<String>(name),
      'parentVersionId': serializer.toJson<String?>(parentVersionId),
      'stateJson': serializer.toJson<String>(stateJson),
      'historyJson': serializer.toJson<String>(historyJson),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'aiReferenceImagePath': serializer.toJson<String?>(aiReferenceImagePath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EditorVersionRecord copyWith({
    String? id,
    int? projectId,
    String? name,
    Value<String?> parentVersionId = const Value.absent(),
    String? stateJson,
    String? historyJson,
    Value<String?> thumbnailPath = const Value.absent(),
    Value<String?> aiReferenceImagePath = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
  }) => EditorVersionRecord(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    parentVersionId: parentVersionId.present
        ? parentVersionId.value
        : this.parentVersionId,
    stateJson: stateJson ?? this.stateJson,
    historyJson: historyJson ?? this.historyJson,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    aiReferenceImagePath: aiReferenceImagePath.present
        ? aiReferenceImagePath.value
        : this.aiReferenceImagePath,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  EditorVersionRecord copyWithCompanion(EditorVersionRecordsCompanion data) {
    return EditorVersionRecord(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      parentVersionId: data.parentVersionId.present
          ? data.parentVersionId.value
          : this.parentVersionId,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
      historyJson: data.historyJson.present
          ? data.historyJson.value
          : this.historyJson,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      aiReferenceImagePath: data.aiReferenceImagePath.present
          ? data.aiReferenceImagePath.value
          : this.aiReferenceImagePath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EditorVersionRecord(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('parentVersionId: $parentVersionId, ')
          ..write('stateJson: $stateJson, ')
          ..write('historyJson: $historyJson, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('aiReferenceImagePath: $aiReferenceImagePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    name,
    parentVersionId,
    stateJson,
    historyJson,
    thumbnailPath,
    aiReferenceImagePath,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EditorVersionRecord &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.parentVersionId == this.parentVersionId &&
          other.stateJson == this.stateJson &&
          other.historyJson == this.historyJson &&
          other.thumbnailPath == this.thumbnailPath &&
          other.aiReferenceImagePath == this.aiReferenceImagePath &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class EditorVersionRecordsCompanion
    extends UpdateCompanion<EditorVersionRecord> {
  final Value<String> id;
  final Value<int> projectId;
  final Value<String> name;
  final Value<String?> parentVersionId;
  final Value<String> stateJson;
  final Value<String> historyJson;
  final Value<String?> thumbnailPath;
  final Value<String?> aiReferenceImagePath;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EditorVersionRecordsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.parentVersionId = const Value.absent(),
    this.stateJson = const Value.absent(),
    this.historyJson = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.aiReferenceImagePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EditorVersionRecordsCompanion.insert({
    required String id,
    required int projectId,
    required String name,
    this.parentVersionId = const Value.absent(),
    required String stateJson,
    this.historyJson = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.aiReferenceImagePath = const Value.absent(),
    required int sortOrder,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name),
       stateJson = Value(stateJson),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt);
  static Insertable<EditorVersionRecord> custom({
    Expression<String>? id,
    Expression<int>? projectId,
    Expression<String>? name,
    Expression<String>? parentVersionId,
    Expression<String>? stateJson,
    Expression<String>? historyJson,
    Expression<String>? thumbnailPath,
    Expression<String>? aiReferenceImagePath,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (parentVersionId != null) 'parent_version_id': parentVersionId,
      if (stateJson != null) 'state_json': stateJson,
      if (historyJson != null) 'history_json': historyJson,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (aiReferenceImagePath != null)
        'ai_reference_image_path': aiReferenceImagePath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EditorVersionRecordsCompanion copyWith({
    Value<String>? id,
    Value<int>? projectId,
    Value<String>? name,
    Value<String?>? parentVersionId,
    Value<String>? stateJson,
    Value<String>? historyJson,
    Value<String?>? thumbnailPath,
    Value<String?>? aiReferenceImagePath,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EditorVersionRecordsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      parentVersionId: parentVersionId ?? this.parentVersionId,
      stateJson: stateJson ?? this.stateJson,
      historyJson: historyJson ?? this.historyJson,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      aiReferenceImagePath: aiReferenceImagePath ?? this.aiReferenceImagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentVersionId.present) {
      map['parent_version_id'] = Variable<String>(parentVersionId.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    if (historyJson.present) {
      map['history_json'] = Variable<String>(historyJson.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (aiReferenceImagePath.present) {
      map['ai_reference_image_path'] = Variable<String>(
        aiReferenceImagePath.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EditorVersionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('parentVersionId: $parentVersionId, ')
          ..write('stateJson: $stateJson, ')
          ..write('historyJson: $historyJson, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('aiReferenceImagePath: $aiReferenceImagePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiChatMessageRecordsTable extends AiChatMessageRecords
    with TableInfo<$AiChatMessageRecordsTable, AiChatMessageRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiChatMessageRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES editor_projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<String> versionId = GeneratedColumn<String>(
    'version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES editor_versions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageTextMeta = const VerificationMeta(
    'messageText',
  );
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    versionId,
    type,
    messageText,
    createdAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiChatMessageRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _messageTextMeta,
        messageText.isAcceptableOrUnknown(data['text']!, _messageTextMeta),
      );
    } else if (isInserting) {
      context.missing(_messageTextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiChatMessageRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiChatMessageRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      )!,
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      messageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AiChatMessageRecordsTable createAlias(String alias) {
    return $AiChatMessageRecordsTable(attachedDatabase, alias);
  }
}

class AiChatMessageRecord extends DataClass
    implements Insertable<AiChatMessageRecord> {
  final int id;
  final int projectId;
  final String? versionId;
  final String type;
  final String messageText;
  final DateTime createdAt;
  final int sortOrder;
  const AiChatMessageRecord({
    required this.id,
    required this.projectId,
    this.versionId,
    required this.type,
    required this.messageText,
    required this.createdAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    if (!nullToAbsent || versionId != null) {
      map['version_id'] = Variable<String>(versionId);
    }
    map['type'] = Variable<String>(type);
    map['text'] = Variable<String>(messageText);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AiChatMessageRecordsCompanion toCompanion(bool nullToAbsent) {
    return AiChatMessageRecordsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      versionId: versionId == null && nullToAbsent
          ? const Value.absent()
          : Value(versionId),
      type: Value(type),
      messageText: Value(messageText),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory AiChatMessageRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiChatMessageRecord(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      versionId: serializer.fromJson<String?>(json['versionId']),
      type: serializer.fromJson<String>(json['type']),
      messageText: serializer.fromJson<String>(json['messageText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'versionId': serializer.toJson<String?>(versionId),
      'type': serializer.toJson<String>(type),
      'messageText': serializer.toJson<String>(messageText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AiChatMessageRecord copyWith({
    int? id,
    int? projectId,
    Value<String?> versionId = const Value.absent(),
    String? type,
    String? messageText,
    DateTime? createdAt,
    int? sortOrder,
  }) => AiChatMessageRecord(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    versionId: versionId.present ? versionId.value : this.versionId,
    type: type ?? this.type,
    messageText: messageText ?? this.messageText,
    createdAt: createdAt ?? this.createdAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AiChatMessageRecord copyWithCompanion(AiChatMessageRecordsCompanion data) {
    return AiChatMessageRecord(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      type: data.type.present ? data.type.value : this.type,
      messageText: data.messageText.present
          ? data.messageText.value
          : this.messageText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiChatMessageRecord(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('versionId: $versionId, ')
          ..write('type: $type, ')
          ..write('messageText: $messageText, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    versionId,
    type,
    messageText,
    createdAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiChatMessageRecord &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.versionId == this.versionId &&
          other.type == this.type &&
          other.messageText == this.messageText &&
          other.createdAt == this.createdAt &&
          other.sortOrder == this.sortOrder);
}

class AiChatMessageRecordsCompanion
    extends UpdateCompanion<AiChatMessageRecord> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String?> versionId;
  final Value<String> type;
  final Value<String> messageText;
  final Value<DateTime> createdAt;
  final Value<int> sortOrder;
  const AiChatMessageRecordsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.versionId = const Value.absent(),
    this.type = const Value.absent(),
    this.messageText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  AiChatMessageRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    this.versionId = const Value.absent(),
    required String type,
    required String messageText,
    required DateTime createdAt,
    required int sortOrder,
  }) : projectId = Value(projectId),
       type = Value(type),
       messageText = Value(messageText),
       createdAt = Value(createdAt),
       sortOrder = Value(sortOrder);
  static Insertable<AiChatMessageRecord> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? versionId,
    Expression<String>? type,
    Expression<String>? messageText,
    Expression<DateTime>? createdAt,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (versionId != null) 'version_id': versionId,
      if (type != null) 'type': type,
      if (messageText != null) 'text': messageText,
      if (createdAt != null) 'created_at': createdAt,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  AiChatMessageRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? projectId,
    Value<String?>? versionId,
    Value<String>? type,
    Value<String>? messageText,
    Value<DateTime>? createdAt,
    Value<int>? sortOrder,
  }) {
    return AiChatMessageRecordsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      versionId: versionId ?? this.versionId,
      type: type ?? this.type,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (versionId.present) {
      map['version_id'] = Variable<String>(versionId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (messageText.present) {
      map['text'] = Variable<String>(messageText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiChatMessageRecordsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('versionId: $versionId, ')
          ..write('type: $type, ')
          ..write('messageText: $messageText, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $EditorPresetRecordsTable extends EditorPresetRecords
    with TableInfo<$EditorPresetRecordsTable, EditorPresetRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EditorPresetRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    stateJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'editor_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<EditorPresetRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EditorPresetRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EditorPresetRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EditorPresetRecordsTable createAlias(String alias) {
    return $EditorPresetRecordsTable(attachedDatabase, alias);
  }
}

class EditorPresetRecord extends DataClass
    implements Insertable<EditorPresetRecord> {
  final int id;
  final String name;
  final String normalizedName;
  final String stateJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EditorPresetRecord({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.stateJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['state_json'] = Variable<String>(stateJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EditorPresetRecordsCompanion toCompanion(bool nullToAbsent) {
    return EditorPresetRecordsCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      stateJson: Value(stateJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EditorPresetRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EditorPresetRecord(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'stateJson': serializer.toJson<String>(stateJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EditorPresetRecord copyWith({
    int? id,
    String? name,
    String? normalizedName,
    String? stateJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EditorPresetRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    stateJson: stateJson ?? this.stateJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EditorPresetRecord copyWithCompanion(EditorPresetRecordsCompanion data) {
    return EditorPresetRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EditorPresetRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('stateJson: $stateJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, normalizedName, stateJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EditorPresetRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.stateJson == this.stateJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EditorPresetRecordsCompanion extends UpdateCompanion<EditorPresetRecord> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String> stateJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EditorPresetRecordsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.stateJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EditorPresetRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String normalizedName,
    required String stateJson,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       normalizedName = Value(normalizedName),
       stateJson = Value(stateJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EditorPresetRecord> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? stateJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (stateJson != null) 'state_json': stateJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EditorPresetRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String>? stateJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return EditorPresetRecordsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      stateJson: stateJson ?? this.stateJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EditorPresetRecordsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('stateJson: $stateJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EditorProjectRecordsTable editorProjectRecords =
      $EditorProjectRecordsTable(this);
  late final $EditorVersionRecordsTable editorVersionRecords =
      $EditorVersionRecordsTable(this);
  late final $AiChatMessageRecordsTable aiChatMessageRecords =
      $AiChatMessageRecordsTable(this);
  late final $EditorPresetRecordsTable editorPresetRecords =
      $EditorPresetRecordsTable(this);
  late final AiChatMessagesDao aiChatMessagesDao = AiChatMessagesDao(
    this as AppDatabase,
  );
  late final EditorProjectsDao editorProjectsDao = EditorProjectsDao(
    this as AppDatabase,
  );
  late final EditorPresetsDao editorPresetsDao = EditorPresetsDao(
    this as AppDatabase,
  );
  late final EditorVersionsDao editorVersionsDao = EditorVersionsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    editorProjectRecords,
    editorVersionRecords,
    aiChatMessageRecords,
    editorPresetRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'editor_projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('editor_versions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'editor_projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ai_chat_messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'editor_versions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ai_chat_messages', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$EditorProjectRecordsTableCreateCompanionBuilder =
    EditorProjectRecordsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> status,
      Value<String?> activeVersionId,
      required String originalImagePath,
      Value<String?> previewImagePath,
      required String currentStateJson,
      required int originalWidth,
      required int originalHeight,
      required int previewWidth,
      required int previewHeight,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastOpenedAt,
    });
typedef $$EditorProjectRecordsTableUpdateCompanionBuilder =
    EditorProjectRecordsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> status,
      Value<String?> activeVersionId,
      Value<String> originalImagePath,
      Value<String?> previewImagePath,
      Value<String> currentStateJson,
      Value<int> originalWidth,
      Value<int> originalHeight,
      Value<int> previewWidth,
      Value<int> previewHeight,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastOpenedAt,
    });

final class $$EditorProjectRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EditorProjectRecordsTable,
          EditorProjectRecord
        > {
  $$EditorProjectRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $EditorVersionRecordsTable,
    List<EditorVersionRecord>
  >
  _editorVersionRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.editorVersionRecords,
        aliasName: $_aliasNameGenerator(
          db.editorProjectRecords.id,
          db.editorVersionRecords.projectId,
        ),
      );

  $$EditorVersionRecordsTableProcessedTableManager
  get editorVersionRecordsRefs {
    final manager = $$EditorVersionRecordsTableTableManager(
      $_db,
      $_db.editorVersionRecords,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _editorVersionRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AiChatMessageRecordsTable,
    List<AiChatMessageRecord>
  >
  _aiChatMessageRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.aiChatMessageRecords,
        aliasName: $_aliasNameGenerator(
          db.editorProjectRecords.id,
          db.aiChatMessageRecords.projectId,
        ),
      );

  $$AiChatMessageRecordsTableProcessedTableManager
  get aiChatMessageRecordsRefs {
    final manager = $$AiChatMessageRecordsTableTableManager(
      $_db,
      $_db.aiChatMessageRecords,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _aiChatMessageRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EditorProjectRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $EditorProjectRecordsTable> {
  $$EditorProjectRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeVersionId => $composableBuilder(
    column: $table.activeVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewImagePath => $composableBuilder(
    column: $table.previewImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentStateJson => $composableBuilder(
    column: $table.currentStateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalWidth => $composableBuilder(
    column: $table.originalWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalHeight => $composableBuilder(
    column: $table.originalHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previewWidth => $composableBuilder(
    column: $table.previewWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get previewHeight => $composableBuilder(
    column: $table.previewHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> editorVersionRecordsRefs(
    Expression<bool> Function($$EditorVersionRecordsTableFilterComposer f) f,
  ) {
    final $$EditorVersionRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.editorVersionRecords,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditorVersionRecordsTableFilterComposer(
            $db: $db,
            $table: $db.editorVersionRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> aiChatMessageRecordsRefs(
    Expression<bool> Function($$AiChatMessageRecordsTableFilterComposer f) f,
  ) {
    final $$AiChatMessageRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiChatMessageRecords,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiChatMessageRecordsTableFilterComposer(
            $db: $db,
            $table: $db.aiChatMessageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EditorProjectRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $EditorProjectRecordsTable> {
  $$EditorProjectRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeVersionId => $composableBuilder(
    column: $table.activeVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewImagePath => $composableBuilder(
    column: $table.previewImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentStateJson => $composableBuilder(
    column: $table.currentStateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalWidth => $composableBuilder(
    column: $table.originalWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalHeight => $composableBuilder(
    column: $table.originalHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previewWidth => $composableBuilder(
    column: $table.previewWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get previewHeight => $composableBuilder(
    column: $table.previewHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EditorProjectRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EditorProjectRecordsTable> {
  $$EditorProjectRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get activeVersionId => $composableBuilder(
    column: $table.activeVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalImagePath => $composableBuilder(
    column: $table.originalImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previewImagePath => $composableBuilder(
    column: $table.previewImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentStateJson => $composableBuilder(
    column: $table.currentStateJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalWidth => $composableBuilder(
    column: $table.originalWidth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalHeight => $composableBuilder(
    column: $table.originalHeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get previewWidth => $composableBuilder(
    column: $table.previewWidth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get previewHeight => $composableBuilder(
    column: $table.previewHeight,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  Expression<T> editorVersionRecordsRefs<T extends Object>(
    Expression<T> Function($$EditorVersionRecordsTableAnnotationComposer a) f,
  ) {
    final $$EditorVersionRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.editorVersionRecords,
          getReferencedColumn: (t) => t.projectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EditorVersionRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.editorVersionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> aiChatMessageRecordsRefs<T extends Object>(
    Expression<T> Function($$AiChatMessageRecordsTableAnnotationComposer a) f,
  ) {
    final $$AiChatMessageRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.aiChatMessageRecords,
          getReferencedColumn: (t) => t.projectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AiChatMessageRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.aiChatMessageRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EditorProjectRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EditorProjectRecordsTable,
          EditorProjectRecord,
          $$EditorProjectRecordsTableFilterComposer,
          $$EditorProjectRecordsTableOrderingComposer,
          $$EditorProjectRecordsTableAnnotationComposer,
          $$EditorProjectRecordsTableCreateCompanionBuilder,
          $$EditorProjectRecordsTableUpdateCompanionBuilder,
          (EditorProjectRecord, $$EditorProjectRecordsTableReferences),
          EditorProjectRecord,
          PrefetchHooks Function({
            bool editorVersionRecordsRefs,
            bool aiChatMessageRecordsRefs,
          })
        > {
  $$EditorProjectRecordsTableTableManager(
    _$AppDatabase db,
    $EditorProjectRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EditorProjectRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EditorProjectRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EditorProjectRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> activeVersionId = const Value.absent(),
                Value<String> originalImagePath = const Value.absent(),
                Value<String?> previewImagePath = const Value.absent(),
                Value<String> currentStateJson = const Value.absent(),
                Value<int> originalWidth = const Value.absent(),
                Value<int> originalHeight = const Value.absent(),
                Value<int> previewWidth = const Value.absent(),
                Value<int> previewHeight = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
              }) => EditorProjectRecordsCompanion(
                id: id,
                name: name,
                status: status,
                activeVersionId: activeVersionId,
                originalImagePath: originalImagePath,
                previewImagePath: previewImagePath,
                currentStateJson: currentStateJson,
                originalWidth: originalWidth,
                originalHeight: originalHeight,
                previewWidth: previewWidth,
                previewHeight: previewHeight,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastOpenedAt: lastOpenedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> status = const Value.absent(),
                Value<String?> activeVersionId = const Value.absent(),
                required String originalImagePath,
                Value<String?> previewImagePath = const Value.absent(),
                required String currentStateJson,
                required int originalWidth,
                required int originalHeight,
                required int previewWidth,
                required int previewHeight,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
              }) => EditorProjectRecordsCompanion.insert(
                id: id,
                name: name,
                status: status,
                activeVersionId: activeVersionId,
                originalImagePath: originalImagePath,
                previewImagePath: previewImagePath,
                currentStateJson: currentStateJson,
                originalWidth: originalWidth,
                originalHeight: originalHeight,
                previewWidth: previewWidth,
                previewHeight: previewHeight,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastOpenedAt: lastOpenedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EditorProjectRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                editorVersionRecordsRefs = false,
                aiChatMessageRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (editorVersionRecordsRefs) db.editorVersionRecords,
                    if (aiChatMessageRecordsRefs) db.aiChatMessageRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (editorVersionRecordsRefs)
                        await $_getPrefetchedData<
                          EditorProjectRecord,
                          $EditorProjectRecordsTable,
                          EditorVersionRecord
                        >(
                          currentTable: table,
                          referencedTable: $$EditorProjectRecordsTableReferences
                              ._editorVersionRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EditorProjectRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).editorVersionRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (aiChatMessageRecordsRefs)
                        await $_getPrefetchedData<
                          EditorProjectRecord,
                          $EditorProjectRecordsTable,
                          AiChatMessageRecord
                        >(
                          currentTable: table,
                          referencedTable: $$EditorProjectRecordsTableReferences
                              ._aiChatMessageRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EditorProjectRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).aiChatMessageRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EditorProjectRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EditorProjectRecordsTable,
      EditorProjectRecord,
      $$EditorProjectRecordsTableFilterComposer,
      $$EditorProjectRecordsTableOrderingComposer,
      $$EditorProjectRecordsTableAnnotationComposer,
      $$EditorProjectRecordsTableCreateCompanionBuilder,
      $$EditorProjectRecordsTableUpdateCompanionBuilder,
      (EditorProjectRecord, $$EditorProjectRecordsTableReferences),
      EditorProjectRecord,
      PrefetchHooks Function({
        bool editorVersionRecordsRefs,
        bool aiChatMessageRecordsRefs,
      })
    >;
typedef $$EditorVersionRecordsTableCreateCompanionBuilder =
    EditorVersionRecordsCompanion Function({
      required String id,
      required int projectId,
      required String name,
      Value<String?> parentVersionId,
      required String stateJson,
      Value<String> historyJson,
      Value<String?> thumbnailPath,
      Value<String?> aiReferenceImagePath,
      required int sortOrder,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$EditorVersionRecordsTableUpdateCompanionBuilder =
    EditorVersionRecordsCompanion Function({
      Value<String> id,
      Value<int> projectId,
      Value<String> name,
      Value<String?> parentVersionId,
      Value<String> stateJson,
      Value<String> historyJson,
      Value<String?> thumbnailPath,
      Value<String?> aiReferenceImagePath,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$EditorVersionRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EditorVersionRecordsTable,
          EditorVersionRecord
        > {
  $$EditorVersionRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EditorProjectRecordsTable _projectIdTable(_$AppDatabase db) =>
      db.editorProjectRecords.createAlias(
        $_aliasNameGenerator(
          db.editorVersionRecords.projectId,
          db.editorProjectRecords.id,
        ),
      );

  $$EditorProjectRecordsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$EditorProjectRecordsTableTableManager(
      $_db,
      $_db.editorProjectRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $AiChatMessageRecordsTable,
    List<AiChatMessageRecord>
  >
  _aiChatMessageRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.aiChatMessageRecords,
        aliasName: $_aliasNameGenerator(
          db.editorVersionRecords.id,
          db.aiChatMessageRecords.versionId,
        ),
      );

  $$AiChatMessageRecordsTableProcessedTableManager
  get aiChatMessageRecordsRefs {
    final manager = $$AiChatMessageRecordsTableTableManager(
      $_db,
      $_db.aiChatMessageRecords,
    ).filter((f) => f.versionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _aiChatMessageRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EditorVersionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $EditorVersionRecordsTable> {
  $$EditorVersionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentVersionId => $composableBuilder(
    column: $table.parentVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiReferenceImagePath => $composableBuilder(
    column: $table.aiReferenceImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EditorProjectRecordsTableFilterComposer get projectId {
    final $$EditorProjectRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.editorProjectRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditorProjectRecordsTableFilterComposer(
            $db: $db,
            $table: $db.editorProjectRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> aiChatMessageRecordsRefs(
    Expression<bool> Function($$AiChatMessageRecordsTableFilterComposer f) f,
  ) {
    final $$AiChatMessageRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aiChatMessageRecords,
      getReferencedColumn: (t) => t.versionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AiChatMessageRecordsTableFilterComposer(
            $db: $db,
            $table: $db.aiChatMessageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EditorVersionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $EditorVersionRecordsTable> {
  $$EditorVersionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentVersionId => $composableBuilder(
    column: $table.parentVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiReferenceImagePath => $composableBuilder(
    column: $table.aiReferenceImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EditorProjectRecordsTableOrderingComposer get projectId {
    final $$EditorProjectRecordsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.projectId,
          referencedTable: $db.editorProjectRecords,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EditorProjectRecordsTableOrderingComposer(
                $db: $db,
                $table: $db.editorProjectRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$EditorVersionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EditorVersionRecordsTable> {
  $$EditorVersionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentVersionId => $composableBuilder(
    column: $table.parentVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);

  GeneratedColumn<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiReferenceImagePath => $composableBuilder(
    column: $table.aiReferenceImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EditorProjectRecordsTableAnnotationComposer get projectId {
    final $$EditorProjectRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.projectId,
          referencedTable: $db.editorProjectRecords,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EditorProjectRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.editorProjectRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> aiChatMessageRecordsRefs<T extends Object>(
    Expression<T> Function($$AiChatMessageRecordsTableAnnotationComposer a) f,
  ) {
    final $$AiChatMessageRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.aiChatMessageRecords,
          getReferencedColumn: (t) => t.versionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AiChatMessageRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.aiChatMessageRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$EditorVersionRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EditorVersionRecordsTable,
          EditorVersionRecord,
          $$EditorVersionRecordsTableFilterComposer,
          $$EditorVersionRecordsTableOrderingComposer,
          $$EditorVersionRecordsTableAnnotationComposer,
          $$EditorVersionRecordsTableCreateCompanionBuilder,
          $$EditorVersionRecordsTableUpdateCompanionBuilder,
          (EditorVersionRecord, $$EditorVersionRecordsTableReferences),
          EditorVersionRecord,
          PrefetchHooks Function({
            bool projectId,
            bool aiChatMessageRecordsRefs,
          })
        > {
  $$EditorVersionRecordsTableTableManager(
    _$AppDatabase db,
    $EditorVersionRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EditorVersionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EditorVersionRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EditorVersionRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentVersionId = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
                Value<String> historyJson = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> aiReferenceImagePath = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EditorVersionRecordsCompanion(
                id: id,
                projectId: projectId,
                name: name,
                parentVersionId: parentVersionId,
                stateJson: stateJson,
                historyJson: historyJson,
                thumbnailPath: thumbnailPath,
                aiReferenceImagePath: aiReferenceImagePath,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int projectId,
                required String name,
                Value<String?> parentVersionId = const Value.absent(),
                required String stateJson,
                Value<String> historyJson = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> aiReferenceImagePath = const Value.absent(),
                required int sortOrder,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => EditorVersionRecordsCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
                parentVersionId: parentVersionId,
                stateJson: stateJson,
                historyJson: historyJson,
                thumbnailPath: thumbnailPath,
                aiReferenceImagePath: aiReferenceImagePath,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EditorVersionRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({projectId = false, aiChatMessageRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (aiChatMessageRecordsRefs) db.aiChatMessageRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (projectId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.projectId,
                                    referencedTable:
                                        $$EditorVersionRecordsTableReferences
                                            ._projectIdTable(db),
                                    referencedColumn:
                                        $$EditorVersionRecordsTableReferences
                                            ._projectIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (aiChatMessageRecordsRefs)
                        await $_getPrefetchedData<
                          EditorVersionRecord,
                          $EditorVersionRecordsTable,
                          AiChatMessageRecord
                        >(
                          currentTable: table,
                          referencedTable: $$EditorVersionRecordsTableReferences
                              ._aiChatMessageRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EditorVersionRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).aiChatMessageRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.versionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EditorVersionRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EditorVersionRecordsTable,
      EditorVersionRecord,
      $$EditorVersionRecordsTableFilterComposer,
      $$EditorVersionRecordsTableOrderingComposer,
      $$EditorVersionRecordsTableAnnotationComposer,
      $$EditorVersionRecordsTableCreateCompanionBuilder,
      $$EditorVersionRecordsTableUpdateCompanionBuilder,
      (EditorVersionRecord, $$EditorVersionRecordsTableReferences),
      EditorVersionRecord,
      PrefetchHooks Function({bool projectId, bool aiChatMessageRecordsRefs})
    >;
typedef $$AiChatMessageRecordsTableCreateCompanionBuilder =
    AiChatMessageRecordsCompanion Function({
      Value<int> id,
      required int projectId,
      Value<String?> versionId,
      required String type,
      required String messageText,
      required DateTime createdAt,
      required int sortOrder,
    });
typedef $$AiChatMessageRecordsTableUpdateCompanionBuilder =
    AiChatMessageRecordsCompanion Function({
      Value<int> id,
      Value<int> projectId,
      Value<String?> versionId,
      Value<String> type,
      Value<String> messageText,
      Value<DateTime> createdAt,
      Value<int> sortOrder,
    });

final class $$AiChatMessageRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AiChatMessageRecordsTable,
          AiChatMessageRecord
        > {
  $$AiChatMessageRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EditorProjectRecordsTable _projectIdTable(_$AppDatabase db) =>
      db.editorProjectRecords.createAlias(
        $_aliasNameGenerator(
          db.aiChatMessageRecords.projectId,
          db.editorProjectRecords.id,
        ),
      );

  $$EditorProjectRecordsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$EditorProjectRecordsTableTableManager(
      $_db,
      $_db.editorProjectRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EditorVersionRecordsTable _versionIdTable(_$AppDatabase db) =>
      db.editorVersionRecords.createAlias(
        $_aliasNameGenerator(
          db.aiChatMessageRecords.versionId,
          db.editorVersionRecords.id,
        ),
      );

  $$EditorVersionRecordsTableProcessedTableManager? get versionId {
    final $_column = $_itemColumn<String>('version_id');
    if ($_column == null) return null;
    final manager = $$EditorVersionRecordsTableTableManager(
      $_db,
      $_db.editorVersionRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_versionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AiChatMessageRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AiChatMessageRecordsTable> {
  $$AiChatMessageRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$EditorProjectRecordsTableFilterComposer get projectId {
    final $$EditorProjectRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.editorProjectRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditorProjectRecordsTableFilterComposer(
            $db: $db,
            $table: $db.editorProjectRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EditorVersionRecordsTableFilterComposer get versionId {
    final $$EditorVersionRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.editorVersionRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EditorVersionRecordsTableFilterComposer(
            $db: $db,
            $table: $db.editorVersionRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiChatMessageRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiChatMessageRecordsTable> {
  $$AiChatMessageRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$EditorProjectRecordsTableOrderingComposer get projectId {
    final $$EditorProjectRecordsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.projectId,
          referencedTable: $db.editorProjectRecords,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EditorProjectRecordsTableOrderingComposer(
                $db: $db,
                $table: $db.editorProjectRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$EditorVersionRecordsTableOrderingComposer get versionId {
    final $$EditorVersionRecordsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.versionId,
          referencedTable: $db.editorVersionRecords,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EditorVersionRecordsTableOrderingComposer(
                $db: $db,
                $table: $db.editorVersionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AiChatMessageRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiChatMessageRecordsTable> {
  $$AiChatMessageRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$EditorProjectRecordsTableAnnotationComposer get projectId {
    final $$EditorProjectRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.projectId,
          referencedTable: $db.editorProjectRecords,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EditorProjectRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.editorProjectRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$EditorVersionRecordsTableAnnotationComposer get versionId {
    final $$EditorVersionRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.versionId,
          referencedTable: $db.editorVersionRecords,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EditorVersionRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.editorVersionRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AiChatMessageRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiChatMessageRecordsTable,
          AiChatMessageRecord,
          $$AiChatMessageRecordsTableFilterComposer,
          $$AiChatMessageRecordsTableOrderingComposer,
          $$AiChatMessageRecordsTableAnnotationComposer,
          $$AiChatMessageRecordsTableCreateCompanionBuilder,
          $$AiChatMessageRecordsTableUpdateCompanionBuilder,
          (AiChatMessageRecord, $$AiChatMessageRecordsTableReferences),
          AiChatMessageRecord,
          PrefetchHooks Function({bool projectId, bool versionId})
        > {
  $$AiChatMessageRecordsTableTableManager(
    _$AppDatabase db,
    $AiChatMessageRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiChatMessageRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiChatMessageRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AiChatMessageRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> projectId = const Value.absent(),
                Value<String?> versionId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> messageText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => AiChatMessageRecordsCompanion(
                id: id,
                projectId: projectId,
                versionId: versionId,
                type: type,
                messageText: messageText,
                createdAt: createdAt,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int projectId,
                Value<String?> versionId = const Value.absent(),
                required String type,
                required String messageText,
                required DateTime createdAt,
                required int sortOrder,
              }) => AiChatMessageRecordsCompanion.insert(
                id: id,
                projectId: projectId,
                versionId: versionId,
                type: type,
                messageText: messageText,
                createdAt: createdAt,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AiChatMessageRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, versionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable:
                                    $$AiChatMessageRecordsTableReferences
                                        ._projectIdTable(db),
                                referencedColumn:
                                    $$AiChatMessageRecordsTableReferences
                                        ._projectIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (versionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.versionId,
                                referencedTable:
                                    $$AiChatMessageRecordsTableReferences
                                        ._versionIdTable(db),
                                referencedColumn:
                                    $$AiChatMessageRecordsTableReferences
                                        ._versionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AiChatMessageRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiChatMessageRecordsTable,
      AiChatMessageRecord,
      $$AiChatMessageRecordsTableFilterComposer,
      $$AiChatMessageRecordsTableOrderingComposer,
      $$AiChatMessageRecordsTableAnnotationComposer,
      $$AiChatMessageRecordsTableCreateCompanionBuilder,
      $$AiChatMessageRecordsTableUpdateCompanionBuilder,
      (AiChatMessageRecord, $$AiChatMessageRecordsTableReferences),
      AiChatMessageRecord,
      PrefetchHooks Function({bool projectId, bool versionId})
    >;
typedef $$EditorPresetRecordsTableCreateCompanionBuilder =
    EditorPresetRecordsCompanion Function({
      Value<int> id,
      required String name,
      required String normalizedName,
      required String stateJson,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$EditorPresetRecordsTableUpdateCompanionBuilder =
    EditorPresetRecordsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<String> stateJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$EditorPresetRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $EditorPresetRecordsTable> {
  $$EditorPresetRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EditorPresetRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $EditorPresetRecordsTable> {
  $$EditorPresetRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EditorPresetRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EditorPresetRecordsTable> {
  $$EditorPresetRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EditorPresetRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EditorPresetRecordsTable,
          EditorPresetRecord,
          $$EditorPresetRecordsTableFilterComposer,
          $$EditorPresetRecordsTableOrderingComposer,
          $$EditorPresetRecordsTableAnnotationComposer,
          $$EditorPresetRecordsTableCreateCompanionBuilder,
          $$EditorPresetRecordsTableUpdateCompanionBuilder,
          (
            EditorPresetRecord,
            BaseReferences<
              _$AppDatabase,
              $EditorPresetRecordsTable,
              EditorPresetRecord
            >,
          ),
          EditorPresetRecord,
          PrefetchHooks Function()
        > {
  $$EditorPresetRecordsTableTableManager(
    _$AppDatabase db,
    $EditorPresetRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EditorPresetRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EditorPresetRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EditorPresetRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EditorPresetRecordsCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                stateJson: stateJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String normalizedName,
                required String stateJson,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => EditorPresetRecordsCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                stateJson: stateJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EditorPresetRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EditorPresetRecordsTable,
      EditorPresetRecord,
      $$EditorPresetRecordsTableFilterComposer,
      $$EditorPresetRecordsTableOrderingComposer,
      $$EditorPresetRecordsTableAnnotationComposer,
      $$EditorPresetRecordsTableCreateCompanionBuilder,
      $$EditorPresetRecordsTableUpdateCompanionBuilder,
      (
        EditorPresetRecord,
        BaseReferences<
          _$AppDatabase,
          $EditorPresetRecordsTable,
          EditorPresetRecord
        >,
      ),
      EditorPresetRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EditorProjectRecordsTableTableManager get editorProjectRecords =>
      $$EditorProjectRecordsTableTableManager(_db, _db.editorProjectRecords);
  $$EditorVersionRecordsTableTableManager get editorVersionRecords =>
      $$EditorVersionRecordsTableTableManager(_db, _db.editorVersionRecords);
  $$AiChatMessageRecordsTableTableManager get aiChatMessageRecords =>
      $$AiChatMessageRecordsTableTableManager(_db, _db.aiChatMessageRecords);
  $$EditorPresetRecordsTableTableManager get editorPresetRecords =>
      $$EditorPresetRecordsTableTableManager(_db, _db.editorPresetRecords);
}

mixin _$AiChatMessagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $EditorProjectRecordsTable get editorProjectRecords =>
      attachedDatabase.editorProjectRecords;
  $EditorVersionRecordsTable get editorVersionRecords =>
      attachedDatabase.editorVersionRecords;
  $AiChatMessageRecordsTable get aiChatMessageRecords =>
      attachedDatabase.aiChatMessageRecords;
  AiChatMessagesDaoManager get managers => AiChatMessagesDaoManager(this);
}

class AiChatMessagesDaoManager {
  final _$AiChatMessagesDaoMixin _db;
  AiChatMessagesDaoManager(this._db);
  $$EditorProjectRecordsTableTableManager get editorProjectRecords =>
      $$EditorProjectRecordsTableTableManager(
        _db.attachedDatabase,
        _db.editorProjectRecords,
      );
  $$EditorVersionRecordsTableTableManager get editorVersionRecords =>
      $$EditorVersionRecordsTableTableManager(
        _db.attachedDatabase,
        _db.editorVersionRecords,
      );
  $$AiChatMessageRecordsTableTableManager get aiChatMessageRecords =>
      $$AiChatMessageRecordsTableTableManager(
        _db.attachedDatabase,
        _db.aiChatMessageRecords,
      );
}

mixin _$EditorProjectsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EditorProjectRecordsTable get editorProjectRecords =>
      attachedDatabase.editorProjectRecords;
  EditorProjectsDaoManager get managers => EditorProjectsDaoManager(this);
}

class EditorProjectsDaoManager {
  final _$EditorProjectsDaoMixin _db;
  EditorProjectsDaoManager(this._db);
  $$EditorProjectRecordsTableTableManager get editorProjectRecords =>
      $$EditorProjectRecordsTableTableManager(
        _db.attachedDatabase,
        _db.editorProjectRecords,
      );
}

mixin _$EditorPresetsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EditorPresetRecordsTable get editorPresetRecords =>
      attachedDatabase.editorPresetRecords;
  EditorPresetsDaoManager get managers => EditorPresetsDaoManager(this);
}

class EditorPresetsDaoManager {
  final _$EditorPresetsDaoMixin _db;
  EditorPresetsDaoManager(this._db);
  $$EditorPresetRecordsTableTableManager get editorPresetRecords =>
      $$EditorPresetRecordsTableTableManager(
        _db.attachedDatabase,
        _db.editorPresetRecords,
      );
}

mixin _$EditorVersionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EditorProjectRecordsTable get editorProjectRecords =>
      attachedDatabase.editorProjectRecords;
  $EditorVersionRecordsTable get editorVersionRecords =>
      attachedDatabase.editorVersionRecords;
  EditorVersionsDaoManager get managers => EditorVersionsDaoManager(this);
}

class EditorVersionsDaoManager {
  final _$EditorVersionsDaoMixin _db;
  EditorVersionsDaoManager(this._db);
  $$EditorProjectRecordsTableTableManager get editorProjectRecords =>
      $$EditorProjectRecordsTableTableManager(
        _db.attachedDatabase,
        _db.editorProjectRecords,
      );
  $$EditorVersionRecordsTableTableManager get editorVersionRecords =>
      $$EditorVersionRecordsTableTableManager(
        _db.attachedDatabase,
        _db.editorVersionRecords,
      );
}
