import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/database/vocabulary_cache.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_models.dart';
import '../vocabulary_models.dart';
import 'mobilier_form_fields_store.dart';

/// Charge le formulaire mobilier depuis SQLite ou l’API
/// (`GET /api/v1/finds/form?organizationId=&typeConceptId=`).
class MobilierFormCache {
  MobilierFormCache({required AuthRepository auth, required AppDatabase db})
      : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  static String formCacheKeyForType(int typeConceptId) =>
      FormCacheType.typeMobilier(typeConceptId);

  /// Gabarit UI (création) ou formulaire avec valeurs (édition / visualisation).
  Future<MobilierFormLoadResult> loadMobilierForm({
    String? mobilierId,
    int? typeConceptId,
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
          final body = await _auth.fetchMobilierFormRaw(
            organizationId: orgId,
            mobilierId: key,
          );
          final result = _parseLoadResult(body);
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
          return _loadMobilierFieldsFromLocal(key, fieldsStore);
        }
      }

      return _loadMobilierFieldsFromLocal(key, fieldsStore);
    }

    final resolvedTypeId =
        typeConceptId ?? await _resolveDefaultSpecimenTypeConceptId(orgId);
    if (resolvedTypeId == null) {
      throw AuthException(
        'Type de mobilier indisponible. Synchronisez les vocabulaires en ligne.',
      );
    }

    return loadFormForSpecimenType(typeConceptId: resolvedTypeId);
  }

  Future<MobilierFormLoadResult> loadFormForSpecimenType({
    required int typeConceptId,
  }) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    final cacheType = formCacheKeyForType(typeConceptId);
    var row = await _db.findCachedForm(
      organisationId: orgId,
      type: cacheType,
    );

    if (row == null && await _auth.canUseProjectsApi()) {
      final body = await _auth.fetchMobilierFormRaw(
        organizationId: orgId,
        typeConceptId: typeConceptId,
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
        'Formulaire mobilier indisponible pour ce type hors ligne. '
        'Synchronisez en ligne au moins une fois.',
      );
    }

    final map = _db.decodeFormMap(row);
    final parsed = _parseLoadResult(map ?? {});
    if (parsed.specimenTypeConceptId != null) return parsed;
    final types = await loadSpecimenTypes();
    final match = types.where((t) => t.id == typeConceptId).toList();
    return MobilierFormLoadResult(
      definition: parsed.definition,
      fieldsRaw: parsed.fieldsRaw,
      specimenTypeConceptId: typeConceptId,
      specimenTypeLabel:
          match.isNotEmpty ? match.first.label : parsed.specimenTypeLabel,
    );
  }

  Future<Map<String, List<ConceptOption>>> loadVocabulariesByFieldCode() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const {};
    return VocabularyCache.loadByFieldCode(_db, organisationId: orgId);
  }

  Future<List<ConceptOption>> loadSpecimenTypes() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const [];

    final row = await _db.findCachedForm(
      organisationId: orgId,
      type: FormCacheType.vocabulaire,
    );
    if (row != null) {
      final map = _db.decodeFormMap(row);
      final data = map?['data'];
      if (data is Map) {
        final vocabs = data['vocabulariesByFieldCode'];
        if (vocabs is Map) {
          final types = ConceptOption.specimenTypesFromVocabularies(
            Map<String, dynamic>.from(vocabs),
          );
          if (types.isNotEmpty) return types;
        }
      }
    }

    if (!await _auth.canUseProjectsApi()) return const [];

    final body = await _auth.fetchVocabulariesRaw(organizationId: orgId);
    final data = body['data'];
    if (data is! Map) return const [];
    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return const [];
    return ConceptOption.specimenTypesFromVocabularies(
      Map<String, dynamic>.from(vocabs),
    );
  }

  /// Premier gabarit mobilier en cache (libellés de champs, file sync).
  Future<MobilierFormLoadResult> loadAnyMobilierFormTemplate() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    final typeId = await _resolveDefaultSpecimenTypeConceptId(orgId);
    if (typeId != null) {
      return loadFormForSpecimenType(typeConceptId: typeId);
    }

    final legacy = await _db.findCachedForm(
      organisationId: orgId,
      type: FormCacheType.mobilier,
    );
    if (legacy != null) {
      final map = _db.decodeFormMap(legacy);
      return _parseLoadResult(map ?? {});
    }

    throw AuthException(
      'Formulaire mobilier indisponible hors ligne. Synchronisez en ligne au moins une fois.',
    );
  }

  /// Télécharge et met en cache les formulaires mobilier par type (sync post-login).
  Future<void> ensureMobilierFormsCached() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return;
    if (!await _auth.canUseProjectsApi()) return;

    final types = await loadSpecimenTypes();
    for (final type in types) {
      final cacheType = formCacheKeyForType(type.id);
      final existing = await _db.findCachedForm(
        organisationId: orgId,
        type: cacheType,
      );
      if (existing != null) continue;

      final body = await _auth.fetchMobilierFormRaw(
        organizationId: orgId,
        typeConceptId: type.id,
      );
      await _db.replaceForm(
        organisationId: orgId,
        type: cacheType,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
    }
  }

  Future<int?> _resolveDefaultSpecimenTypeConceptId(int orgId) async {
    final types = await loadSpecimenTypes();
    if (types.isNotEmpty) return types.first.id;
    return null;
  }

  Future<MobilierFormLoadResult> _loadMobilierFieldsFromLocal(
    String mobilierId,
    MobilierFormFieldsStore fieldsStore,
  ) async {
    final fieldsRaw = await fieldsStore.loadFieldsRaw(mobilierId);
    if (fieldsRaw == null || fieldsRaw.isEmpty) {
      throw AuthException(
        'Formulaire mobilier indisponible hors ligne. Consultez ce mobilier en ligne au moins une fois.',
      );
    }

    final template = await loadAnyMobilierFormTemplate();
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
