import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/database/vocabulary_cache.dart';
import '../../auth/auth_repository.dart';
import '../form/project_entity_type.dart';
import '../form/project_form_models.dart';
import '../vocabulary_models.dart';
import 'recording_unit_detail_models.dart';
import 'recording_unit_form_models.dart';

/// Charge les formulaires UE depuis le catalogue de types du projet
/// (`GET /projects/{id}/recording-unit-types`, mis en cache à la synchro).
class RecordingUnitFormCache {
  RecordingUnitFormCache(
      {required AuthRepository auth, required AppDatabase db})
      : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  /// Clé `forms.type` pour un type d’UE donné.
  static String formCacheKeyForType(int typeConceptId) =>
      FormCacheType.typeUe(typeConceptId);

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

  Future<int?> _resolveTypeFromVocabularyLabel(
    String? typeLabel, {
    String? projectId,
  }) async {
    final label = typeLabel?.trim().toLowerCase();
    if (label == null || label.isEmpty) return null;

    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return null;

    final types = await VocabularyCache.loadTypes(
      _db,
      organisationId: orgId,
      kind: ProjectTypeKind.recordingUnit,
      projectId: projectId,
    );
    for (final type in types) {
      if (type.label.trim().toLowerCase() == label) return type.typeConceptId;
    }
    return null;
  }

  /// Formulaire de création ou de modification selon le type d’UE.
  ///
  /// Sans [projectId], le type est cherché dans les catalogues de tous les
  /// projets en cache.
  Future<RecordingUnitFormLoadResult> loadFormForRecordingUnitType({
    required int typeConceptId,
    String? projectId,
  }) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    var type = await VocabularyCache.findType(
      _db,
      organisationId: orgId,
      kind: ProjectTypeKind.recordingUnit,
      typeConceptId: typeConceptId,
      projectId: projectId,
    );
    if (type == null && projectId != null) {
      final types = await _auth.loadProjectTypes(
        projectId: projectId,
        kind: ProjectTypeKind.recordingUnit,
      );
      for (final t in types) {
        if (t.typeConceptId == typeConceptId) type = t;
      }
    }

    if (type == null) {
      throw AuthException(
        'Formulaire UE indisponible pour ce type hors ligne. '
        'Synchronisez en ligne au moins une fois.',
      );
    }
    return _parseLoadResult(type.toFormBody());
  }

  /// Alias conservé pour la création d’UE.
  Future<RecordingUnitFormLoadResult> loadCreationForm({
    required int typeConceptId,
    String? projectId,
  }) =>
      loadFormForRecordingUnitType(
        typeConceptId: typeConceptId,
        projectId: projectId,
      );

  /// `fieldCode` → options, restreint au projet / type quand ils sont connus.
  Future<Map<String, List<ConceptOption>>> loadVocabulariesByFieldCode({
    String? projectId,
    int? typeConceptId,
  }) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const {};
    return VocabularyCache.loadByFieldCode(
      _db,
      organisationId: orgId,
      projectId: projectId,
      typeConceptId: typeConceptId,
    );
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
