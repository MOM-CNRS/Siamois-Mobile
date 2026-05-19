import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../auth/auth_repository.dart';
import '../form/form_measurement_form.dart';
import '../form/project_form_field_widgets.dart';
import '../form/project_form_layout.dart';
import '../form/project_form_measurement_input.dart';
import '../form/project_form_models.dart';
import '../form/person_directory_store.dart';
import '../form/project_form_person_widgets.dart';
import '../form/project_form_recording_unit_multi_selector.dart';
import '../form/recording_unit_option.dart';
import '../form/project_form_panel_section.dart';
import '../project_detail_models.dart';
import '../recording_units/recording_unit_form_cache.dart';
import '../recording_units/recording_unit_form_models.dart';
import '../recording_units/recording_unit_list_store.dart';
import '../recording_units/recording_unit_detail_store.dart';
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
  final _recordingUnitMultiKey = GlobalKey<ProjectFormRecordingUnitMultiSelectorState>();

  List<ConceptOption> _types = const [];
  ConceptOption? _selectedType;
  bool _typeStep = true;

  ProjectFormDefinition? _definition;
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;

  late final RecordingUnitFormCache _formCache;
  late final RecordingUnitListStore _listStore;
  late final RecordingUnitDetailStore _detailStore;
  late final PersonDirectoryStore _personDirectory;

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

  Future<void> _confirmTypeAndLoadForm() async {
    final type = _selectedType;
    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un type d’unité d’enregistrement.')),
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
    try {
      final fieldAnswers = _formState.buildRecordingUnitFieldAnswers(definition);
      final detail = await widget.auth.createRecordingUnit(
        actionUnitId: widget.projectId,
        recordingUnitTypeConceptId: type.id,
        fieldAnswers: fieldAnswers,
      );

      await _detailStore.saveAfterMutation(
        detail,
        projectId: widget.projectId,
      );

      final item = RecordingUnitItem.fromJson(detail.recordingUnit);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on FormatException catch (e) {
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
        _measurementCtrls.ensure(field);
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (_selectedType != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Type : ${_selectedType!.label}',
                style: theme.textTheme.titleSmall,
              ),
              trailing: TextButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() {
                          _typeStep = true;
                          _definition = null;
                        }),
                child: const Text('Changer'),
              ),
            ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer l’unité d’enregistrement'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle UE'),
      ),
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
