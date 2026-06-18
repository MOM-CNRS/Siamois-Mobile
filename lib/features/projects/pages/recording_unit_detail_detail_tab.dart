import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_section_card.dart';
import '../../../core/widgets/ui/siamois_messenger.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../../auth/auth_repository.dart';
import '../form/person_directory_store.dart';
import '../form/person_option.dart';
import '../form/project_form_models.dart';
import '../form/project_form_readonly_widgets.dart';
import '../form/recording_unit_option.dart';
import '../project_detail_models.dart';
import '../recording_units/recording_unit_detail_mapper.dart';
import '../recording_units/recording_unit_detail_models.dart';
import '../recording_units/recording_unit_form_cache.dart';
import '../recording_units/recording_unit_hierarchy.dart';
import '../recording_units/recording_unit_hierarchy_link.dart';
import '../recording_units/recording_unit_hierarchy_panel.dart';
import '../recording_units/recording_unit_list_store.dart';
import '../recording_units/recording_unit_project_picker.dart';
import '../vocabulary_models.dart';
import 'recording_unit_detail_page.dart';

/// Onglet Détail d'une unité d'enregistrement.
class RecordingUnitDetailDetailTab extends StatefulWidget {
  const RecordingUnitDetailDetailTab({
    super.key,
    required this.detail,
    required this.auth,
    required this.database,
    this.recordingUnitId,
    this.projectId,
    this.summary,
    this.onDetailChanged,
  });

  final RecordingUnitMobileDetail detail;
  final AuthRepository auth;
  final AppDatabase database;
  final String? recordingUnitId;
  final String? projectId;
  final RecordingUnitItem? summary;
  final void Function(RecordingUnitMobileDetail updated)? onDetailChanged;

  @override
  State<RecordingUnitDetailDetailTab> createState() =>
      _RecordingUnitDetailDetailTabState();
}

class _RecordingUnitDetailDetailTabState
    extends State<RecordingUnitDetailDetailTab> {
  ProjectFormDefinition? _formDefinition;
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  Map<int, PersonOption> _peopleById = const {};
  bool _formLoading = true;
  RecordingUnitHierarchy? _hierarchy;
  RecordingUnitHierarchyFields? _hierarchyFields;
  bool _linking = false;
  bool _offlineMode = false;

  @override
  void initState() {
    super.initState();
    _loadFormContext();
    _loadHierarchy();
    _loadOfflineMode();
  }

  Future<void> _loadOfflineMode() async {
    final offline = !(await widget.auth.canUseProjectsApi());
    if (!mounted) return;
    setState(() => _offlineMode = offline);
  }

  @override
  void didUpdateWidget(covariant RecordingUnitDetailDetailTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail ||
        oldWidget.summary != widget.summary ||
        oldWidget.projectId != widget.projectId) {
      _loadFormContext();
      _loadHierarchy();
    }
  }

  Future<void> _loadHierarchy() async {
    var base = RecordingUnitHierarchy.resolve(widget.detail);

    if (await widget.auth.canUseProjectsApi()) {
      final ruId = widget.recordingUnitId?.trim();
      if (ruId != null && ruId.isNotEmpty) {
        try {
          final fromApi = await widget.auth.fetchRecordingUnitRelations(ruId);
          base = RecordingUnitHierarchy.merge(base, fromApi);
        } catch (_) {
          // Relations API indisponibles — détail formulaire conservé.
        }
      }
    }

    final projectId = widget.projectId?.trim();
    List<RecordingUnitItem> catalog = const [];
    if (projectId != null && projectId.isNotEmpty) {
      try {
        catalog = await RecordingUnitListStore(
          auth: widget.auth,
          db: widget.database,
        ).loadAllFromCacheForProject(projectId);
      } catch (_) {
        // Affichage dégradé à partir du détail API uniquement.
      }
    }

    final hierarchy = RecordingUnitHierarchy.enrichWithCatalog(
      base: base,
      catalog: catalog,
      currentRecordingUnitId: widget.recordingUnitId,
      summary: widget.summary,
    );

    if (!mounted) return;
    setState(() => _hierarchy = hierarchy);
  }

  void _openRelatedUnit(RecordingUnitOption option) {
    final currentId = widget.recordingUnitId?.trim();
    if (currentId != null && option.isSameAs(currentId)) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordingUnitDetailPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: option.key,
          projectId: widget.projectId,
          summary: RecordingUnitHierarchy.summaryItem(option),
        ),
      ),
    );
  }

  Future<void> _loadFormContext() async {
    setState(() => _formLoading = true);

    final cache = RecordingUnitFormCache(
      auth: widget.auth,
      db: widget.database,
    );
    int? typeId;
    final ruId = widget.recordingUnitId?.trim();
    if (ruId != null && ruId.isNotEmpty) {
      typeId = await cache.resolveTypeConceptIdForEdit(
        detail: widget.detail,
        recordingUnitId: ruId,
      );
    } else {
      typeId = widget.detail.typeConceptId;
    }
    final orgId = widget.auth.primaryOrganizationId;
    ProjectFormDefinition? definition;
    Map<String, List<ConceptOption>> vocab = const {};
    Map<int, PersonOption> peopleById = const {};

    if (typeId != null) {
      try {
        final result = await cache.loadFormForRecordingUnitType(
          typeConceptId: typeId,
        );
        definition = result.definition;
        vocab = await cache.loadVocabulariesByFieldCode();
      } catch (_) {
        // Affichage dégradé à partir des seules données API.
      }
    }

    if (orgId != null) {
      try {
        final directory = PersonDirectoryStore(
          auth: widget.auth,
          db: widget.database,
        );
        peopleById = await directory.ensureDirectoryByIdMap(orgId);
      } catch (_) {
        // Pas d’annuaire local : noms issus de l’objet API uniquement.
      }
    }

    if (!mounted) return;
    setState(() {
      _formDefinition = definition;
      _vocabByCode = vocab;
      _peopleById = peopleById;
      _hierarchyFields = RecordingUnitHierarchyFields.resolve(
        definition: definition,
        detail: widget.detail,
      );
      _formLoading = false;
    });
  }

  bool get _hasProjectContext {
    final projectId = widget.projectId?.trim();
    final recordingUnitId = widget.recordingUnitId?.trim();
    return projectId != null &&
        projectId.isNotEmpty &&
        recordingUnitId != null &&
        recordingUnitId.isNotEmpty;
  }

  bool get _showHierarchySection {
    if (_hasProjectContext) return true;
    return _hierarchy != null && !_hierarchy!.isEmpty;
  }

  List<RecordingUnitOption> _excludeOptionsForPicker({required bool asParent}) {
    final hierarchy = _hierarchy;
    if (hierarchy == null) return const [];

    final excluded = <RecordingUnitOption>[
      ...RecordingUnitOption.dedupe(
        asParent ? hierarchy.parents : hierarchy.children,
      ),
      // Évite les cycles évidents parent ↔ enfant.
      ...RecordingUnitOption.dedupe(
        asParent ? hierarchy.children : hierarchy.parents,
      ),
    ];
    return RecordingUnitOption.dedupe(excluded);
  }

  Future<void> _addRelatedUnit({required bool asParent}) async {
    final projectId = widget.projectId?.trim();
    final recordingUnitId = widget.recordingUnitId?.trim();
    final fields = _hierarchyFields;
    if (projectId == null ||
        projectId.isEmpty ||
        recordingUnitId == null ||
        recordingUnitId.isEmpty ||
        fields == null) {
      return;
    }

    final field = asParent ? fields.parentField : fields.childField;
    if (field == null) {
      if (!mounted) return;
      context.showInfoMessage(
        asParent
            ? 'Ce type d’UE ne permet pas d’ajouter une UE parente ici.'
            : 'Ce type d’UE ne permet pas d’ajouter une UE fille ici.',
      );
      return;
    }

    final hierarchy = _hierarchy;

    final picked = await RecordingUnitProjectPicker.show(
      context,
      auth: widget.auth,
      database: widget.database,
      projectId: projectId,
      title: asParent ? 'Ajouter une UE parente' : 'Ajouter une UE fille',
      excludeOptions: _excludeOptionsForPicker(asParent: asParent),
      excludeRecordingUnitId: recordingUnitId,
    );
    if (picked == null || !mounted) return;

    final currentList = asParent
        ? RecordingUnitOption.dedupe(hierarchy?.parents ?? const [])
        : RecordingUnitOption.dedupe(hierarchy?.children ?? const []);
    if (RecordingUnitOption.listContainsUnit(currentList, picked)) {
      if (!mounted) return;
      context.showInfoMessage(
        asParent
            ? 'Cette UE est déjà listée comme parente.'
            : 'Cette UE est déjà listée comme fille.',
      );
      return;
    }

    setState(() => _linking = true);
    try {
      final updated = await RecordingUnitHierarchyLink(
        auth: widget.auth,
        database: widget.database,
      ).addRelatedUnit(
        recordingUnitId: recordingUnitId,
        detail: widget.detail,
        field: field,
        asParent: asParent,
        toAdd: picked,
        projectId: projectId,
      );

      if (!mounted) return;
      final online = await widget.auth.canUseProjectsApi();
      if (!mounted) return;
      context.showInfoMessage(
        online
            ? 'UE liée avec succès.'
            : 'Lien enregistré localement. '
                'Il sera envoyé à la prochaine synchronisation.',
      );
      widget.onDetailChanged?.call(updated);
    } on FormatException catch (e) {
      if (!mounted) return;
      context.showErrorMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _confirmRemoveRelatedUnit({
    required RecordingUnitOption option,
    required bool asParent,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          asParent ? 'Retirer l’UE parente' : 'Retirer l’UE fille',
        ),
        content: Text(
          'Retirer « ${option.label} » des unités liées à cette UE ?\n\n'
          'Le lien sera également retiré sur la fiche de l’UE associée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _removeRelatedUnit(option: option, asParent: asParent);
  }

  Future<void> _removeRelatedUnit({
    required RecordingUnitOption option,
    required bool asParent,
  }) async {
    final projectId = widget.projectId?.trim();
    final recordingUnitId = widget.recordingUnitId?.trim();
    final fields = _hierarchyFields;
    if (projectId == null ||
        projectId.isEmpty ||
        recordingUnitId == null ||
        recordingUnitId.isEmpty ||
        fields == null) {
      return;
    }

    final field = asParent ? fields.parentField : fields.childField;
    if (field == null) return;

    setState(() => _linking = true);
    try {
      final updated = await RecordingUnitHierarchyLink(
        auth: widget.auth,
        database: widget.database,
      ).removeRelatedUnit(
        recordingUnitId: recordingUnitId,
        detail: widget.detail,
        field: field,
        asParent: asParent,
        toRemove: option,
        projectId: projectId,
      );

      if (!mounted) return;
      final online = await widget.auth.canUseProjectsApi();
      if (!mounted) return;
      context.showInfoMessage(
        online
            ? 'Lien retiré avec succès.'
            : 'Lien retiré localement. '
                'La modification sera envoyée à la prochaine synchronisation.',
      );
      widget.onDetailChanged?.call(updated);
    } on FormatException catch (e) {
      if (!mounted) return;
      context.showErrorMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  bool _isMultiline(RecordingUnitDetailRow row) {
    if (row.multiline) return true;
    return row.value.contains('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = RecordingUnitDetailMapper.rowsInDisplayOrder(
      widget.detail,
      formDefinition: _formDefinition,
      vocabByCode: _vocabByCode,
      peopleById: _peopleById,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.md,
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.xxl,
      ),
      children: [
        if (_formLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (rows.isEmpty)
          Text(
            'Aucune donnée à afficher pour cette unité d’enregistrement.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: SiamoisColors.textSecondary,
            ),
          )
        else
          ...rows.map((row) {
            if (row.isSection) {
              return SiamoisFormSectionHeader(title: row.label);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ProjectFormReadOnlyField(
                label: row.label,
                value: row.value,
                multiline: _isMultiline(row),
              ),
            );
          }),
        if (_showHierarchySection) ...[
          const SizedBox(height: 16),
          if (_hierarchy == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            RecordingUnitHierarchyPanel(
              parents: _hierarchy!.parents,
              children: _hierarchy!.children,
              onOpenUnit: _openRelatedUnit,
              linking: _linking,
              offline: _offlineMode,
              onAddParent: _hasProjectContext &&
                      !_formLoading &&
                      !_linking &&
                      (_hierarchyFields?.canLinkParent ?? false)
                  ? () => _addRelatedUnit(asParent: true)
                  : null,
              onAddChild: _hasProjectContext &&
                      !_formLoading &&
                      !_linking &&
                      (_hierarchyFields?.canLinkChild ?? false)
                  ? () => _addRelatedUnit(asParent: false)
                  : null,
              onRemoveParent: _hasProjectContext &&
                      !_formLoading &&
                      !_linking &&
                      (_hierarchyFields?.canLinkParent ?? false)
                  ? (option) => _confirmRemoveRelatedUnit(
                        option: option,
                        asParent: true,
                      )
                  : null,
              onRemoveChild: _hasProjectContext &&
                      !_formLoading &&
                      !_linking &&
                      (_hierarchyFields?.canLinkChild ?? false)
                  ? (option) => _confirmRemoveRelatedUnit(
                        option: option,
                        asParent: false,
                      )
                  : null,
            ),
        ],
      ],
    );
  }
}
