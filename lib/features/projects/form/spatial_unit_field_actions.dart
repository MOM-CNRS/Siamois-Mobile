import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vocabulary_cache.dart';
import '../../auth/auth_repository.dart';
import '../vocabulary_models.dart';
import 'project_form_models.dart';
import 'spatial_unit_create_sheet.dart';
import 'spatial_unit_store.dart';

/// Recherche et création de lieux pour les champs formulaire.
class SpatialUnitFieldActions {
  SpatialUnitFieldActions({
    required AuthRepository auth,
    required AppDatabase database,
  })  : _auth = auth,
        _database = database,
        _store = SpatialUnitStore(
          auth: auth,
          db: database,
        );

  final AuthRepository _auth;
  final AppDatabase _database;
  final SpatialUnitStore _store;

  Future<List<SpatialUnitOption>> search(String query) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) return const [];
    return _store.search(organizationId: orgId, query: query);
  }

  Future<List<ConceptOption>> _loadSpatialCategories(int orgId) async {
    if (await _auth.canUseProjectsApi()) {
      try {
        final fromApi = await _auth.fetchVocabulariesByFieldCode(
          organizationId: orgId,
        );
        final categories =
            ConceptOption.spatialUnitCategoriesFromVocabularies(fromApi);
        if (categories.isNotEmpty) return categories;
      } on AuthException {
        // Repli cache ci-dessous.
      }
    }

    final cached = await VocabularyCache.loadByFieldCode(
      _database,
      organisationId: orgId,
    );
    return ConceptOption.spatialUnitCategoriesFromVocabularies(cached);
  }

  Future<SpatialUnitOption?> createNew(BuildContext context) async {
    final orgId = _auth.primaryOrganizationId;
    if (orgId == null) {
      return null;
    }

    final categories = await _loadSpatialCategories(orgId);

    if (!context.mounted) return null;
    final created = await showSpatialUnitCreateSheet(
      context: context,
      store: _store,
      auth: _auth,
      organizationId: orgId,
      initialCategories: categories,
    );
    return created?.place;
  }
}
