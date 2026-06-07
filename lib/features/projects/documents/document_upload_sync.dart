import 'dart:io';

import '../../../core/database/app_database.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import 'document_tmp_models.dart';
import 'document_tmp_store.dart';
import 'project_document_store.dart';
import 'recording_unit_document_store.dart';

/// Envoie les documents en attente (`documents_tmp`) vers le serveur.
class DocumentUploadSync {
  DocumentUploadSync({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<DocumentUploadSyncResult> syncPendingUploads() async {
    await _db.resetDocumentUploadsForRetry();
    final store = DocumentTmpStore(db: _db, auth: _auth);
    final pending = await store.pendingUploads();
    if (pending.isEmpty) {
      return const DocumentUploadSyncResult(synced: 0, failed: 0);
    }

    var synced = 0;
    var failed = 0;

    final projectStore = ProjectDocumentStore(auth: _auth, db: _db);
    final ruStore = RecordingUnitDocumentStore(auth: _auth, db: _db);

    for (final entry in pending) {
      await _db.updateDocumentTmpStatus(
        localId: entry.localId,
        status: DocumentTmpStatus.uploading,
      );

      try {
        final row = await _db.documentTmpByLocalId(entry.localId);
        if (row == null || row.fileContent.isEmpty) {
          throw AuthException('Fichier local introuvable.');
        }

        final tempDir = Directory.systemTemp;
        final fileName = entry.fileName?.trim().isNotEmpty == true
            ? entry.fileName!
            : 'document';
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(row.fileContent, flush: true);

        final ProjectDocumentItem created;
        if (entry.parentType == DocumentTmpParentType.recordingUnit) {
          created = await _auth.createRecordingUnitDocument(
            recordingUnitId: entry.parentId,
            title: entry.title,
            description: entry.description,
            natureConceptId: entry.natureConceptId,
            scaleConceptId: entry.scaleConceptId,
            formatConceptId: entry.formatConceptId,
            filePath: tempFile.path,
            fileName: fileName,
          );
          await ruStore.saveLocal(
            item: created,
            uniteEnregistrementId: entry.parentId,
          );
        } else {
          created = await _auth.createProjectDocument(
            projectId: entry.parentId,
            title: entry.title,
            description: entry.description,
            natureConceptId: entry.natureConceptId,
            scaleConceptId: entry.scaleConceptId,
            formatConceptId: entry.formatConceptId,
            filePath: tempFile.path,
            fileName: fileName,
          );
          await projectStore.saveLocal(
            item: created,
            projectId: entry.parentId,
          );
        }

        await _db.upsertDocumentTmpPrefetch(
          localId: 'prefetch-${created.id}',
          resourceId: created.id,
          parentType: entry.parentType,
          parentId: entry.parentId,
          titre: created.title,
          fileContent: row.fileContent,
          description: created.description,
          fileName: created.fileName,
          mimeType: created.mimeType,
          fileCode: created.fileCode,
          url: created.url,
        );
        await store.remove(entry.localId);
        synced++;
      } on AuthException catch (e) {
        await _db.updateDocumentTmpStatus(
          localId: entry.localId,
          status: DocumentTmpStatus.failed,
          uploadError: e.message,
        );
        failed++;
      } catch (e) {
        await _db.updateDocumentTmpStatus(
          localId: entry.localId,
          status: DocumentTmpStatus.failed,
          uploadError: e.toString(),
        );
        failed++;
      }
    }

    return DocumentUploadSyncResult(synced: synced, failed: failed);
  }
}

class DocumentUploadSyncResult {
  const DocumentUploadSyncResult({
    required this.synced,
    required this.failed,
  });

  final int synced;
  final int failed;

  bool get hasWork => synced > 0 || failed > 0;
}
