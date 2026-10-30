import 'package:flutter_test/flutter_test.dart';
import 'package:siamois_mobile/features/projects/form/project_entity_type.dart';
import 'package:siamois_mobile/features/projects/form/project_form_models.dart';
import 'package:siamois_mobile/features/projects/vocabulary_models.dart';

/// Forme de `GET /projects/{id}/recording-unit-types` sur Siamois `main`.
const _catalog = {
  'data': [
    {
      'id': '4290',
      'concept': {'id': '4290', 'resolvedLabel': 'Couche'},
      'formBundle': {
        'resourceType': 'forms',
        'layoutJson':
            '{"sections":[{"title":"Général","rows":[{"columns":[{"fieldId":-301},{"fieldId":501}]}]}]}',
      },
      'fields': {
        '-301': {
          'id': '-301',
          'label': 'Type',
          'answerType': 'SELECT_ONE',
          'fieldCode': 'SIARU.TYPE',
          'valueBinding': 'type',
          'vocabulary': {
            'source': {'kind': 'FIELD_CODE', 'fieldCode': 'SIARU.TYPE'},
            'mode': 'FOLLOW',
          },
        },
        '501': {
          'id': '501',
          'label': 'Épaisseur',
          'answerType': 'DECIMAL',
          'vocabulary': null,
        },
        '502': {
          'id': '502',
          'label': 'Période',
          'answerType': 'SELECT_ONE',
          'vocabulary': {
            'source': {'kind': 'BRANCH', 'topTermConceptId': '99'},
            'mode': 'FOLLOW',
          },
        },
      },
    },
    {
      'id': '4291',
      'concept': {'id': '4291', 'resolvedLabel': 'Fait'},
      'fields': <String, dynamic>{},
    },
  ],
  'fields': {
    // Le catalogue racine ne porte jamais `vocabulary`.
    '501': {'id': '501', 'label': 'Épaisseur', 'answerType': 'DECIMAL'},
  },
};

void main() {
  test('parseCatalog lit les types de data[] (ids en chaîne)', () {
    final types = ProjectEntityType.parseCatalog(_catalog);
    expect(types.map((t) => t.typeConceptId), [4290, 4291]);
    expect(types.first.label, 'Couche');
    expect(types.first.option.id, 4290);
  });

  test('parseCatalog tolère une réponse vide ou invalide', () {
    expect(ProjectEntityType.parseCatalog(null), isEmpty);
    expect(ProjectEntityType.parseCatalog({'data': 'x'}), isEmpty);
    expect(ProjectEntityType.parseCatalog({'data': []}), isEmpty);
  });

  test('vocabularyFields : champs à liste, avec ou sans fieldCode', () {
    final type = ProjectEntityType.parseCatalog(_catalog).first;
    final refs = type.vocabularyFields;
    expect(refs.map((r) => r.fieldId), unorderedEquals(['-301', '502']));
    expect(
      refs.firstWhere((r) => r.fieldId == '-301').fieldCode,
      'SIARU.TYPE',
    );
    expect(refs.firstWhere((r) => r.fieldId == '502').fieldCode, isNull);
  });

  test('toFormBody se lit comme l\'ancien creation-form', () {
    final type = ProjectEntityType.parseCatalog(_catalog).first;
    final definition = ProjectFormDefinition.fromApiData(type.toFormBody());
    expect(definition.fieldsById.keys, containsAll([-301, 501, 502]));
    expect(definition.panels, isNotEmpty);
    expect(
      definition.fieldsById[501]!.normalizedType,
      ProjectAnswerType.decimal,
    );
  });

  test('ConceptOption lit un ResolvedConceptResource', () {
    final option = ConceptOption.fromAutocompleteJson(
      {'id': '12', 'resolvedLabel': 'Argile'},
    );
    expect(option?.id, 12);
    expect(option?.label, 'Argile');
  });
}
