import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
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
      final definition = await _cache.loadDocumentForm(
        documentId: widget.document?.id,
      );
      final vocab = await _cache.loadVocabulariesByFieldCode();
      if (!mounted) return;

      _formState.applyCurrentValues(definition.currentValues);

      for (final field in definition.fields) {
        final type = field.normalizedType;
        if (type == DocumentInputType.text ||
            type == DocumentInputType.textArea) {
          final initial = _formState.textValues[field.fieldKey] ?? '';
          _textControllers[field.fieldKey] = TextEditingController(text: initial);
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

  TextEditingController _textController(String key) {
    return _textControllers.putIfAbsent(
      key,
      () => TextEditingController(text: _formState.textValues[key] ?? ''),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withReadStream: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final path = file.path;
    if (path == null) return;
    setState(() {
      _formState.pickedFilePath = path;
      _formState.pickedFileName = file.name;
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire.')),
      );
      return;
    }

    if (!widget.isEdit &&
        (_formState.pickedFilePath == null || _formState.pickedFilePath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fichier.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (widget.isEdit) {
        final updated = await widget.auth.updateDocument(
          documentId: widget.document!.id,
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
        final online = await widget.auth.isServerReachable();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Document enregistré localement. Il sera envoyé au serveur '
                'lors de la prochaine synchronisation.',
              ),
            ),
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

  Widget _buildField(DocumentFormField field) {
    switch (field.normalizedType) {
      case DocumentInputType.text:
        return TextFormField(
          controller: _textController(field.fieldKey),
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          maxLength: field.maxLength,
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
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          maxLength: field.maxLength,
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
          ),
          options: options,
          value: _formState.conceptValues[field.fieldKey],
          onChanged: (v) =>
              setState(() => _formState.conceptValues[field.fieldKey] = v),
        );
      case DocumentInputType.file:
        final name = _formState.pickedFileName ??
            _definition?.currentValues?.fileName;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: widget.isEdit ? null : _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                widget.isEdit
                    ? 'Fichier actuel : ${name ?? '—'}'
                    : (name ?? 'Choisir un fichier'),
              ),
            ),
            if (!widget.isEdit && field.isRequired)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Un fichier est obligatoire pour la création.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Modifier le document' : 'Nouveau document'),
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
                      Text(
                        widget.isEdit
                            ? 'Modifiez les métadonnées du document.'
                            : 'Renseignez les champs et joignez un fichier.',
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
                            : Text(widget.isEdit ? 'Enregistrer' : 'Créer'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
