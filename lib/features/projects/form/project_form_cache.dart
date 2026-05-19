import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../auth/auth_repository.dart';
import '../vocabulary_models.dart';
import '../documents/document_form_cache.dart';
import '../mobiliers/mobilier_form_cache.dart';
import 'project_form_models.dart';

/// Charge le formulaire projet et les vocabulaires depuis le cache SQLite.
class ProjectFormCache {
  ProjectFormCache({required AuthRepository auth, required AppDatabase db})
      : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<ProjectFormDefinition> loadProjectForm() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    var row = await _db.findValidForm(
      organisationId: orgId,
      type: FormCacheType.projet,
    );

    if (row == null && await _auth.isServerReachable()) {
      final body = await _auth.fetchProjectFormRaw(organizationId: orgId);
      await _db.replaceForm(
        organisationId: orgId,
        type: FormCacheType.projet,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
      await DocumentFormCache(auth: _auth, db: _db).ensureDocumentFormCached();
      await MobilierFormCache(auth: _auth, db: _db).ensureMobilierFormCached();
      row = await _db.findValidForm(
        organisationId: orgId,
        type: FormCacheType.projet,
      );
    } else {
      await DocumentFormCache(auth: _auth, db: _db).ensureDocumentFormCached();
      await MobilierFormCache(auth: _auth, db: _db).ensureMobilierFormCached();
    }

    if (row == null) {
      throw AuthException(
        'Formulaire projet indisponible. Synchronisez en ligne.',
      );
    }

    final map = _db.decodeFormMap(row);
    return ProjectFormDefinition.fromApiData(map ?? {});
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
}
