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
import '../form/project_form_panel_section.dart';
import '../form/project_form_readonly_widgets.dart';
import '../form/spatial_unit_field_actions.dart';
import '../form/project_form_recording_unit_multi_selector.dart';
import '../form/recording_unit_option.dart';
import '../recording_units/recording_unit_detail_models.dart';
import '../recording_units/recording_unit_list_store.dart';
import '../vocabulary_models.dart';
import 'mobilier_form_cache.dart';
import 'mobilier_form_fields_store.dart';
import 'mobilier_form_models.dart';
import 'mobilier_form_prefill.dart';
import 'mobilier_list_store.dart';
import 'mobilier_local_id.dart';
import 'mobilier_offline_create.dart';

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
  final _recordingUnitMultiKeys =
      <String, GlobalKey<ProjectFormRecordingUnitMultiSelectorState>>{};

  ProjectFormDefinition? _definition;
  Map<String, dynamic> _fieldsRaw = const {};
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  Map<int, PersonOption> _peopleById = const {};
  String? _projectId;
  int? _specimenTypeConceptId;
  String? _specimenTypeLabel;
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;

  late final MobilierFormCache _cache;
  late final MobilierFormFieldsStore _fieldsStore;
  late final MobilierListStore _listStore;
  late final RecordingUnitListStore _recordingUnitListStore;
  late final PersonDirectoryStore _personDirectory;
  late final SpatialUnitFieldActions _spatialActions;

  @override
  void initState() {
    super.initState();
    _cache = MobilierFormCache(auth: widget.auth, db: widget.database);
    _fieldsStore = MobilierFormFieldsStore(widget.database);
    _listStore = MobilierListStore(
      auth: widget.auth,
      db: widget.database,
    );
    _recordingUnitListStore = RecordingUnitListStore(
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
    try {
      final result = await _cache.loadMobilierForm(
        mobilierId: widget.mobilier?.id,
      );
      final vocab = await _cache.loadVocabulariesByFieldCode();
      if (!mounted) return;

      _projectId = await widget.database.projectIdForRecordingUnit(
        widget.recordingUnitId,
      );

      final orgId = widget.auth.primaryOrganizationId;
      Map<int, PersonOption> peopleById = const {};
      if (orgId != null) {
        peopleById = await _personDirectory.ensureDirectoryByIdMap(orgId);
      }

      MobilierFormPrefill.applyFromApiFields(
        _formState,
        result.definition,
        result.fieldsRaw,
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
        _fieldsRaw = result.fieldsRaw;
        _vocabByCode = vocab;
        _peopleById = peopleById;
        _specimenTypeConceptId = result.specimenTypeConceptId;
        _specimenTypeLabel = result.specimenTypeLabel;
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
    final syncNotifier = AppSyncStatusScope.maybeOf(context)?.notifier;
    try {
      if (widget.isCreate) {
        final request = _formState.buildMobilierCreateRequest(
          recordingUnitId: widget.recordingUnitId,
          definition: definition,
          fallbackSpecimenTypeConceptId: _specimenTypeConceptId,
        );
        final online = await widget.auth.canUseProjectsApi();

        if (!online) {
          final listId = MobilierLocalId.toListId(MobilierLocalId.newLocalUuid());
          final item = MobilierOfflineCreate.buildListItem(
            listId: listId,
            typeLabel: _typeLabelForConceptId(request.specimenTypeConceptId),
            definition: definition,
            fieldAnswers: request.fieldAnswers,
          );

          await _listStore.upsertLocal(
            item: item,
            recordingUnitId: widget.recordingUnitId,
          );
          await _fieldsStore.saveFromFieldAnswers(
            mobilierId: listId,
            recordingUnitId: widget.recordingUnitId,
            fieldsRaw: _fieldsRaw,
            definition: definition,
            fieldAnswers: request.fieldAnswers,
          );
          await OutboxStore(widget.database).enqueueMobilierCreate(
            localMobilierId: listId,
            recordingUnitId: widget.recordingUnitId,
            specimenTypeConceptId: request.specimenTypeConceptId,
            fieldAnswers: request.fieldAnswers,
          );

          await syncNotifier?.refresh();

          if (!mounted) return;
          context.showInfoMessage(
            'Mobilier enregistré localement. Il sera créé sur le serveur '
            'à la prochaine synchronisation.',
          );
          Navigator.of(context).pop(item);
          return;
        }

        final created = await widget.auth.createMobilier(
          recordingUnitId: request.recordingUnitId,
          specimenTypeConceptId: request.specimenTypeConceptId,
          fieldAnswers: request.fieldAnswers,
        );
        await _listStore.upsertLocal(
          item: created,
          recordingUnitId: widget.recordingUnitId,
        );
        await _fieldsStore.saveFromFieldAnswers(
          mobilierId: created.id,
          recordingUnitId: widget.recordingUnitId,
          fieldsRaw: _fieldsRaw,
          definition: definition,
          fieldAnswers: request.fieldAnswers,
        );
        if (!mounted) return;
        Navigator.of(context).pop(created);
      } else {
        if (MobilierLocalId.isLocalListId(widget.mobilier!.id)) {
          if (!mounted) return;
          context.showInfoMessage(
            'Mobilier local : synchronisez-le avant de le modifier sur le serveur.',
          );
          return;
        }
        final findId = widget.mobilier!.id.trim();
        if (findId.isEmpty) {
          throw const FormatException(
            'Identifiant du mobilier introuvable pour la modification.',
          );
        }
        final patchAnswers =
            _formState.buildMobilierPatchFieldAnswers(definition);
        final updated = await widget.auth.patchMobilier(
          findId: findId,
          fieldAnswers: patchAnswers,
        );
        await _listStore.upsertLocal(
          item: updated,
          recordingUnitId: widget.recordingUnitId,
        );
        await _fieldsStore.saveFromFieldAnswers(
          mobilierId: updated.id,
          recordingUnitId: widget.recordingUnitId,
          fieldsRaw: _fieldsRaw,
          definition: definition,
          fieldAnswers: patchAnswers,
        );
        if (!mounted) return;
        Navigator.of(context).pop(updated);
      }
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

  String? _typeLabelForConceptId(int conceptId) {
    if (_specimenTypeConceptId == conceptId &&
        _specimenTypeLabel != null &&
        _specimenTypeLabel!.trim().isNotEmpty) {
      return _specimenTypeLabel;
    }
    final definition = _definition;
    if (definition == null) return null;
    for (final field in definition.fields) {
      if (field.valueBinding != 'type') continue;
      final options = _formState.conceptsForField(field, _vocabByCode);
      for (final option in options) {
        if (option.id == conceptId) return option.label;
      }
    }
    return _specimenTypeLabel;
  }

  bool get _definitionHasTypeField {
    final definition = _definition;
    if (definition == null) return false;
    return definition.fields.any((f) => f.valueBinding == 'type');
  }

  Future<void> _confirmDelete() async {
    final mobilier = widget.mobilier;
    if (mobilier == null) return;

    if (MobilierLocalId.isLocalListId(mobilier.id)) {
      await widget.database.deleteSyncActionsForLocalEntity(mobilier.id);
      await _listStore.removeLocal(mobilier.id);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
      return;
    }

    final findId = mobilier.id.trim();
    if (findId.isEmpty) {
      context.showErrorMessage('Identifiant introuvable pour la suppression.');
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
      await widget.auth.deleteMobilier(findId);
      await _listStore.removeLocal(widget.mobilier!.id);
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
    final projectId = _projectId;
    if (projectId == null || projectId.trim().isEmpty) {
      return const RecordingUnitOptionsLoad(options: [], fromCache: true);
    }
    final result = await _recordingUnitListStore.loadAllForPicker(
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
      case ProjectAnswerType.selectMultipleRecordingUnit:
        return _formState
            .recordingUnits(field.key)
            .map((e) => e.display)
            .join('\n');
      case ProjectAnswerType.selectOnePerson:
        return PersonOption.resolveDisplay(
          _formState.person(field.key),
          directoryById: _peopleById,
        );
      case ProjectAnswerType.selectMultiplePerson:
        final people = _formState.persons(field.key);
        if (people.isEmpty) return null;
        return people.map((e) => e.display).where((s) => s.isNotEmpty).join('\n');
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
          isRequired: slot.isRequired,
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
          isRequired: slot.isRequired,
          value: _formState.dateValues[field.key],
          onChanged: (d) => setState(() => _formState.dateValues[field.key] = d),
        );
      case ProjectAnswerType.selectOneFromFieldCode:
        final options = _formState.conceptsForField(field, _vocabByCode);
        return ProjectFormConceptDropdown(
          field: field,
          options: options,
          isRequired: slot.isRequired,
          value: _formState.conceptValues[field.key],
          onChanged: (v) =>
              setState(() => _formState.conceptValues[field.key] = v),
        );
      case ProjectAnswerType.selectMultiple:
        final multiOptions = _formState.conceptsForField(field, _vocabByCode);
        return ProjectFormConceptMultiSelector(
          field: field,
          options: multiOptions,
          isRequired: slot.isRequired,
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
          isRequired: slot.isRequired,
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
          isRequired: slot.isRequired,
          search: _searchSpatial,
          selected: _formState.spatialMultiValues[field.key] ?? const [],
          onChanged: (list) => setState(
            () => _formState.spatialMultiValues[field.key] = list,
          ),
          onCreateNew: _createSpatial,
        );
      case ProjectAnswerType.selectMultipleRecordingUnit:
        if (_projectId == null || _projectId!.trim().isEmpty) {
          return ProjectFormReadOnlyField(
            label: field.label,
            value:
                'Projet parent introuvable — synchronisez les UE du projet en ligne.',
            hint: field.hint,
          );
        }
        return ProjectFormRecordingUnitMultiSelector(
          key: _recordingUnitMultiKey(field.key),
          field: field,
          loadOptions: _loadRecordingUnitOptions,
          selected: _formState.recordingUnits(field.key),
          onChanged: (list) => setState(
            () => _formState.recordingUnitMultiValues[field.key] = list,
          ),
          isRequired: slot.isRequired,
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

  String get _title {
    if (widget.readOnly) return 'Mobilier';
    if (widget.isCreate) return 'Nouveau mobilier';
    return 'Modifier le mobilier';
  }

  Future<void> _openEdit() async {
    final mobilier = widget.mobilier;
    if (mobilier == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobilierFormPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: widget.recordingUnitId,
          mobilier: mobilier,
        ),
      ),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.mobilier;

    final showForm = !_loading && _loadError == null && _definition != null;

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
        ],
      ),
      floatingActionButton: widget.readOnly && widget.mobilier != null
          ? FloatingActionButton.extended(
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
            )
          : showForm && !widget.readOnly
              ? SiamoisFormActionFab(
                  label: widget.isCreate ? 'Créer le mobilier' : 'Enregistrer',
                  icon: widget.isCreate ? Icons.add_rounded : Icons.save_rounded,
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
                      if (widget.isCreate)
                        Text(
                          'Le mobilier sera rattaché à l’unité d’enregistrement '
                          'courante.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (widget.isCreate &&
                          (_specimenTypeLabel?.trim().isNotEmpty ?? false) &&
                          !_definitionHasTypeField) ...[
                        const SizedBox(height: 16),
                        ProjectFormReadOnlyField(
                          label: 'Type',
                          value: _specimenTypeLabel,
                        ),
                      ],
                      if (widget.isCreate) const SizedBox(height: 20),
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
