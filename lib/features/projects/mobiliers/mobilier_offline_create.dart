import '../form/project_form_models.dart';
import '../recording_units/recording_unit_detail_models.dart';

/// Construit un mobilier local (cache + file d’attente) avant envoi serveur.
abstract final class MobilierOfflineCreate {
  static MobilierItem buildListItem({
    required String listId,
    required String? typeLabel,
    required ProjectFormDefinition definition,
    required Map<String, dynamic> fieldAnswers,
  }) {
    return MobilierItem(
      id: listId,
      displayCode: _displayCode(definition, fieldAnswers) ??
          'Mobilier (hors ligne)',
      typeLabel: typeLabel,
    );
  }

  static String? _displayCode(
    ProjectFormDefinition definition,
    Map<String, dynamic> fieldAnswers,
  ) {
    final identifier = _valueForBinding(
      definition,
      fieldAnswers,
      'identifier',
    );
    if (identifier != null && identifier.isNotEmpty) return identifier;

    final name = _valueForBinding(definition, fieldAnswers, 'name');
    if (name != null && name.isNotEmpty) return name;

    final full = _valueForBinding(
      definition,
      fieldAnswers,
      'fullIdentifier',
    );
    if (full != null && full.isNotEmpty) return full;

    return null;
  }

  static String? _valueForBinding(
    ProjectFormDefinition definition,
    Map<String, dynamic> fieldAnswers,
    String binding,
  ) {
    for (final field in definition.fields) {
      if (field.valueBinding != binding) continue;
      final raw = fieldAnswers['${field.fieldId}'];
      final text = raw?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
