import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/app_sync_status_scope.dart';
import '../../../core/sync/entity_sync_state.dart';
import '../../../core/widgets/sync/siamois_unsynced_indicator.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import '../recording_units/recording_unit_list_store.dart';
import 'create_recording_unit_page.dart';
import 'recording_unit_detail_page.dart';

/// Onglet UE : liste paginée des unités d’enregistrement du projet.
class ProjectDetailRecordingUnitsTab extends StatefulWidget {
  const ProjectDetailRecordingUnitsTab({
    super.key,
    required this.auth,
    required this.database,
    required this.projectId,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String projectId;

  @override
  State<ProjectDetailRecordingUnitsTab> createState() =>
      _ProjectDetailRecordingUnitsTabState();
}

class _ProjectDetailRecordingUnitsTabState
    extends State<ProjectDetailRecordingUnitsTab>
    with AutomaticKeepAliveClientMixin {
  final _items = <RecordingUnitItem>[];
  final _scrollController = ScrollController();

  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _offlineMode = false;
  int _total = 0;

  static const _pageSize = 20;

  late final RecordingUnitListStore _store;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _store = RecordingUnitListStore(
      auth: widget.auth,
      db: widget.database,
    );
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
      });
    }

    try {
      final offline = !await _store.isOnline;
      final page = await _store.loadPage(
        projectId: widget.projectId,
        offset: 0,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _hasMore = page.hasMore;
        _offlineMode = offline;
        _loading = false;
      });
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final page = await _store.loadPage(
        projectId: widget.projectId,
        offset: _items.length,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() => _loadingMore = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<RecordingUnitItem>(
      MaterialPageRoute(
        builder: (_) => CreateRecordingUnitPage(
          auth: widget.auth,
          database: widget.database,
          projectId: widget.projectId,
        ),
      ),
    );
    if (created != null && mounted) {
      await _load(reset: true);
    }
  }

  void _openUnit(RecordingUnitItem unit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordingUnitDetailPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: unit.id,
          projectId: widget.projectId,
          summary: unit,
        ),
      ),
    ).then((_) {
      if (mounted) _load(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.layers_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _offlineMode
                    ? 'Aucune UE en cache'
                    : 'Aucune unité d’enregistrement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _offlineMode
                    ? 'Ouvrez l’onglet UE en ligne au moins une fois pour '
                        'consulter la liste hors connexion.'
                    : 'Les UE de ce projet apparaîtront ici.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualiser'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          if (_offlineMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: theme.colorScheme.tertiaryContainer.withValues(
                  alpha: 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Mode hors ligne — liste issue du cache local.',
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                _offlineMode ? 44 : 12,
                16,
                24,
              ),
              itemCount: 1 + _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, index) {
          if (index >= _items.length) return const SizedBox.shrink();
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _total == 1 ? '1 UE' : '$_total UE',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final itemIndex = index - 1;
          if (itemIndex >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return _RecordingUnitTile(
            unit: _items[itemIndex],
            theme: theme,
            onTap: () => _openUnit(_items[itemIndex]),
          );
        },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle UE'),
      ),
    );
  }
}

class _RecordingUnitTile extends StatelessWidget {
  const _RecordingUnitTile({
    required this.unit,
    required this.theme,
    required this.onTap,
  });

  final RecordingUnitItem unit;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final metaParts = <String>[];
    if (unit.typeLabel != null) metaParts.add(unit.typeLabel!);
    if (unit.placeLabel != null) metaParts.add(unit.placeLabel!);
    if (unit.dateRangeLabel != null) metaParts.add(unit.dateRangeLabel!);

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.layers_outlined,
                color: colorScheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit.displayCode,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _UnsyncedUeBadge(recordingUnitId: unit.id),
                    ],
                  ),
                  if (metaParts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      metaParts.join(' · '),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (unit.specimenCount != null ||
                      unit.stratigraphicCount != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (unit.specimenCount != null)
                          _CountChip(
                            label: unit.specimenCount == 1
                                ? '1 mobilier'
                                : '${unit.specimenCount} mobiliers',
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        if (unit.stratigraphicCount != null)
                          _CountChip(
                            label: unit.stratigraphicCount == 1
                                ? '1 relation strat.'
                                : '${unit.stratigraphicCount} rel. strat.',
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _UnsyncedUeBadge extends StatelessWidget {
  const _UnsyncedUeBadge({required this.recordingUnitId});

  final String recordingUnitId;

  @override
  Widget build(BuildContext context) {
    final service = AppSyncStatusScope.maybeOf(context)?.notifier;
    if (service == null) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: service.recordingUnitHasUnsyncedContent(recordingUnitId),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return const Padding(
          padding: EdgeInsets.only(left: 8),
          child: SiamoisUnsyncedIndicator(state: EntitySyncState.pending),
        );
      },
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.colorScheme,
    required this.theme,
  });

  final String label;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
