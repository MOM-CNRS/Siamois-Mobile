import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/app_sync_status_scope.dart';
import '../../../core/sync/outbox_store.dart';
import '../../auth/auth_repository.dart';
import '../form/form_measurement_form.dart';
import '../form/project_form_cache.dart';
import '../form/project_form_field_widgets.dart';
import '../form/project_form_measurement_input.dart';
import '../form/project_form_layout.dart';
import '../form/project_form_models.dart';
import '../form/project_form_panel_section.dart';
import '../form/spatial_unit_field_actions.dart';
import '../project_detail_store.dart';
import '../project_local_id.dart';
import '../project_offline_create.dart';
import '../../../core/widgets/ui/siamois_form_action_fab.dart';
import '../../../core/widgets/ui/siamois_messenger.dart';
import '../vocabulary_models.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({
    super.key,
    required this.auth,
    required this.database,
  });

  final AuthRepository auth;
  final AppDatabase database;

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
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
  late final SpatialUnitFieldActions _spatialActions;
  late final ProjectDetailStore _detailStore;

  @override
  void initState() {
    super.initState();
    _cache = ProjectFormCache(auth: widget.auth, db: widget.database);
    _detailStore = ProjectDetailStore(auth: widget.auth, db: widget.database);
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final definition = await _cache.loadProjectForm();
      final vocab = await _cache.loadVocabulariesByFieldCode();
      if (!mounted) return;

      if (kDebugMode) {
        final diagnostic = VocabularyDiagnostic.fromVocabByCode(vocab);
        debugPrint(
          '[Siamois Projet] Création — vocabulaires: ${diagnostic.summary}',
        );
        for (final field in definition.fields) {
          if (field.normalizedType != ProjectAnswerType.selectOneFromFieldCode) {
            continue;
          }
          final options = _formState.conceptsForField(field, vocab);
          final code = field.fieldCode ?? 'SIAAU.TYPE';
          debugPrint(
            '[Siamois Projet]   « ${field.label} » ($code) — '
            '${options.length} option(s)',
          );
        }
        final hint = diagnostic.categoryEmptyHint;
        if (hint != null) {
          debugPrint('[Siamois Projet]   $hint');
        }
      }

      for (final field in definition.fields) {
        if (field.isTextInput) {
          _textControllers[field.key] = TextEditingController();
        }
        if (field.isMeasurementInput) {
          _measurementCtrls.ensure(field);
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
      () => TextEditingController(),
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
    final syncNotifier = AppSyncStatusScope.maybeOf(context)?.notifier;
    try {
      final payload = _formState.buildPayload(
        organizationId: orgId,
        definition: definition,
        vocabByCode: _vocabByCode,
        generateIdentifierIfMissing: true,
      );
      final online = await widget.auth.canUseProjectsApi();

      if (!online) {
        final listId = ProjectLocalId.toListId(ProjectLocalId.newLocalUuid());
        final summary = ProjectOfflineCreate.buildSummary(
          listId: listId,
          payload: payload,
        );
        final detail = ProjectOfflineCreate.buildDetail(
          listId: listId,
          payload: payload,
          definition: definition,
          formState: _formState,
          vocabByCode: _vocabByCode,
        );

        await _detailStore.saveAfterMutation(listId, detail);
        await OutboxStore(widget.database).enqueueProjectCreate(
          localProjectId: listId,
          payload: payload,
        );

        await syncNotifier?.refresh();

        if (!mounted) return;
        context.showInfoMessage(
          'Projet enregistré localement. '
          'Il sera créé sur le serveur à la prochaine synchronisation.',
        );
        Navigator.of(context).pop(summary);
        return;
      }

      final project = await widget.auth.createProjectFromPayload(payload);
      final detailFromForm = ProjectOfflineCreate.buildDetail(
        listId: project.storageId,
        payload: payload,
        definition: definition,
        formState: _formState,
        vocabByCode: _vocabByCode,
      );
      await _detailStore.cacheAfterOnlineCreate(
        project,
        organisationId: orgId,
        detailFromForm: detailFromForm,
      );
      await syncNotifier?.refresh();

      if (!mounted) return;
      Navigator.of(context).pop(project);
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

  Future<List<SpatialUnitOption>> _searchSpatial(String query) =>
      _spatialActions.search(query);

  Future<SpatialUnitOption?> _createSpatial() =>
      _spatialActions.createNew(context);

  Widget _buildField(ProjectFormFieldSlot slot) {
    final field = slot.field;
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
        _measurementCtrls.ensure(field);
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

    final showForm = !_loading && _loadError == null && _definition != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau projet'),
      ),
      floatingActionButton: showForm
          ? SiamoisFormActionFab(
              label: 'Créer le projet',
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
                        'Renseignez les champs du formulaire projet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._definition!.panelsForCreate().map(
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
