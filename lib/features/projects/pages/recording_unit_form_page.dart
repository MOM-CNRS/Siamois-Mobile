import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/app_sync_status_scope.dart';
import '../../../core/sync/entity_snapshot_store.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_conflict_payload.dart';
import '../../../core/sync/sync_conflict_exception.dart';
import '../../../core/sync/sync_conflict_field_diff.dart';
import '../../../core/widgets/sync/sync_conflict_resolution_dialog.dart';
import '../../../core/widgets/ui/siamois_messenger.dart';
import '../../../core/widgets/ui/siamois_form_action_fab.dart';
import '../../auth/auth_repository.dart';
import '../form/form_measurement_form.dart';
import '../form/project_form_field_widgets.dart';
import '../form/project_form_layout.dart';
import '../form/project_form_measurement_input.dart';
import '../form/project_form_models.dart';
import '../form/person_directory_store.dart';
import '../form/person_option.dart';
import '../form/project_form_person_widgets.dart';
import '../form/project_form_recording_unit_multi_selector.dart';
import '../form/recording_unit_option.dart';
import '../form/project_form_panel_section.dart';
import '../form/project_form_readonly_widgets.dart';
import '../form/spatial_unit_field_actions.dart';
import '../project_detail_models.dart';
import '../recording_units/recording_unit_detail_models.dart';
import '../recording_units/recording_unit_detail_store.dart';
import '../recording_units/recording_unit_field_answers_merge.dart';
import '../recording_units/recording_unit_form_cache.dart';
import '../recording_units/recording_unit_form_models.dart';
import '../recording_units/recording_unit_form_prefill.dart';
import '../recording_units/recording_unit_hierarchy.dart';
import '../recording_units/recording_unit_list_store.dart';
import '../recording_units/recording_unit_store.dart';
import '../vocabulary_models.dart';

/// Modification d’une unité d’enregistrement (formulaire selon le type).
class RecordingUnitFormPage extends StatefulWidget {
  const RecordingUnitFormPage({
    super.key,
    required this.auth,
    required this.database,
    required this.recordingUnitId,
    required this.initialDetail,
    this.projectId,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String recordingUnitId;
  final RecordingUnitMobileDetail initialDetail;
  final String? projectId;

  @override
  State<RecordingUnitFormPage> createState() => _RecordingUnitFormPageState();
}

class _RecordingUnitFormPageState extends State<RecordingUnitFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _formState = ProjectFormState();
  final _textControllers = <String, TextEditingController>{};
  final _measurementCtrls = FormMeasurementControllers();
  final _recordingUnitMultiKeys =
      <String, GlobalKey<ProjectFormRecordingUnitMultiSelectorState>>{};

  ProjectFormDefinition? _definition;
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  Map<int, PersonOption> _peopleById = const {};
  String? _typeLabel;
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;

  late final RecordingUnitFormCache _formCache;
  late final RecordingUnitDetailStore _detailStore;
  late final RecordingUnitListStore _listStore;
  late final PersonDirectoryStore _personDirectory;
  late final SpatialUnitFieldActions _spatialActions;

  @override
  void initState() {
    super.initState();
    _formCache = RecordingUnitFormCache(
      auth: widget.auth,
      db: widget.database,
    );
    _detailStore = RecordingUnitDetailStore(
      auth: widget.auth,
      db: widget.database,
    );
    _listStore = RecordingUnitListStore(
      auth: widget.auth,
      db: widget.database,
    );
    _personDirectory = PersonDirectoryStore(
      auth: widget.auth,
      db: widget.database,
    );
    _spatialActions = SpatialUnitFieldActions(
      auth: widget.auth,
      database: widget.database,
    );
    _load();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _measurementCtrls.dispose();
    super.dispose();
  }

  GlobalKey<ProjectFormRecordingUnitMultiSelectorState> _recordingUnitMultiKey(
    String fieldKey,
  ) {
    return _recordingUnitMultiKeys.putIfAbsent(
      fieldKey,
      GlobalKey<ProjectFormRecordingUnitMultiSelectorState>.new,
    );
  }

  void _refreshRecordingUnitMultiOptions(List<RecordingUnitOption> options) {
    for (final key in _recordingUnitMultiKeys.values) {
      key.currentState?.updateOptions(options, fromCache: false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final typeId = await _formCache.resolveTypeConceptIdForEdit(
      detail: widget.initialDetail,
      recordingUnitId: widget.recordingUnitId,
    );
    if (typeId == null) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Type d’UE introuvable pour charger le formulaire.';
        _loading = false;
      });
      return;
    }

    try {
      final result = await _formCache.loadFormForRecordingUnitType(
        typeConceptId: typeId,
      );
      final vocab = await _formCache.loadVocabulariesByFieldCode();
      if (!mounted) return;

      final orgId = widget.auth.primaryOrganizationId;
      Map<int, PersonOption> peopleById = const {};
      if (orgId != null) {
        peopleById = await _personDirectory.ensureDirectoryByIdMap(orgId);
      }

      RecordingUnitFormPrefill.applyFromDetail(
        _formState,
        result.definition,
        widget.initialDetail,
        directoryById: peopleById,
        vocabByCode: vocab,
      );

      for (final field in result.definition.fields) {
        if (field.isTextInput) {
          _textControllers[field.key] = TextEditingController(
            text: _formState.textValues[field.key] ?? '',
          );
        }
        if (field.isMeasurementInput) {
          _measurementCtrls.ensure(
            field,
            initial: _formState.measurement(field.key),
          );
        }
      }

      setState(() {
        _definition = result.definition;
        _vocabByCode = vocab;
        _peopleById = peopleById;
        _typeLabel = widget.initialDetail.typeLabel;
        _loading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  TextEditingController _textController(ProjectFormField field) {
    return _textControllers.putIfAbsent(
      field.key,
      () => TextEditingController(text: _formState.textValues[field.key] ?? ''),
    );
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;

    final definition = _definition;
    if (definition == null) return;

    for (final field in definition.fields) {
      if (field.isTextInput) {
        _formState.setText(field.key, _textController(field).text);
      }
    }
    _measurementCtrls.syncTo(_formState, definition);

    final fieldAnswers = _formState.buildRecordingUnitFieldAnswers(definition);

    setState(() => _submitting = true);
    try {
      final online = await widget.auth.canUseProjectsApi();

      if (!online) {
        final localDetail = await _persistOfflineEdits(fieldAnswers: fieldAnswers);
        if (!mounted) return;
        context.showInfoMessage(
          'Modifications enregistrées localement. '
          'Elles seront envoyées à la prochaine synchronisation.',
        );
        Navigator.of(context).pop(localDetail);
        return;
      }

      final baseRevision = await EntitySnapshotStore(widget.database)
          .recordingUnitBaseRevision(widget.recordingUnitId);

      try {
        final detail = await widget.auth.patchRecordingUnit(
          widget.recordingUnitId,
          fieldAnswers: fieldAnswers,
          expectedRevision: baseRevision,
        );

        final merged = RecordingUnitFieldAnswersMerge.apply(
          detail: detail,
          definition: definition,
          fieldAnswers: fieldAnswers,
        );

        await _detailStore.saveAfterMutation(
          merged,
          projectId: widget.projectId,
        );

        await EntitySnapshotStore(widget.database).saveRecordingUnitSnapshot(
          entityId: widget.recordingUnitId,
          serverRevision: readRecordingUnitSyncRevision(merged.recordingUnit),
          detailApiData: merged.toApiData(),
        );

        final item = RecordingUnitItem.fromJson(merged.recordingUnit);
        if (item.id.isNotEmpty && widget.projectId != null) {
          await _listStore.upsertLocal(
            item: item,
            projectId: widget.projectId!,
            typeConceptId: merged.typeConceptId,
          );
        }

        if (!mounted) return;
        Navigator.of(context).pop(merged);
      } on AuthException {
        final localDetail = await _persistOfflineEdits(fieldAnswers: fieldAnswers);
        if (!mounted) return;
        context.showInfoMessage(
          'Serveur injoignable — modifications enregistrées localement. '
          'Elles seront synchronisées à la reconnexion.',
        );
        Navigator.of(context).pop(localDetail);
      }
    } on SyncConflictException catch (e) {
      if (!mounted) return;
      await _handleSyncConflict(e, fieldAnswers);
    } on AuthException catch (e) {
      if (mounted) {
        context.showErrorMessage(e.message);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorMessage('Erreur : $e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  RecordingUnitMobileDetail _applyFieldAnswersLocally({
    required Map<String, dynamic> fieldAnswers,
  }) {
    final definition = _definition;
    return RecordingUnitFieldAnswersMerge.apply(
      detail: widget.initialDetail,
      definition: definition,
      fieldAnswers: fieldAnswers,
    );
  }

  Future<RecordingUnitMobileDetail> _persistOfflineEdits({
    required Map<String, dynamic> fieldAnswers,
  }) async {
    final baseRevision = await EntitySnapshotStore(widget.database)
        .recordingUnitBaseRevision(widget.recordingUnitId);

    await OutboxStore(widget.database).enqueueRecordingUnitUpdate(
      recordingUnitId: widget.recordingUnitId,
      fieldAnswers: fieldAnswers,
      baseServerRevision: baseRevision,
      projectId: widget.projectId,
    );

    final localDetail = _applyFieldAnswersLocally(fieldAnswers: fieldAnswers);
    await _detailStore.saveAfterMutation(
      localDetail,
      projectId: widget.projectId,
    );

    final item = RecordingUnitItem.fromJson(localDetail.recordingUnit);
    if (item.id.isNotEmpty && widget.projectId != null) {
      await _listStore.upsertLocal(
        item: item,
        projectId: widget.projectId!,
        typeConceptId: localDetail.typeConceptId,
      );
    }

    if (mounted) {
      await AppSyncStatusScope.maybeOf(context)?.notifier?.refresh();
    }
    return localDetail;
  }

  Future<void> _handleSyncConflict(
    SyncConflictException conflict,
    Map<String, dynamic> fieldAnswers,
  ) async {
    final fieldLabels = _definition != null
        ? SyncConflictFieldDiffBuilder.labelsFromDefinition(_definition!)
        : const <int, String>{};
    final fieldAnswerTypes = _definition != null
        ? SyncConflictFieldDiffBuilder.answerTypesFromDefinition(_definition!)
        : const <int, String>{};
    final baseSnapshot = await EntitySnapshotStore(widget.database)
        .recordingUnitBaseSnapshot(widget.recordingUnitId);
    final baseDetail = baseSnapshot != null
        ? RecordingUnitMobileDetail.fromApiData(baseSnapshot)
        : widget.initialDetail;
    final fieldDiffs = SyncConflictFieldDiffBuilder.buildFromFieldAnswers(
      fieldAnswers: fieldAnswers,
      fieldLabels: fieldLabels,
      fieldAnswerTypes: fieldAnswerTypes,
      serverDetail: conflict.serverDetail,
      baseDetail: baseDetail,
    );

    if (!mounted) return;

    final choice = await showSyncConflictResolutionDialog(
      context: context,
      entityLabel: widget.initialDetail.displayCode,
      payload: SyncConflictPayload.fromException(conflict),
      fieldDiffs: fieldDiffs,
    );
    if (!mounted || choice == SyncConflictResolution.cancel) return;

    if (choice == SyncConflictResolution.useServer) {
      await _applyServerConflictVersion(conflict);
      return;
    }

    if (choice == SyncConflictResolution.retryLocal) {
      if (conflict.currentRevision <= 0) {
        context.showInfoMessage(
          'Révision serveur indisponible pour réessayer.',
        );
        return;
      }

      final serverDetail = conflict.serverDetail;
      if (serverDetail != null) {
        await EntitySnapshotStore(widget.database).saveRecordingUnitSnapshot(
          entityId: widget.recordingUnitId,
          serverRevision: conflict.currentRevision,
          detailApiData: serverDetail.toApiData(),
        );
      }

      final detail = await widget.auth.patchRecordingUnit(
        widget.recordingUnitId,
        fieldAnswers: fieldAnswers,
        expectedRevision: conflict.currentRevision,
      );

      final merged = RecordingUnitFieldAnswersMerge.apply(
        detail: detail,
        definition: _definition,
        fieldAnswers: fieldAnswers,
      );

      await _detailStore.saveAfterMutation(
        merged,
        projectId: widget.projectId,
      );
      await EntitySnapshotStore(widget.database).saveRecordingUnitSnapshot(
        entityId: widget.recordingUnitId,
        serverRevision: readRecordingUnitSyncRevision(merged.recordingUnit),
        detailApiData: merged.toApiData(),
      );

      final item = RecordingUnitItem.fromJson(merged.recordingUnit);
      if (item.id.isNotEmpty && widget.projectId != null) {
        await _listStore.upsertLocal(
          item: item,
          projectId: widget.projectId!,
          typeConceptId: merged.typeConceptId,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(merged);
    }
  }

  Future<void> _applyServerConflictVersion(SyncConflictException conflict) async {
    final server = conflict.serverDetail;
    if (server == null) {
      context.showErrorMessage('État serveur indisponible.');
      return;
    }

    await _detailStore.saveAfterMutation(
      server,
      projectId: widget.projectId,
    );
    await EntitySnapshotStore(widget.database).saveRecordingUnitSnapshot(
      entityId: widget.recordingUnitId,
      serverRevision: readRecordingUnitSyncRevision(server.recordingUnit),
      detailApiData: server.toApiData(),
    );

    if (!mounted) return;
    Navigator.of(context).pop(server);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l’unité d’enregistrement ?'),
        content: Text(
          '« ${widget.initialDetail.displayCode} » sera définitivement supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await RecordingUnitStore(
        auth: widget.auth,
        db: widget.database,
      ).delete(recordingUnitId: widget.recordingUnitId);
      if (!mounted) return;
      await AppSyncStatusScope.maybeOf(context)?.notifier?.refresh();
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } on AuthException catch (e) {
      if (mounted) {
        context.showErrorMessage(e.message);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorMessage('Erreur : $e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<RecordingUnitOptionsLoad> _loadRecordingUnitOptions() async {
    final projectId = widget.projectId;
    if (projectId == null || projectId.trim().isEmpty) {
      return const RecordingUnitOptionsLoad(options: [], fromCache: true);
    }
    final result = await _listStore.loadAllForPicker(
      projectId,
      excludeRecordingUnitId: widget.recordingUnitId,
      onRefreshedFromNetwork: (fresh) {
        _refreshRecordingUnitMultiOptions(
          fresh.map(RecordingUnitOption.fromItem).toList(),
        );
      },
    );
    return RecordingUnitOptionsLoad(
      options: result.items.map(RecordingUnitOption.fromItem).toList(),
      fromCache: result.fromCache,
    );
  }

  Future<List<SpatialUnitOption>> _searchSpatial(String query) =>
      _spatialActions.search(query);

  Future<SpatialUnitOption?> _createSpatial() =>
      _spatialActions.createNew(context);

  bool _isSlotRequired(ProjectFormFieldSlot slot) {
    if (RecordingUnitHierarchy.isHierarchyRelationField(
      label: slot.field.label,
      valueBinding: slot.field.valueBinding,
      fieldCode: slot.field.fieldCode,
      answerType: slot.field.answerType,
      hint: slot.field.hint,
    )) {
      return false;
    }
    return slot.isRequired;
  }

  Widget _buildField(ProjectFormFieldSlot slot) {
    final field = slot.field;
    if (field.isRecordingUnitTypeField) {
      return ProjectFormReadOnlyField(
        label: field.label,
        value: _typeLabel,
        hint: field.hint,
      );
    }
    final orgId = widget.auth.primaryOrganizationId;
    switch (field.normalizedType) {
      case ProjectAnswerType.text:
      case ProjectAnswerType.integer:
        return ProjectFormTextInput(
          field: field,
          controller: _textController(field),
          isRequired: _isSlotRequired(slot),
          validator: _isSlotRequired(slot)
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return '« ${field.label} » est obligatoire';
                  }
                  return null;
                }
              : null,
        );
      case ProjectAnswerType.measurement:
        _measurementCtrls.ensure(
          field,
          initial: _formState.measurement(field.key),
        );
        return ProjectFormMeasurementInput(
          field: field,
          numericController: _measurementCtrls.numeric[field.key]!,
          commentController: _measurementCtrls.comment[field.key]!,
          isRequired: _isSlotRequired(slot),
        );
      case ProjectAnswerType.selectMultipleRecordingUnit:
        return ProjectFormRecordingUnitMultiSelector(
          key: _recordingUnitMultiKey(field.key),
          field: field,
          loadOptions: _loadRecordingUnitOptions,
          selected: _formState.recordingUnits(field.key),
          onChanged: (list) => setState(
            () => _formState.recordingUnitMultiValues[field.key] = list,
          ),
          isRequired: _isSlotRequired(slot),
        );
      case ProjectAnswerType.dateTime:
        return ProjectFormDateInput(
          field: field,
          isRequired: _isSlotRequired(slot),
          value: _formState.dateValues[field.key],
          onChanged: (d) => setState(() => _formState.dateValues[field.key] = d),
        );
      case ProjectAnswerType.selectOneFromFieldCode:
        final options = _formState.conceptsForField(field, _vocabByCode);
        return ProjectFormConceptDropdown(
          field: field,
          options: options,
          isRequired: _isSlotRequired(slot),
          value: _formState.conceptValues[field.key],
          onChanged: (v) =>
              setState(() => _formState.conceptValues[field.key] = v),
        );
      case ProjectAnswerType.selectMultiple:
        final multiOptions = _formState.conceptsForField(field, _vocabByCode);
        return ProjectFormConceptMultiSelector(
          field: field,
          options: multiOptions,
          isRequired: _isSlotRequired(slot),
          selected: _formState.conceptMulti(field.key),
          onChanged: (ids) => setState(
            () => _formState.conceptMultiValues[field.key] = ids,
          ),
        );
      case ProjectAnswerType.selectOneActionCode:
      case ProjectAnswerType.selectOneSpatialUnit:
        if (orgId == null) return const SizedBox.shrink();
        return ProjectFormSpatialAutocomplete(
          field: field,
          organizationId: orgId,
          isRequired: _isSlotRequired(slot),
          search: _searchSpatial,
          value: _formState.spatialSingleValues[field.key],
          onChanged: (v) => setState(
            () => _formState.spatialSingleValues[field.key] = v,
          ),
          onCreateNew: _createSpatial,
        );
      case ProjectAnswerType.selectMultipleSpatialUnitTree:
        return ProjectFormSpatialMultiSelector(
          field: field,
          isRequired: _isSlotRequired(slot),
          search: _searchSpatial,
          selected: _formState.spatialMultiValues[field.key] ?? const [],
          onChanged: (list) => setState(
            () => _formState.spatialMultiValues[field.key] = list,
          ),
          onCreateNew: _createSpatial,
        );
      case ProjectAnswerType.selectOnePerson:
        if (orgId == null) return const SizedBox.shrink();
        return ProjectFormPersonAutocomplete(
          field: field,
          directory: _personDirectory,
          organizationId: orgId,
          directoryById: _peopleById,
          value: _formState.person(field.key),
          onChanged: (p) => setState(
            () => _formState.personSingleValues[field.key] = p,
          ),
          isRequired: _isSlotRequired(slot),
        );
      case ProjectAnswerType.selectMultiplePerson:
        if (orgId == null) return const SizedBox.shrink();
        return ProjectFormPersonMultiSelector(
          field: field,
          directory: _personDirectory,
          organizationId: orgId,
          directoryById: _peopleById,
          selected: _formState.persons(field.key),
          onChanged: (list) => setState(
            () => _formState.personMultiValues[field.key] = list,
          ),
          isRequired: _isSlotRequired(slot),
        );
      default:
        return ListTile(
          title: Text(field.label),
          subtitle: Text('Type « ${field.answerType} » non pris en charge'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.initialDetail.displayCode;

    final showForm = !_loading && _loadError == null && _definition != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'Modifier l’UE' : title),
        actions: [
          IconButton(
            onPressed: _submitting ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      floatingActionButton: showForm
          ? SiamoisFormActionFab(
              label: 'Enregistrer',
              submitting: _submitting,
              onPressed: _submit,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      kSiamoisFormFabListBottomPadding,
                    ),
                    children: [
                      Text(
                        'Modifiez les champs puis enregistrez.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._definition!.panels.map(
                        (panel) => ProjectFormPanelSection(
                          panel: panel,
                          fieldBuilder: _buildField,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
