import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utilitaires pour réinitialiser la base SQLite locale (Drift).
abstract final class DatabaseMaintenance {
  static const databaseFileName = 'siamois_offline';

  /// Supprime le fichier SQLite et ses fichiers journaliers (-wal, -shm).
  static Future<void> deleteOfflineDatabaseFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final basePath = p.join(dir.path, '$databaseFileName.sqlite');

    for (final suffix in const ['', '-wal', '-shm']) {
      final file = File('$basePath$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[Siamois] Base locale supprimée ($basePath) — une nouvelle base '
        'sera créée au prochain lancement.',
      );
    }
  }
}
