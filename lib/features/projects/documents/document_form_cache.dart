import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/database/vocabulary_cache.dart';
import '../../auth/auth_repository.dart';
import '../vocabulary_models.dart';
import 'document_form_models.dart';
import 'document_tmp_models.dart';

/// Charge le formulaire document depuis SQLite ou l’API.
class DocumentFormCache {
  DocumentFormCache({required AuthRepository auth, required AppDatabase db})
      : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<DocumentFormDefinition> loadDocumentForm({
    String? documentId,
  }) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      throw AuthException('Organisation inconnue.');
    }

    final trimmedId = documentId?.trim();
    if (trimmedId != null &&
        trimmedId.isNotEmpty &&
        !DocumentTmpEntry.isLocalListId(trimmedId)) {
      if (!await _auth.isOfflineEnvironment()) {
        try {
          final body = await _auth.fetchDocumentFormRaw(
            organizationId: orgId,
            documentId: trimmedId,
          );
          return DocumentFormDefinition.fromApiData(body);
        } on AuthException {
          // Gabarit local ci-dessous.
        }
      }
    }

    var row = await _db.findCachedForm(
      organisationId: orgId,
      type: FormCacheType.document,
    );

    if (row == null && await _auth.canUseProjectsApi()) {
      final body = await _auth.fetchDocumentFormRaw(organizationId: orgId);
      await _db.replaceForm(
        organisationId: orgId,
        type: FormCacheType.document,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
      row = await _db.findCachedForm(
        organisationId: orgId,
        type: FormCacheType.document,
      );
    }

    if (row == null) {
      throw AuthException(
        'Formulaire document indisponible hors ligne. Synchronisez en ligne au moins une fois.',
      );
    }

    final map = _db.decodeFormMap(row);
    return DocumentFormDefinition.fromApiData(map ?? {});
  }

  Future<Map<String, List<ConceptOption>>> loadVocabulariesByFieldCode() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const {};
    return VocabularyCache.loadByFieldCode(_db, organisationId: orgId);
  }

  /// Télécharge et met en cache le formulaire document (sync en ligne).
  Future<void> ensureDocumentFormCached() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return;

    final existing = await _db.findCachedForm(
      organisationId: orgId,
      type: FormCacheType.document,
    );
    if (existing != null) return;

    if (!await _auth.canUseProjectsApi()) return;

    final body = await _auth.fetchDocumentFormRaw(organizationId: orgId);
    await _db.replaceForm(
      organisationId: orgId,
      type: FormCacheType.document,
      contenuJson: jsonEncode(body),
      ttlDays: 1,
    );
  }
}
