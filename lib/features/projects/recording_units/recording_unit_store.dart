import '../../../core/database/app_database.dart';
import '../../../core/sync/outbox_store.dart';
import '../../auth/auth_repository.dart';
import '../documents/document_tmp_store.dart';
import 'recording_unit_local_id.dart';

/// Suppression d’unités d’enregistrement (cache local, serveur, file d’attente).
class RecordingUnitStore {
  RecordingUnitStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<bool> get _isOnline => _auth.canUseProjectsApi();

  /// Supprime une UE localement et/ou sur le serveur.
  Future<void> delete({
    required String recordingUnitId,
  }) async {
    final key = recordingUnitId.trim();
    if (key.isEmpty) {
      throw AuthException('Identifiant d’unité d’enregistrement invalide.');
    }

    final isLocal = RecordingUnitLocalId.isLocalListId(key);
    final outbox = OutboxStore(_db);

    if (isLocal) {
      await outbox.removeLocalRecordingUnitActions(key);
      await _db.purgeOutboxForRecordingUnit(key);
      await _db.deleteRecordingUnitFromCache(
        resourceId: key,
        cascadeChildren: true,
      );
      return;
    }

    await _ensureDeletableOnServer(key);

    if (await _isOnline) {
      try {
        await _auth.deleteRecordingUnit(key);
        await outbox.removePendingRecordingUnitActions(key);
        await _db.deleteRecordingUnitFromCache(
          resourceId: key,
          cascadeChildren: false,
        );
        return;
      } on AuthException {
        // Repli hors ligne ci-dessous.
      }
    }

    await outbox.enqueueRecordingUnitDelete(recordingUnitId: key);
    await _db.deleteRecordingUnitFromCache(
      resourceId: key,
      cascadeChildren: false,
    );
  }

  Future<void> _ensureDeletableOnServer(String recordingUnitId) async {
    final mobilierCount =
        (await _db.mobiliersForRecordingUnit(recordingUnitId)).length;
    final docCount = await _db.countDocumentsForRecordingUnit(recordingUnitId);
    final pendingDocs = await DocumentTmpStore(db: _db, auth: _auth)
        .pendingForRecordingUnit(recordingUnitId);

    if (mobilierCount > 0 || docCount > 0 || pendingDocs.isNotEmpty) {
      throw AuthException(
        'Impossible de supprimer cette unité d’enregistrement : '
        'elle contient encore des mobiliers ou des documents.',
      );
    }
  }
}
