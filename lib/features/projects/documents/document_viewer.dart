import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import 'document_open_helper.dart';
import 'document_remote_store.dart';
import 'document_tmp_models.dart';
import 'document_tmp_store.dart';

/// Ouvre un document (cache `documents_tmp`, téléchargement API, ou fichier local).
class DocumentViewer {
  DocumentViewer({
    required this.auth,
    required this.store,
    required this.database,
  });

  final AuthRepository auth;
  final DocumentRemoteStore store;
  final AppDatabase database;

  Future<void> open(BuildContext context, ProjectDocumentItem doc) async {
    final tmpStore = DocumentTmpStore(db: database, auth: auth);

    try {
      final cached = await tmpStore.materializeToTempFile(doc.id);
      if (cached != null) {
        await _openFile(context, doc, cached.path);
        return;
      }

      if (DocumentTmpEntry.isLocalListId(doc.id)) {
        if (!context.mounted) return;
        _showSnack(context, 'Fichier local introuvable.');
        return;
      }

      if (!store.canOpenRemote) {
        _showSnack(context, 'Serveur inconnu. Reconnectez-vous.');
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléchargement du document…'),
          duration: Duration(seconds: 2),
        ),
      );

      final file = await auth.downloadDocumentToTempFile(
        resourceId: doc.id,
        suggestedFileName: doc.fileName ?? 'document_${doc.id}',
        mimeType: doc.mimeType,
      );

      await _openFile(context, doc, file.path);
    } on AuthException catch (e) {
      if (!context.mounted) return;
      _showSnack(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, 'Erreur : $e');
    }
  }

  Future<void> _openFile(
    BuildContext context,
    ProjectDocumentItem doc,
    String path,
  ) async {
    final openError = await DocumentOpenHelper.openLocalFile(
      path: path,
      mimeType: doc.mimeType,
    );

    if (openError.isEmpty) return;

    final absolute = store.absoluteUrlFor(doc.url);
    if (absolute != null && await canLaunchUrl(Uri.parse(absolute))) {
      await launchUrl(
        Uri.parse(absolute),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    if (!context.mounted) return;
    _showSnack(context, openError);
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
