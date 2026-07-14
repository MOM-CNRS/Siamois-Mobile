import '../../core/database/app_database.dart';
import '../../core/sync/outbox_store.dart';
import '../auth/auth_repository.dart';
import 'documents/document_tmp_store.dart';
import 'project_local_id.dart';

/// Suppression de projets (cache local, serveur, file d’attente).
class ProjectStore {
  ProjectStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<bool> get _isOnline => _auth.canUseProjectsApi();

  /// Supprime un projet localement et/ou sur le serveur.
  Future<void> delete({
    required String projectId,
    required int organizationId,
  }) async {
    final key = projectId.trim();
    if (key.isEmpty) {
      throw AuthException('Identifiant de projet invalide.');
    }

    final isLocal = ProjectLocalId.isLocalListId(key);
    final outbox = OutboxStore(_db);

    if (isLocal) {
      await outbox.removeLocalProjectActions(key);
      await _db.purgeOutboxForProject(key);
      await _db.deleteProjectFromCache(
        projectId: key,
        organisationId: organizationId,
        cascadeChildren: true,
      );
      return;
    }

    await _ensureDeletableOnServer(key);

    if (await _isOnline) {
      try {
        await _auth.deleteProject(projectId: key);
        await outbox.removePendingProjectActions(key);
        await _db.deleteProjectFromCache(
          projectId: key,
          organisationId: organizationId,
          cascadeChildren: false,
        );
        return;
      } on AuthException {
        // Repli hors ligne ci-dessous.
      }
    }

    await outbox.enqueueProjectDelete(
      projectId: key,
      organizationId: organizationId,
    );
    await _db.deleteProjectFromCache(
      projectId: key,
      organisationId: organizationId,
      cascadeChildren: false,
    );
  }

  Future<void> _ensureDeletableOnServer(String projectId) async {
    final ueCount = await _db.countRecordingUnitsForProject(projectId);
    final docCount = await _db.countDocumentsForProject(projectId);
    final pendingDocs = await DocumentTmpStore(db: _db, auth: _auth)
        .pendingForProject(projectId);

    if (ueCount > 0 || docCount > 0 || pendingDocs.isNotEmpty) {
      throw AuthException(
        'Impossible de supprimer ce projet : il contient encore '
        'des unités d’enregistrement ou des documents.',
      );
    }
  }
}
