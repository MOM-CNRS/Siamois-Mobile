import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../auth/auth_repository.dart';
import '../vocabulary_models.dart';
import 'document_form_models.dart';

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

    if (documentId != null && documentId.trim().isNotEmpty) {
      final body = await _auth.fetchDocumentFormRaw(
        organizationId: orgId,
        documentId: documentId.trim(),
      );
      return DocumentFormDefinition.fromApiData(body);
    }

    var row = await _db.findValidForm(
      organisationId: orgId,
      type: FormCacheType.document,
    );

    if (row == null && await _auth.isServerReachable()) {
      final body = await _auth.fetchDocumentFormRaw(organizationId: orgId);
      await _db.replaceForm(
        organisationId: orgId,
        type: FormCacheType.document,
        contenuJson: jsonEncode(body),
        ttlDays: 1,
      );
      row = await _db.findValidForm(
        organisationId: orgId,
        type: FormCacheType.document,
      );
    }

    if (row == null) {
      throw AuthException(
        'Formulaire document indisponible. Synchronisez en ligne.',
      );
    }

    final map = _db.decodeFormMap(row);
    return DocumentFormDefinition.fromApiData(map ?? {});
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

  /// Télécharge et met en cache le formulaire document (appelé avec le formulaire projet).
  Future<void> ensureDocumentFormCached() async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return;

    final existing = await _db.findValidForm(
      organisationId: orgId,
      type: FormCacheType.document,
    );
    if (existing != null) return;

    if (!await _auth.isServerReachable()) return;

    final body = await _auth.fetchDocumentFormRaw(organizationId: orgId);
    await _db.replaceForm(
      organisationId: orgId,
      type: FormCacheType.document,
      contenuJson: jsonEncode(body),
      ttlDays: 1,
    );
  }
}
