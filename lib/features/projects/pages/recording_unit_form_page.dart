import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/entity_snapshot_store.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/sync/sync_conflict_payload.dart';
import '../../../core/sync/sync_conflict_exception.dart';
import '../../../core/sync/sync_conflict_field_diff.dart';
import '../../../core/widgets/sync/sync_conflict_resolution_dialog.dart';
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
import '../project_detail_models.dart';
import '../recording_units/recording_unit_detail_models.dart';
import '../recording_units/recording_unit_detail_store.dart';
import '../recording_units/recording_unit_form_cache.dart';
import '../recording_units/recording_unit_form_models.dart';
import '../recording_units/recording_unit_form_prefill.dart';
import '../recording_units/recording_unit_list_store.dart';
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
  final _recordingUnitMultiKey = GlobalKey<ProjectFormRecordingUnitMultiSelectorState>();

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

      final fieldsRaw = <String, dynamic>{};
      for (final entry in widget.initialDetail.fields.entries) {
        fieldsRaw['${entry.value.fieldId}'] = {
          'fieldId': entry.value.fieldId,
          'currentValue': entry.value.currentValue,
        };
      }

      final orgId = widget.auth.primaryOrganizationId;
      Map<int, PersonOption> peopleById = const {};
      if (orgId != null) {
        peopleById = await _personDirectory.ensureDirectoryByIdMap(orgId);
      }

      RecordingUnitFormPrefill.applyFromApiFields(
        _formState,
        result.definition,
        fieldsRaw,
        directoryById: peopleById,
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
        final snapshotStore = EntitySnapshotStore(widget.database);
        final baseRevision =
            await snapshotStore.recordingUnitBaseRevision(widget.recordingUnitId);

        await OutboxStore(widget.database).enqueueRecordingUnitUpdate(
          recordingUnitId: widget.recordingUnitId,
          fieldAnswers: fieldAnswers,
          baseServerRevision: baseRevision,
          projectId: widget.projectId,
        );

        final localDetail = _applyFieldAnswersLocally(
          fieldAnswers: fieldAnswers,
        );
        await _detailStore.saveAfterMutation(
          localDetail,
          projectId: widget.projectId,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Modifications enregistrées localement. '
              'Elles seront envoyées à la prochaine synchronisation.',
            ),
          ),
        );
        Navigator.of(context).pop(localDetail);
        return;
      }

      final baseRevision = await EntitySnapshotStore(widget.database)
          .recordingUnitBaseRevision(widget.recordingUnitId);

      final detail = await widget.auth.patchRecordingUnit(
        widget.recordingUnitId,
        fieldAnswers: fieldAnswers,
        expectedRevision: baseRevision,
      );

      await _detailStore.saveAfterMutation(
        detail,
        projectId: widget.projectId,
      );

      await EntitySnapshotStore(widget.database).saveRecordingUnitSnapshot(
        entityId: widget.recordingUnitId,
        serverRevision: readRecordingUnitSyncRevision(detail.recordingUnit),
        detailApiData: detail.toApiData(),
      );

      final item = RecordingUnitItem.fromJson(detail.recordingUnit);
      if (item.id.isNotEmpty && widget.projectId != null) {
        await _listStore.upsertLocal(
          item: item,
          projectId: widget.projectId!,
          typeConceptId: detail.typeConceptId,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(detail);
    } on SyncConflictException catch (e) {
      if (!mounted) return;
      await _handleSyncConflict(e, fieldAnswers);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  RecordingUnitMobileDetail _applyFieldAnswersLocally({
    required Map<String, dynamic> fieldAnswers,
  }) {
    final detail = widget.initialDetail;
    final fields = Map<String, RecordingUnitFormFieldEntry>.from(detail.fields);
    for (final entry in fieldAnswers.entries) {
      final key = entry.key;
      final existing = fields[key];
      if (existing == null) continue;
      fields[key] = RecordingUnitFormFieldEntry(
        fieldId: existing.fieldId,
        label: existing.label,
        hint: existing.hint,
        answerType: existing.answerType,
        valueBinding: existing.valueBinding,
        fieldCode: existing.fieldCode,
        currentValue: entry.value,
      );
    }
    return RecordingUnitMobileDetail(
      recordingUnit: Map<String, dynamic>.from(detail.recordingUnit),
      formName: detail.formName,
      layoutJson: detail.layoutJson,
      fields: fields,
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Révision serveur indisponible pour réessayer.'),
          ),
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

      await _detailStore.saveAfterMutation(
        detail,
        projectId: widget.projectId,
      );
      await EntitySnapshotStore(widget.database).saveRecordingUnitSnapshot(
        entityId: widget.recordingUnitId,
        serverRevision: readRecordingUnitSyncRevision(detail.recordingUnit),
        detailApiData: detail.toApiData(),
      );

      final item = RecordingUnitItem.fromJson(detail.recordingUnit);
      if (item.id.isNotEmpty && widget.projectId != null) {
        await _listStore.upsertLocal(
          item: item,
          projectId: widget.projectId!,
          typeConceptId: detail.typeConceptId,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(detail);
    }
  }

  Future<void> _applyServerConflictVersion(SyncConflictException conflict) async {
    final server = conflict.serverDetail;
    if (server == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('État serveur indisponible.')),
      );
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
      await widget.auth.deleteRecordingUnit(widget.recordingUnitId);
      await _detailStore.removeLocal(widget.recordingUnitId);
      if (widget.projectId != null) {
        await _listStore.removeLocal(widget.recordingUnitId);
      }
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
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
        _recordingUnitMultiKey.currentState?.updateOptions(
          fresh.map(RecordingUnitOption.fromItem).toList(),
          fromCache: false,
        );
      },
    );
    return RecordingUnitOptionsLoad(
      options: result.items.map(RecordingUnitOption.fromItem).toList(),
      fromCache: result.fromCache,
    );
  }

  Future<List<SpatialUnitOption>> _searchSpatial(String query) {
    final orgId = widget.auth.primaryOrganizationId!;
    return widget.auth.searchSpatialUnits(
      organizationId: orgId,
      query: query,
    );
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
          validator: slot.isRequired
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
          isRequired: slot.isRequired,
        );
      case ProjectAnswerType.selectMultipleRecordingUnit:
        return ProjectFormRecordingUnitMultiSelector(
          key: _recordingUnitMultiKey,
          field: field,
          loadOptions: _loadRecordingUnitOptions,
          selected: _formState.recordingUnits(field.key),
          onChanged: (list) => setState(
            () => _formState.recordingUnitMultiValues[field.key] = list,
          ),
          isRequired: slot.isRequired,
        );
      case ProjectAnswerType.dateTime:
        return ProjectFormDateInput(
          field: field,
          value: _formState.dateValues[field.key],
          onChanged: (d) => setState(() => _formState.dateValues[field.key] = d),
        );
      case ProjectAnswerType.selectOneFromFieldCode:
        final options = _formState.conceptsForField(field, _vocabByCode);
        return ProjectFormConceptDropdown(
          field: field,
          options: options,
          value: _formState.conceptValues[field.key],
          onChanged: (v) =>
              setState(() => _formState.conceptValues[field.key] = v),
        );
      case ProjectAnswerType.selectOneActionCode:
      case ProjectAnswerType.selectOneSpatialUnit:
        if (orgId == null) return const SizedBox.shrink();
        return ProjectFormSpatialAutocomplete(
          field: field,
          organizationId: orgId,
          search: _searchSpatial,
          value: _formState.spatialSingleValues[field.key],
          onChanged: (v) => setState(
            () => _formState.spatialSingleValues[field.key] = v,
          ),
        );
      case ProjectAnswerType.selectMultipleSpatialUnitTree:
        return ProjectFormSpatialMultiSelector(
          field: field,
          search: _searchSpatial,
          selected: _formState.spatialMultiValues[field.key] ?? const [],
          onChanged: (list) => setState(
            () => _formState.spatialMultiValues[field.key] = list,
          ),
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
          isRequired: slot.isRequired,
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
          isRequired: slot.isRequired,
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
