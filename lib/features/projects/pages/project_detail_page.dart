import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/routes.dart';
import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../../../core/widgets/ui/siamois_tabbed_scaffold.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_cache.dart';
import '../form/project_form_models.dart';
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
  bool _loading = true;

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
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _formError = null;
    });

    ProjectFormDefinition? definition;
    Map<String, dynamic>? project;
    var offline = false;

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
      offline = result.fromCache;
    } on AuthException catch (e) {
      _formError ??= e.message;
    }

    if (!mounted) return;
    setState(() {
      _definition = definition;
      _project = project;
      _offlineMode = offline || _formError != null;
      _loading = false;
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

  Future<void> _openEdit() async {
    final project = _project;
    if (project == null) return;
    if (_offlineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Modification indisponible hors ligne.',
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
      ),
      ProjectDetailRecordingUnitsTab(
        auth: widget.auth,
        database: widget.database,
        projectId: widget.projectId,
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
    final canEdit = !_loading &&
        !_offlineMode &&
        project != null &&
        _definition != null;

    final profile = widget.auth.userProfile;

    return SiamoisTabbedScaffold(
      title: title,
      subtitle: subtitle,
      loading: _loading,
      onRetry: _load,
      onLogout: _logout,
      drawerHeaderSubtitle: profile?.organizationLine,
      tabController: _tabController,
      actions: [
        if (canEdit)
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier le projet',
          ),
      ],
      tabs: const [
        Tab(text: 'Fiche'),
        Tab(text: 'Documents'),
        Tab(text: 'UE'),
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
