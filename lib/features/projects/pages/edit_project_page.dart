import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../auth/auth_repository.dart';
import '../form/form_measurement_form.dart';
import '../form/project_form_cache.dart';
import '../form/project_form_field_widgets.dart';
import '../form/project_form_measurement_input.dart';
import '../form/project_form_layout.dart';
import '../form/project_form_models.dart';
import '../form/project_form_panel_section.dart';
import '../form/project_form_prefill.dart';
import '../form/project_form_readonly_widgets.dart';
import '../../../core/widgets/ui/siamois_form_action_fab.dart';
import '../project_models.dart';
import '../vocabulary_models.dart';

class EditProjectPage extends StatefulWidget {
  const EditProjectPage({
    super.key,
    required this.auth,
    required this.database,
    required this.projectId,
    required this.initialProject,
    this.summary,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String projectId;
  final Map<String, dynamic> initialProject;
  final ProjectSummary? summary;

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _formState = ProjectFormState();
  final _textControllers = <String, TextEditingController>{};
  final _measurementCtrls = FormMeasurementControllers();

  ProjectFormDefinition? _definition;
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;

  late final ProjectFormCache _cache;

  @override
  void initState() {
    super.initState();
    _cache = ProjectFormCache(auth: widget.auth, db: widget.database);
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
    try {
      final definition = await _cache.loadProjectForm();
      final vocab = await _cache.loadVocabulariesByFieldCode();
      if (!mounted) return;

      ProjectFormPrefill.apply(
        _formState,
        definition,
        widget.initialProject,
      );

      for (final field in definition.fields) {
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
        _definition = definition;
        _vocabByCode = vocab;
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
    final orgId = widget.auth.primaryOrganizationId;
    if (definition == null || orgId == null) return;

    for (final field in definition.fields) {
      if (field.isTextInput) {
        _formState.setText(field.key, _textController(field).text);
      }
    }
    _measurementCtrls.syncTo(_formState, definition);

    setState(() => _submitting = true);
    try {
      final patch = _formState.buildPatchPayload(definition: definition);
      final updated = await widget.auth.patchProject(
        projectId: widget.projectId,
        payload: patch,
      );

      await widget.database.upsertProjet(
        project: updated,
        organisationId: orgId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(updated);
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

  Future<List<SpatialUnitOption>> _searchSpatial(String query) {
    final orgId = widget.auth.primaryOrganizationId!;
    return widget.auth.searchSpatialUnits(
      organizationId: orgId,
      query: query,
    );
  }

  Widget _buildField(ProjectFormFieldSlot slot) {
    final field = slot.field;
    if (!field.isPatchableOnApi) {
      return ProjectFormReadOnlyField(
        label: field.label,
        value: _readOnlyValue(field),
        hint: field.hint,
        multiline: field.normalizedType ==
            ProjectAnswerType.selectMultipleSpatialUnitTree,
      );
    }

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
      case ProjectAnswerType.selectMultipleSpatialUnitTree:
        return ProjectFormSpatialMultiSelector(
          field: field,
          search: _searchSpatial,
          selected: _formState.spatialMultiValues[field.key] ?? const [],
          onChanged: (list) => setState(
            () => _formState.spatialMultiValues[field.key] = list,
          ),
        );
      default:
        return ProjectFormReadOnlyField(
          label: field.label,
          value: _readOnlyValue(field),
          hint: field.hint,
        );
    }
  }

  String? _readOnlyValue(ProjectFormField field) {
    final binding = field.valueBinding;
    switch (binding) {
      case 'identifier':
        return widget.initialProject['identifier']?.toString() ??
            widget.initialProject['fullIdentifier']?.toString();
      case 'primaryActionCode':
        return widget.initialProject['codeOperationArcheologique']?.toString();
      case 'mainLocation':
        final su = _formState.spatialSingleValues[field.key];
        return su?.display;
      default:
        return _formState.text(field.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final showForm = !_loading && _loadError == null && _definition != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le projet'),
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
                        'Modifiez les champs autorisés. L’identifiant et certains '
                        'champs ne peuvent pas être modifiés depuis l’application.',
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
