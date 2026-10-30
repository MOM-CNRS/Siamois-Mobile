import '../vocabulary_models.dart';

/// Famille de types configurés par projet
/// (`GET /projects/{id}/{apiSegment}-types`).
enum ProjectTypeKind {
  recordingUnit('recording-unit'),
  find('find'),
  document('document');

  const ProjectTypeKind(this.apiSegment);

  final String apiSegment;
}

/// Un champ à liste de concepts d'un type (`fields[fieldId]`).
class VocabularyFieldRef {
  const VocabularyFieldRef({required this.fieldId, this.fieldCode});

  final String fieldId;
  final String? fieldCode;
}

/// Un type du catalogue d'un projet : son concept, son formulaire et ses champs.
class ProjectEntityType {
  const ProjectEntityType({
    required this.typeConceptId,
    required this.label,
    required this.raw,
  });

  final int typeConceptId;
  final String label;

  /// Entrée brute `data[i]` (`formBundle`, `fields`, …).
  final Map<String, dynamic> raw;

  ConceptOption get option => ConceptOption(id: typeConceptId, label: label);

  Map<String, dynamic> get fields => _asMap(raw['fields']);

  /// Corps équivalent à l'ancien `creation-form` / `finds/form`, lisible par
  /// `ProjectFormDefinition.fromApiData`.
  Map<String, dynamic> toFormBody() => {
        'data': {
          'form': raw['formBundle'],
          'fields': fields,
        },
      };

  List<VocabularyFieldRef> get vocabularyFields =>
      vocabularyFieldsOf(fields);

  /// Champs dont la liste de concepts doit être pré-chargée.
  static List<VocabularyFieldRef> vocabularyFieldsOf(
    Map<String, dynamic> fields,
  ) {
    const listTypes = {
      'SELECT_ONE',
      'SELECT_MULTIPLE',
      'SELECT_ONE_FROM_FIELD_CODE',
      'SELECT_MULTIPLE_FROM_FIELD_CODE',
    };
    final out = <VocabularyFieldRef>[];
    for (final entry in fields.entries) {
      final field = entry.value;
      if (field is! Map) continue;
      final code = field['fieldCode']?.toString().trim();
      final hasVocabulary = field['vocabulary'] is Map;
      final answerType = field['answerType']?.toString().toUpperCase();
      final isList = answerType != null && listTypes.contains(answerType);
      if (hasVocabulary || (isList && code != null && code.isNotEmpty)) {
        out.add(VocabularyFieldRef(
          fieldId: entry.key.toString(),
          fieldCode: code == null || code.isEmpty ? null : code,
        ));
      }
    }
    return out;
  }

  /// `data[]` d'une réponse `…-types`.
  static List<ProjectEntityType> parseCatalog(dynamic body) {
    if (body is! Map) return const [];
    final data = body['data'];
    if (data is! List) return const [];
    final out = <ProjectEntityType>[];
    for (final item in data) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final concept = _asMap(map['concept']);
      final id = int.tryParse(
        (map['id'] ?? concept['id'] ?? '').toString(),
      );
      if (id == null) continue;
      final label = (concept['resolvedLabel'] ??
              concept['label'] ??
              concept['prefLabel'] ??
              'Type $id')
          .toString()
          .trim();
      out.add(ProjectEntityType(typeConceptId: id, label: label, raw: map));
    }
    return out;
  }

  static Map<String, dynamic> _asMap(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}
