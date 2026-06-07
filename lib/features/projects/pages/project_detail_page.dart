import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/routes.dart';
import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../../../core/widgets/ui/siamois_tabbed_scaffold.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_cache.dart';
import '../form/project_form_models.dart';
import '../project_detail_counts.dart';
import '../project_detail_store.dart';
import '../project_models.dart';
import 'edit_project_page.dart';
import 'project_detail_documents_tab.dart';
import 'project_detail_fiche_tab.dart';
import 'project_detail_recording_units_tab.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    super.key,
    required this.auth,
    required this.database,
    required this.projectId,
    this.summary,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String projectId;
  final ProjectSummary? summary;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  ProjectFormDefinition? _definition;
  Map<String, dynamic>? _project;
  ProjectSummary? _summary;
  String? _formError;
  bool _offlineMode = false;
  bool _canUseApi = false;
  bool _loading = true;
  int _recordingUnitCount = 0;
  int _documentCount = 0;

  late final ProjectFormCache _cache;
  late final ProjectDetailStore _detailStore;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cache = ProjectFormCache(auth: widget.auth, db: widget.database);
    _detailStore = ProjectDetailStore(
      auth: widget.auth,
      db: widget.database,
    );
    _summary = widget.summary;
    _tabController.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _formError = null;
    });

    ProjectFormDefinition? definition;
    Map<String, dynamic>? project;
    final offline = await widget.auth.isOfflineEnvironment();
    final canUseApi = await widget.auth.canUseProjectsApi();

    try {
      definition = await _cache.loadProjectForm();
    } on AuthException catch (e) {
      _formError = e.message;
    }

    try {
      final result = await _detailStore.load(
        widget.projectId,
        summary: _summary ?? widget.summary,
      );
      project = result.detail;
    } on AuthException catch (e) {
      _formError ??= e.message;
    }

    var counts = const ProjectDetailCounts(
      recordingUnitCount: 0,
      documentCount: 0,
    );
    if (project != null || _summary != null || widget.summary != null) {
      try {
        counts = await ProjectDetailCounts.resolve(
          auth: widget.auth,
          db: widget.database,
          projectId: widget.projectId,
          project: project,
          summary: _summary ?? widget.summary,
        );
      } catch (_) {
        // Les onglets restent utilisables même si les compteurs échouent.
      }
    }

    if (!mounted) return;
    setState(() {
      _definition = definition;
      _project = project;
      _offlineMode = offline;
      _canUseApi = canUseApi;
      _recordingUnitCount = counts.recordingUnitCount;
      _documentCount = counts.documentCount;
      _loading = false;
    });
  }

  Future<void> _refreshCounts() async {
    try {
      final counts = await ProjectDetailCounts.resolve(
        auth: widget.auth,
        db: widget.database,
        projectId: widget.projectId,
        project: _project,
        summary: _summary ?? widget.summary,
      );
      if (!mounted) return;
      setState(() {
        _recordingUnitCount = counts.recordingUnitCount;
        _documentCount = counts.documentCount;
      });
    } catch (_) {}
  }

  String _tabLabel(String base, int count) => '$base ($count)';

  Future<void> _logout() async {
    await widget.auth.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  Future<void> _openEdit() async {
    final project = _project;
    if (project == null) return;
    if (!_canUseApi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _offlineMode
                ? 'Modification indisponible hors ligne.'
                : 'Reconnectez-vous en ligne pour modifier ce projet.',
          ),
        ),
      );
      return;
    }

    final updated = await Navigator.of(context).push<ProjectSummary>(
      MaterialPageRoute(
        builder: (_) => EditProjectPage(
          auth: widget.auth,
          database: widget.database,
          projectId: widget.projectId,
          initialProject: project,
          summary: _summary ?? widget.summary,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _summary = updated);
      await _load();
    }
  }

  List<Widget> _buildTabChildren() {
    final project = _project;
    final definition = _definition;

    return [
      if (project != null && definition != null)
        ProjectDetailFicheTab(
          project: project,
          definition: definition,
        )
      else
        SiamoisDetailTabPadding(
          child: _FicheUnavailableState(
            offline: _offlineMode,
            formError: _formError,
            hasProject: project != null,
            hasForm: definition != null,
          ),
        ),
      ProjectDetailDocumentsTab(
        auth: widget.auth,
        database: widget.database,
        projectId: widget.projectId,
        onListChanged: _refreshCounts,
      ),
      ProjectDetailRecordingUnitsTab(
        auth: widget.auth,
        database: widget.database,
        projectId: widget.projectId,
        onListChanged: _refreshCounts,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary ?? widget.summary;
    final project = _project;
    final title = summary?.name ??
        (project != null ? project['name']?.toString() : null) ??
        'Détail du projet';
    final subtitle = summary?.displayCode;
    final canEdit = !_loading && project != null && _definition != null;

    final profile = widget.auth.userProfile;

    return SiamoisTabbedScaffold(
      title: title,
      subtitle: subtitle,
      loading: _loading,
      onRetry: _load,
      onLogout: _logout,
      drawerHeaderSubtitle: profile?.organizationLine,
      tabController: _tabController,
      floatingActionButton: canEdit && _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
            )
          : null,
      tabs: [
        const Tab(text: 'Fiche'),
        Tab(text: _tabLabel('Documents', _documentCount)),
        Tab(text: _tabLabel('UE', _recordingUnitCount)),
      ],
      children: _buildTabChildren(),
    );
  }
}

class _FicheUnavailableState extends StatelessWidget {
  const _FicheUnavailableState({
    required this.offline,
    required this.formError,
    required this.hasProject,
    required this.hasForm,
  });

  final bool offline;
  final String? formError;
  final bool hasProject;
  final bool hasForm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String message;
    if (!hasProject && !hasForm) {
      message = formError ??
          'Fiche indisponible. Consultez ce projet en ligne au moins une fois.';
    } else if (!hasForm) {
      message = formError ??
          'Formulaire projet indisponible hors ligne. Synchronisez en ligne.';
    } else {
      message =
          'Détail projet incomplet hors ligne. Les onglets Documents et UE utilisent le cache local.';
    }

    return SingleChildScrollView(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (offline)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SiamoisSpacing.md,
              vertical: SiamoisSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: SiamoisColors.warning.withValues(alpha: 0.12),
              border: Border.all(
                color: SiamoisColors.warning.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: SiamoisColors.warning,
                  size: 20,
                ),
                const SizedBox(width: SiamoisSpacing.sm),
                Expanded(
                  child: Text(
                    'Mode hors ligne',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: SiamoisColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (offline) const SizedBox(height: SiamoisSpacing.lg),
        Icon(
          Icons.info_outline_rounded,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: SiamoisSpacing.md),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: SiamoisColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
      ),
    );
  }
}
