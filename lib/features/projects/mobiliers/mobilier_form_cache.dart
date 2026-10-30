import '../../../core/database/app_database.dart';
import '../../../core/database/vocabulary_cache.dart';
import '../../auth/auth_repository.dart';
import '../form/project_entity_type.dart';
import '../form/project_form_models.dart';
import '../vocabulary_models.dart';
import 'mobilier_form_fields_store.dart';

/// Charge le formulaire mobilier depuis le catalogue de types du projet
/// (`GET /projects/{id}/find-types`, mis en cache à la synchro).
class MobilierFormCache {
  MobilierFormCache({required AuthRepository auth, required AppDatabase db})
      : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  /// Gabarit UI (création) ou formulaire avec valeurs (édition / visualisation).
  ///
  /// Sans [projectId], le type est cherché dans les catalogues de tous les
  /// projets en cache.
  Future<MobilierFormLoadResult> loadMobilierForm({
    String? mobilierId,
    int? typeConceptId,
    String? projectId,
  }) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    if (mobilierId != null && mobilierId.trim().isNotEmpty) {
      final key = mobilierId.trim();
      final fieldsStore = MobilierFormFieldsStore(_db);

      if (await _auth.canUseProjectsApi()) {
        try {
          final body = await _auth.fetchMobilierFormRaw(mobilierId: key);
          var result = _parseLoadResult(body);
          if (result.definition.panels.isEmpty) {
            // Le détail n'embarque pas toujours le layout : celui du type.
            final template = await loadAnyMobilierFormTemplate(
              projectId: projectId,
            );
            result = MobilierFormLoadResult(
              definition: template.definition,
              fieldsRaw: result.fieldsRaw,
              specimenTypeConceptId: result.specimenTypeConceptId,
              specimenTypeLabel: result.specimenTypeLabel,
            );
          }
          final recordingUnitId = await _resolveRecordingUnitIdForMobilier(key);
          if (recordingUnitId != null) {
            await fieldsStore.saveFromApiFields(
              mobilierId: key,
              recordingUnitId: recordingUnitId,
              fieldsRaw: result.fieldsRaw,
            );
          }
          return result;
        } on AuthException {
          return _loadMobilierFieldsFromLocal(key, fieldsStore, projectId);
        }
      }

      return _loadMobilierFieldsFromLocal(key, fieldsStore, projectId);
    }

    final resolvedTypeId = typeConceptId ??
        await _resolveDefaultSpecimenTypeConceptId(projectId: projectId);
    if (resolvedTypeId == null) {
      throw AuthException(
        'Type de mobilier indisponible. Synchronisez en ligne.',
      );
    }

    return loadFormForSpecimenType(
      typeConceptId: resolvedTypeId,
      projectId: projectId,
    );
  }

  Future<MobilierFormLoadResult> loadFormForSpecimenType({
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
      kind: ProjectTypeKind.find,
      typeConceptId: typeConceptId,
      projectId: projectId,
    );
    if (type == null && projectId != null) {
      final types = await _auth.loadProjectTypes(
        projectId: projectId,
        kind: ProjectTypeKind.find,
      );
      for (final t in types) {
        if (t.typeConceptId == typeConceptId) type = t;
      }
    }
    if (type == null) {
      throw AuthException(
        'Formulaire mobilier indisponible pour ce type hors ligne. '
        'Synchronisez en ligne au moins une fois.',
      );
    }

    final parsed = _parseLoadResult(type.toFormBody());
    return MobilierFormLoadResult(
      definition: parsed.definition,
      fieldsRaw: parsed.fieldsRaw,
      specimenTypeConceptId: type.typeConceptId,
      specimenTypeLabel: type.label,
    );
  }

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

  /// Types de mobilier du projet (catalogue `find-types`).
  Future<List<ConceptOption>> loadSpecimenTypes({String? projectId}) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const [];

    final cached = await VocabularyCache.loadTypes(
      _db,
      organisationId: orgId,
      kind: ProjectTypeKind.find,
      projectId: projectId,
    );
    if (cached.isNotEmpty) return [for (final t in cached) t.option];

    if (projectId == null || !await _auth.canUseProjectsApi()) return const [];
    final types = await _auth.loadProjectTypes(
      projectId: projectId,
      kind: ProjectTypeKind.find,
    );
    return [for (final t in types) t.option];
  }

  /// Premier gabarit mobilier en cache (libellés de champs, file sync).
  Future<MobilierFormLoadResult> loadAnyMobilierFormTemplate({
    String? projectId,
  }) async {
    final typeId =
        await _resolveDefaultSpecimenTypeConceptId(projectId: projectId);
    if (typeId != null) {
      return loadFormForSpecimenType(
        typeConceptId: typeId,
        projectId: projectId,
      );
    }
    throw AuthException(
      'Formulaire mobilier indisponible hors ligne. Synchronisez en ligne au moins une fois.',
    );
  }

  Future<int?> _resolveDefaultSpecimenTypeConceptId({String? projectId}) async {
    final types = await loadSpecimenTypes(projectId: projectId);
    if (types.isNotEmpty) return types.first.id;
    return null;
  }

  Future<MobilierFormLoadResult> _loadMobilierFieldsFromLocal(
    String mobilierId,
    MobilierFormFieldsStore fieldsStore,
    String? projectId,
  ) async {
    final fieldsRaw = await fieldsStore.loadFieldsRaw(mobilierId);
    if (fieldsRaw == null || fieldsRaw.isEmpty) {
      throw AuthException(
        'Formulaire mobilier indisponible hors ligne. Consultez ce mobilier en ligne au moins une fois.',
      );
    }

    final template = await loadAnyMobilierFormTemplate(projectId: projectId);
    return MobilierFormLoadResult(
      definition: template.definition,
      fieldsRaw: fieldsRaw,
    );
  }

  Future<String?> _resolveRecordingUnitIdForMobilier(String mobilierId) async {
    return _db.recordingUnitIdForMobilier(mobilierId);
  }

  MobilierFormLoadResult _parseLoadResult(dynamic data) {
    if (data is! Map) {
      return const MobilierFormLoadResult(
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

    final findType = _parseFindType(payload['findType'] ?? payload['type']);

    return MobilierFormLoadResult(
      definition: definition,
      fieldsRaw: fieldsMap,
      specimenTypeConceptId: findType?.id,
      specimenTypeLabel: findType?.label,
    );
  }

  static ({int id, String? label})? _parseFindType(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final idRaw = map['id'] ?? map['conceptId'] ?? map['resourceId'];
    int? id;
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is num) {
      id = idRaw.toInt();
    } else {
      id = int.tryParse(idRaw?.toString() ?? '');
    }
    if (id == null) return null;
    final label = (map['label'] as String?)?.trim() ??
        (map['name'] as String?)?.trim() ??
        (map['prefLabel'] as String?)?.trim();
    return (id: id, label: label);
  }
}

class MobilierFormLoadResult {
  const MobilierFormLoadResult({
    required this.definition,
    this.fieldsRaw = const {},
    this.specimenTypeConceptId,
    this.specimenTypeLabel,
  });

  final ProjectFormDefinition definition;
  final Map<String, dynamic> fieldsRaw;

  /// Type utilisé pour charger le gabarit (`findType` / `typeConceptId`).
  final int? specimenTypeConceptId;
  final String? specimenTypeLabel;
}
