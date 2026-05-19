import 'package:flutter/material.dart';

import '../../features/auth/auth_repository.dart';
import 'app_sync_status_service.dart';
import 'sync_orchestrator.dart';

/// Fournit [AppSyncStatusService], [AuthRepository] et [SyncOrchestrator] à l’arbre.
class AppSyncStatusScope extends InheritedNotifier<AppSyncStatusService> {
  const AppSyncStatusScope({
    super.key,
    required this.auth,
    required this.sync,
    required AppSyncStatusService service,
    required super.child,
  }) : super(notifier: service);

  final AuthRepository auth;
  final SyncOrchestrator sync;

  static AppSyncStatusScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSyncStatusScope>();
    assert(scope != null, 'AppSyncStatusScope introuvable dans l’arbre.');
    return scope!;
  }

  static AppSyncStatusScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSyncStatusScope>();
  }

  static AppSyncStatusService serviceOf(BuildContext context) =>
      of(context).notifier!;
}
