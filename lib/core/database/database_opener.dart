import 'package:flutter/foundation.dart';

import 'app_database.dart';
import 'database_maintenance.dart';

/// Ouvre la base locale ; en cas d’incompatibilité, supprime et recrée une fois.
Future<AppDatabase> openAppDatabase() async {
  AppDatabase? db;
  try {
    db = AppDatabase();
    await _verifyDatabase(db);
    return db;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[Siamois] Ouverture base locale échouée: $e\n$st');
    }
    await db?.close();
    await DatabaseMaintenance.deleteOfflineDatabaseFiles();

    final fresh = AppDatabase();
    try {
      await _verifyDatabase(fresh);
      if (kDebugMode) {
        debugPrint('[Siamois] Base locale recréée avec succès.');
      }
      return fresh;
    } catch (e2, st2) {
      await fresh.close();
      if (kDebugMode) {
        debugPrint('[Siamois] Recréation base locale échouée: $e2\n$st2');
      }
      rethrow;
    }
  }
}

Future<void> _verifyDatabase(AppDatabase db) async {
  await db.customSelect('SELECT 1').get();
  final version = await db.customSelect('PRAGMA user_version').getSingle();
  final raw = version.data.values.first;
  final userVersion = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
  if (userVersion > db.schemaVersion) {
    throw StateError(
      'Version locale ($userVersion) plus récente que l’application '
      '(${db.schemaVersion}).',
    );
  }
}
