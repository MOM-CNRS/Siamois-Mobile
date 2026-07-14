import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/widgets/ui/siamois_form_action_fab.dart';
import '../../../core/widgets/ui/siamois_messenger.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_field_widgets.dart';
import '../form/project_form_models.dart';
import '../project_detail_models.dart';
import '../vocabulary_models.dart';
import 'document_form_cache.dart';
import 'document_form_models.dart';
import 'document_tmp_models.dart';
import 'document_tmp_store.dart';
import 'project_document_store.dart';
import 'recording_unit_document_store.dart';

/// Création ou édition d’un document (projet ou unité d’enregistrement).
class DocumentFormPage extends StatefulWidget {
  DocumentFormPage({
    super.key,
    required this.auth,
    required this.database,
    this.projectId,
    this.recordingUnitId,
    this.document,
  }) : assert(
          _hasParentId(projectId, recordingUnitId),
          'projectId ou recordingUnitId requis',
        );

  static bool _hasParentId(String? projectId, String? recordingUnitId) {
    final hasProject = projectId != null && projectId.trim().isNotEmpty;
    final hasRu =
        recordingUnitId != null && recordingUnitId.trim().isNotEmpty;
    return hasProject || hasRu;
  }

  final AuthRepository auth;
  final AppDatabase database;
  final String? projectId;
  final String? recordingUnitId;

  /// Présent en mode édition.
  final ProjectDocumentItem? document;

  bool get isEdit => document != null;

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _formState = DocumentFormState();
  final _textControllers = <String, TextEditingController>{};

  DocumentFormDefinition? _definition;
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;

  late final DocumentFormCache _cache;
  late final ProjectDocumentStore _projectDocumentStore;
  late final RecordingUnitDocumentStore _recordingUnitDocumentStore;

  @override
  void initState() {
    super.initState();
    _cache = DocumentFormCache(auth: widget.auth, db: widget.database);
    _projectDocumentStore = ProjectDocumentStore(
      auth: widget.auth,
      db: widget.database,
    );
    _recordingUnitDocumentStore = RecordingUnitDocumentStore(
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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final listId = widget.document?.id;
      final apiDocumentId = listId != null &&
              listId.trim().isNotEmpty &&
              !DocumentTmpEntry.isLocalListId(listId)
          ? listId.trim()
          : null;
      final definition = await _cache.loadDocumentForm(
        documentId: apiDocumentId,
      );
      final vocab = await _cache.loadVocabulariesByFieldCode();
      if (!mounted) return;

      _formState.applyCurrentValues(definition.currentValues);
      if (widget.isEdit && widget.document != null) {
        _prefillFromDocument(widget.document!);
      }

      for (final c in _textControllers.values) {
        c.dispose();
      }
      _textControllers.clear();

      for (final field in definition.fields) {
        final type = field.normalizedType;
        if (type == DocumentInputType.text ||
            type == DocumentInputType.textArea) {
          final initial = _formState.textValues[field.fieldKey] ?? '';
          _textControllers[field.fieldKey] =
              TextEditingController(text: initial);
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

  void _prefillFromDocument(ProjectDocumentItem doc) {
    final title = doc.displayTitle.trim();
    if (title.isNotEmpty) {
      _formState.textValues['title'] ??= title;
    }
    final description = doc.description?.trim();
    if (description != null && description.isNotEmpty) {
      _formState.textValues['description'] ??= description;
    }
    _formState.pickedFileName ??= doc.fileName;
  }

  TextEditingController _textController(String key) {
    return _textControllers.putIfAbsent(
      key,
      () => TextEditingController(text: _formState.textValues[key] ?? ''),
    );
  }

  void _setPickedAttachment({required String path, required String name}) {
    setState(() {
      _formState.pickedFilePath = path;
      _formState.pickedFileName = name;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withReadStream: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final path = file.path;
    if (path == null) return;
    _setPickedAttachment(
      path: path,
      name: file.name.isNotEmpty ? file.name : path.split('/').last,
    );
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (photo == null) return;
      final path = photo.path;
      if (path.isEmpty) return;
      final name = photo.name.trim().isNotEmpty
          ? photo.name
          : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _setPickedAttachment(path: path, name: name);
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage('Impossible d\'ouvrir l\'appareil photo : $e');
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;

    final definition = _definition;
    if (definition == null) return;

    for (final field in definition.fields) {
      final type = field.normalizedType;
      if (type == DocumentInputType.text ||
          type == DocumentInputType.textArea) {
        _formState.textValues[field.fieldKey] =
            _textController(field.fieldKey).text;
      }
    }

    final title = _formState.textValues['title']?.trim() ?? '';
    if (title.isEmpty) {
      context.showInfoMessage('Le titre est obligatoire.');
      return;
    }

    if (!widget.isEdit &&
        (_formState.pickedFilePath == null || _formState.pickedFilePath!.isEmpty)) {
      context.showInfoMessage(
        'Veuillez sélectionner un fichier ou prendre une photo.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (widget.isEdit) {
        final doc = widget.document!;
        if (DocumentTmpEntry.isLocalListId(doc.id)) {
          if (!mounted) return;
          context.showInfoMessage(
            'Document local : synchronisez-le avant de le modifier sur le serveur.',
          );
          return;
        }
        final updated = await widget.auth.patchDocument(
          documentId: doc.id,
          payload: _formState.buildPatchPayload(),
        );
        final projectId = widget.projectId;
        final recordingUnitId = widget.recordingUnitId;
        if (projectId != null) {
          await _projectDocumentStore.saveLocal(
            item: updated,
            projectId: projectId,
          );
        } else if (recordingUnitId != null) {
          await _recordingUnitDocumentStore.saveLocal(
            item: updated,
            uniteEnregistrementId: recordingUnitId,
          );
        }
      } else {
        final online = await widget.auth.canUseProjectsApi();
        if (!online) {
          final tmpStore = DocumentTmpStore(
            db: widget.database,
            auth: widget.auth,
          );
          final parentType = widget.recordingUnitId != null
              ? DocumentTmpParentType.recordingUnit
              : DocumentTmpParentType.project;
          final parentId =
              widget.recordingUnitId ?? widget.projectId!.trim();
          await tmpStore.savePendingUpload(
            parentType: parentType,
            parentId: parentId,
            title: title,
            filePath: _formState.pickedFilePath!,
            description: _formState.textValues['description'],
            fileName: _formState.pickedFileName,
            natureConceptId: _formState.conceptValues['nature'],
            scaleConceptId: _formState.conceptValues['scale'],
            formatConceptId: _formState.conceptValues['format'],
          );
          if (!mounted) return;
          context.showInfoMessage(
            'Document enregistré localement. Il sera envoyé au serveur '
            'lors de la prochaine synchronisation.',
          );
          Navigator.of(context).pop(true);
          return;
        }

        final created = widget.recordingUnitId != null
            ? await widget.auth.createRecordingUnitDocument(
                recordingUnitId: widget.recordingUnitId!,
                title: title,
                description: _formState.textValues['description'],
                natureConceptId: _formState.conceptValues['nature'],
                scaleConceptId: _formState.conceptValues['scale'],
                formatConceptId: _formState.conceptValues['format'],
                filePath: _formState.pickedFilePath!,
                fileName: _formState.pickedFileName ?? 'document',
              )
            : await widget.auth.createProjectDocument(
                projectId: widget.projectId!,
                title: title,
                description: _formState.textValues['description'],
                natureConceptId: _formState.conceptValues['nature'],
                scaleConceptId: _formState.conceptValues['scale'],
                formatConceptId: _formState.conceptValues['format'],
                filePath: _formState.pickedFilePath!,
                fileName: _formState.pickedFileName ?? 'document',
              );
        final projectId = widget.projectId;
        final recordingUnitId = widget.recordingUnitId;
        if (projectId != null) {
          await _projectDocumentStore.saveLocal(
            item: created,
            projectId: projectId,
          );
        } else if (recordingUnitId != null) {
          await _recordingUnitDocumentStore.saveLocal(
            item: created,
            uniteEnregistrementId: recordingUnitId,
          );
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  Widget _buildField(DocumentFormField field) {
    final theme = Theme.of(context);
    switch (field.normalizedType) {
      case DocumentInputType.text:
        return TextFormField(
          controller: _textController(field.fieldKey),
          enabled: !_submitting,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          maxLength: field.effectiveMaxLength,
          validator: field.isRequired
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return '« ${field.label} » est obligatoire';
                  }
                  return null;
                }
              : null,
          onChanged: (v) => _formState.textValues[field.fieldKey] = v,
        );
      case DocumentInputType.textArea:
        return TextFormField(
          controller: _textController(field.fieldKey),
          enabled: !_submitting,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          maxLength: field.effectiveMaxLength,
          onChanged: (v) => _formState.textValues[field.fieldKey] = v,
        );
      case DocumentInputType.conceptSelect:
        final options = _formState.conceptsForField(field, _vocabByCode);
        return ProjectFormConceptDropdown(
          field: ProjectFormField(
            key: field.fieldKey,
            fieldId: 0,
            answerType: 'SELECT_ONE_FROM_FIELD_CODE',
            label: field.label,
            fieldCode: field.fieldCode,
            isRequired: field.isRequired,
          ),
          options: options,
          value: _formState.conceptValues[field.fieldKey],
          onChanged: (v) =>
              setState(() => _formState.conceptValues[field.fieldKey] = v),
        );
      case DocumentInputType.file:
        final name = _formState.pickedFileName ??
            _definition?.currentValues?.fileName;
        final hasSelection =
            (_formState.pickedFilePath ?? '').trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isEdit)
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text('Fichier actuel : ${name ?? '—'}'),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('Fichier'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Photo'),
                    ),
                  ),
                ],
              ),
              if (hasSelection) ...[
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.check_circle_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    name ?? 'Fichier sélectionné',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Retirer',
                    onPressed: () {
                      setState(() {
                        _formState.pickedFilePath = null;
                        _formState.pickedFileName = null;
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ],
            if (!widget.isEdit && field.isRequired)
              Padding(padding: const EdgeInsets.only(top: 6, left: 4)),
          ],
        );
      default:
        return ListTile(
          title: Text(field.label),
          subtitle: Text('Type « ${field.inputType} » non pris en charge'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final showForm = !_loading && _loadError == null && _definition != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Modifier le document' : 'Nouveau document'),
      ),
      floatingActionButton: showForm
          ? SiamoisFormActionFab(
              label: widget.isEdit ? 'Enregistrer' : 'Créer',
              icon: widget.isEdit ? Icons.save_rounded : Icons.add_rounded,
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
                        widget.isEdit
                            ? 'Modifiez les métadonnées du document.'
                            : 'Renseignez les champs et joignez un fichier ou une photo.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._definition!.fields.map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildField(field),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
