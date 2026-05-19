import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_models.dart';
import '../vocabulary_models.dart';
import 'recording_unit_form_models.dart';

/// Charge les formulaires UE (création par type) depuis SQLite ou l’API.
class RecordingUnitFormCache {
  RecordingUnitFormCache({required AuthRepository auth, required AppDatabase db})
      : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<RecordingUnitFormLoadResult> loadCreationForm({
    required int typeConceptId,
  }) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    final cacheType = FormCacheType.typeUe(typeConceptId);
    var row = await _db.findValidForm(
      organisationId: orgId,
      type: cacheType,
    );

    if (row == null && await _auth.isServerReachable()) {
      final body = await _auth.fetchRecordingUnitCreationFormRaw(
        organizationId: orgId,
        recordingUnitTypeConceptId: typeConceptId,
      );
      await _db.replaceForm(
        organisationId: orgId,
        type: cacheType,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
      row = await _db.findValidForm(
        organisationId: orgId,
        type: cacheType,
      );
    }

    if (row == null) {
      throw AuthException(
        'Formulaire UE indisponible pour ce type. Synchronisez en ligne.',
      );
    }

    final map = _db.decodeFormMap(row);
    return _parseLoadResult(map ?? {});
  }

  Future<Map<String, List<ConceptOption>>> loadVocabulariesByFieldCode() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const {};

    final row = await _db.findValidForm(
      organisationId: orgId,
      type: FormCacheType.vocabulaire,
    );
    if (row == null) return const {};

    final map = _db.decodeFormMap(row);
    final data = map?['data'];
    if (data is! Map) return const {};

    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return const {};

    return ConceptOption.vocabulariesFromApiMap(
      Map<String, dynamic>.from(vocabs),
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
