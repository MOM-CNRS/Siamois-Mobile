import 'dart:async';

import '../../../core/database/app_database.dart' hide Form;
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import 'document_remote_store.dart';
import 'document_tmp_models.dart';
import 'document_tmp_store.dart';

/// Charge et met à jour le cache local des documents d’une UE.
class RecordingUnitDocumentStore implements DocumentRemoteStore {
  RecordingUnitDocumentStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<bool> get isOnline => _auth.canUseProjectsApi();

  Future<bool> get isOffline => _auth.isOfflineEnvironment();

  Future<bool> get _isOnline => isOnline;

  /// En ligne : API puis remplacement du cache. Hors ligne : SQLite uniquement.
  Future<List<ProjectDocumentItem>> loadForRecordingUnit(
    String uniteEnregistrementId,
  ) async {
    final key = uniteEnregistrementId.trim();
    if (key.isEmpty) return const [];

    if (await _isOnline) {
      try {
        final remote = await _auth.fetchRecordingUnitDocuments(key);
        await _db.replaceDocumentsForRecordingUnit(
          uniteEnregistrementId: key,
          items: remote,
        );
        final merged = await _mergePendingUploads(key, remote);
        _prefetchInBackground(merged, key);
        return merged;
      } on AuthException {
        return _loadFromLocal(key);
      }
    }

    return _loadFromLocal(key);
  }

  Future<List<ProjectDocumentItem>> _loadFromLocal(
    String uniteEnregistrementId,
  ) async {
    final rows = await _db.documentsForRecordingUnit(uniteEnregistrementId);
    final items = rows.map(_itemFromRow).toList();
    return _mergePendingUploads(uniteEnregistrementId, items);
  }

  Future<List<ProjectDocumentItem>> _mergePendingUploads(
    String recordingUnitId,
    List<ProjectDocumentItem> base,
  ) async {
    final pending = await DocumentTmpStore(db: _db, auth: _auth)
        .pendingForRecordingUnit(recordingUnitId);
    if (pending.isEmpty) return base;

    final ids = base.map((e) => e.id).toSet();
    final merged = [...base];
    for (final entry in pending) {
      final item = entry.toListItem();
      if (!ids.contains(item.id)) merged.add(item);
    }
    merged.sort(
      (a, b) => a.displayTitle.toLowerCase().compareTo(
            b.displayTitle.toLowerCase(),
          ),
    );
    return merged;
  }

  void _prefetchInBackground(
    List<ProjectDocumentItem> items,
    String recordingUnitId,
  ) {
    final store = DocumentTmpStore(db: _db, auth: _auth);
    for (final item in items) {
      if (DocumentTmpEntry.isLocalListId(item.id)) continue;
      unawaited(
        store
            .prefetchFromServer(
              item: item,
              parentType: DocumentTmpParentType.recordingUnit,
              parentId: recordingUnitId,
            )
            .catchError((_) {}),
      );
    }
  }

  Future<bool> canOpenDocument(ProjectDocumentItem doc) async {
    if (DocumentTmpEntry.isLocalListId(doc.id)) return true;
    final bytes =
        await DocumentTmpStore(db: _db, auth: _auth).readBytes(doc.id);
    if (bytes != null && bytes.isNotEmpty) return true;
    return await _isOnline;
  }

  static ProjectDocumentItem _itemFromRow(DocumentUniteEnregistrement row) {
    return ProjectDocumentItem(
      id: row.resourceId,
      title: row.titre,
      description: row.description,
      fileName: row.fileName,
      mimeType: row.mimeType,
      url: row.url,
      fileCode: row.fileCode,
    );
  }

  Future<void> removeLocal(String resourceId) async {
    await _db.deleteRecordingUnitDocumentByResourceId(resourceId);
  }

  Future<void> saveLocal({
    required ProjectDocumentItem item,
    required String uniteEnregistrementId,
  }) async {
    await _db.upsertRecordingUnitDocument(
      item: item,
      uniteEnregistrementId: uniteEnregistrementId,
    );
  }

  @override
  String? absoluteUrlFor(String? relativeUrl) {
    return _auth.absoluteServerUrl(relativeUrl);
  }

  @override
  bool get canOpenRemote => _auth.lastUsedBaseUrl.trim().isNotEmpty;
}
