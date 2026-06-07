import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/app_sync_status_scope.dart';
import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/siamois_title_bar.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../../auth/auth_repository.dart';
import '../documents/document_form_page.dart';
import '../documents/document_tmp_models.dart';
import '../documents/document_tmp_store.dart';
import '../documents/document_viewer.dart';
import '../documents/project_document_store.dart';
import '../documents/recording_unit_document_store.dart';
import '../project_detail_models.dart';

/// Consultation d’un document : métadonnées et actions (visualiser, modifier, supprimer).
class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({
    super.key,
    required this.auth,
    required this.database,
    required this.document,
    this.projectId,
    this.recordingUnitId,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final ProjectDocumentItem document;
  final String? projectId;
  final String? recordingUnitId;

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  ProjectDocumentStore? _projectStore;
  RecordingUnitDocumentStore? _recordingUnitStore;
  late final DocumentViewer _viewer;
  late final DocumentTmpStore _tmpStore;

  bool _canOpenFile = false;
  bool _checkingFile = true;
  Uint8List? _previewBytes;
  bool _loadingPreview = false;

  bool get _isImage =>
      widget.document.mimeType?.toLowerCase().startsWith('image/') ?? false;

  @override
  void initState() {
    super.initState();
    _tmpStore = DocumentTmpStore(db: widget.database, auth: widget.auth);
    if (widget.recordingUnitId != null) {
      _recordingUnitStore = RecordingUnitDocumentStore(
        auth: widget.auth,
        db: widget.database,
      );
      _viewer = DocumentViewer(
        auth: widget.auth,
        store: _recordingUnitStore!,
        database: widget.database,
      );
    } else {
      _projectStore = ProjectDocumentStore(
        auth: widget.auth,
        db: widget.database,
      );
      _viewer = DocumentViewer(
        auth: widget.auth,
        store: _projectStore!,
        database: widget.database,
      );
    }
    _initAvailability();
  }

  Future<bool> _canOpenDocument(ProjectDocumentItem doc) {
    final ru = _recordingUnitStore;
    if (ru != null) return ru.canOpenDocument(doc);
    return _projectStore!.canOpenDocument(doc);
  }

  Future<void> _removeLocal(String resourceId) {
    final ru = _recordingUnitStore;
    if (ru != null) return ru.removeLocal(resourceId);
    return _projectStore!.removeLocal(resourceId);
  }

  Future<void> _initAvailability() async {
    final can = await _canOpenDocument(widget.document);
    if (!mounted) return;
    setState(() {
      _canOpenFile = can;
      _checkingFile = false;
    });
    if (can && _isImage) {
      await _loadPreviewBytes();
    }
  }

  Future<void> _loadPreviewBytes() async {
    setState(() => _loadingPreview = true);
    try {
      final bytes = await _resolveImageBytes();
      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
        _loadingPreview = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPreview = false);
    }
  }

  Future<Uint8List?> _resolveImageBytes() async {
    final doc = widget.document;
    final cached = await _tmpStore.readBytes(doc.id);
    if (cached != null && cached.isNotEmpty) return cached;

    if (DocumentTmpEntry.isLocalListId(doc.id)) return null;

    if (!await widget.auth.canUseProjectsApi()) return null;

    final file = await widget.auth.downloadDocumentToTempFile(
      resourceId: doc.id,
      suggestedFileName: doc.fileName ?? 'document_${doc.id}',
      mimeType: doc.mimeType,
    );
    return file.readAsBytes();
  }

  Future<void> _visualizeImage() async {
    if (!_canOpenFile) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fichier indisponible hors ligne. Synchronisez en ligne pour le consulter.',
          ),
        ),
      );
      return;
    }

    final doc = widget.document;
    if (_isImage) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (ctx) => _DocumentImageViewerDialog(
          title: doc.displayTitle,
          initialBytes: _previewBytes,
          loadBytes: _resolveImageBytes,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    await _viewer.open(context, doc);
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentFormPage(
          auth: widget.auth,
          database: widget.database,
          projectId: widget.projectId,
          recordingUnitId: widget.recordingUnitId,
          document: widget.document,
        ),
      ),
    );
    if (changed == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmDelete() async {
    final doc = widget.document;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le document ?'),
        content: Text(
          '« ${doc.displayTitle} » sera définitivement supprimé.',
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

    try {
      if (DocumentTmpEntry.isLocalListId(doc.id)) {
        await _tmpStore.remove(
          DocumentTmpEntry.localIdFromListId(doc.id),
        );
      } else {
        await widget.auth.deleteDocument(doc.id);
        await _removeLocal(doc.id);
        await widget.database.deleteDocumentTmpByResourceId(doc.id);
      }
      if (!mounted) return;
      final sync = AppSyncStatusScope.maybeOf(context)?.notifier;
      await sync?.refresh();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  String get _viewButtonLabel =>
      _isImage ? 'Visualiser l\'image' : 'Visualiser le fichier';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = widget.document;

    return Scaffold(
      backgroundColor: SiamoisColors.surface,
      appBar: SiamoisTitleBar(
        title: 'Détail du document',
        subtitle: doc.displayTitle,
        showBrandMark: false,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          SiamoisSpacing.pageHorizontal,
          SiamoisSpacing.md,
          SiamoisSpacing.pageHorizontal,
          SiamoisSpacing.xxl,
        ),
        children: [
          if (_isImage) ...[
            _ImagePreviewCard(
              loading: _checkingFile || _loadingPreview,
              bytes: _previewBytes,
              canOpen: _canOpenFile,
            ),
            const SizedBox(height: SiamoisSpacing.lg),
          ],
          _MetadataCard(document: doc),
          const SizedBox(height: SiamoisSpacing.xl),
          if (_checkingFile)
            const Center(child: CircularProgressIndicator())
          else ...[
            FilledButton.icon(
              onPressed: _canOpenFile ? _visualizeImage : null,
              icon: Icon(
                _isImage ? Icons.image_outlined : Icons.visibility_outlined,
              ),
              label: Text(_viewButtonLabel),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: SiamoisSpacing.sm),
            OutlinedButton.icon(
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: SiamoisSpacing.sm),
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Supprimer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: SiamoisColors.error,
                side: const BorderSide(color: SiamoisColors.error),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (!_canOpenFile) ...[
              const SizedBox(height: SiamoisSpacing.md),
              Text(
                'Le fichier n’est pas encore disponible en local. '
                'Connectez-vous en ligne pour le visualiser.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SiamoisColors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.loading,
    required this.bytes,
    required this.canOpen,
  });

  final bool loading;
  final Uint8List? bytes;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : bytes != null
                ? InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.memory(
                      bytes!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(SiamoisSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            canOpen
                                ? Icons.image_outlined
                                : Icons.cloud_off_outlined,
                            size: 48,
                            color: SiamoisColors.textTertiary,
                          ),
                          const SizedBox(height: SiamoisSpacing.sm),
                          Text(
                            canOpen
                                ? 'Aperçu indisponible'
                                : 'Image non téléchargée',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: SiamoisColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.document});

  final ProjectDocumentItem document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <_DetailRow>[
      _DetailRow('Titre', document.displayTitle),
      if (document.description?.trim().isNotEmpty == true)
        _DetailRow('Description', document.description!.trim()),
      if (document.fileName?.trim().isNotEmpty == true)
        _DetailRow('Fichier', document.fileName!.trim()),
      if (document.natureLabel?.trim().isNotEmpty == true)
        _DetailRow('Nature', document.natureLabel!.trim()),
      if (document.formatLabel?.trim().isNotEmpty == true)
        _DetailRow('Format', document.formatLabel!.trim()),
      if (document.mimeType?.trim().isNotEmpty == true)
        _DetailRow('Type MIME', document.mimeType!.trim()),
      if (document.sizeLabel != null)
        _DetailRow('Taille', document.sizeLabel!),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SiamoisSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SiamoisSpacing.md),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: SiamoisSpacing.lg),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: SiamoisColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// Visualisation plein écran d’une image (zoom / déplacement).
class _DocumentImageViewerDialog extends StatefulWidget {
  const _DocumentImageViewerDialog({
    required this.title,
    required this.loadBytes,
    this.initialBytes,
  });

  final String title;
  final Uint8List? initialBytes;
  final Future<Uint8List?> Function() loadBytes;

  @override
  State<_DocumentImageViewerDialog> createState() =>
      _DocumentImageViewerDialogState();
}

class _DocumentImageViewerDialogState extends State<_DocumentImageViewerDialog> {
  Uint8List? _bytes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bytes = widget.initialBytes;
    if (_bytes == null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await widget.loadBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
        if (bytes == null || bytes.isEmpty) {
          _error = 'Impossible de charger l’image.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erreur : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SiamoisSpacing.sm,
                vertical: SiamoisSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _bytes != null
                          ? InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 5,
                              child: Center(
                                child: Image.memory(
                                  _bytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
