import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/database/vocabulary_cache.dart';
import '../../auth/auth_repository.dart';
import '../documents/document_form_cache.dart';
import 'project_form_models.dart';
import '../vocabulary_models.dart';

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

    var row = await _db.findCachedForm(
      organisationId: orgId,
      type: FormCacheType.projet,
    );

    if (row == null && await _auth.canUseProjectsApi()) {
      final body = await _auth.fetchProjectFormRaw(organizationId: orgId);
      await _db.replaceForm(
        organisationId: orgId,
        type: FormCacheType.projet,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
      row = await _db.findCachedForm(
        organisationId: orgId,
        type: FormCacheType.projet,
      );
    } else if (await _auth.canUseProjectsApi()) {
      await DocumentFormCache(auth: _auth, db: _db).ensureDocumentFormCached();
    }

    if (row == null) {
      throw AuthException(
        'Formulaire projet indisponible hors ligne. Synchronisez en ligne au moins une fois.',
      );
    }

    final map = _db.decodeFormMap(row);
    return ProjectFormDefinition.fromApiData(map ?? {});
  }

  Future<Map<String, List<ConceptOption>>> loadVocabulariesByFieldCode() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const {};
    return VocabularyCache.loadByFieldCode(_db, organisationId: orgId);
  }
}
