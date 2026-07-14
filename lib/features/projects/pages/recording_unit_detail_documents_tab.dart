import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/app_sync_status_scope.dart';
import '../../../core/sync/entity_sync_state.dart';
import '../../../core/widgets/sync/siamois_unsynced_indicator.dart';
import '../../../core/widgets/ui/siamois_list_screen_layout.dart';
import '../../../core/widgets/ui/siamois_messenger.dart';
import '../../auth/auth_repository.dart';
import '../documents/document_form_page.dart';
import '../documents/document_tmp_models.dart';
import '../documents/document_tmp_store.dart';
import '../documents/recording_unit_document_store.dart';
import '../project_detail_models.dart';
import 'document_detail_page.dart';

/// Onglet Documents d'une unité d'enregistrement.
class RecordingUnitDetailDocumentsTab extends StatefulWidget {
  const RecordingUnitDetailDocumentsTab({
    super.key,
    required this.auth,
    required this.database,
    required this.recordingUnitId,
    this.onListChanged,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String recordingUnitId;
  final VoidCallback? onListChanged;

  @override
  State<RecordingUnitDetailDocumentsTab> createState() =>
      _RecordingUnitDetailDocumentsTabState();
}

class _RecordingUnitDetailDocumentsTabState
    extends State<RecordingUnitDetailDocumentsTab>
    with AutomaticKeepAliveClientMixin {
  List<ProjectDocumentItem>? _documents;
  Map<String, EntitySyncState> _syncStates = {};
  String? _error;
  bool _loading = true;

  late final RecordingUnitDocumentStore _store;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _store = RecordingUnitDocumentStore(
      auth: widget.auth,
      db: widget.database,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await _store.loadForRecordingUnit(widget.recordingUnitId);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _loading = false;
      });
      await _loadSyncStates(docs);
      widget.onListChanged?.call();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentFormPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: widget.recordingUnitId,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _loadSyncStates(List<ProjectDocumentItem> docs) async {
    final service = AppSyncStatusScope.maybeOf(context)?.notifier;
    if (service == null || !mounted) return;

    final map = <String, EntitySyncState>{};
    for (final doc in docs) {
      map[doc.id] = await service.documentSyncState(doc.id);
    }
    if (!mounted) return;
    setState(() => _syncStates = map);
  }

  Future<void> _openDetail(ProjectDocumentItem doc) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: widget.recordingUnitId,
          document: doc,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _confirmDelete(ProjectDocumentItem doc) async {
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
        await DocumentTmpStore(db: widget.database, auth: widget.auth).remove(
          DocumentTmpEntry.localIdFromListId(doc.id),
        );
      } else {
        await widget.auth.deleteDocument(doc.id);
        await _store.removeLocal(doc.id);
        await widget.database.deleteDocumentTmpByResourceId(doc.id);
      }
      if (!mounted) return;
      context.showInfoMessage('Document supprimé.');
      await AppSyncStatusScope.maybeOf(context)?.notifier?.refresh();
      await _load();
    } on AuthException catch (e) {
      if (!mounted) return;
      context.showErrorMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage('Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    final docs = _documents ?? const [];

    return SiamoisListScreenLayout(
      offlineDetail: 'Les documents affichés proviennent du cache local.',
      child: Stack(
        children: [
          docs.isEmpty
              ? _EmptyState(onRefresh: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return _DocumentTile(
                        document: doc,
                        theme: theme,
                        syncState:
                            _syncStates[doc.id] ?? EntitySyncState.synced,
                        onTap: () => _openDetail(doc),
                        onDelete: () => _confirmDelete(doc),
                      );
                    },
                  ),
                ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Document'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.theme,
    required this.syncState,
    required this.onTap,
    required this.onDelete,
  });

  final ProjectDocumentItem document;
  final ThemeData theme;
  final EntitySyncState syncState;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  IconData _iconForMime(String? mime) {
    if (mime == null) return Icons.insert_drive_file_outlined;
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('zip') || mime.contains('compressed')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForMime(document.mimeType),
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (syncState.needsSyncIndicator) ...[
                        const SizedBox(width: 8),
                        SiamoisUnsyncedIndicator(state: syncState),
                      ],
                    ],
                  ),
                  subtitle: _buildSubtitle(colorScheme),
                  isThreeLine:
                      document.subtitle != null || document.sizeLabel != null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton.filledTonal(
                  tooltip: 'Supprimer',
                  onPressed: onDelete,
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    backgroundColor:
                        colorScheme.errorContainer.withValues(alpha: 0.45),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildSubtitle(ColorScheme colorScheme) {
    final children = <Widget>[];
    if (document.subtitle != null) {
      children.add(
        Text(
          document.subtitle!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    if (document.sizeLabel != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 2));
      children.add(
        Text(
          document.sizeLabel!,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    if (children.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun document',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez un document à cette unité d’enregistrement.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
