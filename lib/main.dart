import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/database/database_opener.dart';
import 'core/network/connectivity_service.dart';
import 'core/sync/app_sync_status_service.dart';
import 'core/sync/sync_orchestrator.dart';
import 'features/auth/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  final db = await openAppDatabase();
  final connectivity = ConnectivityService();
  final auth = AuthRepository(
    database: db,
    connectivity: connectivity,
  );
  await auth.init();

  final sync = SyncOrchestrator(
    auth: auth,
    db: db,
    connectivity: connectivity,
  );

  final syncStatus = AppSyncStatusService(
    auth: auth,
    db: db,
    connectivity: connectivity,
  );
  await syncStatus.init();

  runApp(
    SiamoisApp(
      auth: auth,
      sync: sync,
      database: db,
      syncStatus: syncStatus,
    ),
  );
}
