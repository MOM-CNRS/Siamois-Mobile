import 'dart:async';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/outbox_store.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import 'document_remote_store.dart';
import 'document_tmp_models.dart';
import 'document_tmp_store.dart';

/// Charge et met à jour le cache local des documents d’un projet.
class ProjectDocumentStore implements DocumentRemoteStore {
  ProjectDocumentStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<bool> get isOnline => _auth.canUseProjectsApi();

  /// Serveur injoignable (affichage bandeau), indépendant du jeton API.
  Future<bool> get isOffline => _auth.isOfflineEnvironment();

  Future<bool> get _isOnline => isOnline;

  /// En ligne : API puis remplacement du cache. Hors ligne : SQLite uniquement.
  Future<List<ProjectDocumentItem>> loadForProject(String projectId) async {
    final key = projectId.trim();
    if (key.isEmpty) return const [];

    if (await _isOnline) {
      try {
        final remote = await _auth.fetchProjectDocuments(key);
        final visible = await _withoutPendingDeletes(remote);
        await _db.replaceDocumentsForProject(
          projectId: key,
          items: visible,
        );
        final merged = await _mergePendingUploads(key, visible);
        _prefetchInBackground(merged, key);
        return merged;
      } on AuthException {
        return _loadFromLocal(key);
      }
    }

    return _loadFromLocal(key);
  }

  Future<List<ProjectDocumentItem>> _loadFromLocal(String projectId) async {
    final rows = await _db.documentsForProject(projectId);
    final items = rows.map(_itemFromRow).toList();
    final visible = await _withoutPendingDeletes(items);
    return _mergePendingUploads(projectId, visible);
  }

  Future<List<ProjectDocumentItem>> _withoutPendingDeletes(
    List<ProjectDocumentItem> items,
  ) async {
    final deleteIds = await OutboxStore(_db).pendingDocumentDeleteIds();
    if (deleteIds.isEmpty) return items;
    return items.where((d) => !deleteIds.contains(d.id.trim())).toList();
  }

  Future<List<ProjectDocumentItem>> _mergePendingUploads(
    String projectId,
    List<ProjectDocumentItem> base,
  ) async {
    final pending = await DocumentTmpStore(db: _db, auth: _auth)
        .pendingForProject(projectId);
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
    String projectId,
  ) {
    final store = DocumentTmpStore(db: _db, auth: _auth);
    for (final item in items) {
      if (DocumentTmpEntry.isLocalListId(item.id)) continue;
      unawaited(
        store
            .prefetchFromServer(
              item: item,
              parentType: DocumentTmpParentType.project,
              parentId: projectId,
            )
            .catchError((_) {}),
      );
    }
  }

  /// Consultation possible (binaire local ou serveur joignable).
  Future<bool> canOpenDocument(ProjectDocumentItem doc) async {
    if (DocumentTmpEntry.isLocalListId(doc.id)) return true;
    final bytes =
        await DocumentTmpStore(db: _db, auth: _auth).readBytes(doc.id);
    if (bytes != null && bytes.isNotEmpty) return true;
    return await _isOnline;
  }

  static ProjectDocumentItem _itemFromRow(Document row) {
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
    await _db.deleteDocumentByResourceId(resourceId);
  }

  Future<void> saveLocal({
    required ProjectDocumentItem item,
    required String projectId,
  }) async {
    await _db.upsertDocument(item: item, projectId: projectId);
  }

  /// URL absolue à partir du chemin relatif renvoyé par l’API.
  @override
  String? absoluteUrlFor(String? relativeUrl) {
    return _auth.absoluteServerUrl(relativeUrl);
  }

  @override
  bool get canOpenRemote => _auth.lastUsedBaseUrl.trim().isNotEmpty;
}
