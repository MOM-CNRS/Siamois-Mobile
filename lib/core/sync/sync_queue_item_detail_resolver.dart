import 'dart:convert';

import '../database/app_database.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/projects/documents/document_tmp_models.dart';
import '../../features/projects/form/project_form_cache.dart';
import '../../features/projects/form/project_form_models.dart';
import '../../features/projects/form/recording_unit_option.dart';
import '../../features/projects/mobiliers/mobilier_form_cache.dart';
import '../../features/projects/mobiliers/mobilier_offline_create.dart';
import '../../features/projects/recording_units/recording_unit_detail_models.dart';
import '../../features/projects/recording_units/recording_unit_form_cache.dart';
import '../../features/projects/recording_units/recording_unit_local_id.dart';
import 'sync_action_models.dart';
import 'sync_conflict_field_diff.dart';
import 'sync_conflict_payload.dart';
import 'sync_queue_models.dart';

/// Élément métier (UE, mobilier, projet…) pour l’affichage du détail sync.
class SyncQueueResolvedElement {
  const SyncQueueResolvedElement({
    required this.kind,
    this.code,
    this.name,
  });

  final String kind;
  final String? code;
  final String? name;

  bool get hasCode => code != null && code!.trim().isNotEmpty;
  bool get hasName => name != null && name!.trim().isNotEmpty;
}

/// Champ modifié avec libellé formulaire.
class SyncQueueResolvedField {
  const SyncQueueResolvedField({
    required this.fieldLabel,
    required this.value,
  });

  final String fieldLabel;
  final String value;
}

/// Contexte enrichi pour le détail d’une action (cache local).
class SyncQueueResolvedContext {
  const SyncQueueResolvedContext({
    required this.element,
    this.project,
    this.parentElement,
    this.changedFields = const [],
    this.conflictFieldDiffs = const [],
  });

  final SyncQueueResolvedElement element;
  final SyncQueueResolvedElement? project;
  final SyncQueueResolvedElement? parentElement;
  final List<SyncQueueResolvedField> changedFields;
  final List<SyncConflictFieldDiff> conflictFieldDiffs;
}

/// Résout codes, noms et libellés de champs depuis SQLite.
class SyncQueueItemDetailResolver {
  SyncQueueItemDetailResolver({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<SyncQueueResolvedContext> resolve({
    required SyncQueueItem item,
    SyncActionEntry? action,
    DocumentTmpEntry? document,
  }) async {
    if (document != null) {
      return _resolveDocument(document);
    }
    if (action != null) {
      return _resolveAction(action);
    }
    return SyncQueueResolvedContext(
      element: SyncQueueResolvedElement(
        kind: _kindFromItemTitle(item.title),
        code: item.subtitle,
      ),
    );
  }

  Future<SyncQueueResolvedContext> _resolveDocument(
    DocumentTmpEntry document,
  ) async {
    SyncQueueResolvedElement? project;
    SyncQueueResolvedElement? parentElement;
    if (document.parentType == DocumentTmpParentType.project) {
      parentElement = await _resolveProject(document.parentId);
      project = parentElement;
    } else {
      parentElement = await _resolveRecordingUnit(document.parentId);
      final projectId = await _db.projectIdForRecordingUnit(document.parentId);
      if (projectId != null) {
        project = await _resolveProject(projectId);
      }
    }

    return SyncQueueResolvedContext(
      element: SyncQueueResolvedElement(
        kind: 'Document',
        code: _firstNonEmpty([
          document.fileCode,
          document.fileName,
          document.resourceId,
        ]),
        name: document.title,
      ),
      project: project,
      parentElement: parentElement,
      changedFields: [
        if (document.description != null &&
            document.description!.trim().isNotEmpty)
          SyncQueueResolvedField(
            fieldLabel: 'Description',
            value: document.description!.trim(),
          ),
        if (document.fileName != null && document.fileName!.trim().isNotEmpty)
          SyncQueueResolvedField(
            fieldLabel: 'Fichier',
            value: document.fileName!.trim(),
          ),
      ],
    );
  }

  Future<SyncQueueResolvedContext> _resolveAction(SyncActionEntry action) async {
    final payload = action.payload;
    final projectId = payload['projectId']?.toString();
    final project = projectId != null ? await _resolveProject(projectId) : null;

    final element = await _resolveElementForAction(action);
    final fieldLabels = await _fieldLabelsForAction(action);
    final changedFields = _resolveChangedFields(
      payload['fieldAnswers'],
      fieldLabels,
    );
    final conflictPayload = action.status == SyncActionStatus.conflict
        ? SyncConflictPayload.tryParse(action.errorMessage)
        : null;
    final conflictFieldDiffs = conflictPayload != null
        ? SyncConflictFieldDiffBuilder.build(
            action: action,
            payload: conflictPayload,
            fieldLabels: fieldLabels,
          )
        : const <SyncConflictFieldDiff>[];

    return SyncQueueResolvedContext(
      element: element,
      project: project,
      changedFields: changedFields,
      conflictFieldDiffs: conflictFieldDiffs,
    );
  }

  Future<SyncQueueResolvedElement> _resolveElementForAction(
    SyncActionEntry action,
  ) async {
    final kind = _entityKindLabel(action.entityType);
    final payload = action.payload;

    switch (action.entityType) {
      case SyncEntityType.recordingUnit:
        final id = _firstNonEmpty([
          action.serverEntityId,
          action.localEntityId,
        ]);
        if (action.operation == SyncOperation.create) {
          final code = _firstNonEmpty([
            payload['actionUnitId']?.toString(),
            _codeFromFieldAnswers(payload['fieldAnswers']),
            id,
          ]);
          final typeLabel = await _recordingUnitTypeLabel(
            payload['recordingUnitTypeConceptId'],
          );
          return SyncQueueResolvedElement(
            kind: kind,
            code: code ?? 'Nouvelle unité',
            name: typeLabel,
          );
        }
        final resolved = id != null
            ? await _resolveRecordingUnit(id)
            : SyncQueueResolvedElement(kind: kind);
        return SyncQueueResolvedElement(
          kind: kind,
          code: resolved.code,
          name: resolved.name ?? resolved.code,
        );

      case SyncEntityType.mobilier:
        final id = _firstNonEmpty([
          action.serverEntityId,
          action.localEntityId,
        ]);
        if (id != null) {
          final resolved = await _resolveMobilier(id, payload['fieldAnswers']);
          return SyncQueueResolvedElement(
            kind: kind,
            code: resolved.code,
            name: resolved.name,
          );
        }
        return SyncQueueResolvedElement(kind: kind);

      case SyncEntityType.project:
        final id = _firstNonEmpty([
          action.serverEntityId,
          action.localEntityId,
          payload['projectId']?.toString(),
        ]);
        if (id != null) {
          final resolved = await _resolveProject(id);
          return SyncQueueResolvedElement(
            kind: kind,
            code: resolved.code,
            name: resolved.name,
          );
        }
        return SyncQueueResolvedElement(kind: kind);

      case SyncEntityType.document:
        return SyncQueueResolvedElement(
          kind: kind,
          code: _friendlyId(action.serverEntityId ?? action.localEntityId),
        );

      default:
        return SyncQueueResolvedElement(
          kind: kind,
          code: _friendlyId(action.serverEntityId ?? action.localEntityId),
        );
    }
  }

  Future<SyncQueueResolvedElement> _resolveRecordingUnit(String rawId) async {
    final id = rawId.trim();
    if (id.isEmpty) {
      return const SyncQueueResolvedElement(kind: 'Unité d’enregistrement');
    }

    if (RecordingUnitLocalId.isLocalListId(id)) {
      return const SyncQueueResolvedElement(
        kind: 'Unité d’enregistrement',
        code: 'Brouillon local',
        name: 'Pas encore enregistrée sur le serveur',
      );
    }

    final listRow = await _db.recordingUnitListRow(id);
    if (listRow != null) {
      return SyncQueueResolvedElement(
        kind: 'Unité d’enregistrement',
        code: listRow.displayCode,
        name: _firstNonEmpty([listRow.typeLabel, listRow.placeLabel]),
      );
    }

    final detailRow = await _db.recordingUnitDetailRow(id);
    if (detailRow != null) {
      try {
        final decoded = jsonDecode(detailRow.detailJson);
        if (decoded is Map) {
          final detail = RecordingUnitMobileDetail.fromApiData(
            Map<String, dynamic>.from(decoded),
          );
          return SyncQueueResolvedElement(
            kind: 'Unité d’enregistrement',
            code: detail.displayCode,
            name: _firstNonEmpty([detail.typeLabel, detail.formName]),
          );
        }
      } catch (_) {}
    }

    return SyncQueueResolvedElement(
      kind: 'Unité d’enregistrement',
      code: _friendlyId(id),
    );
  }

  Future<SyncQueueResolvedElement> _resolveMobilier(
    String rawId,
    dynamic fieldAnswersRaw,
  ) async {
    final id = rawId.trim();
    final row = await _db.mobilierListRow(id);

    if (row != null) {
      return SyncQueueResolvedElement(
        kind: 'Mobilier',
        code: row.displayCode,
        name: row.typeLabel,
      );
    }

    if (fieldAnswersRaw is Map) {
      try {
        final definition = await MobilierFormCache(auth: _auth, db: _db)
            .loadMobilierForm()
            .then((r) => r.definition);
        final answers = Map<String, dynamic>.from(fieldAnswersRaw);
        final item = MobilierOfflineCreate.buildListItem(
          listId: id,
          typeLabel: null,
          definition: definition,
          fieldAnswers: answers,
        );
        return SyncQueueResolvedElement(
          kind: 'Mobilier',
          code: item.displayCode,
          name: item.typeLabel,
        );
      } catch (_) {}
    }

    return SyncQueueResolvedElement(
      kind: 'Mobilier',
      code: _friendlyId(id),
      name: 'Brouillon local',
    );
  }

  Future<SyncQueueResolvedElement> _resolveProject(String rawId) async {
    final id = rawId.trim();
    final row = await _db.findProjetRow(id);
    if (row != null) {
      return SyncQueueResolvedElement(
        kind: 'Projet',
        code: _firstNonEmpty([row.fullIdentifier, row.identifiant, row.id]),
        name: row.nom,
      );
    }

    final detailRow = await _db.projectDetailRow(id);
    if (detailRow != null) {
      try {
        final decoded = jsonDecode(detailRow.detailJson);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          return SyncQueueResolvedElement(
            kind: 'Projet',
            code: _firstNonEmpty([
              map['fullIdentifier']?.toString(),
              map['identifier']?.toString(),
              map['id']?.toString(),
            ]),
            name: map['name']?.toString(),
          );
        }
      } catch (_) {}
    }

    return SyncQueueResolvedElement(
      kind: 'Projet',
      code: _friendlyId(id),
    );
  }

  Future<Map<int, String>> _fieldLabelsForAction(SyncActionEntry action) async {
    try {
      switch (action.entityType) {
        case SyncEntityType.recordingUnit:
          return _recordingUnitFieldLabels(action);
        case SyncEntityType.mobilier:
          return _mobilierFieldLabels();
        case SyncEntityType.project:
          return _projectFieldLabels();
        default:
          return const {};
      }
    } catch (_) {
      return const {};
    }
  }

  Future<Map<int, String>> _recordingUnitFieldLabels(
    SyncActionEntry action,
  ) async {
    final ruId = _firstNonEmpty([
      action.serverEntityId,
      action.localEntityId,
    ]);
    if (ruId == null) {
      final typeRaw = action.payload['recordingUnitTypeConceptId'];
      final typeId = _parseInt(typeRaw);
      if (typeId == null) return const {};
      final form = await RecordingUnitFormCache(auth: _auth, db: _db)
          .loadFormForRecordingUnitType(typeConceptId: typeId);
      return _labelsFromDefinition(form.definition);
    }

    final detailRow = await _db.recordingUnitDetailRow(ruId);
    RecordingUnitMobileDetail? detail;
    if (detailRow != null) {
      try {
        final decoded = jsonDecode(detailRow.detailJson);
        if (decoded is Map) {
          detail = RecordingUnitMobileDetail.fromApiData(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    final cache = RecordingUnitFormCache(auth: _auth, db: _db);
    final typeId = detail != null
        ? await cache.resolveTypeConceptIdForEdit(
            detail: detail,
            recordingUnitId: ruId,
          )
        : (await _db.recordingUnitListRow(ruId))?.typeConceptId;

    if (typeId == null) return const {};

    final form =
        await cache.loadFormForRecordingUnitType(typeConceptId: typeId);
    return _labelsFromDefinition(form.definition);
  }

  Future<Map<int, String>> _mobilierFieldLabels() async {
    final result =
        await MobilierFormCache(auth: _auth, db: _db).loadMobilierForm();
    return _labelsFromDefinition(result.definition);
  }

  Future<Map<int, String>> _projectFieldLabels() async {
    final definition =
        await ProjectFormCache(auth: _auth, db: _db).loadProjectForm();
    return _labelsFromDefinition(definition);
  }

  Map<int, String> _labelsFromDefinition(ProjectFormDefinition definition) {
    return {
      for (final field in definition.fieldsById.values)
        field.fieldId: field.label.trim().isNotEmpty
            ? field.label.trim()
            : 'Champ ${field.fieldId}',
    };
  }

  List<SyncQueueResolvedField> _resolveChangedFields(
    dynamic fieldAnswersRaw,
    Map<int, String> fieldLabels,
  ) {
    if (fieldAnswersRaw is! Map) return const [];

    final out = <SyncQueueResolvedField>[];
    for (final entry in fieldAnswersRaw.entries) {
      final fieldId = int.tryParse(entry.key.toString());
      final label = fieldId != null
          ? fieldLabels[fieldId] ?? 'Champ $fieldId'
          : entry.key.toString();
      final value = _humanizeFieldValue(entry.value);
      if (value.trim().isEmpty) continue;
      out.add(SyncQueueResolvedField(fieldLabel: label, value: value));
    }
    return out;
  }

  Future<String?> _recordingUnitTypeLabel(dynamic typeRaw) async {
    final typeId = _parseInt(typeRaw);
    if (typeId == null) return null;

    final vocab = await RecordingUnitFormCache(auth: _auth, db: _db)
        .loadVocabulariesByFieldCode();
    for (final options in vocab.values) {
      for (final opt in options) {
        if (opt.id == typeId) return opt.label;
      }
    }
    return 'Type d’unité n°$typeId';
  }

  String? _codeFromFieldAnswers(dynamic raw) {
    if (raw is! Map) return null;
    for (final value in raw.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _humanizeFieldValue(dynamic raw) {
    if (raw == null) return '';

    final units = RecordingUnitOption.listFromCurrentValue(raw);
    if (units.isNotEmpty) {
      return units.map((u) => u.display).join('\n');
    }

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return '';
      final asDate = DateTime.tryParse(trimmed);
      if (asDate != null && trimmed.contains('-')) {
        return _formatDateTime(asDate);
      }
      return trimmed;
    }

    if (raw is num || raw is bool) return raw.toString();

    if (raw is List) {
      if (raw.isEmpty) return 'Aucune valeur';
      if (raw.every((e) => e is String || e is num)) {
        return raw.map((e) => e.toString()).join(', ');
      }
      return '${raw.length} élément${raw.length > 1 ? 's' : ''}';
    }

    if (raw is Map) {
      final label = raw['fullIdentifier'] ??
          raw['label'] ??
          raw['name'] ??
          raw['displayLabel'];
      if (label != null && label.toString().trim().isNotEmpty) {
        return label.toString().trim();
      }
    }

    return raw.toString();
  }

  String _entityKindLabel(String entityType) {
    return switch (entityType) {
      SyncEntityType.recordingUnit => 'Unité d’enregistrement',
      SyncEntityType.mobilier => 'Mobilier',
      SyncEntityType.project => 'Projet',
      SyncEntityType.document => 'Document',
      _ => 'Élément',
    };
  }

  String _kindFromItemTitle(String title) {
    if (title.contains('Unité')) return 'Unité d’enregistrement';
    if (title.contains('Mobilier')) return 'Mobilier';
    if (title.contains('Document')) return 'Document';
    if (title.contains('Projet')) return 'Projet';
    return 'Élément';
  }

  int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String _friendlyId(String? raw) {
    final id = raw?.trim() ?? '';
    if (id.isEmpty) return '—';
    if (id.length <= 32) return id;
    return '${id.substring(0, 14)}…${id.substring(id.length - 6)}';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} à $h:$m';
  }
}
