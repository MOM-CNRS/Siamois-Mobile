import 'dart:convert';

import '../../features/projects/form/project_entity_type.dart';
import '../../features/projects/vocabulary_models.dart';
import 'app_database.dart';
import 'tables.dart';

/// Concepts par champ et catalogues de types, pré-chargés à la synchro.
///
/// Stockage dans la table `forms` (pas de migration) :
/// - `CONCEPTS|{projectId|-}|{typeConceptId|-}|{fieldId}` : liste d'un champ ;
/// - `TYPES|{kind}|{projectId}` : réponse brute d'un catalogue de types.
abstract final class VocabularyCache {
  /// Préfixe de clé pour un champ lu par son identifiant.
  static const fieldIdKeyPrefix = '#';

  static const _ttlDays = 1;

  static Future<void> saveFieldConcepts(
    AppDatabase db, {
    required int organisationId,
    String? projectId,
    int? typeConceptId,
    required String fieldId,
    String? fieldCode,
    required List<ConceptOption> concepts,
    required int total,
  }) {
    return db.replaceForm(
      organisationId: organisationId,
      type: FormCacheType.fieldConcepts(
        projectId: projectId,
        typeConceptId: typeConceptId,
        fieldId: fieldId,
      ),
      contenuJson: jsonEncode({
        'fieldId': fieldId,
        'fieldCode': fieldCode,
        'total': total,
        'concepts': [
          for (final c in concepts) {'id': c.id, 'label': c.label},
        ],
      }),
      ttlDays: _ttlDays,
    );
  }

  /// `fieldCode` (et `#fieldId`) → options, pour un projet / type donné.
  ///
  /// Sans filtre : union de toutes les listes en cache. Avec `projectId` et/ou
  /// `typeConceptId` : pour chaque champ, la liste la plus spécifique.
  static Future<Map<String, List<ConceptOption>>> loadByFieldCode(
    AppDatabase db, {
    required int organisationId,
    String? projectId,
    int? typeConceptId,
  }) async {
    final rows = await db.findFormsByTypePrefix(
      organisationId: organisationId,
      prefix: FormCacheType.conceptsPrefix,
    );

    final byKey = <String, List<({int specificity, List<ConceptOption> options})>>{};
    for (final row in rows) {
      final parts = row.type.split('|');
      if (parts.length < 4) continue;
      final rowProject = parts[1];
      final rowType = parts[2];
      if (projectId != null && rowProject != '-' && rowProject != projectId) {
        continue;
      }
      if (typeConceptId != null &&
          rowType != '-' &&
          rowType != typeConceptId.toString()) {
        continue;
      }
      final map = db.decodeFormMap(row);
      final concepts = map?['concepts'];
      if (map == null || concepts is! List) continue;

      final options = <ConceptOption>[
        for (final c in concepts)
          if (c is Map && c['id'] is num && c['label'] != null)
            ConceptOption(
              id: (c['id'] as num).toInt(),
              label: c['label'].toString(),
            ),
      ];
      final specificity =
          (rowProject != '-' ? 1 : 0) + (rowType != '-' ? 1 : 0);
      final code = map['fieldCode']?.toString().trim();
      final keys = <String>[
        if (code != null && code.isNotEmpty) code,
        '$fieldIdKeyPrefix${parts[3]}',
      ];
      for (final key in keys) {
        byKey
            .putIfAbsent(key, () => [])
            .add((specificity: specificity, options: options));
      }
    }

    final filtered = projectId != null || typeConceptId != null;
    final out = <String, List<ConceptOption>>{};
    for (final entry in byKey.entries) {
      var candidates = entry.value;
      if (filtered) {
        final best = candidates
            .map((c) => c.specificity)
            .reduce((a, b) => a > b ? a : b);
        candidates = candidates.where((c) => c.specificity == best).toList();
      }
      final seen = <int>{};
      out[entry.key] = [
        for (final c in candidates)
          for (final o in c.options)
            if (seen.add(o.id)) o,
      ];
    }
    return out;
  }

  /// Options d'un champ lu par son identifiant (`#fieldId`).
  static List<ConceptOption> optionsForFieldId(
    Map<String, List<ConceptOption>> vocabByCode,
    String fieldId,
  ) =>
      vocabByCode['$fieldIdKeyPrefix$fieldId'] ?? const [];

  static Future<void> saveCatalog(
    AppDatabase db, {
    required int organisationId,
    required ProjectTypeKind kind,
    required String projectId,
    required Map<String, dynamic> body,
  }) {
    return db.replaceForm(
      organisationId: organisationId,
      type: FormCacheType.typeCatalog(kind.apiSegment, projectId),
      contenuJson: jsonEncode(body),
      ttlDays: _ttlDays,
    );
  }

  /// Types d'un projet ; sans `projectId`, union des types de tous les projets
  /// en cache (dédoublonnée par concept).
  static Future<List<ProjectEntityType>> loadTypes(
    AppDatabase db, {
    required int organisationId,
    required ProjectTypeKind kind,
    String? projectId,
  }) async {
    final rows = projectId != null
        ? [
            await db.findCachedForm(
              organisationId: organisationId,
              type: FormCacheType.typeCatalog(kind.apiSegment, projectId),
            ),
          ]
        : await db.findFormsByTypePrefix(
            organisationId: organisationId,
            prefix: 'TYPES|${kind.apiSegment}|',
          );

    final out = <int, ProjectEntityType>{};
    for (final row in rows) {
      if (row == null) continue;
      for (final type in ProjectEntityType.parseCatalog(db.decodeFormMap(row))) {
        out.putIfAbsent(type.typeConceptId, () => type);
      }
    }
    return out.values.toList()..sort((a, b) => a.label.compareTo(b.label));
  }

  /// Un type précis ; sans `projectId`, le premier trouvé dans les projets en cache.
  static Future<ProjectEntityType?> findType(
    AppDatabase db, {
    required int organisationId,
    required ProjectTypeKind kind,
    required int typeConceptId,
    String? projectId,
  }) async {
    final types = await loadTypes(
      db,
      organisationId: organisationId,
      kind: kind,
      projectId: projectId,
    );
    for (final t in types) {
      if (t.typeConceptId == typeConceptId) return t;
    }
    return null;
  }

  /// Types de projet / catégories de lieu : liste d'un champ d'organisation.
  static Future<List<ConceptOption>> loadOrganisationOptions(
    AppDatabase db, {
    required int organisationId,
    required String fieldCode,
  }) async {
    final vocab = await loadByFieldCode(db, organisationId: organisationId);
    return ConceptOption.optionsForFieldCode(vocab, fieldCode);
  }
}
