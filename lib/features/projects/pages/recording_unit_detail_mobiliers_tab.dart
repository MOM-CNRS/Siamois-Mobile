import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../auth/auth_repository.dart';
import '../mobiliers/mobilier_form_page.dart';
import '../mobiliers/mobilier_list_store.dart';
import '../recording_units/recording_unit_detail_models.dart';

/// Onglet Mobiliers d'une unité d'enregistrement.
class RecordingUnitDetailMobiliersTab extends StatefulWidget {
  const RecordingUnitDetailMobiliersTab({
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
  State<RecordingUnitDetailMobiliersTab> createState() =>
      _RecordingUnitDetailMobiliersTabState();
}

class _RecordingUnitDetailMobiliersTabState
    extends State<RecordingUnitDetailMobiliersTab>
    with AutomaticKeepAliveClientMixin {
  final _items = <MobilierItem>[];
  final _scrollController = ScrollController();

  String? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _offlineMode = false;
  int _total = 0;

  static const _pageSize = 20;

  late final MobilierListStore _store;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _store = MobilierListStore(
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

  Future<void> _load({required bool reset, bool fromServer = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
      });
    }

    try {
      final page = fromServer
          ? await _store.refreshFromNetwork(
              recordingUnitId: widget.recordingUnitId,
              limit: _pageSize,
            )
          : await _store.loadPage(
              recordingUnitId: widget.recordingUnitId,
              offset: 0,
              limit: _pageSize,
            );
      final offline = await widget.auth.isOfflineEnvironment();
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final page = await _store.loadPage(
        recordingUnitId: widget.recordingUnitId,
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
      widget.onListChanged?.call();
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
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobilierFormPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: widget.recordingUnitId,
        ),
      ),
    );
    if (result != null) await _load(reset: true);
  }

  Future<void> _openMobilier(MobilierItem item, {bool readOnly = true}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobilierFormPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: widget.recordingUnitId,
          mobilier: item,
          readOnly: readOnly,
        ),
      ),
    );
    if (result != null) await _load(reset: true);
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
                onPressed: () => _load(reset: true, fromServer: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_offlineMode && _items.isNotEmpty)
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
        if (_items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _offlineMode
                        ? 'Aucun mobilier en cache'
                        : 'Aucun mobilier',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _offlineMode
                        ? 'Ouvrez l’onglet Mobiliers en ligne au moins une fois '
                            'pour consulter la liste hors connexion.'
                        : 'Ajoutez un mobilier à cette unité d’enregistrement.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _load(reset: true, fromServer: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Actualiser'),
                  ),
                ],
              ),
            ),
          )
        else
          RefreshIndicator(
            onRefresh: () => _load(reset: true, fromServer: true),
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                _offlineMode ? 44 : 12,
                16,
                88,
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
                      _total == 1 ? '1 mobilier' : '$_total mobiliers',
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

                return _MobilierTile(
                  item: _items[itemIndex],
                  theme: theme,
                  onTap: () => _openMobilier(_items[itemIndex]),
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
            label: const Text('Mobilier'),
          ),
        ),
      ],
    );
  }
}

class _MobilierTile extends StatelessWidget {
  const _MobilierTile({
    required this.item,
    required this.theme,
    required this.onTap,
  });

  final MobilierItem item;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final metaParts = <String>[];
    if (item.typeLabel != null) metaParts.add(item.typeLabel!);
    if (item.collectionDateLabel != null) {
      metaParts.add('Collecte : ${item.collectionDateLabel}');
    }

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
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.onTertiaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayCode,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
    );
  }
}
