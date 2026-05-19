import '../../../core/database/app_database.dart';
import '../project_detail_models.dart';

/// Préfixe des identifiants locaux (document pas encore sur le serveur).
const kLocalDocumentIdPrefix = 'local:';

abstract final class DocumentTmpKind {
  static const prefetch = 'prefetch';
  static const pendingUpload = 'pending_upload';
}

abstract final class DocumentTmpStatus {
  static const pending = 'pending';
  static const uploading = 'uploading';
  static const synced = 'synced';
  static const failed = 'failed';
}

abstract final class DocumentTmpParentType {
  static const project = 'project';
  static const recordingUnit = 'recording_unit';
}

/// Entrée `documents_tmp` exposée à l’UI.
class DocumentTmpEntry {
  const DocumentTmpEntry({
    required this.localId,
    required this.parentType,
    required this.parentId,
    required this.kind,
    required this.status,
    required this.title,
    this.resourceId,
    this.description,
    this.fileName,
    this.mimeType,
    this.fileCode,
    this.url,
    this.natureConceptId,
    this.scaleConceptId,
    this.formatConceptId,
    this.fileSize = 0,
    this.uploadError,
    this.createdAt,
    this.updatedAt,
  });

  final String localId;
  final String? resourceId;
  final String parentType;
  final String parentId;
  final String kind;
  final String status;
  final String title;
  final String? description;
  final String? fileName;
  final String? mimeType;
  final String? fileCode;
  final String? url;
  final int? natureConceptId;
  final int? scaleConceptId;
  final int? formatConceptId;
  final int fileSize;
  final String? uploadError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPendingUpload =>
      kind == DocumentTmpKind.pendingUpload &&
      (status == DocumentTmpStatus.pending ||
          status == DocumentTmpStatus.failed);

  bool get isPrefetch => kind == DocumentTmpKind.prefetch;

  /// Identifiant affiché dans les listes (`local:uuid` ou id serveur).
  String get listId =>
      resourceId?.trim().isNotEmpty == true
          ? resourceId!
          : '$kLocalDocumentIdPrefix$localId';

  static bool isLocalListId(String id) => id.startsWith(kLocalDocumentIdPrefix);

  static String localIdFromListId(String listId) {
    if (!isLocalListId(listId)) return listId;
    return listId.substring(kLocalDocumentIdPrefix.length);
  }

  factory DocumentTmpEntry.fromRow(DocumentTmpRow row) {
    return DocumentTmpEntry(
      localId: row.localId,
      resourceId: row.resourceId,
      parentType: row.parentType,
      parentId: row.parentId,
      kind: row.kind,
      status: row.status,
      title: row.titre,
      description: row.description,
      fileName: row.fileName,
      mimeType: row.mimeType,
      fileCode: row.fileCode,
      url: row.url,
      natureConceptId: row.natureConceptId,
      scaleConceptId: row.scaleConceptId,
      formatConceptId: row.formatConceptId,
      fileSize: row.fileSize,
      uploadError: row.uploadError,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ProjectDocumentItem toListItem() {
    return ProjectDocumentItem(
      id: listId,
      title: title,
      description: description,
      fileName: fileName,
      mimeType: mimeType,
      url: url,
      fileCode: fileCode,
    );
  }
}
