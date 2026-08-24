import '../../core/database/app_database.dart';
import '../auth/auth_repository.dart';
import 'documents/document_tmp_store.dart';
import 'documents/project_document_store.dart';
import 'form/project_detail_mapper.dart';
import 'project_detail_store.dart';
import 'project_models.dart';

/// Compteurs UE / documents affichés sur le détail projet.
class ProjectDetailCounts {
  const ProjectDetailCounts({
    required this.recordingUnitCount,
    required this.documentCount,
  });

  final int recordingUnitCount;
  final int documentCount;

  static Future<ProjectDetailCounts> resolve({
    required AuthRepository auth,
    required AppDatabase db,
    required String projectId,
    Map<String, dynamic>? project,
    ProjectSummary? summary,
  }) async {
    final key = _storageId(projectId, project, summary);
    if (key.isEmpty) {
      return const ProjectDetailCounts(
        recordingUnitCount: 0,
        documentCount: 0,
      );
    }

    final detailStore = ProjectDetailStore(auth: auth, db: db);
    final online = await detailStore.isOnline;

    final ueCount = await _recordingUnitCount(
      auth: auth,
      db: db,
      projectId: key,
      project: project,
      summary: summary,
      online: online,
    );

    final documentCount = await _documentCount(
      auth: auth,
      db: db,
      projectId: key,
      project: project,
      online: online,
    );

    return ProjectDetailCounts(
      recordingUnitCount: ueCount,
      documentCount: documentCount,
    );
  }

  static Future<int> _recordingUnitCount({
    required AuthRepository auth,
    required AppDatabase db,
    required String projectId,
    Map<String, dynamic>? project,
    ProjectSummary? summary,
    required bool online,
  }) async {
    final fromDetail = project != null
        ? ProjectDetailMapper.recordingUnitCount(project)
        : summary?.recordingUnitCount;
    if (fromDetail != null) return fromDetail;

    final local = await db.countRecordingUnitsForProject(projectId);
    if (!online) return local;

    try {
      final page = await auth.fetchProjectRecordingUnits(
        projectId,
        offset: 0,
        limit: 1,
      );
      return page.total;
    } on AuthException {
      return local;
    }
  }

  static Future<int> _documentCount({
    required AuthRepository auth,
    required AppDatabase db,
    required String projectId,
    Map<String, dynamic>? project,
    required bool online,
  }) async {
    if (online) {
      try {
        return (await ProjectDocumentStore(auth: auth, db: db)
                .loadForProject(projectId))
            .length;
      } on AuthException {
        return _documentCountOffline(db: db, auth: auth, projectId: projectId);
      }
    }

    final fromDetail =
        project != null ? ProjectDetailMapper.documentCount(project) : null;
    if (fromDetail != null) {
      return fromDetail +
          await _pendingDocumentsNotInCache(
            db: db,
            auth: auth,
            projectId: projectId,
          );
    }

    return _documentCountOffline(db: db, auth: auth, projectId: projectId);
  }

  static Future<int> _documentCountOffline({
    required AppDatabase db,
    required AuthRepository auth,
    required String projectId,
  }) async {
    final local = await db.countDocumentsForProject(projectId);
    return local +
        await _pendingDocumentsNotInCache(
          db: db,
          auth: auth,
          projectId: projectId,
        );
  }

  static Future<int> _pendingDocumentsNotInCache({
    required AppDatabase db,
    required AuthRepository auth,
    required String projectId,
  }) async {
    final pending =
        await DocumentTmpStore(db: db, auth: auth).pendingForProject(projectId);
    if (pending.isEmpty) return 0;

    final knownIds =
        (await db.documentsForProject(projectId)).map((r) => r.resourceId).toSet();
    var extra = 0;
    for (final entry in pending) {
      if (!knownIds.contains(entry.toListItem().id)) extra++;
    }
    return extra;
  }

  static String _storageId(
    String projectId,
    Map<String, dynamic>? project,
    ProjectSummary? summary,
  ) {
    if (summary != null) return summary.storageId;
    final fromProject = project?['id']?.toString().trim();
    if (fromProject != null && fromProject.isNotEmpty) return fromProject;
    return projectId.trim();
  }
}
