import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/routes.dart';
import '../../core/sync/app_sync_status_scope.dart';
import '../../core/sync/app_sync_status_service.dart';
import '../../core/widgets/sync/sync_conflict_resolution_dialog.dart';
import '../../core/widgets/ui/siamois_messenger.dart';
import '../../core/sync/sync_action_models.dart';
import '../../core/sync/sync_conflict_resolver.dart';
import '../../core/sync/sync_progress.dart';
import '../../core/sync/sync_queue_item_detail_resolver.dart';
import '../../core/sync/sync_queue_models.dart';
import '../../core/sync/sync_queue_service.dart';
import '../../core/sync/sync_route_args.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/ui/siamois_empty_state.dart';
import '../../core/widgets/ui/siamois_error_state.dart';
import '../../core/widgets/ui/siamois_offline_banner.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import '../auth/auth_repository.dart';
import 'sync_queue_item_detail_sheet.dart';

/// Panneau listant les opérations locales en attente d’envoi au serveur.
class SyncQueuePage extends StatefulWidget {
  const SyncQueuePage({
    super.key,
    required this.database,
    required this.auth,
  });

  final AppDatabase database;
  final AuthRepository auth;

  @override
  State<SyncQueuePage> createState() => _SyncQueuePageState();
}

class _SyncQueuePageState extends State<SyncQueuePage> {
  late final SyncQueueService _queue;
  List<SyncQueueItem>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _queue = SyncQueueService(
      widget.database,
      conflictResolver: SyncConflictResolver(
        auth: widget.auth,
        db: widget.database,
      ),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _queue.loadItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      await AppSyncStatusScope.maybeOf(context)?.notifier?.refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _resolveConflict(SyncQueueItem item) async {
    final action = await _queue.outboxActionForItem(item);
    if (action == null || !mounted) return;

    final resolved = await SyncQueueItemDetailResolver(
      auth: widget.auth,
      db: widget.database,
    ).resolve(item: item, action: action);

    if (!mounted) return;

    final choice = await showSyncConflictResolutionDialog(
      context: context,
      entityLabel: item.title,
      payload: item.conflictPayload,
      fieldDiffs: resolved.conflictFieldDiffs,
    );
    if (!mounted || choice == SyncConflictResolution.cancel) return;

    final syncNotifier = AppSyncStatusScope.maybeOf(context)?.notifier;
    try {
      switch (choice) {
        case SyncConflictResolution.useServer:
          await _queue.acceptServerVersion(action);
          if (!mounted) return;
          context.showInfoMessage('Version serveur appliquée localement.');
        case SyncConflictResolution.retryLocal:
          await _queue.retryLocalChanges(action);
          if (!mounted) return;
          context.showInfoMessage(
            'Modifications locales replanifiées. '
            'Relancez la synchronisation.',
          );
        case SyncConflictResolution.cancel:
          return;
      }
      await syncNotifier?.refresh();
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage('Résolution impossible : $e');
    }
  }

  Future<void> _confirmDelete(SyncQueueItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: SiamoisColors.error),
        title: const Text('Supprimer cette opération ?'),
        content: Text(
          '« ${item.title} » sera retirée de la file d’attente. '
          '${item.status == SyncActionStatus.conflict ? 'Le conflit ne sera plus signalé. ' : ''}'
          'Les données locales créées pour cette opération (brouillon) seront '
          'également supprimées le cas échéant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: SiamoisColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final syncNotifier = AppSyncStatusScope.maybeOf(context)?.notifier;
    try {
      await _queue.removeFailedItem(item);
      await syncNotifier?.refresh();
      await _load();
      if (!mounted) return;
      context.showInfoMessage('Opération retirée de la file.');
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage('Impossible de supprimer : $e');
    }
  }

  Future<void> _openItemDetail(SyncQueueItem item) async {
    await showSyncQueueItemDetailSheet(
      context: context,
      queue: _queue,
      item: item,
      database: widget.database,
      auth: widget.auth,
    );
  }

  Future<void> _runSync() async {
    final service = AppSyncStatusScope.maybeOf(context)?.notifier;
    if (service == null || !service.isConnected) {
      if (!mounted) return;
      context.showInfoMessage(
        'Serveur injoignable. Connectez-vous au réseau pour synchroniser.',
      );
      return;
    }

    final result = await Navigator.of(context).pushNamed<SyncRunResult?>(
      AppRoutes.sync,
      arguments: const SyncRouteArgs(
        cameFromOnlineLogin: true,
        manual: true,
        queueOnly: true,
      ),
    );

    if (!mounted) return;
    await service.refresh();
    await _load();
    if (!mounted) return;

    final message = switch (result) {
      SyncRunResult.success => 'Synchronisation terminée.',
      SyncRunResult.conflicts =>
        'Synchronisation terminée avec des conflits à résoudre.',
      SyncRunResult.failures =>
        'Synchronisation terminée avec des erreurs.',
      null => null,
    };
    if (message != null) {
      if (result == SyncRunResult.failures) {
        context.showErrorMessage(message);
      } else {
        context.showInfoMessage(message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = AppSyncStatusScope.maybeOf(context)?.notifier;

    return Scaffold(
      backgroundColor: SiamoisColors.surface,
      appBar: SiamoisTitleBar(
        title: 'Actions à synchroniser',
        showBrandMark: false,
        leading: const BackButton(),
        actions: [
          if (service != null)
            ListenableBuilder(
              listenable: service,
              builder: (context, _) {
                return IconButton(
                  tooltip: 'Synchroniser maintenant',
                  onPressed: service.isSyncing || !service.isConnected
                      ? null
                      : _runSync,
                  icon: service.isSyncing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                );
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SiamoisOfflineBanner(
            detail: 'Les actions en file seront envoyées à la reconnexion.',
          ),
          Expanded(child: _buildBody(theme, service)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppSyncStatusService? service) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return SiamoisErrorState(
        message: _error!,
        onRetry: _load,
      );
    }

    final items = _items ?? const [];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            SiamoisEmptyState(
              icon: Icons.cloud_done_rounded,
              title: 'Rien à synchroniser',
              subtitle:
                  'Les créations, modifications et documents en attente '
                  'apparaîtront ici.',
            ),
          ],
        ),
      );
    }

    final pending = items
        .where(
          (i) =>
              i.status == SyncActionStatus.pending ||
              i.status == SyncActionStatus.uploading,
        )
        .length;
    final errors = items.length - pending;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SiamoisSpacing.pageHorizontal,
          SiamoisSpacing.md,
          SiamoisSpacing.pageHorizontal,
          SiamoisSpacing.xxl,
        ),
        children: [
          if (service != null)
            ListenableBuilder(
              listenable: service,
              builder: (context, _) {
                return _SummaryBanner(
                  total: items.length,
                  pending: pending,
                  errors: errors,
                  isConnected: service.isConnected,
                  isSyncing: service.isSyncing,
                  onSync: service.isSyncing || !service.isConnected
                      ? null
                      : _runSync,
                );
              },
            )
          else
            _SummaryBanner(
              total: items.length,
              pending: pending,
              errors: errors,
              isConnected: false,
              isSyncing: false,
              onSync: null,
            ),
          const SizedBox(height: SiamoisSpacing.lg),
          Text(
            '${items.length} opération${items.length > 1 ? 's' : ''}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: SiamoisColors.textSecondary,
            ),
          ),
          const SizedBox(height: SiamoisSpacing.sm),
          ...items.map(
            (item) => _SyncQueueTile(
              item: item,
              onTap: () => _openItemDetail(item),
              onDelete: item.canDelete ? () => _confirmDelete(item) : null,
              onResolve: item.canResolve ? () => _resolveConflict(item) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.total,
    required this.pending,
    required this.errors,
    required this.isConnected,
    required this.isSyncing,
    this.onSync,
  });

  final int total;
  final int pending;
  final int errors;
  final bool isConnected;
  final bool isSyncing;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SiamoisSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pending_actions_rounded,
                  color: errors > 0
                      ? SiamoisColors.error
                      : SiamoisColors.warning,
                ),
                const SizedBox(width: SiamoisSpacing.sm),
                Expanded(
                  child: Text(
                    '$total en file d’attente'
                    '${errors > 0 ? ' · $errors en erreur' : ''}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SiamoisSpacing.sm),
            Text(
              isConnected
                  ? '$pending en attente d’envoi. '
                      'L’ordre respecte la séquence d’enregistrement.'
                  : 'Hors ligne : les actions seront envoyées '
                      'à la prochaine synchronisation.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: SiamoisColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (onSync != null) ...[
              const SizedBox(height: SiamoisSpacing.md),
              FilledButton.icon(
                onPressed: isSyncing ? null : onSync,
                icon: const Icon(Icons.sync_rounded),
                label: Text(
                  isSyncing ? 'Synchronisation…' : 'Synchroniser maintenant',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncQueueTile extends StatelessWidget {
  const _SyncQueueTile({
    required this.item,
    required this.onTap,
    this.onDelete,
    this.onResolve,
  });

  final SyncQueueItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: SiamoisSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SiamoisSpacing.md,
            SiamoisSpacing.md,
            SiamoisSpacing.md,
            SiamoisSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    child: Icon(
                      _sourceIcon(item.source),
                      size: 20,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: SiamoisSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _StatusChip(
                        label: item.statusLabel,
                        color: statusColor,
                      ),
                      if (onResolve != null)
                        IconButton(
                          onPressed: onResolve,
                          tooltip: 'Résoudre le conflit',
                          icon: const Icon(Icons.compare_arrows_rounded),
                          color: SiamoisColors.warning,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: SiamoisColors.error,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.45),
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
              if (item.listErrorMessage != null) ...[
                const SizedBox(height: SiamoisSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SiamoisSpacing.sm),
                  decoration: BoxDecoration(
                    color: (item.status == SyncActionStatus.conflict
                            ? SiamoisColors.warning
                            : SiamoisColors.error)
                        .withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(SiamoisSpacing.radiusMd),
                    border: Border.all(
                      color: (item.status == SyncActionStatus.conflict
                              ? SiamoisColors.warning
                              : SiamoisColors.error)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    item.listErrorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.status == SyncActionStatus.conflict
                          ? SiamoisColors.warning
                          : SiamoisColors.error,
                    ),
                  ),
                ),
              ],
              if (item.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  _formatWhen(item.createdAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: SiamoisColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _sourceIcon(SyncQueueItemSource source) {
    return switch (source) {
      SyncQueueItemSource.outbox => Icons.edit_note_rounded,
      SyncQueueItemSource.document => Icons.attach_file_rounded,
    };
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'failed' => SiamoisColors.error,
      'conflict' => SiamoisColors.warning,
      'uploading' => SiamoisColors.primary,
      _ => SiamoisColors.textSecondary,
    };
  }

  static String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return 'Enregistré le ${local.day}/${local.month}/${local.year} à $h:$m';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
