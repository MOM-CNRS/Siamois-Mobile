import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/outbox_store.dart';
import '../../auth/auth_repository.dart';
import 'document_tmp_models.dart';
import 'document_tmp_store.dart';
import 'project_document_store.dart';
import 'recording_unit_document_store.dart';

/// Suppression de documents (cache local, serveur, file d’attente hors ligne).
class DocumentStore {
  DocumentStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<bool> get _isOnline => _auth.canUseProjectsApi();

  /// Supprime un document localement et/ou sur le serveur.
  ///
  /// - document local (`local:…`) : retire uniquement `documents_tmp`
  /// - en ligne : DELETE API puis cache
  /// - hors ligne : retire du cache et enfile la suppression pour sync
  Future<void> delete({
    required String documentId,
    String? projectId,
    String? recordingUnitId,
  }) async {
    final key = documentId.trim();
    if (key.isEmpty) {
      throw AuthException('Identifiant de document invalide.');
    }

    if (DocumentTmpEntry.isLocalListId(key)) {
      await DocumentTmpStore(db: _db, auth: _auth).remove(
        DocumentTmpEntry.localIdFromListId(key),
      );
      return;
    }

    final outbox = OutboxStore(_db);
    final parentType = recordingUnitId != null && recordingUnitId.trim().isNotEmpty
        ? DocumentTmpParentType.recordingUnit
        : (projectId != null && projectId.trim().isNotEmpty
            ? DocumentTmpParentType.project
            : null);
    final parentId = recordingUnitId?.trim().isNotEmpty == true
        ? recordingUnitId!.trim()
        : projectId?.trim();

    if (await _isOnline) {
      try {
        await _auth.deleteDocument(key);
        await outbox.removePendingDocumentActions(key);
        await _removeLocalCaches(
          documentId: key,
          projectId: projectId,
          recordingUnitId: recordingUnitId,
        );
        return;
      } on AuthException {
        // Repli hors ligne ci-dessous.
      }
    }

    await outbox.enqueueDocumentDelete(
      documentId: key,
      parentType: parentType,
      parentId: parentId,
    );
    await _removeLocalCaches(
      documentId: key,
      projectId: projectId,
      recordingUnitId: recordingUnitId,
    );
  }

  Future<void> _removeLocalCaches({
    required String documentId,
    String? projectId,
    String? recordingUnitId,
  }) async {
    final projectStore = ProjectDocumentStore(auth: _auth, db: _db);
    final ruStore = RecordingUnitDocumentStore(auth: _auth, db: _db);

    if (projectId != null && projectId.trim().isNotEmpty) {
      await projectStore.removeLocal(documentId);
    }
    if (recordingUnitId != null && recordingUnitId.trim().isNotEmpty) {
      await ruStore.removeLocal(documentId);
    }
    // Au cas où le parent n’est pas connu : nettoie les deux tables cache.
    if ((projectId == null || projectId.trim().isEmpty) &&
        (recordingUnitId == null || recordingUnitId.trim().isEmpty)) {
      await projectStore.removeLocal(documentId);
      await ruStore.removeLocal(documentId);
    }
    await _db.deleteDocumentTmpByResourceId(documentId);
  }
}
