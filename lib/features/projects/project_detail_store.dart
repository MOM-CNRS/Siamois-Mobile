import 'dart:convert';

import '../../core/database/app_database.dart';
import '../auth/auth_repository.dart';
import 'project_models.dart';

/// Résultat du chargement détail projet (API ou cache SQLite).
class ProjectDetailLoadResult {
  const ProjectDetailLoadResult({
    required this.detail,
    required this.fromCache,
  });

  final Map<String, dynamic> detail;
  final bool fromCache;
}

/// Détail projet : API en ligne puis cache SQLite, sinon résumé local.
class ProjectDetailStore {
  ProjectDetailStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  /// `true` si les données peuvent être chargées depuis l’API (pas le mode local seul).
  Future<bool> get isOnline => _auth.canUseProjectsApi();

  Future<ProjectDetailLoadResult> load(
    String projectId, {
    ProjectSummary? summary,
  }) async {
    final key = _resolveStorageId(projectId, summary);
    if (key.isEmpty) {
      throw AuthException('Identifiant de projet invalide.');
    }

    if (await isOnline) {
      try {
        final detail = await _auth.fetchProjectDetail(key);
        await _persistDetail(key, detail);
        return ProjectDetailLoadResult(detail: detail, fromCache: false);
      } on AuthException {
        return _loadFromLocal(key, summary: summary);
      }
    }

    return _loadFromLocal(key, summary: summary);
  }

  Future<void> saveAfterMutation(
    String projectId,
    Map<String, dynamic> detail,
  ) async {
    final key = _resolveStorageId(projectId, null, detail: detail);
    if (key.isEmpty) return;
    await _persistDetail(key, detail);

    final orgId = _auth.primaryOrganizationId;
    if (orgId != null) {
      await _db.upsertProjet(
        project: ProjectSummary.fromJson(detail),
        organisationId: orgId,
      );
    }
  }

  Future<ProjectDetailLoadResult> _loadFromLocal(
    String resourceId, {
    ProjectSummary? summary,
  }) async {
    final row = await _db.projectDetailRow(resourceId);
    if (row != null) {
      final decoded = jsonDecode(row.detailJson);
      if (decoded is Map) {
        return ProjectDetailLoadResult(
          detail: Map<String, dynamic>.from(decoded),
          fromCache: true,
        );
      }
      throw AuthException('Cache projet corrompu.');
    }

    final fallback = await _minimalDetail(
      resourceId,
      summary: summary,
    );
    if (fallback != null) {
      return ProjectDetailLoadResult(detail: fallback, fromCache: true);
    }

    throw AuthException(
      'Détail projet indisponible hors ligne. Ouvrez ce projet en ligne au moins une fois.',
    );
  }

  Future<Map<String, dynamic>?> _minimalDetail(
    String resourceId, {
    ProjectSummary? summary,
  }) async {
    if (summary != null) {
      return _detailFromSummary(summary, resourceId);
    }

    final row = await _db.findProjetRow(resourceId);
    if (row == null) return null;

    return {
      'id': row.id,
      'name': row.nom,
      'fullIdentifier': row.fullIdentifier,
      'identifier': row.identifiant,
      if (row.recordingUnitCount != null)
        'recordingUnitList': {
          'meta': {'count': row.recordingUnitCount},
        },
    };
  }

  static Map<String, dynamic> _detailFromSummary(
    ProjectSummary summary,
    String resourceId,
  ) {
    return {
      'id': summary.id.isNotEmpty ? summary.id : resourceId,
      'name': summary.name,
      'fullIdentifier': summary.fullIdentifier,
      'identifier': summary.identifier,
      if (summary.recordingUnitCount != null)
        'recordingUnitList': {
          'meta': {'count': summary.recordingUnitCount},
        },
    };
  }

  Future<void> _persistDetail(
    String resourceId,
    Map<String, dynamic> detail,
  ) async {
    await _db.replaceProjectDetail(
      resourceId: resourceId,
      detailJson: jsonEncode(detail),
    );
  }

  static String _resolveStorageId(
    String projectId,
    ProjectSummary? summary, {
    Map<String, dynamic>? detail,
  }) {
    if (summary != null) return summary.storageId;
    final fromDetail = detail?['id']?.toString().trim();
    if (fromDetail != null && fromDetail.isNotEmpty) return fromDetail;
    return projectId.trim();
  }
}
