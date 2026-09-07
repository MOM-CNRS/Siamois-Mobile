import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/database/vocabulary_cache.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_models.dart';
import '../vocabulary_models.dart';
import 'recording_unit_detail_models.dart';
import 'recording_unit_form_models.dart';
/// Charge les formulaires UE depuis la table `forms` (colonne `type` =
/// `TYPE_UE_{typeConceptId}`) ou l’API de création pour ce type.
class RecordingUnitFormCache {
  RecordingUnitFormCache({required AuthRepository auth, required AppDatabase db})
      : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  /// Clé `forms.type` pour un projet et un type d’UE donnés.
  static String formCacheKeyForType(String projectId, int typeConceptId) =>
      FormCacheType.typeUe(projectId, typeConceptId);

  /// Résout le type d’UE à partir du détail API, avec repli SQLite.
  static int? resolveTypeConceptId(
    RecordingUnitMobileDetail detail, {
    int? cachedTypeConceptId,
  }) =>
      detail.resolveTypeConceptId(fallback: cachedTypeConceptId);

  /// Résolution complète pour l’édition (détail, cache liste/détail, vocabulaire).
  Future<int?> resolveTypeConceptIdForEdit({
    required RecordingUnitMobileDetail detail,
    required String recordingUnitId,
  }) async {
    final detailRow = await _db.recordingUnitDetailRow(recordingUnitId.trim());
    var typeId = resolveTypeConceptId(
      detail,
      cachedTypeConceptId: detailRow?.typeConceptId,
    );
    if (typeId != null) return typeId;

    final listRow = await _db.recordingUnitListRow(recordingUnitId.trim());
    typeId = resolveTypeConceptId(
      detail,
      cachedTypeConceptId: listRow?.typeConceptId,
    );
    if (typeId != null) return typeId;

    return _resolveTypeFromVocabularyLabel(detail.typeLabel);
  }

  Future<int?> _resolveTypeFromVocabularyLabel(String? typeLabel) async {
    final label = typeLabel?.trim();
    if (label == null || label.isEmpty) return null;

    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return null;

    final vocab = await loadVocabulariesByFieldCode();
    final normalized = label.toLowerCase();
    for (final options in vocab.values) {
      for (final opt in options) {
        if (opt.label.trim().toLowerCase() == normalized) return opt.id;
      }
    }
    return null;
  }

  /// Formulaire de création ou de modification selon le projet et le type d’UE.
  Future<RecordingUnitFormLoadResult> loadFormForRecordingUnitType({
    required String projectId,
    required int typeConceptId,
  }) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    final cacheType = formCacheKeyForType(projectId, typeConceptId);
    var row = await _db.findCachedForm(
      organisationId: orgId,
      type: cacheType,
    );

    final online = await _auth.canUseProjectsApi();
    final cachedStale = row != null && _definitionMissingFieldCodes(row);

    if ((row == null || cachedStale) && online) {
      final body = await _auth.fetchRecordingUnitCreationFormRaw(
        projectId: projectId,
        recordingUnitTypeConceptId: typeConceptId,
      );
      await _db.replaceForm(
        organisationId: orgId,
        type: cacheType,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
      row = await _db.findCachedForm(
        organisationId: orgId,
        type: cacheType,
      );
    }

    if (row == null) {
      throw AuthException(
        'Formulaire UE indisponible pour ce type hors ligne. '
        'Synchronisez en ligne au moins une fois.',
      );
    }

    final map = _db.decodeFormMap(row);
    return _parseLoadResult(map ?? {});
  }

  /// Anciens caches sans `fieldCode` (vocabulaire chrono / géomorpho, etc.).
  bool _definitionMissingFieldCodes(Form row) {
    final map = _db.decodeFormMap(row);
    if (map == null) return true;
    final result = _parseLoadResult(map);
    for (final field in result.definition.fieldsInLayoutOrder) {
      if (!field.normalizedType.contains('FROM_FIELD_CODE')) continue;
      final code = field.fieldCode?.trim() ?? '';
      if (code.isEmpty) return true;
    }
    return false;
  }

  /// Alias conservé pour la création d’UE.
  Future<RecordingUnitFormLoadResult> loadCreationForm({
    required String projectId,
    required int typeConceptId,
  }) =>
      loadFormForRecordingUnitType(
        projectId: projectId,
        typeConceptId: typeConceptId,
      );

  Future<Map<String, List<ConceptOption>>> loadVocabulariesByFieldCode() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const {};
    return VocabularyCache.loadByFieldCode(_db, organisationId: orgId);
  }

  RecordingUnitFormLoadResult _parseLoadResult(dynamic data) {
    if (data is! Map) {
      return const RecordingUnitFormLoadResult(
        definition: ProjectFormDefinition(fieldsById: {}, panels: []),
      );
    }
    final root = Map<String, dynamic>.from(data);
    final inner = root['data'];
    final payload = inner is Map ? Map<String, dynamic>.from(inner) : root;

    final definition = ProjectFormDefinition.fromApiData(payload);
    final fieldsRaw = payload['fields'];
    final fieldsMap = fieldsRaw is Map
        ? Map<String, dynamic>.from(fieldsRaw)
        : <String, dynamic>{};

    return RecordingUnitFormLoadResult(
      definition: definition,
      fieldsRaw: fieldsMap,
    );
  }
}
