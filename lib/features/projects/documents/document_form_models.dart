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

  String get normalizedType {
    switch (fieldKey) {
      case 'title':
        return DocumentInputType.text;
      case 'description':
        return DocumentInputType.textArea;
      default:
        break;
    }
    final normalized = DocumentInputType.normalize(inputType);
    if (normalized.isEmpty) return DocumentInputType.text;
    return normalized;
  }

  /// Longueur max utilisable par [TextFormField] (0 ou négatif = illimité).
  int? get effectiveMaxLength {
    final value = maxLength;
    if (value == null || value <= 0) return null;
    return value;
  }

  static DocumentFormField? fromJson(Map<String, dynamic> json) {
    final key = (json['fieldKey'] as String?)?.trim();
    if (key == null || key.isEmpty) return null;

    final inputType =
        (json['inputType'] as String?) ?? DocumentInputType.text;
    final label = (json['label'] as String?)?.trim();
    return DocumentFormField(
      fieldKey: key,
      inputType: inputType,
      label: label != null && label.isNotEmpty ? label : labelForKey(key),
      fieldCode: (json['fieldCode'] as String?)?.trim(),
      maxLength: _int(json['maxLength']),
      isRequired: _isRequiredFromJson(json, key),
    );
  }

  static bool _isRequiredFromJson(Map<String, dynamic> json, String key) {
    if (_truthy(json['isRequired']) || _truthy(json['required'])) {
      return true;
    }
    return key == 'title' || key == 'file';
  }

  static bool _truthy(dynamic raw) {
    if (raw == true) return true;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes' || s == 'oui';
    }
    return false;
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

    return DocumentFormDefinition(
      fields: ensureRequiredFields(fields),
      currentValues: current,
    );
  }

  static List<DocumentFormField> ensureRequiredFields(
    List<DocumentFormField> fields,
  ) {
    const fallbacks = [
      DocumentFormField(
        fieldKey: 'title',
        inputType: DocumentInputType.text,
        label: 'Titre',
        maxLength: 50,
        isRequired: true,
      ),
      DocumentFormField(
        fieldKey: 'description',
        inputType: DocumentInputType.textArea,
        label: 'Description',
        isRequired: false,
      ),
      DocumentFormField(
        fieldKey: 'file',
        inputType: DocumentInputType.file,
        label: 'Fichier',
        isRequired: true,
      ),
    ];

    final keys = fields.map((f) => f.fieldKey).toSet();
    final merged = List<DocumentFormField>.from(fields);
    if (!keys.contains('title')) {
      merged.insert(0, fallbacks[0]);
    }
    if (!keys.contains('description')) {
      final fileIdx = merged.indexWhere((f) => f.fieldKey == 'file');
      merged.insert(fileIdx >= 0 ? fileIdx : merged.length, fallbacks[1]);
    }
    if (!keys.contains('file')) {
      merged.add(fallbacks[2]);
    }
    return merged;
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

  DocumentPatchPayload buildPatchPayload() {
    return DocumentPatchPayload(
      title: textValues['title']?.trim(),
      description: textValues['description']?.trim(),
      natureConceptId: conceptValues['nature'],
      scaleConceptId: conceptValues['scale'],
      formatConceptId: conceptValues['format'],
    );
  }
}

/// Corps de `PATCH /api/v1/documents/{id}` (métadonnées uniquement, pas le fichier).
class DocumentPatchPayload {
  const DocumentPatchPayload({
    this.title,
    this.description,
    this.natureConceptId,
    this.scaleConceptId,
    this.formatConceptId,
  });

  final String? title;
  final String? description;
  final int? natureConceptId;
  final int? scaleConceptId;
  final int? formatConceptId;

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (natureConceptId != null) 'natureConceptId': natureConceptId,
      if (scaleConceptId != null) 'scaleConceptId': scaleConceptId,
      if (formatConceptId != null) 'formatConceptId': formatConceptId,
    };
  }
}
