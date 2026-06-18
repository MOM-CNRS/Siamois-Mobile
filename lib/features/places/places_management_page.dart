import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/routes.dart';
import '../../core/sync/app_sync_status_scope.dart';
import '../../core/sync/app_sync_status_service.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/ui/siamois_empty_state.dart';
import '../../core/widgets/ui/siamois_entity_tile.dart';
import '../../core/widgets/ui/siamois_messenger.dart';
import '../../core/widgets/ui/siamois_message_banner.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import '../auth/auth_repository.dart';
import '../projects/form/spatial_unit_create_sheet.dart';
import '../projects/form/spatial_unit_local_id.dart';
import '../projects/form/spatial_unit_models.dart';
import '../projects/form/spatial_unit_store.dart';
import '../projects/vocabulary_models.dart';

class PlacesManagementPage extends StatefulWidget {
  const PlacesManagementPage({
    super.key,
    required this.auth,
    required this.database,
  });

  final AuthRepository auth;
  final AppDatabase database;

  @override
  State<PlacesManagementPage> createState() => _PlacesManagementPageState();
}

class _PlacesManagementPageState extends State<PlacesManagementPage> {
  late final SpatialUnitStore _store;
  List<PlaceListItem> _places = const [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  bool _refreshing = false;
  bool _listLoading = true;

  @override
  void initState() {
    super.initState();
    _store = SpatialUnitStore(
      auth: widget.auth,
      db: widget.database,
      connectivity: widget.auth.connectivity,
    );
    _reloadPlaces();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int? get _organizationId => widget.auth.primaryOrganizationId;

  Future<void> _reloadPlaces({bool showLoading = false}) async {
    if (showLoading && mounted) setState(() => _listLoading = true);
    final items = await _load();
    if (!mounted) return;
    setState(() {
      _places = items;
      _listLoading = false;
    });
  }

  void _upsertPlaceInList(PlaceListItem item) {
    final index = _places.indexWhere((p) => p.place.id == item.place.id);
    final next = List<PlaceListItem>.from(_places);
    if (index >= 0) {
      next[index] = item;
    } else {
      next.add(item);
      next.sort(
        (a, b) => a.place.label.toLowerCase().compareTo(
              b.place.label.toLowerCase(),
            ),
      );
    }
    setState(() => _places = next);
  }

  void _removePlaceFromList(int placeId) {
    setState(() {
      _places = _places.where((p) => p.place.id != placeId).toList();
    });
  }

  Future<List<PlaceListItem>> _load() async {
    final orgId = _organizationId;
    if (orgId == null) return const [];
    return _store.listAll(
      organizationId: orgId,
      query: _searchQuery,
    );
  }

  Future<void> _refresh({bool syncFromServer = true}) async {
    final orgId = _organizationId;
    if (orgId == null) return;

    setState(() => _refreshing = true);
    try {
      if (syncFromServer && await _store.isOnline()) {
        final count = await _store.syncFromApi(organizationId: orgId);
        if (mounted) {
          context.showInfoMessage(
            '$count lieu${count > 1 ? 'x' : ''} synchronisé${count > 1 ? 's' : ''}.',
          );
        }
      } else if (syncFromServer && mounted) {
        context.showInfoMessage(
          'Hors connexion : affichage du cache local.',
        );
      }
      if (!mounted) return;
      await AppSyncStatusScope.maybeOf(context)?.notifier?.refresh();
      await _reloadPlaces();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      setState(() => _searchQuery = trimmed);
      _reloadPlaces(showLoading: true);
    });
  }

  Future<void> _logout() async {
    await widget.auth.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  Future<void> _openCreatePlace() async {
    final orgId = _organizationId;
    if (orgId == null) {
      context.showInfoMessage(
        'Organisation introuvable. Reconnectez-vous pour créer un lieu.',
      );
      return;
    }

    final created = await showSpatialUnitCreateSheet(
      context: context,
      store: _store,
      auth: widget.auth,
      organizationId: orgId,
    );
    if (!mounted || created == null) return;

    if (_searchQuery.isNotEmpty) {
      _searchController.clear();
      _searchQuery = '';
    }

    _upsertPlaceInList(created);
    await _reloadPlaces();

    if (!mounted) return;
    final pending = created.pendingSync ||
        SpatialUnitLocalId.isLocalId(created.place.id);
    context.showInfoMessage(
      pending
          ? 'Lieu « ${created.place.label} » enregistré localement.'
          : 'Lieu « ${created.place.label} » créé.',
    );
  }

  void _showPlaceDetails(PlaceListItem item) {
    final orgId = _organizationId;
    if (orgId == null) return;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) {
        return _PlaceDetailSheet(
          item: item,
          organizationId: orgId,
          store: _store,
          auth: widget.auth,
          onEdit: () {
            Navigator.of(ctx).pop();
            _openEditPlace(item);
          },
          onDelete: () {
            Navigator.of(ctx).pop();
            _confirmDeletePlace(item);
          },
        );
      },
    );
  }

  Future<void> _openEditPlace(PlaceListItem item) async {
    final orgId = _organizationId;
    if (orgId == null) return;

    final updated = await showSpatialUnitEditSheet(
      context: context,
      store: _store,
      auth: widget.auth,
      organizationId: orgId,
      item: item,
    );
    if (!mounted || updated == null) return;

    _upsertPlaceInList(updated);
    await _reloadPlaces();

    if (!mounted) return;
    final pending =
        updated.pendingSync || SpatialUnitLocalId.isLocalId(updated.place.id);
    context.showInfoMessage(
      pending
          ? 'Lieu « ${updated.place.label} » enregistré localement.'
          : 'Lieu « ${updated.place.label} » modifié.',
    );
  }

  Future<void> _confirmDeletePlace(PlaceListItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline_rounded, color: SiamoisColors.error),
          title: const Text('Supprimer ce lieu ?'),
          content: Text(
            'Le lieu « ${item.place.label} » sera supprimé. '
            'Cette action sera synchronisée avec le serveur si vous êtes connecté.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: SiamoisColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final orgId = _organizationId;
    if (orgId == null) return;

    try {
      await _store.delete(
        placeId: item.place.id,
        organizationId: orgId,
      );
      if (!mounted) return;
      _removePlaceFromList(item.place.id);
      context.showInfoMessage('Lieu « ${item.place.label} » supprimé.');
    } on AuthException catch (e) {
      if (mounted) context.showErrorMessage(e.message);
    } catch (e) {
      if (mounted) context.showErrorMessage('Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.auth.userProfile;
    final orgId = _organizationId;
    final syncScope = AppSyncStatusScope.maybeOf(context);
    final syncService = syncScope?.notifier;

    return SiamoisScaffold(
      title: 'Gestion des lieux',
      subtitle: profile?.organizationLine,
      drawerHeaderSubtitle: profile?.organizationLine,
      onLogout: _logout,
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _refreshing ? null : () => _refresh(),
          icon: _refreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
      toolbar: _PlacesSearchToolbar(
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
      ),
      floatingActionButton: orgId != null
          ? FloatingActionButton.extended(
              onPressed: _openCreatePlace,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Nouveau lieu'),
            )
          : null,
      body: orgId == null
          ? const SiamoisEmptyState(
              icon: Icons.business_outlined,
              title: 'Organisation introuvable',
              subtitle: 'Reconnectez-vous pour accéder aux lieux.',
            )
          : _listLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _refresh(syncFromServer: true),
                  child: _buildPlacesList(
                    context: context,
                    theme: theme,
                    places: _places,
                    syncService: syncService,
                  ),
                ),
    );
  }

  Widget _buildPlacesList({
    required BuildContext context,
    required ThemeData theme,
    required List<PlaceListItem> places,
    required AppSyncStatusService? syncService,
  }) {
    final isSearching = _searchQuery.isNotEmpty;
    final pendingCount = places.where((p) => p.pendingSync).length;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (syncService != null)
          SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: syncService,
              builder: (context, _) {
                if (syncService.isConnected) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SiamoisSpacing.lg,
                    SiamoisSpacing.md,
                    SiamoisSpacing.lg,
                    0,
                  ),
                  child: SiamoisMessageBanner(
                    kind: SiamoisMessageKind.info,
                    message:
                        'Mode hors connexion : les lieux affichés proviennent du cache local. '
                        'Les créations seront synchronisées à la reconnexion.',
                  ),
                );
              },
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SiamoisSpacing.lg,
              SiamoisSpacing.md,
              SiamoisSpacing.lg,
              SiamoisSpacing.sm,
            ),
            child: Text(
              places.isEmpty
                  ? 'Aucun lieu'
                  : '${places.length} lieu${places.length > 1 ? 'x' : ''}'
                      '${pendingCount > 0 ? ' · $pendingCount en attente de sync' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: SiamoisColors.textSecondary,
              ),
            ),
          ),
        ),
        if (places.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: SiamoisEmptyState(
              icon: Icons.place_outlined,
              title: isSearching ? 'Aucun résultat' : 'Aucun lieu en cache',
              subtitle: isSearching
                  ? 'Essayez un autre terme de recherche.'
                  : 'Synchronisez l’application ou créez un premier lieu.',
              actionLabel: isSearching ? null : 'Actualiser',
              onAction: isSearching ? null : () => _refresh(),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              SiamoisSpacing.lg,
              0,
              SiamoisSpacing.lg,
              SiamoisSpacing.xxl * 2,
            ),
            sliver: SliverList.separated(
              itemCount: places.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: SiamoisSpacing.sm),
              itemBuilder: (context, index) {
                final item = places[index];
                final place = item.place;
                final isLocal = SpatialUnitLocalId.isLocalId(place.id);
                final subtitle = [
                  if (isLocal) 'En attente de synchronisation',
                ].whereType<String>().join(' · ');

                return SiamoisEntityTile(
                  title: place.label,
                  subtitle: subtitle.isEmpty ? null : subtitle,
                  leading: Icon(
                    isLocal || item.pendingSync
                        ? Icons.cloud_upload_outlined
                        : Icons.place_outlined,
                    color: isLocal || item.pendingSync
                        ? SiamoisColors.warning
                        : SiamoisColors.primary,
                  ),
                  trailing: isLocal || item.pendingSync
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: SiamoisColors.warning
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: SiamoisColors.warning
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Local',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: SiamoisColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => _showPlaceDetails(item),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Panneau de détail d’un lieu (contenu + actions en bas).
class _PlaceDetailSheet extends StatefulWidget {
  const _PlaceDetailSheet({
    required this.item,
    required this.organizationId,
    required this.store,
    required this.auth,
    required this.onEdit,
    required this.onDelete,
  });

  final PlaceListItem item;
  final int organizationId;
  final SpatialUnitStore store;
  final AuthRepository auth;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<_PlaceDetailSheet> {
  PlaceDetail? _loadedDetail;
  String? _categoryLabel;

  @override
  void initState() {
    super.initState();
    _resolveCategoryLabel(widget.item.typeConceptId);
    _enrichFromServer();
  }

  int? get _typeConceptId =>
      _loadedDetail?.typeConceptId ?? widget.item.typeConceptId;

  FullAddressOption? get _address =>
      _loadedDetail?.address ?? widget.item.address;

  Future<void> _enrichFromServer() async {
    final detail = await widget.store.loadDetailForEdit(
      organizationId: widget.organizationId,
      placeId: widget.item.place.id,
    );
    if (!mounted || detail == null) return;
    setState(() => _loadedDetail = detail);
    await _resolveCategoryLabel(detail.typeConceptId);
  }

  Future<void> _resolveCategoryLabel(int? typeConceptId) async {
    if (typeConceptId == null) return;
    try {
      final fromApi = await widget.auth.fetchVocabulariesByFieldCode(
        organizationId: widget.organizationId,
      );
      final categories =
          ConceptOption.spatialUnitCategoriesFromVocabularies(fromApi);
      ConceptOption? match;
      for (final category in categories) {
        if (category.id == typeConceptId) {
          match = category;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _categoryLabel = match?.label ?? 'Catégorie $typeConceptId';
      });
    } on AuthException {
      if (!mounted) return;
      setState(() {
        _categoryLabel = _categoryLabel ?? 'Catégorie $typeConceptId';
      });
    }
  }

  String _displayValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = widget.item.place;
    final isLocal = SpatialUnitLocalId.isLocalId(place.id);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SiamoisSpacing.lg,
        SiamoisSpacing.md,
        SiamoisSpacing.lg,
        SiamoisSpacing.xl + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            place.label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SiamoisSpacing.md),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailRow(label: 'Nom', value: place.label),
                  _DetailRow(
                    label: 'Identifiant',
                    value: isLocal ? '${place.id} (local)' : '${place.id}',
                  ),
                  _DetailRow(
                    label: 'Catégorie',
                    value: _typeConceptId == null
                        ? '—'
                        : _displayValue(
                            _categoryLabel ?? 'Catégorie $_typeConceptId',
                          ),
                  ),
                  _DetailRow(
                    label: 'Adresse',
                    value: _displayValue(_address?.label),
                  ),
                  if (widget.item.pendingSync || isLocal) ...[
                    const SizedBox(height: SiamoisSpacing.sm),
                    const SiamoisMessageBanner(
                      kind: SiamoisMessageKind.info,
                      message:
                          'Ce lieu sera envoyé au serveur lors de la prochaine synchronisation.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: SiamoisSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
              ),
              const SizedBox(width: SiamoisSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SiamoisColors.error,
                    side: const BorderSide(color: SiamoisColors.error),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Supprimer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: SiamoisSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _PlacesSearchToolbar extends StatefulWidget {
  const _PlacesSearchToolbar({
    required this.searchController,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  State<_PlacesSearchToolbar> createState() => _PlacesSearchToolbarState();
}

class _PlacesSearchToolbarState extends State<_PlacesSearchToolbar> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _PlacesSearchToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onControllerChanged);
      widget.searchController.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _clearSearch() {
    widget.searchController.clear();
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SiamoisSpacing.lg,
        0,
        SiamoisSpacing.lg,
        SiamoisSpacing.md,
      ),
      child: TextField(
        controller: widget.searchController,
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un lieu…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: widget.searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Effacer',
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SiamoisSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: SiamoisColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
