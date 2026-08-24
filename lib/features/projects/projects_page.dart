import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/routes.dart';
import '../../core/sync/app_sync_status_scope.dart';
import '../../core/sync/app_sync_status_service.dart';
import '../../core/sync/sync_orchestrator.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/ui/siamois_empty_state.dart';
import '../../core/widgets/ui/siamois_messenger.dart';
import '../../core/widgets/ui/siamois_error_state.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import '../auth/auth_repository.dart';
import '../auth/auth_models.dart';
import 'project_models.dart';
import 'project_local_id.dart';
import 'widgets/create_project_sheet.dart';
import 'widgets/project_detail_flow.dart';
import 'widgets/project_list_tile.dart';
import 'widgets/projects_summary_bar.dart';
import 'widgets/projects_toolbar.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({
    super.key,
    required this.auth,
    required this.sync,
    required this.database,
  });

  final AuthRepository auth;
  final SyncOrchestrator sync;
  final AppDatabase database;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<ProjectSummary> _projects = const [];
  List<StoredOrganization> _organizations = const [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  bool _loading = true;
  bool _refreshing = false;
  bool _switchingOrg = false;
  String? _errorMessage;
  AppSyncStatusService? _syncStatus;
  bool _wasSyncing = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = AppSyncStatusScope.maybeOf(context)?.notifier;
    if (!identical(service, _syncStatus)) {
      _syncStatus?.removeListener(_onSyncStatusChanged);
      _syncStatus = service;
      _wasSyncing = service?.isSyncing ?? false;
      _syncStatus?.addListener(_onSyncStatusChanged);
    }
  }

  void _onSyncStatusChanged() {
    final service = _syncStatus;
    if (service == null) return;
    final syncing = service.isSyncing;
    if (_wasSyncing && !syncing) {
      unawaited(_reloadOrganizations());
    }
    _wasSyncing = syncing;
  }

  Future<void> _bootstrap() async {
    await _reloadOrganizations();
    final online = await widget.auth.canUseProjectsApi();
    if (!mounted) return;
    await _reloadProjects(
      fromServer: online,
      replaceCache: online,
      showLoading: true,
    );
  }

  Future<void> _reloadOrganizations() async {
    final orgs = await widget.auth.loadAccessibleOrganizationsCached();
    if (!mounted) return;
    setState(() => _organizations = orgs);
  }

  @override
  void dispose() {
    _syncStatus?.removeListener(_onSyncStatusChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onOrganizationSelected(StoredOrganization org) async {
    if (_switchingOrg) return;
    if (org.id == widget.auth.primaryOrganizationId) return;

    setState(() => _switchingOrg = true);
    try {
      await widget.auth.selectPrimaryOrganization(org);
      if (!mounted) return;
      await _reloadProjects(showLoading: true);
      if (!mounted) return;
      context.showInfoMessage('Organisation « ${org.name} » sélectionnée.');
    } on AuthException catch (e) {
      if (mounted) context.showErrorMessage(e.message);
    } finally {
      if (mounted) setState(() => _switchingOrg = false);
    }
  }

  Future<List<ProjectSummary>> _fetchProjects({
    bool fromServer = false,
    bool replaceCache = false,
    ProjectSummary? ensureVisible,
  }) async {
    var all = await widget.sync.loadProjectsForDisplay(
      fetchFromServer: fromServer,
      replaceCache: replaceCache,
    );
    if (ensureVisible != null &&
        !all.any((p) => p.storageId == ensureVisible.storageId)) {
      final orgId = widget.auth.primaryOrganizationId;
      if (orgId != null) {
        await widget.database.upsertProjet(
          project: ensureVisible,
          organisationId: orgId,
        );
      }
      all = [ensureVisible, ...all];
      all.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.displayCode.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _reloadProjects({
    bool fromServer = false,
    bool replaceCache = false,
    ProjectSummary? ensureVisible,
    bool showLoading = false,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }
    try {
      final items = await _fetchProjects(
        fromServer: fromServer,
        replaceCache: replaceCache,
        ensureVisible: ensureVisible,
      );
      if (!mounted) return;
      setState(() {
        _projects = items;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _errorText(e);
      });
    }
  }

  String _errorText(Object error) {
    if (error is AuthException) return error.message;
    if (error is DioException) {
      return 'Erreur réseau : ${error.message}';
    }
    return error.toString();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;

    setState(() => _refreshing = true);
    try {
      if (await widget.auth.canUseProjectsApi()) {
        await _reloadOrganizations();
        await _reloadProjects(fromServer: true, replaceCache: true);
        if (!mounted) return;
        context.showInfoMessage(
          '${_projects.length} projet${_projects.length > 1 ? 's' : ''} '
          'chargé${_projects.length > 1 ? 's' : ''} depuis le serveur.',
        );
      } else {
        await _reloadOrganizations();
        await _reloadProjects(fromServer: false);
        if (!mounted) return;
        context.showInfoMessage('Hors connexion : affichage du cache local.');
      }
      await AppSyncStatusScope.maybeOf(context)?.notifier?.refresh();
    } catch (e) {
      if (mounted) context.showErrorMessage(_errorText(e));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      setState(() => _searchQuery = trimmed);
      _reloadProjects(showLoading: true);
    });
  }

  Future<void> _logout() async {
    await widget.auth.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  Future<void> _openCreateProject() async {
    if (widget.auth.primaryOrganizationId == null) {
      context.showInfoMessage(
        'Organisation introuvable. Reconnectez-vous pour créer un projet.',
      );
      return;
    }

    final created = await openCreateProjectFlow(
      context: context,
      auth: widget.auth,
      database: widget.database,
    );
    if (!mounted || created == null) return;

    final isLocal = ProjectLocalId.isLocalListId(created.storageId);
    if (!isLocal) {
      context.showInfoMessage('Projet « ${created.name} » créé.');
    }

    await _reloadProjects(ensureVisible: created);
    if (!mounted) return;

    if (!isLocal) {
      final deleted = await openProjectDetail(
        context: context,
        auth: widget.auth,
        database: widget.database,
        project: created,
      );
      if (deleted == true && mounted) {
        await _reloadProjects();
      }
    }
  }

  Widget _buildBody({
    required bool canCreate,
  }) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return SiamoisErrorState(
        message: _errorMessage!,
        onRetry: _refresh,
      );
    }

    final projects = _projects;
    final isSearching = _searchQuery.isNotEmpty;

    if (projects.isEmpty) {
      return isSearching
          ? SiamoisEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Aucun résultat',
              subtitle: 'Aucun projet ne correspond à « $_searchQuery ».',
            )
          : FutureBuilder<bool>(
              future: widget.auth.canUseProjectsApi(),
              builder: (context, snapshot) {
                final online = snapshot.data == true;
                return SiamoisEmptyState(
                  icon: Icons.folder_open_outlined,
                  title: online
                      ? 'Aucun projet accessible'
                      : 'Aucun projet en cache',
                  subtitle: online
                      ? 'Aucun projet n’est disponible pour votre compte '
                          'dans cette organisation.'
                      : 'Connectez-vous en ligne au moins une fois pour '
                          'synchroniser vos projets, puis réessayez hors connexion.',
                  actionLabel: canCreate && online ? 'Créer un projet' : null,
                  onAction: canCreate && online ? _openCreateProject : null,
                );
              },
            );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      edgeOffset: 8,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: ProjectsSummaryBar(
              projectCount: projects.length,
              isSearching: isSearching,
              searchQuery: _searchQuery,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SiamoisSpacing.md,
              SiamoisSpacing.sm,
              SiamoisSpacing.md,
              88,
            ),
            sliver: SliverList.separated(
              itemCount: projects.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: SiamoisSpacing.listGap),
              itemBuilder: (context, index) {
                final p = projects[index];
                return ProjectListTile(
                  project: p,
                  onTap: () async {
                    final deleted = await openProjectDetail(
                      context: context,
                      auth: widget.auth,
                      database: widget.database,
                      project: p,
                    );
                    if (deleted == true && mounted) {
                      await _reloadProjects();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.auth.userProfile;
    final canCreate = widget.auth.primaryOrganizationId != null;
    final busy = _refreshing || _switchingOrg;

    return SiamoisScaffold(
      title: 'Projets',
      drawerHeaderTitle: profile?.displayName,
      onLogout: _logout,
      organizations: _organizations,
      selectedOrganizationId: widget.auth.primaryOrganizationId,
      onOrganizationSelected: _onOrganizationSelected,
      organizationsEnabled: !busy,
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: busy ? null : _refresh,
          icon: _refreshing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
      toolbar: ProjectsToolbar(
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
      ),
      offlineBannerDetail:
          'Les projets affichés proviennent du cache local.',
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreateProject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau projet'),
            )
          : null,
      body: _buildBody(canCreate: canCreate),
    );
  }
}
