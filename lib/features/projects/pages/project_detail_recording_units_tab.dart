import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/app_sync_status_scope.dart';
import '../../../core/sync/entity_sync_state.dart';
import '../../../core/widgets/sync/siamois_unsynced_indicator.dart';
import '../../../core/widgets/ui/siamois_list_screen_layout.dart';
import '../../../core/widgets/ui/siamois_list_summary_bar.dart';
import '../../auth/auth_repository.dart';
import '../project_detail_models.dart';
import '../recording_units/recording_unit_list_store.dart';
import '../recording_units/recording_unit_tree.dart';
import 'create_recording_unit_page.dart';
import 'recording_unit_detail_page.dart';

/// Onglet UE : liste paginée (API en ligne, cache SQLite hors ligne).
class ProjectDetailRecordingUnitsTab extends StatefulWidget {
  const ProjectDetailRecordingUnitsTab({
    super.key,
    required this.auth,
    required this.database,
    required this.projectId,
    this.onListChanged,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String projectId;
  final VoidCallback? onListChanged;

  @override
  State<ProjectDetailRecordingUnitsTab> createState() =>
      _ProjectDetailRecordingUnitsTabState();
}

class _ProjectDetailRecordingUnitsTabState
    extends State<ProjectDetailRecordingUnitsTab>
    with AutomaticKeepAliveClientMixin {
  final _items = <RecordingUnitItem>[];
  final _displayEntries = <RecordingUnitTreeEntry>[];
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String? _error;
  bool _loading = true;
  bool _offlineMode = false;
  bool _isSearchActive = false;
  int _total = 0;
  String _searchQuery = '';
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      _searchQuery = trimmed;
      if (trimmed.isEmpty) {
        _load(reset: true);
      } else {
        _runSearch(trimmed);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
      _isSearchActive = true;
    });

    try {
      if (await _store.isOnline) {
        try {
          await _store.syncFullListFromNetwork(widget.projectId);
        } on AuthException {
          // Filtre sur le cache déjà présent.
        }
      }

      final all = await _store.loadAllFromCacheForProject(widget.projectId);
      final filtered =
          all.where((u) => _recordingUnitMatchesQuery(u, query)).toList();
      final offline = await widget.auth.isOfflineEnvironment();

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(filtered);
        _displayEntries
          ..clear()
          ..addAll(
            filtered
                .map((unit) => RecordingUnitTreeEntry(unit: unit, depth: 0))
                .toList(),
          );
        _total = filtered.length;
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

  void _onScroll() {
    // La liste arborescente charge l’intégralité du cache projet.
  }

  List<RecordingUnitTreeEntry> _buildDisplayEntries(List<RecordingUnitItem> items) {
    return RecordingUnitTree.flatten(items);
  }

  Future<void> _refreshHierarchyInBackground() async {
    if (!await _store.isOnline) return;
    try {
      await _store.syncFullListFromNetwork(widget.projectId);
      if (!mounted || _isSearchActive) return;
      await _load(reset: false);
    } catch (_) {
      // Le cache affiché reste valide.
    }
  }

  Future<void> _load({required bool reset, bool fromServer = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _displayEntries.clear();
      });
    }

    try {
      if (fromServer && await _store.isOnline) {
        await _store.syncFullListFromNetwork(widget.projectId);
      } else if (reset && await _store.isOnline) {
        _store.scheduleFullListSyncFromNetwork(widget.projectId);
      }

      if (await _store.isOnline) {
        final cachedCount =
            (await _store.loadAllFromCacheForProject(widget.projectId)).length;
        if (cachedCount == 0) {
          await _store.loadPage(
            projectId: widget.projectId,
            offset: 0,
            limit: _pageSize,
          );
        }
      }

      final cached = await _store.loadAllFromCacheForProject(widget.projectId);
      final offline = await widget.auth.isOfflineEnvironment();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(cached);
        _displayEntries
          ..clear()
          ..addAll(_buildDisplayEntries(cached));
        _total = cached.length;
        _isSearchActive = false;
        _offlineMode = offline;
        _loading = false;
      });
      widget.onListChanged?.call();

      if (reset && await _store.isOnline) {
        unawaited(_refreshHierarchyInBackground());
      }
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
    Navigator.of(context)
        .push<Object?>(
      MaterialPageRoute(
        builder: (_) => RecordingUnitDetailPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: unit.id,
          projectId: widget.projectId,
          summary: unit,
        ),
      ),
    )
        .then((_) {
      if (mounted) _load(reset: true);
    });
  }

  Widget _createUeFab() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle UE'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) {
      return SiamoisListScreenLayout(
        toolbar: _RecordingUnitSearchBar(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        offlineDetail: 'Les unités affichées proviennent du cache local.',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SiamoisListScreenLayout(
        toolbar: _RecordingUnitSearchBar(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        offlineDetail: 'Les unités affichées proviennent du cache local.',
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _load(reset: true, fromServer: true),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
            _createUeFab(),
          ],
        ),
      );
    }

    final isSearching = _searchQuery.isNotEmpty;
    final listEmpty = _displayEntries.isEmpty && !isSearching;
    final summaryCount = isSearching ? _displayEntries.length : _total;

    return SiamoisListScreenLayout(
      toolbar: _RecordingUnitSearchBar(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onClear: _clearSearch,
      ),
      offlineDetail: 'Les unités affichées proviennent du cache local.',
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!listEmpty)
                SiamoisListSummaryBar(
                  count: summaryCount,
                  singularLabel: 'UE',
                  pluralLabel: 'UE',
                  icon: Icons.layers_outlined,
                  isSearching: isSearching,
                  searchQuery: _searchQuery,
                ),
              Expanded(
                child: listEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.layers_outlined,
                                size: 56,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
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
                                    : 'Créez une première UE pour ce projet.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _load(reset: true, fromServer: true),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Actualiser'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () {
                          if (_searchQuery.isNotEmpty) {
                            return _runSearch(_searchQuery);
                          }
                          return _load(reset: true, fromServer: true);
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                          itemCount: isSearching && _displayEntries.isEmpty
                              ? 1
                              : _displayEntries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (isSearching && _displayEntries.isEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.45),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Aucune UE ne correspond à « $_searchQuery ».',
                                      textAlign: TextAlign.center,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final entry = _displayEntries[index];
                            return _RecordingUnitTile(
                              unit: entry.unit,
                              depth: entry.depth,
                              theme: theme,
                              onTap: () => _openUnit(entry.unit),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          _createUeFab(),
        ],
      ),
    );
  }
}

bool _recordingUnitMatchesQuery(RecordingUnitItem unit, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  bool contains(String? value) {
    if (value == null) return false;
    return value.trim().toLowerCase().contains(q);
  }

  return contains(unit.displayCode) ||
      contains(unit.identifier) ||
      contains(unit.typeLabel);
}

class _RecordingUnitSearchBar extends StatelessWidget {
  const _RecordingUnitSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasQuery = controller.text.isNotEmpty;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SearchBar(
          controller: controller,
          hintText: 'Rechercher par code ou libellé…',
          leading: const Icon(Icons.search_rounded, size: 22),
          trailing: hasQuery
              ? [
                  IconButton(
                    tooltip: 'Effacer',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ]
              : const [],
          onChanged: onChanged,
          onSubmitted: onChanged,
        ),
      ),
    );
  }
}

class _RecordingUnitTile extends StatelessWidget {
  const _RecordingUnitTile({
    required this.unit,
    required this.depth,
    required this.theme,
    required this.onTap,
  });

  final RecordingUnitItem unit;
  final int depth;
  final ThemeData theme;
  final VoidCallback onTap;

  static const _indentPerLevel = 18.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final metaParts = <String>[];
    if (unit.typeLabel != null) metaParts.add(unit.typeLabel!);
    if (unit.placeLabel != null) metaParts.add(unit.placeLabel!);
    if (unit.dateRangeLabel != null) metaParts.add(unit.dateRangeLabel!);

    return Padding(
      padding: EdgeInsets.only(left: depth * _indentPerLevel),
      child: Material(
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
                if (depth > 0) ...[
                  Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    depth == 0
                        ? Icons.layers_outlined
                        : Icons.layers_rounded,
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
