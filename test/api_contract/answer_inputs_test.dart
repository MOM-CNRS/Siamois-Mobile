import 'package:flutter_test/flutter_test.dart';
import 'package:siamois_mobile/features/auth/auth_repository.dart';

void main() {
  test('scalaires, listes et null sont enveloppés en AnswerInput', () {
    final out = AuthRepository.asAnswerInputs({
      '10': 'texte',
      '11': 3,
      '12': true,
      '13': [5, 7],
      '14': null,
      '15': <dynamic>[],
    });
    expect(out['10'], {'value': 'texte'});
    expect(out['11'], {'value': 3});
    expect(out['12'], {'value': true});
    expect(out['13'], {'values': [5, 7]});
    expect(out['14'], {'value': null});
    // Liste vide : vide le champ multiple.
    expect(out['15'], {'values': <dynamic>[]});
  });

  test('une mesure reste un objet sous value', () {
    final measurement = {'numericValue': 2.5, 'symbol': 'm', 'comment': ''};
    final out = AuthRepository.asAnswerInputs({'20': measurement});
    expect(out['20'], {'value': measurement});
  });

  test('add / remove et value / values déjà au bon format sont conservés', () {
    final out = AuthRepository.asAnswerInputs({
      '30': {'add': [1], 'remove': [2]},
      '31': {'value': 'x'},
      '32': {'values': [9]},
    });
    expect(out['30'], {'add': [1], 'remove': [2]});
    expect(out['31'], {'value': 'x'});
    expect(out['32'], {'values': [9]});
  });

  test('aucune réponse : map vide', () {
    expect(AuthRepository.asAnswerInputs(const {}), isEmpty);
  });

  test("l'identifiant saisi n'est pas envoyé dans answers", () {
    final out = AuthRepository.asAnswerInputs({
      '10': 'UE-12',
      'identifier': 'UE-12',
    });
    expect(out.keys, ['10']);
  });
}
