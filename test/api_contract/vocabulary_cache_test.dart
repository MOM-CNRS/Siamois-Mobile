import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siamois_mobile/core/database/app_database.dart';
import 'package:siamois_mobile/core/database/vocabulary_cache.dart';
import 'package:siamois_mobile/features/projects/form/project_entity_type.dart';
import 'package:siamois_mobile/features/projects/vocabulary_models.dart';

const _org = 1;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.organisations).insert(
          OrganisationsCompanion.insert(id: const Value(_org), nom: 'Org'),
        );
  });
  tearDown(() => db.close());

  Future<void> save({
    String? projectId,
    int? typeConceptId,
    required String fieldId,
    String? fieldCode,
    required List<ConceptOption> concepts,
  }) =>
      VocabularyCache.saveFieldConcepts(
        db,
        organisationId: _org,
        projectId: projectId,
        typeConceptId: typeConceptId,
        fieldId: fieldId,
        fieldCode: fieldCode,
        concepts: concepts,
        total: concepts.length,
      );

  test('la liste du projet / type prime sur celle de l\'organisation', () async {
    await save(
      fieldId: '10',
      fieldCode: 'SIARU.CHRONO',
      concepts: const [ConceptOption(id: 1, label: 'Tout')],
    );
    await save(
      projectId: 'p1',
      typeConceptId: 7,
      fieldId: '10',
      fieldCode: 'SIARU.CHRONO',
      concepts: const [ConceptOption(id: 2, label: 'Branche A')],
    );

    final scoped = await VocabularyCache.loadByFieldCode(
      db,
      organisationId: _org,
      projectId: 'p1',
      typeConceptId: 7,
    );
    expect(scoped['SIARU.CHRONO']!.map((o) => o.id), [2]);

    final other = await VocabularyCache.loadByFieldCode(
      db,
      organisationId: _org,
      projectId: 'p2',
    );
    expect(other['SIARU.CHRONO']!.map((o) => o.id), [1]);
  });

  test('sans filtre : union dédoublonnée, et clé par fieldId', () async {
    await save(
      projectId: 'p1',
      typeConceptId: 7,
      fieldId: '10',
      fieldCode: 'X',
      concepts: const [
        ConceptOption(id: 1, label: 'a'),
        ConceptOption(id: 2, label: 'b'),
      ],
    );
    await save(
      projectId: 'p2',
      typeConceptId: 7,
      fieldId: '10',
      fieldCode: 'X',
      concepts: const [
        ConceptOption(id: 2, label: 'b'),
        ConceptOption(id: 3, label: 'c'),
      ],
    );
    await save(
      projectId: 'p1',
      fieldId: '11',
      concepts: const [ConceptOption(id: 9, label: 'sans code')],
    );

    final all = await VocabularyCache.loadByFieldCode(db, organisationId: _org);
    expect(all['X']!.map((o) => o.id), [1, 2, 3]);
    expect(VocabularyCache.optionsForFieldId(all, '11').single.id, 9);
  });

  test('catalogue : lecture par projet et union', () async {
    Map<String, dynamic> body(String id, String label) => {
          'data': [
            {
              'id': id,
              'concept': {'id': id, 'resolvedLabel': label},
              'fields': <String, dynamic>{},
            },
          ],
        };
    await VocabularyCache.saveCatalog(
      db,
      organisationId: _org,
      kind: ProjectTypeKind.find,
      projectId: 'p1',
      body: body('1', 'Céramique'),
    );
    await VocabularyCache.saveCatalog(
      db,
      organisationId: _org,
      kind: ProjectTypeKind.find,
      projectId: 'p2',
      body: body('2', 'Os'),
    );

    final p1 = await VocabularyCache.loadTypes(
      db,
      organisationId: _org,
      kind: ProjectTypeKind.find,
      projectId: 'p1',
    );
    expect(p1.map((t) => t.label), ['Céramique']);

    final all = await VocabularyCache.loadTypes(
      db,
      organisationId: _org,
      kind: ProjectTypeKind.find,
    );
    expect(all.map((t) => t.typeConceptId), unorderedEquals([1, 2]));

    final none = await VocabularyCache.loadTypes(
      db,
      organisationId: _org,
      kind: ProjectTypeKind.recordingUnit,
    );
    expect(none, isEmpty);
  });
}
