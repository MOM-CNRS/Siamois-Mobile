import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/sync/outbox_store.dart';
import '../../auth/auth_repository.dart';
import 'project_form_models.dart';
import 'spatial_unit_local_id.dart';
import 'spatial_unit_models.dart';

/// Cache local des lieux + création hors ligne avec synchronisation différée.
class SpatialUnitStore {
  SpatialUnitStore({
    required AuthRepository auth,
    required AppDatabase db,
  })  : _auth = auth,
        _db = db;

  final AuthRepository _auth;
  final AppDatabase _db;

  Future<bool> _isOnline() => _auth.canUseProjectsApi();

  /// Recherche locale puis API si en ligne et cache insuffisant.
  Future<List<SpatialUnitOption>> search({
    required int organizationId,
    required String query,
    int limit = 20,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final local = await _searchCached(
      organizationId: organizationId,
      query: q,
      limit: limit,
    );
    if (local.length >= limit) return local;

    if (!await _isOnline()) return local;

    try {
      final remote = await _auth.searchSpatialUnits(
        organizationId: organizationId,
        query: q,
        limit: limit,
      );
      if (remote.isEmpty) return local;

      await _upsertOptions(
        organizationId: organizationId,
        places: remote,
        pendingSync: false,
      );

      final merged = <int, SpatialUnitOption>{};
      for (final item in [...local, ...remote]) {
        merged[item.id] = item;
      }
      return _filterByQuery(merged.values.toList(), q, limit);
    } on AuthException {
      return local;
    }
  }

  List<SpatialUnitOption> _filterByQuery(
    List<SpatialUnitOption> items,
    String query,
    int limit,
  ) {
    final lower = query.toLowerCase();
    return items
        .where(
          (p) =>
              p.label.toLowerCase().contains(lower) ||
              (p.code?.toLowerCase().contains(lower) ?? false),
        )
        .take(limit)
        .toList();
  }

  /// Crée un lieu en ligne ou localement (file d’attente outbox).
  Future<SpatialUnitOption> create(CreateSpatialUnitRequest request) async {
    if (await _isOnline()) {
      try {
        final created = await _auth.createSpatialUnit(request);
        await _upsertOptions(
          organizationId: request.organizationId,
          places: [created],
          pendingSync: false,
          typeConceptId: request.typeConceptId,
          address: request.address,
        );
        return created;
      } on AuthException {
        // Repli hors ligne si l’API n’est pas disponible.
      }
    }

    final localId = await _db.nextLocalPlaceId(
      organisationId: request.organizationId,
    );
    final option = SpatialUnitOption(
      id: localId,
      label: request.name.trim(),
      code: null,
    );

    await _upsertOptions(
      organizationId: request.organizationId,
      places: [option],
      pendingSync: true,
      typeConceptId: request.typeConceptId,
      address: request.address,
    );

    await OutboxStore(_db).enqueuePlaceCreate(
      localPlaceId: localId,
      organizationId: request.organizationId,
      request: request,
    );

    return option;
  }

  /// Modifie un lieu en ligne ou localement (file d’attente outbox).
  Future<SpatialUnitOption> update({
    required int placeId,
    required CreateSpatialUnitRequest request,
  }) async {
    final orgId = request.organizationId;
    final existing = await _db.cachedPlaceRow(
      organisationId: orgId,
      placeId: placeId,
    );
    final isLocal = SpatialUnitLocalId.isLocalId(placeId);

    if (await _isOnline() && !isLocal) {
      try {
        final updated = await _auth.updateSpatialUnit(
          placeId: placeId,
          request: request,
        );
        await _upsertOptions(
          organizationId: orgId,
          places: [updated],
          pendingSync: false,
          typeConceptId: request.typeConceptId,
          address: request.address,
        );
        return updated;
      } on AuthException {
        // Repli hors ligne.
      }
    }

    final option = SpatialUnitOption(
      id: placeId,
      label: request.name.trim(),
      code: existing?.code,
    );

    await _upsertOptions(
      organizationId: orgId,
      places: [option],
      pendingSync: true,
      typeConceptId: request.typeConceptId,
      address: request.address,
    );

    final outbox = OutboxStore(_db);
    if (isLocal) {
      await outbox.updatePlaceCreate(
        localPlaceId: placeId,
        organizationId: orgId,
        request: request,
      );
    } else {
      await outbox.enqueuePlaceUpdate(
        placeId: placeId,
        organizationId: orgId,
        request: request,
      );
    }

    return option;
  }

  Future<PlaceListItem?> getPlaceListItem({
    required int organizationId,
    required int placeId,
  }) async {
    final row = await _db.cachedPlaceRow(
      organisationId: organizationId,
      placeId: placeId,
    );
    if (row == null) return null;
    return _mapCachedRow(row);
  }

  Future<PlaceListItem> createItem(CreateSpatialUnitRequest request) async {
    final option = await create(request);
    final item = await getPlaceListItem(
      organizationId: request.organizationId,
      placeId: option.id,
    );
    if (item != null) return item;
    return PlaceListItem(
      place: option,
      pendingSync: SpatialUnitLocalId.isLocalId(option.id),
      typeConceptId: request.typeConceptId,
      address: request.address,
    );
  }

  Future<PlaceListItem> updateItem({
    required int placeId,
    required CreateSpatialUnitRequest request,
  }) async {
    final option = await update(placeId: placeId, request: request);
    final item = await getPlaceListItem(
      organizationId: request.organizationId,
      placeId: option.id,
    );
    if (item != null) return item;
    return PlaceListItem(
      place: option,
      pendingSync: true,
      typeConceptId: request.typeConceptId,
      address: request.address,
    );
  }

  /// Supprime un lieu en ligne ou localement (file d’attente outbox).
  Future<void> delete({
    required int placeId,
    required int organizationId,
  }) async {
    final isLocal = SpatialUnitLocalId.isLocalId(placeId);
    final outbox = OutboxStore(_db);

    if (isLocal) {
      await outbox.removePlaceActions(placeId);
      await _db.deleteCachedPlace(
        organisationId: organizationId,
        placeId: placeId,
      );
      return;
    }

    if (await _isOnline()) {
      await _auth.deleteSpatialUnit(
        placeId: placeId,
        organizationId: organizationId,
      );
      await outbox.removePlaceActions(placeId);
      await _db.deleteCachedPlace(
        organisationId: organizationId,
        placeId: placeId,
      );
      return;
    }

    await _db.markCachedPlacePendingDelete(
      organisationId: organizationId,
      placeId: placeId,
    );
    await outbox.enqueuePlaceDelete(
      placeId: placeId,
      organizationId: organizationId,
    );
  }

  /// Charge le détail pour édition (cache puis API).
  Future<PlaceDetail?> loadDetailForEdit({
    required int organizationId,
    required int placeId,
  }) async {
    final cached = await _db.cachedPlaceRow(
      organisationId: organizationId,
      placeId: placeId,
    );
    FullAddressOption? cachedAddress;
    if (cached?.addressJson != null && cached!.addressJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached.addressJson!);
        cachedAddress = FullAddressOption.fromJson(decoded);
      } catch (_) {}
    }

    if (cached != null &&
        (cached.typeConceptId != null || cachedAddress != null)) {
      return PlaceDetail(
        id: placeId,
        name: cached.name,
        code: cached.code,
        typeConceptId: cached.typeConceptId,
        address: cachedAddress,
      );
    }

    if (await _isOnline() && !SpatialUnitLocalId.isLocalId(placeId)) {
      try {
        final detail = await _auth.fetchPlaceDetail(
          organizationId: organizationId,
          placeId: placeId,
        );
        await _db.upsertCachedPlace(
          organisationId: organizationId,
          placeId: detail.id,
          name: detail.name,
          code: detail.code,
          pendingSync: cached?.pendingSync ?? false,
          typeConceptId: detail.typeConceptId,
          addressJson: detail.address == null
              ? null
              : jsonEncode(detail.address!.toJson()),
        );
        return detail;
      } on AuthException {
        // Cache partiel ci-dessous.
      }
    }

    if (cached == null) return null;
    return PlaceDetail(
      id: placeId,
      name: cached.name,
      code: cached.code,
      typeConceptId: cached.typeConceptId,
      address: cachedAddress,
    );
  }

  /// Télécharge toutes les pages et remplace le cache organisation.
  Future<int> syncFromApi({required int organizationId}) async {
    final places = await _auth.fetchAllOrganizationPlaces(
      organizationId: organizationId,
    );
    await _db.replaceCachedPlacesForOrganisation(
      organisationId: organizationId,
      places: places
          .map(
            (p) => (
              placeId: p.id,
              name: p.label,
              code: p.code,
            ),
          )
          .toList(),
    );
    return places.length;
  }

  Future<int> cachedCount(int organizationId) =>
      _db.countCachedPlaces(organisationId: organizationId);

  Future<bool> isOnline() => _isOnline();

  /// Liste tous les lieux en cache (recherche optionnelle, sans limite).
  Future<List<PlaceListItem>> listAll({
    required int organizationId,
    String query = '',
  }) async {
    final raw = await _db.listCachedPlacesRaw(
      organisationId: organizationId,
      query: query.trim().isEmpty ? null : query.trim(),
    );
    return raw.map(_mapCachedRow).toList();
  }

  PlaceListItem _mapCachedRow(
    ({
      int placeId,
      String name,
      String? code,
      bool pendingSync,
      bool pendingDelete,
      int? typeConceptId,
      String? addressJson,
    }) r,
  ) {
    FullAddressOption? address;
    if (r.addressJson != null && r.addressJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(r.addressJson!);
        address = FullAddressOption.fromJson(decoded);
      } catch (_) {}
    }
    return PlaceListItem(
      place: SpatialUnitOption(
        id: r.placeId,
        label: r.name,
        code: r.code,
      ),
      pendingSync: r.pendingSync,
      pendingDelete: r.pendingDelete,
      typeConceptId: r.typeConceptId,
      address: address,
    );
  }

  Future<List<SpatialUnitOption>> _searchCached({
    required int organizationId,
    required String query,
    required int limit,
  }) async {
    final raw = await _db.searchCachedPlacesRaw(
      organisationId: organizationId,
      query: query,
      limit: limit,
    );
    return raw
        .map(
          (r) => SpatialUnitOption(
            id: r.placeId,
            label: r.name,
            code: r.code,
          ),
        )
        .toList();
  }

  Future<void> _upsertOptions({
    required int organizationId,
    required List<SpatialUnitOption> places,
    required bool pendingSync,
    int? typeConceptId,
    FullAddressOption? address,
    bool pendingDelete = false,
  }) {
    return _db.upsertCachedPlaces(
      organisationId: organizationId,
      places: places
          .map(
            (p) => (
              placeId: p.id,
              name: p.label,
              code: p.code,
            ),
          )
          .toList(),
      pendingSync: pendingSync,
      typeConceptId: typeConceptId,
      addressJson:
          address == null ? null : jsonEncode(address.toJson()),
      pendingDelete: pendingDelete,
    );
  }
}
