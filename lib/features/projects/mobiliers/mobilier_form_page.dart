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
import '../form/project_form_panel_section.dart';
import '../form/project_form_readonly_widgets.dart';
import '../recording_units/recording_unit_detail_models.dart';
import '../vocabulary_models.dart';
import 'mobilier_form_cache.dart';
import 'mobilier_form_models.dart';
import 'mobilier_form_prefill.dart';
import 'mobilier_list_store.dart';

/// Création, édition ou visualisation d’un mobilier rattaché à une UE.
class MobilierFormPage extends StatefulWidget {
  const MobilierFormPage({
    super.key,
    required this.auth,
    required this.database,
    required this.recordingUnitId,
    this.mobilier,
    this.readOnly = false,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String recordingUnitId;

  /// Présent en édition / visualisation.
  final MobilierItem? mobilier;
  final bool readOnly;

  bool get isCreate => mobilier == null;
  bool get isEdit => mobilier != null && !readOnly;

  @override
  State<MobilierFormPage> createState() => _MobilierFormPageState();
}

class _MobilierFormPageState extends State<MobilierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _formState = ProjectFormState();
  final _textControllers = <String, TextEditingController>{};
  final _measurementCtrls = FormMeasurementControllers();

  ProjectFormDefinition? _definition;
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;

  late final MobilierFormCache _cache;
  late final MobilierListStore _listStore;
  late final PersonDirectoryStore _personDirectory;

  @override
  void initState() {
    super.initState();
    _cache = MobilierFormCache(auth: widget.auth, db: widget.database);
    _listStore = MobilierListStore(
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
    try {
      final result = await _cache.loadMobilierForm(
        mobilierId: widget.mobilier?.id,
      );
      final vocab = await _cache.loadVocabulariesByFieldCode();
      if (!mounted) return;

      MobilierFormPrefill.applyFromApiFields(
        _formState,
        result.definition,
        result.fieldsRaw,
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

    setState(() => _submitting = true);
    try {
      if (widget.isCreate) {
        final request = _formState.buildMobilierCreateRequest(
          recordingUnitId: widget.recordingUnitId,
          definition: definition,
        );
        final created = await widget.auth.createMobilier(
          recordingUnitId: request.recordingUnitId,
          specimenTypeConceptId: request.specimenTypeConceptId,
          fieldAnswers: request.fieldAnswers,
        );
        await _listStore.upsertLocal(
          item: created,
          recordingUnitId: widget.recordingUnitId,
        );
        if (!mounted) return;
        Navigator.of(context).pop(created);
      } else {
        final specimenId = widget.mobilier!.numericSpecimenId;
        if (specimenId == null) {
          throw const FormatException(
            'Identifiant numérique du mobilier introuvable pour la modification.',
          );
        }
        final updated = await widget.auth.patchMobilier(
          specimenId: specimenId,
          fieldAnswers: _formState.buildMobilierPatchFieldAnswers(definition),
        );
        await _listStore.upsertLocal(
          item: updated,
          recordingUnitId: widget.recordingUnitId,
        );
        if (!mounted) return;
        Navigator.of(context).pop(updated);
      }
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

  Future<void> _confirmDelete() async {
    final mobilier = widget.mobilier;
    if (mobilier == null) return;

    final specimenId = mobilier.numericSpecimenId;
    if (specimenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiant numérique introuvable pour la suppression.'),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le mobilier ?'),
        content: Text(
          '« ${mobilier.displayCode} » sera définitivement supprimé.',
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
      await widget.auth.deleteMobilier(specimenId);
      await _listStore.removeLocal(widget.mobilier!.id);
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

  Future<List<SpatialUnitOption>> _searchSpatial(String query) {
    final orgId = widget.auth.primaryOrganizationId!;
    return widget.auth.searchSpatialUnits(
      organizationId: orgId,
      query: query,
    );
  }

  String? _readOnlyValue(ProjectFormField field) {
    switch (field.normalizedType) {
      case ProjectAnswerType.text:
      case ProjectAnswerType.integer:
        return _formState.text(field.key);
      case ProjectAnswerType.measurement:
        final m = _formState.measurement(field.key);
        if (m == null || m.isEmpty) return null;
        final parts = <String>[];
        if (m.numericValue != null) {
          parts.add('${m.numericValue} ${m.unitSymbol}');
        }
        if (m.comment.isNotEmpty) parts.add(m.comment);
        return parts.join(' — ');
      case ProjectAnswerType.dateTime:
        final d = _formState.dateValues[field.key];
        if (d == null) return null;
        return '${d.day.toString().padLeft(2, '0')}/'
            '${d.month.toString().padLeft(2, '0')}/'
            '${d.year}';
      case ProjectAnswerType.selectOneFromFieldCode:
        final id = _formState.conceptValues[field.key];
        if (id == null) return null;
        final options = _formState.conceptsForField(field, _vocabByCode);
        return options
            .where((o) => o.id == id)
            .map((o) => o.label)
            .firstOrNull;
      case ProjectAnswerType.selectOneSpatialUnit:
        return _formState.spatialSingleValues[field.key]?.display;
      case ProjectAnswerType.selectMultipleSpatialUnitTree:
        final list = _formState.spatialMultiValues[field.key] ?? const [];
        return list.map((e) => e.display).join('\n');
      case ProjectAnswerType.selectOnePerson:
        return _formState.person(field.key)?.display;
      case ProjectAnswerType.selectMultiplePerson:
        return _formState
            .persons(field.key)
            .map((e) => e.display)
            .join('\n');
      default:
        return null;
    }
  }

  Widget _buildField(ProjectFormFieldSlot slot) {
    final field = slot.field;

    if (widget.readOnly) {
      return ProjectFormReadOnlyField(
        label: field.label,
        value: _readOnlyValue(field),
        hint: field.hint,
        multiline: field.normalizedType ==
            ProjectAnswerType.selectMultipleSpatialUnitTree,
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

  String get _title {
    if (widget.readOnly) return 'Mobilier';
    if (widget.isCreate) return 'Nouveau mobilier';
    return 'Modifier le mobilier';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.mobilier;

    return Scaffold(
      appBar: AppBar(
        title: Text(summary?.displayCode ?? _title),
        actions: [
          if (widget.isEdit)
            IconButton(
              onPressed: _submitting ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
            ),
          if (widget.readOnly && widget.mobilier != null)
            IconButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MobilierFormPage(
                      auth: widget.auth,
                      database: widget.database,
                      recordingUnitId: widget.recordingUnitId,
                      mobilier: widget.mobilier,
                    ),
                  ),
                );
                if (result != null && mounted) {
                  Navigator.of(context).pop(result);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
            ),
        ],
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      if (widget.isCreate)
                        Text(
                          'Le mobilier sera rattaché à l’unité d’enregistrement '
                          'courante.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (widget.isCreate) const SizedBox(height: 20),
                      ..._definition!.panels.map(
                        (panel) => ProjectFormPanelSection(
                          panel: panel,
                          fieldBuilder: _buildField,
                        ),
                      ),
                      if (!widget.readOnly) ...[
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.isCreate
                                      ? 'Créer le mobilier'
                                      : 'Enregistrer',
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
