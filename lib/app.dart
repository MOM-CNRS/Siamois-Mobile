import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/database/app_database.dart';
import 'core/routes.dart';
import 'core/sync/app_sync_status_scope.dart';
import 'core/sync/app_sync_status_service.dart';
import 'core/sync/sync_orchestrator.dart';
import 'core/sync/sync_progress.dart';
import 'core/sync/sync_route_args.dart';
import 'core/theme/siamois_theme.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_page.dart';
import 'features/places/places_management_page.dart';
import 'features/projects/projects_page.dart';
import 'features/settings/my_thesaurus_page.dart';
import 'features/settings/server_settings_page.dart';
import 'features/settings/settings_page.dart';
import 'features/splash/splash_page.dart';
import 'features/sync/sync_page.dart';
import 'features/sync/sync_queue_page.dart';

class SiamoisApp extends StatelessWidget {
  const SiamoisApp({
    super.key,
    required this.auth,
    required this.sync,
    required this.database,
    required this.syncStatus,
  });

  final AuthRepository auth;
  final SyncOrchestrator sync;
  final AppDatabase database;
  final AppSyncStatusService syncStatus;

  @override
  Widget build(BuildContext context) {
    return AppSyncStatusScope(
      auth: auth,
      sync: sync,
      service: syncStatus,
      child: MaterialApp(
        title: 'Siamois',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [syncStatus.navigatorObserver],
        theme: SiamoisTheme.light(),
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [
          Locale('fr', 'FR'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashPage(),
          AppRoutes.login: (_) => LoginPage(auth: auth, sync: sync),
          AppRoutes.serverSettings: (_) => ServerSettingsPage(auth: auth),
          AppRoutes.projects: (_) => ProjectsPage(
                auth: auth,
                sync: sync,
                database: database,
              ),
          AppRoutes.settings: (_) => SettingsPage(database: database),
          AppRoutes.myThesaurus: (_) => MyThesaurusPage(
                auth: auth,
                database: database,
              ),
          AppRoutes.placesManagement: (_) => PlacesManagementPage(
                auth: auth,
                database: database,
              ),
          AppRoutes.syncQueue: (_) => SyncQueuePage(
                database: database,
                auth: auth,
              ),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.sync) {
            final args = settings.arguments;
            var online = false;
            var manual = false;
            if (args is SyncRouteArgs) {
              online = args.cameFromOnlineLogin;
              manual = args.manual;
            } else if (args is bool) {
              online = args;
            }
            return MaterialPageRoute<SyncRunResult?>(
              builder: (_) => SyncPage(
                sync: sync,
                syncStatus: syncStatus,
                cameFromOnlineLogin: online,
                manual: manual,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
