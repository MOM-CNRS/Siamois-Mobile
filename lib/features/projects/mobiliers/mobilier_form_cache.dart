import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/database/vocabulary_cache.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_models.dart';
import '../vocabulary_models.dart';
import 'mobilier_form_fields_store.dart';

/// Charge le formulaire mobilier depuis SQLite ou l’API.
class MobilierFormCache {
  MobilierFormCache({required AuthRepository auth, required AppDatabase db})
      : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  /// Gabarit UI (création) ou formulaire avec valeurs (édition / visualisation).
  Future<MobilierFormLoadResult> loadMobilierForm({
    String? mobilierId,
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

    var row = await _db.findCachedForm(
      organisationId: orgId,
      type: FormCacheType.mobilier,
    );

    if (row == null && await _auth.canUseProjectsApi()) {
      final body = await _auth.fetchMobilierFormRaw(organizationId: orgId);
      await _db.replaceForm(
        organisationId: orgId,
        type: FormCacheType.mobilier,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
      row = await _db.findCachedForm(
        organisationId: orgId,
        type: FormCacheType.mobilier,
      );
    }

    if (row == null) {
      throw AuthException(
        'Formulaire mobilier indisponible hors ligne. Synchronisez en ligne au moins une fois.',
      );
    }

    final map = _db.decodeFormMap(row);
    return _parseLoadResult(map ?? {});
  }

  Future<Map<String, List<ConceptOption>>> loadVocabulariesByFieldCode() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const {};
    return VocabularyCache.loadByFieldCode(_db, organisationId: orgId);
  }

  /// Télécharge et met en cache le formulaire mobilier (sync post-login).
  Future<void> ensureMobilierFormCached() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return;

    final existing = await _db.findCachedForm(
      organisationId: orgId,
      type: FormCacheType.mobilier,
    );
    if (existing != null) return;

    if (!await _auth.canUseProjectsApi()) return;

    final body = await _auth.fetchMobilierFormRaw(organizationId: orgId);
    await _db.replaceForm(
      organisationId: orgId,
      type: FormCacheType.mobilier,
      contenuJson: jsonEncode(body),
      ttlDays: 1,
    );
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

    final template = await _loadMobilierFormTemplate();
    return MobilierFormLoadResult(
      definition: template.definition,
      fieldsRaw: fieldsRaw,
    );
  }

  Future<MobilierFormLoadResult> _loadMobilierFormTemplate() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    final row = await _db.findCachedForm(
      organisationId: orgId,
      type: FormCacheType.mobilier,
    );
    if (row == null) {
      throw AuthException(
        'Formulaire mobilier indisponible hors ligne. Synchronisez en ligne au moins une fois.',
      );
    }
    final map = _db.decodeFormMap(row);
    return _parseLoadResult(map ?? {});
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

    return MobilierFormLoadResult(
      definition: definition,
      fieldsRaw: fieldsMap,
    );
  }
}

class MobilierFormLoadResult {
  const MobilierFormLoadResult({
    required this.definition,
    this.fieldsRaw = const {},
  });

  final ProjectFormDefinition definition;
  final Map<String, dynamic> fieldsRaw;
}
