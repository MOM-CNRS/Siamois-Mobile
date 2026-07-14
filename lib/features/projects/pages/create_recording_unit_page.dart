import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/app_sync_status_scope.dart';
import '../../../core/sync/outbox_store.dart';
import '../../../core/widgets/ui/siamois_form_action_fab.dart';
import '../../../core/widgets/ui/siamois_messenger.dart';
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
import '../recording_units/recording_unit_form_cache.dart';
import '../recording_units/recording_unit_form_models.dart';
import '../recording_units/recording_unit_hierarchy.dart';
import '../recording_units/recording_unit_list_store.dart';
import '../recording_units/recording_unit_detail_store.dart';
import '../recording_units/recording_unit_field_answers_merge.dart';
import '../recording_units/recording_unit_local_id.dart';
import '../recording_units/recording_unit_offline_create.dart';
import '../vocabulary_models.dart';

/// Création UE : choix du type (SIARU.TYPE) puis formulaire adapté.
class CreateRecordingUnitPage extends StatefulWidget {
  const CreateRecordingUnitPage({
    super.key,
    required this.auth,
    required this.database,
    required this.projectId,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String projectId;

  @override
  State<CreateRecordingUnitPage> createState() =>
      _CreateRecordingUnitPageState();
}

class _CreateRecordingUnitPageState extends State<CreateRecordingUnitPage> {
  final _formKey = GlobalKey<FormState>();
  final _formState = ProjectFormState();
  final _textControllers = <String, TextEditingController>{};
  final _measurementCtrls = FormMeasurementControllers();
  final _recordingUnitMultiKeys =
      <String, GlobalKey<ProjectFormRecordingUnitMultiSelectorState>>{};

  List<ConceptOption> _types = const [];
  ConceptOption? _selectedType;
  bool _typeStep = true;

  ProjectFormDefinition? _definition;
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;
  Map<int, PersonOption> _peopleById = const {};

  late final RecordingUnitFormCache _formCache;
  late final RecordingUnitListStore _listStore;
  late final RecordingUnitDetailStore _detailStore;
  late final PersonDirectoryStore _personDirectory;
  late final SpatialUnitFieldActions _spatialActions;

  @override
  void initState() {
    super.initState();
    _formCache = RecordingUnitFormCache(
      auth: widget.auth,
      db: widget.database,
    );
    _listStore = RecordingUnitListStore(
      auth: widget.auth,
      db: widget.database,
    );
    _detailStore = RecordingUnitDetailStore(
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
    _loadTypes();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _measurementCtrls.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final types = await widget.auth.fetchRecordingUnitTypeConcepts();
      if (!mounted) return;
      setState(() {
        _types = types;
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

  Future<void> _confirmTypeAndLoadForm() async {
    final type = _selectedType;
    if (type == null) {
      context.showInfoMessage(
        'Choisissez un type d’unité d’enregistrement.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final result = await _formCache.loadCreationForm(typeConceptId: type.id);
      final vocab = await _formCache.loadVocabulariesByFieldCode();
      final orgId = widget.auth.primaryOrganizationId;
      Map<int, PersonOption> peopleById = const {};
      if (orgId != null) {
        peopleById = await _personDirectory.ensureDirectoryByIdMap(orgId);
      }
      if (!mounted) return;

      _formState.textValues.clear();
      _formState.dateValues.clear();
      _formState.conceptValues.clear();
      _formState.spatialSingleValues.clear();
      _formState.spatialMultiValues.clear();
      _formState.measurementValues.clear();
      _formState.recordingUnitMultiValues.clear();
      for (final c in _textControllers.values) {
        c.dispose();
      }
      _textControllers.clear();
      _measurementCtrls.dispose();

      for (final field in result.definition.fields) {
        if (field.isTextInput) {
          _textControllers[field.key] = TextEditingController();
        }
        if (field.isMeasurementInput) {
          _measurementCtrls.ensure(field);
        }
      }

      setState(() {
        _definition = result.definition;
        _vocabByCode = vocab;
        _peopleById = peopleById;
        _typeStep = false;
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

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;

    final definition = _definition;
    final type = _selectedType;
    if (definition == null || type == null) return;

    for (final field in definition.fields) {
      if (field.isTextInput) {
        _formState.setText(field.key, _textController(field).text);
      }
    }
    _measurementCtrls.syncTo(_formState, definition);

    setState(() => _submitting = true);
    final syncNotifier = AppSyncStatusScope.maybeOf(context)?.notifier;
    try {
      final fieldAnswers = _formState.buildRecordingUnitFieldAnswers(definition);
      final online = await widget.auth.canUseProjectsApi();

      if (!online) {
        final listId = RecordingUnitLocalId.toListId(
          RecordingUnitLocalId.newLocalUuid(),
        );
        final detail = RecordingUnitOfflineCreate.buildDetail(
          listId: listId,
          type: type,
          definition: definition,
          fieldAnswers: fieldAnswers,
        );

        await _detailStore.saveAfterMutation(
          detail,
          projectId: widget.projectId,
        );

        await OutboxStore(widget.database).enqueueRecordingUnitCreate(
          localRecordingUnitId: listId,
          actionUnitId: widget.projectId,
          recordingUnitTypeConceptId: type.id,
          fieldAnswers: fieldAnswers,
          projectId: widget.projectId,
        );

        final item = RecordingUnitOfflineCreate.buildListItem(
          detail: detail,
          type: type,
        );
        if (item.id.isNotEmpty) {
          await _listStore.upsertLocal(
            item: item,
            projectId: widget.projectId,
            typeConceptId: type.id,
          );
        }

        await syncNotifier?.refresh();

        if (!mounted) return;
        context.showInfoMessage(
          'Unité d’enregistrement enregistrée localement. '
          'Elle sera créée sur le serveur à la prochaine synchronisation.',
        );
        Navigator.of(context).pop(item);
        return;
      }

      final detail = await widget.auth.createRecordingUnit(
        actionUnitId: widget.projectId,
        recordingUnitTypeConceptId: type.id,
        fieldAnswers: fieldAnswers,
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

      final item = RecordingUnitItem.fromJson(merged.recordingUnit);
      if (item.id.isNotEmpty) {
        await _listStore.upsertLocal(
          item: item,
          projectId: widget.projectId,
          typeConceptId: type.id,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(item);
    } on AuthException catch (e) {
      if (mounted) {
        context.showErrorMessage(e.message);
      }
    } on FormatException catch (e) {
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

  TextEditingController _textController(ProjectFormField field) {
    return _textControllers.putIfAbsent(
      field.key,
      () => TextEditingController(),
    );
  }

  Future<RecordingUnitOptionsLoad> _loadRecordingUnitOptions() async {
    final result = await _listStore.loadAllForPicker(
      widget.projectId,
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProjectFormReadOnlyField(
            label: field.label,
            value: _selectedType?.label,
            hint: field.hint,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _submitting
                  ? null
                  : () => setState(() {
                        _typeStep = true;
                        _definition = null;
                      }),
              child: const Text('Changer le type'),
            ),
          ),
        ],
      );
    }

    final orgId = widget.auth.primaryOrganizationId;
    switch (field.normalizedType) {
      case ProjectAnswerType.text:
      case ProjectAnswerType.integer:
        return ProjectFormTextInput(
          field: field,
          controller: _textController(field),
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
        _measurementCtrls.ensure(field);
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
      case ProjectAnswerType.selectMultiple:
        final multiOptions = _formState.conceptsForField(field, _vocabByCode);
        return ProjectFormConceptMultiSelector(
          field: field,
          options: multiOptions,
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

  Widget _buildTypeStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Choisissez le type d’unité d’enregistrement. Le formulaire affiché dépend de ce choix.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        if (_types.isEmpty)
          Text(
            'Aucun type disponible (vocabulaire SIARU.TYPE). Synchronisez en ligne.',
            style: theme.textTheme.bodyMedium,
          )
        else
          ..._types.map(
            (type) => RadioListTile<int>(
              value: type.id,
              groupValue: _selectedType?.id,
              title: Text(type.label),
              onChanged: (id) {
                setState(() {
                  _selectedType = _types.firstWhere((t) => t.id == id);
                });
              },
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _confirmTypeAndLoadForm,
          child: const Text('Continuer'),
        ),
      ],
    );
  }

  Widget _buildFormStep(ThemeData theme) {
    final definition = _definition;
    if (definition == null) return const SizedBox.shrink();

    return Form(
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
            'Complétez le formulaire puis validez la création.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ...definition.panels.map(
            (panel) => ProjectFormPanelSection(
              panel: panel,
              fieldBuilder: _buildField,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final showFormFab =
        !_loading && _loadError == null && !_typeStep && _definition != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle UE'),
      ),
      floatingActionButton: showFormFab
          ? SiamoisFormActionFab(
              label: 'Enregistrer',
              icon: Icons.add_rounded,
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
                          onPressed:
                              _typeStep ? _loadTypes : _confirmTypeAndLoadForm,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _typeStep
                  ? _buildTypeStep(theme)
                  : _buildFormStep(theme),
    );
  }
}
