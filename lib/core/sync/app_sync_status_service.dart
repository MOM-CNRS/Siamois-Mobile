import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/projects/documents/document_tmp_models.dart';
import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import 'entity_sync_state.dart';
import 'sync_action_models.dart';

/// Mode réseau affiché dans la barre de titre.
enum AppConnectionMode {
  connected,
  offline,
}

/// État global : connexion, file d’attente, dernière sync réussie.
class AppSyncStatusService extends ChangeNotifier {
  AppSyncStatusService({
    required AuthRepository auth,
    required AppDatabase db,
    required ConnectivityService connectivity,
    Connectivity? platformConnectivity,
  })  : _auth = auth,
        _db = db,
        _connectivity = connectivity,
        _platformConnectivity = platformConnectivity ?? Connectivity();

  static const _lastSyncPrefsKey = 'last_successful_sync_at';

  final AuthRepository _auth;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final Connectivity _platformConnectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _refreshDebounce;
  Timer? _periodicRefreshTimer;
  Future<void>? _refreshInFlight;

  static const _pollInterval = Duration(seconds: 3);

  late final NavigatorObserver navigatorObserver =
      _AppSyncStatusNavigatorObserver(this);

  AppConnectionMode _mode = AppConnectionMode.offline;
  int _queueCount = 0;
  DateTime? _lastSuccessfulSyncAt;
  bool _isSyncing = false;

  AppConnectionMode get mode => _mode;
  int get queueCount => _queueCount;
  DateTime? get lastSuccessfulSyncAt => _lastSuccessfulSyncAt;
  bool get isSyncing => _isSyncing;
  bool get isConnected => _mode == AppConnectionMode.connected;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncPrefsKey);
    if (ms != null) {
      _lastSuccessfulSyncAt = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    await refresh();
    _connectivitySub = _platformConnectivity.onConnectivityChanged.listen((_) {
      _scheduleRefresh();
    });
    _periodicRefreshTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(refresh());
    });
  }

  /// À appeler quand un écran devient visible (ex. [RouteAware.didPopNext]).
  void onScreenVisible() => _scheduleRefresh();

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(refresh());
    });
  }

  Future<void> refresh() {
    _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  Future<void> _doRefresh() async {
    final online = !await _auth.isOfflineEnvironment();
    final docRows = await _db.pendingUploadDocumentsTmp();
    final outboxCount = await _db.countPendingSyncActions();

    final newMode =
        online ? AppConnectionMode.connected : AppConnectionMode.offline;
    final newQueueCount = docRows.length + outboxCount;
    final changed = newMode != _mode || newQueueCount != _queueCount;
    _mode = newMode;
    _queueCount = newQueueCount;
    if (changed) notifyListeners();
  }

  Future<void> recordSuccessfulSync() async {
    _lastSuccessfulSyncAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastSyncPrefsKey,
      _lastSuccessfulSyncAt!.millisecondsSinceEpoch,
    );
    await refresh();
  }

  Future<void> setSyncing(bool value) async {
    if (_isSyncing == value) return;
    _isSyncing = value;
    notifyListeners();
  }

  Future<EntitySyncState> documentSyncState(String listId) async {
    DocumentTmpRow? row;
    if (DocumentTmpEntry.isLocalListId(listId)) {
      row = await _db.documentTmpByLocalId(
        DocumentTmpEntry.localIdFromListId(listId),
      );
    } else {
      row = await _db.documentTmpByResourceId(listId);
    }
    if (row == null || row.kind != DocumentTmpKind.pendingUpload) {
      return EntitySyncState.synced;
    }
    return _stateFromTmpStatus(row.status);
  }

  Future<bool> recordingUnitHasUnsyncedContent(String recordingUnitId) async {
    final docRows = await _db.documentTmpForRecordingUnit(recordingUnitId);
    final hasDocs = docRows.any(
      (r) =>
          r.kind == DocumentTmpKind.pendingUpload &&
          (r.status == DocumentTmpStatus.pending ||
              r.status == DocumentTmpStatus.failed),
    );
    if (hasDocs) return true;

    final actions = await _db.pendingSyncActions();
    return actions.any(
      (a) =>
          a.entityType == SyncEntityType.recordingUnit &&
          (a.serverEntityId == recordingUnitId ||
              a.localEntityId == recordingUnitId) &&
          (a.status == SyncActionStatus.pending ||
              a.status == SyncActionStatus.failed ||
              a.status == SyncActionStatus.conflict),
    );
  }

  Future<bool> mobilierHasUnsyncedContent(String mobilierId) async {
    final actions = await _db.pendingSyncActions();
    return actions.any(
      (a) =>
          a.entityType == SyncEntityType.mobilier &&
          (a.serverEntityId == mobilierId || a.localEntityId == mobilierId) &&
          (a.status == SyncActionStatus.pending ||
              a.status == SyncActionStatus.failed ||
              a.status == SyncActionStatus.conflict),
    );
  }

  static EntitySyncState _stateFromTmpStatus(String status) {
    if (status == DocumentTmpStatus.failed) return EntitySyncState.error;
    if (status == DocumentTmpStatus.pending ||
        status == DocumentTmpStatus.uploading) {
      return EntitySyncState.pending;
    }
    return EntitySyncState.synced;
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _refreshDebounce?.cancel();
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }
}

/// Rafraîchit le statut connexion à chaque navigation.
class _AppSyncStatusNavigatorObserver extends NavigatorObserver {
  _AppSyncStatusNavigatorObserver(this._service);

  final AppSyncStatusService _service;

  void _onRouteChange() => _service.onScreenVisible();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onRouteChange();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onRouteChange();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _onRouteChange();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onRouteChange();
  }
}
