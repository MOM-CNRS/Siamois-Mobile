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
import '../recording_units/recording_unit_favorite_store.dart';
import '../recording_units/recording_unit_list_store.dart';
import 'create_recording_unit_page.dart';
import 'recording_unit_detail_page.dart';

/// Onglet UE : pagination à la demande (scroll infini) pour les gros projets.
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
  final _favoriteIds = <String>{};
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _offlineMode = false;
  int _total = 0;
  int _cachedCount = 0;
  String _searchQuery = '';
  Timer? _searchDebounce;

  static const _pageSize = 50;

  late final RecordingUnitListStore _store;
  late final RecordingUnitFavoriteStore _favorites;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _store = RecordingUnitListStore(
      auth: widget.auth,
      db: widget.database,
    );
    _favorites = RecordingUnitFavoriteStore(
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
      _load(reset: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Si le contenu tient dans l’écran, maxScrollExtent == 0 et la condition
    // ci-dessous serait toujours vraie → téléchargement en chaîne des 13k UE
    // et UI figée (bouton retour inclus).
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 400) return;
    unawaited(_loadMore());
  }

  /// Charge quelques pages de plus si la 1re ne remplit pas l’écran (sans boucle infinie).
  void _scheduleFillViewport({int depth = 0}) {
    if (depth > 4) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_hasMore || _loadingMore || _loading) return;
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent > 0) return;
      await _loadMore();
      if (mounted) _scheduleFillViewport(depth: depth + 1);
    });
  }

  Future<void> _toggleFavorite(RecordingUnitItem unit) async {
    final isFavorite = await _favorites.toggle(
      projectId: widget.projectId,
      resourceId: unit.id,
    );
    if (!mounted) return;
    setState(() {
      if (isFavorite) {
        _favoriteIds.add(unit.id);
      } else {
        _favoriteIds.remove(unit.id);
      }
    });
  }

  Future<RecordingUnitListResult> _fetchPage({required int offset}) {
    if (_searchQuery.isNotEmpty) {
      return _store.searchPage(
        projectId: widget.projectId,
        query: _searchQuery,
        offset: offset,
        limit: _pageSize,
      );
    }
    return _store.loadPage(
      projectId: widget.projectId,
      offset: offset,
      limit: _pageSize,
    );
  }

  Future<void> _load({required bool reset, bool fromServer = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _hasMore = false;
      });
    }

    try {
      // fromServer n’a d’effet qu’en mode liste (pas en recherche cache).
      final page = await _fetchPage(offset: 0);
      final favoriteIds =
          await _favorites.favoriteIdsForProject(widget.projectId);
      final offline = await widget.auth.isOfflineEnvironment();
      final cached = await _store.cachedCount(widget.projectId);
      if (!mounted) return;
      setState(() {
        _favoriteIds
          ..clear()
          ..addAll(favoriteIds);
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total;
        _cachedCount = cached;
        _hasMore = page.hasMore;
        _offlineMode = offline;
        _loading = false;
      });
      widget.onListChanged?.call();
      _scheduleFillViewport();
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
      final page = await _fetchPage(offset: _items.length);
      final cached = await _store.cachedCount(widget.projectId);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _cachedCount = cached;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingMore = false;
        _hasMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
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
        .push(
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

  String get _offlineBannerDetail {
    if (_cachedCount <= 0) {
      return 'Aucune UE en cache local. Ouvrez cet onglet en ligne et faites '
          'défiler la liste pour enregistrer des pages hors connexion.';
    }
    return '$_cachedCount UE en cache local (disponibles hors connexion). '
        'Faites défiler en ligne pour en enregistrer davantage.';
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
        offlineDetail: _offlineBannerDetail,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _items.isEmpty) {
      return SiamoisListScreenLayout(
        toolbar: _RecordingUnitSearchBar(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        offlineDetail: _offlineBannerDetail,
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
    final listEmpty = _items.isEmpty && !isSearching;

    return SiamoisListScreenLayout(
      toolbar: _RecordingUnitSearchBar(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onClear: _clearSearch,
      ),
      offlineDetail: _offlineBannerDetail,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!listEmpty || isSearching)
                SiamoisListSummaryBar(
                  count: _total,
                  singularLabel: 'UE',
                  pluralLabel: 'UE',
                  icon: Icons.layers_outlined,
                  isSearching: isSearching,
                  searchQuery: _searchQuery,
                ),
              if (isSearching && !_offlineMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(
                    'Recherche dans les UE déjà chargées sur cet appareil. '
                    'Faites défiler la liste pour enrichir le cache.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                        onRefresh: () => _load(reset: true, fromServer: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                          itemCount: _itemCount,
                          itemBuilder: (context, index) {
                            if (isSearching && _items.isEmpty) {
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
                                      'Aucune UE ne correspond à « $_searchQuery » '
                                      'dans le cache local.',
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

                            if (index >= _items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final unit = _items[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _items.length - 1 && !_hasMore
                                    ? 0
                                    : 8,
                              ),
                              child: _RecordingUnitTile(
                                unit: unit,
                                theme: theme,
                                isFavorite: _favoriteIds.contains(unit.id),
                                onTap: () => _openUnit(unit),
                                onToggleFavorite: () => _toggleFavorite(unit),
                              ),
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

  int get _itemCount {
    if (_searchQuery.isNotEmpty && _items.isEmpty) return 1;
    if (_hasMore || _loadingMore) return _items.length + 1;
    return _items.length;
  }
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
    required this.theme,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final RecordingUnitItem unit;
  final ThemeData theme;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.displayCode,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metaParts.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFavorite
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              _UnsyncedUeBadge(recordingUnitId: unit.id),
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
