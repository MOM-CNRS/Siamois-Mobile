import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_models.dart';
import '../vocabulary_models.dart';

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
      final body = await _auth.fetchMobilierFormRaw(
        organizationId: orgId,
        mobilierId: mobilierId.trim(),
      );
      return _parseLoadResult(body);
    }

    var row = await _db.findValidForm(
      organisationId: orgId,
      type: FormCacheType.mobilier,
    );

    if (row == null && await _auth.isServerReachable()) {
      final body = await _auth.fetchMobilierFormRaw(organizationId: orgId);
      await _db.replaceForm(
        organisationId: orgId,
        type: FormCacheType.mobilier,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
      row = await _db.findValidForm(
        organisationId: orgId,
        type: FormCacheType.mobilier,
      );
    }

    if (row == null) {
      throw AuthException(
        'Formulaire mobilier indisponible. Synchronisez en ligne.',
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

  /// Télécharge et met en cache le formulaire mobilier (sync post-login).
  Future<void> ensureMobilierFormCached() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return;

    final existing = await _db.findValidForm(
      organisationId: orgId,
      type: FormCacheType.mobilier,
    );
    if (existing != null) return;

    if (!await _auth.isServerReachable()) return;

    final body = await _auth.fetchMobilierFormRaw(organizationId: orgId);
    await _db.replaceForm(
      organisationId: orgId,
      type: FormCacheType.mobilier,
      contenuJson: jsonEncode(body),
      ttlDays: 1,
    );
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
