import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/database/app_database.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import 'document_tmp_models.dart';

/// Stockage binaire local (`documents_tmp`) et file d’attente d’envoi.
class DocumentTmpStore {
  DocumentTmpStore({
    required AppDatabase db,
    required AuthRepository auth,
  })  : _db = db,
        _auth = auth;

  final AppDatabase _db;
  final AuthRepository _auth;

  static String _newLocalId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().hashCode.abs()}';

  /// Enregistre un document créé hors ligne (fichier + métadonnées).
  Future<DocumentTmpEntry> savePendingUpload({
    required String parentType,
    required String parentId,
    required String title,
    required String filePath,
    String? description,
    String? fileName,
    String? mimeType,
    int? natureConceptId,
    int? scaleConceptId,
    int? formatConceptId,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final localId = _newLocalId();
    final name = fileName ?? p.basename(filePath);

    await _db.insertDocumentTmp(
      localId: localId,
      parentType: parentType,
      parentId: parentId,
      kind: DocumentTmpKind.pendingUpload,
      status: DocumentTmpStatus.pending,
      titre: title.trim(),
      fileContent: bytes,
      description: description?.trim(),
      fileName: name,
      mimeType: mimeType,
      natureConceptId: natureConceptId,
      scaleConceptId: scaleConceptId,
      formatConceptId: formatConceptId,
    );

    return DocumentTmpEntry.fromRow(
      (await _db.documentTmpByLocalId(localId))!,
    );
  }

  /// Pré-télécharge le binaire d’un document serveur pour consultation hors ligne.
  Future<void> prefetchFromServer({
    required ProjectDocumentItem item,
    required String parentType,
    required String parentId,
  }) async {
    if (item.id.isEmpty || DocumentTmpEntry.isLocalListId(item.id)) return;

    final bytes = await _auth.downloadDocumentBytes(
      resourceId: item.id,
    );
    if (bytes.isEmpty) return;

    await _db.upsertDocumentTmpPrefetch(
      localId: 'prefetch-${item.id}',
      resourceId: item.id,
      parentType: parentType,
      parentId: parentId,
      titre: item.title,
      fileContent: bytes,
      description: item.description,
      fileName: item.fileName,
      mimeType: item.mimeType,
      fileCode: item.fileCode,
      url: item.url,
    );
  }

  Future<DocumentTmpEntry?> findByListId(String listId) async {
    if (DocumentTmpEntry.isLocalListId(listId)) {
      final localId = DocumentTmpEntry.localIdFromListId(listId);
      final row = await _db.documentTmpByLocalId(localId);
      return row == null ? null : DocumentTmpEntry.fromRow(row);
    }
    final row = await _db.documentTmpByResourceId(listId);
    return row == null ? null : DocumentTmpEntry.fromRow(row);
  }

  Future<Uint8List?> readBytes(String listId) async {
    final entry = await findByListId(listId);
    if (entry == null) return null;
    final row = await _db.documentTmpByLocalId(entry.localId);
    return row?.fileContent;
  }

  /// Écrit le binaire dans un fichier temporaire pour ouverture locale.
  Future<File?> materializeToTempFile(String listId) async {
    final entry = await findByListId(listId);
    if (entry == null) return null;

    final row = await _db.documentTmpByLocalId(entry.localId);
    if (row == null || row.fileContent.isEmpty) return null;

    final dir = await getTemporaryDirectory();
    final safeName = entry.fileName?.trim().isNotEmpty == true
        ? entry.fileName!
        : 'document_${entry.localId}';
    final file = File(p.join(dir.path, safeName));
    await file.writeAsBytes(row.fileContent, flush: true);
    return file;
  }

  Future<List<DocumentTmpEntry>> pendingUploads() async {
    final rows = await _db.pendingUploadDocumentsTmp();
    return rows.map(DocumentTmpEntry.fromRow).toList();
  }

  Future<List<DocumentTmpEntry>> pendingForProject(String projectId) {
    return _pendingForParent(DocumentTmpParentType.project, projectId);
  }

  Future<List<DocumentTmpEntry>> pendingForRecordingUnit(
    String recordingUnitId,
  ) {
    return _pendingForParent(
      DocumentTmpParentType.recordingUnit,
      recordingUnitId,
    );
  }

  Future<List<DocumentTmpEntry>> _pendingForParent(
    String parentType,
    String parentId,
  ) async {
    final rows = parentType == DocumentTmpParentType.project
        ? await _db.documentTmpForProject(parentId)
        : await _db.documentTmpForRecordingUnit(parentId);
    return rows
        .where(
          (r) =>
              r.kind == DocumentTmpKind.pendingUpload &&
              (r.status == DocumentTmpStatus.pending ||
                  r.status == DocumentTmpStatus.failed),
        )
        .map(DocumentTmpEntry.fromRow)
        .toList();
  }

  Future<void> remove(String localId) => _db.deleteDocumentTmp(localId);
}
