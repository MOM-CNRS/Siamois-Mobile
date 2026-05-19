import '../vocabulary_models.dart';

/// Types de champs du formulaire document (`GET /api/v1/documents/form`).
abstract final class DocumentInputType {
  static const text = 'TEXT';
  static const textArea = 'TEXTAREA';
  static const conceptSelect = 'CONCEPT_SELECT';
  static const file = 'FILE';

  static String normalize(String? raw) => (raw ?? '').trim().toUpperCase();
}

class DocumentFormField {
  const DocumentFormField({
    required this.fieldKey,
    required this.inputType,
    required this.label,
    this.fieldCode,
    this.maxLength,
    this.isRequired = false,
  });

  final String fieldKey;
  final String inputType;
  final String label;
  final String? fieldCode;
  final int? maxLength;
  final bool isRequired;

  String get normalizedType => DocumentInputType.normalize(inputType);

  static DocumentFormField? fromJson(Map<String, dynamic> json) {
    final key = (json['fieldKey'] as String?)?.trim();
    if (key == null || key.isEmpty) return null;

    final inputType =
        (json['inputType'] as String?) ?? DocumentInputType.text;
    return DocumentFormField(
      fieldKey: key,
      inputType: inputType,
      label: labelForKey(key),
      fieldCode: (json['fieldCode'] as String?)?.trim(),
      maxLength: _int(json['maxLength']),
      isRequired: key == 'title' || key == 'file',
    );
  }

  static String labelForKey(String key) {
    const labels = {
      'title': 'Titre',
      'description': 'Description',
      'nature': 'Nature',
      'scale': 'Échelle',
      'format': 'Format',
      'file': 'Fichier',
    };
    return labels[key] ?? key;
  }

  static int? _int(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}

/// Valeurs courantes pour l’édition (`currentValues` dans la réponse form).
class DocumentFormCurrentValues {
  const DocumentFormCurrentValues({
    this.title,
    this.description,
    this.nature,
    this.scale,
    this.format,
    this.fileName,
    this.mimeType,
  });

  final String? title;
  final String? description;
  final ConceptOption? nature;
  final ConceptOption? scale;
  final ConceptOption? format;
  final String? fileName;
  final String? mimeType;

  factory DocumentFormCurrentValues.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DocumentFormCurrentValues();
    return DocumentFormCurrentValues(
      title: _str(json['title']),
      description: _str(json['description']),
      nature: ConceptOption.fromAutocompleteJson(json['nature']),
      scale: ConceptOption.fromAutocompleteJson(json['scale']),
      format: ConceptOption.fromAutocompleteJson(json['format']),
      fileName: _str(json['fileName']),
      mimeType: _str(json['mimeType']),
    );
  }

  static String? _str(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}

class DocumentFormDefinition {
  const DocumentFormDefinition({
    required this.fields,
    this.currentValues,
  });

  final List<DocumentFormField> fields;
  final DocumentFormCurrentValues? currentValues;

  factory DocumentFormDefinition.fromApiData(dynamic data) {
    if (data is! Map) {
      return const DocumentFormDefinition(fields: []);
    }
    final root = Map<String, dynamic>.from(data);
    final inner = root['data'];
    final payload = inner is Map ? Map<String, dynamic>.from(inner) : root;

    final fieldsRaw = payload['fields'];
    final fields = <DocumentFormField>[];
    if (fieldsRaw is List) {
      for (final item in fieldsRaw) {
        if (item is Map) {
          final field = DocumentFormField.fromJson(Map<String, dynamic>.from(item));
          if (field != null) fields.add(field);
        }
      }
    }

    final currentRaw = payload['currentValues'];
    DocumentFormCurrentValues? current;
    if (currentRaw is Map) {
      current = DocumentFormCurrentValues.fromJson(
        Map<String, dynamic>.from(currentRaw),
      );
    }

    return DocumentFormDefinition(fields: fields, currentValues: current);
  }
}

/// État de saisie du formulaire document.
class DocumentFormState {
  final Map<String, String> textValues = {};
  final Map<String, int?> conceptValues = {};
  String? pickedFilePath;
  String? pickedFileName;

  void applyCurrentValues(DocumentFormCurrentValues? values) {
    if (values == null) return;
    if (values.title != null) textValues['title'] = values.title!;
    if (values.description != null) {
      textValues['description'] = values.description!;
    }
    if (values.nature != null) conceptValues['nature'] = values.nature!.id;
    if (values.scale != null) conceptValues['scale'] = values.scale!.id;
    if (values.format != null) conceptValues['format'] = values.format!.id;
    pickedFileName = values.fileName;
  }

  List<ConceptOption> conceptsForField(
    DocumentFormField field,
    Map<String, List<ConceptOption>> vocabByCode,
  ) {
    final code = field.fieldCode;
    if (code != null && vocabByCode.containsKey(code)) {
      return vocabByCode[code] ?? const [];
    }
    return const [];
  }

  Map<String, dynamic> buildPatchPayload() {
    return {
      if (textValues.containsKey('title'))
        'title': textValues['title']?.trim(),
      if (textValues.containsKey('description'))
        'description': textValues['description']?.trim(),
      if (conceptValues['nature'] != null)
        'natureConceptId': conceptValues['nature'],
      if (conceptValues['scale'] != null) 'scaleConceptId': conceptValues['scale'],
      if (conceptValues['format'] != null)
        'formatConceptId': conceptValues['format'],
    };
  }
}
