import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/routes.dart';
import '../../core/sync/app_sync_status_scope.dart';
import '../../core/sync/sync_orchestrator.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/ui/siamois_empty_state.dart';
import '../../core/widgets/ui/siamois_error_state.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import '../auth/auth_repository.dart';
import 'project_models.dart';
import 'widgets/create_project_sheet.dart';
import 'widgets/project_detail_flow.dart';
import 'widgets/project_list_tile.dart';
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
  Future<List<ProjectSummary>>? _future;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ProjectSummary>> _load() async {
    final all = await widget.sync.loadProjectsForDisplay();
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.displayCode.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _refresh() async {
    if (await widget.auth.isServerReachable()) {
      await widget.sync.refreshProjectsOnly();
    }
    await AppSyncStatusScope.maybeOf(context)?.notifier?.refresh();
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      setState(() {
        _searchQuery = trimmed;
        _future = _load();
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Organisation introuvable. Reconnectez-vous pour créer un projet.',
          ),
        ),
      );
      return;
    }

    final created = await openCreateProjectFlow(
      context: context,
      auth: widget.auth,
      database: widget.database,
    );
    if (!mounted || created == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Projet « ${created.name} » créé.'),
      ),
    );
    await _refresh();
  }

  int _totalRecordingUnits(List<ProjectSummary> projects) {
    return projects.fold<int>(
      0,
      (sum, p) => sum + (p.recordingUnitCount ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.auth.userProfile;
    final subtitle = profile?.organizationLine;
    final canCreate = widget.auth.primaryOrganizationId != null;

    return SiamoisScaffold(
      title: 'Projets',
      subtitle: subtitle,
      drawerHeaderSubtitle: profile?.organizationLine,
      onLogout: _logout,
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      toolbar: ProjectsToolbar(
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreateProject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau projet'),
            )
          : null,
      body: FutureBuilder<List<ProjectSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is AuthException
                ? (snapshot.error as AuthException).message
                : snapshot.error is DioException
                    ? 'Erreur réseau : ${(snapshot.error as DioException).message}'
                    : snapshot.error.toString();
            return SiamoisErrorState(
              message: message,
              onRetry: () => setState(() => _future = _load()),
            );
          }

          final projects = snapshot.data ?? [];
          final isSearching = _searchQuery.isNotEmpty;

          if (projects.isEmpty) {
            return isSearching
                ? SiamoisEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Aucun résultat',
                    subtitle:
                        'Aucun projet ne correspond à « $_searchQuery ».',
                  )
                : SiamoisEmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'Aucun projet accessible',
                    subtitle:
                        'Aucun projet n’est disponible pour votre compte '
                        'dans cette organisation.',
                    actionLabel: canCreate ? 'Créer un projet' : null,
                    onAction: canCreate ? _openCreateProject : null,
                  );
          }

          final totalUe = _totalRecordingUnits(projects);

          return RefreshIndicator(
            onRefresh: _refresh,
            edgeOffset: 8,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SiamoisSpacing.pageHorizontal,
                      SiamoisSpacing.xs,
                      SiamoisSpacing.pageHorizontal,
                      SiamoisSpacing.xxs,
                    ),
                    child: Text(
                      _summaryLine(
                        count: projects.length,
                        totalUe: totalUe,
                        isSearching: isSearching,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: SiamoisColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    SiamoisSpacing.md,
                    SiamoisSpacing.xs,
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
                        onTap: () => openProjectDetail(
                          context: context,
                          auth: widget.auth,
                          database: widget.database,
                          project: p,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _summaryLine({
    required int count,
    required int totalUe,
    required bool isSearching,
  }) {
    final base = isSearching
        ? '$count résultat${count > 1 ? 's' : ''} pour « $_searchQuery »'
        : '$count projet${count > 1 ? 's' : ''}';
    if (totalUe > 0) {
      return '$base · $totalUe UE au total';
    }
    return base;
  }
}

