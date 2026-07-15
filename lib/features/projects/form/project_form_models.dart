import '../vocabulary_models.dart';
import 'form_measurement_value.dart';
import 'form_measurement_form.dart';
import 'form_recording_unit_multi.dart';
import 'person_option.dart';
import 'project_form_layout.dart';
import 'recording_unit_option.dart';

/// Types de champs renvoyés par l’API (`answerType`).
abstract final class ProjectAnswerType {
  static const text = 'TEXT';
  static const integer = 'INTEGER';
  static const measurement = 'MEASUREMENT';
  static const dateTime = 'DATETIME';
  static const selectOneFromFieldCode = 'SELECT_ONE_FROM_FIELD_CODE';
  static const selectMultiple = 'SELECT_MULTIPLE';
  static const selectOneActionCode = 'SELECT_ONE_ACTION_CODE';
  static const selectMultipleSpatialUnitTree =
      'SELECT_MULTIPLE_SPATIAL_UNIT_TREE';
  static const selectOneSpatialUnit = 'SELECT_ONE_SPATIAL_UNIT';
  static const selectMultipleRecordingUnit =
      'SELECT_MULTIPLE_RECORDING_UNIT';
  static const selectOnePerson = 'SELECT_ONE_PERSON';
  static const selectMultiplePerson = 'SELECT_MULTIPLE_PERSON';

  static String normalize(String? raw) => (raw ?? '').trim().toUpperCase();
}

/// Définition d’un champ du formulaire projet (table `form`, type PROJET).
class ProjectFormField {
  const ProjectFormField({
    required this.key,
    required this.fieldId,
    required this.answerType,
    required this.label,
    this.hint,
    this.valueBinding,
    this.fieldCode,
    this.isSystemField = false,
    this.isRequired = false,
    this.defaultUnitId,
    this.unitSymbol = 'm',
  });

  final String key;
  final int fieldId;
  final String answerType;
  final String label;
  final String? hint;
  final String? valueBinding;
  final String? fieldCode;
  final bool isSystemField;

  /// Obligatoire : `isRequired` / `required` dans `fields`, ou `valueBinding` métier.
  final bool isRequired;

  final int? defaultUnitId;
  final String unitSymbol;

  String get normalizedType => ProjectAnswerType.normalize(answerType);

  bool get isTextInput =>
      normalizedType == ProjectAnswerType.text ||
      normalizedType == ProjectAnswerType.integer;

  bool get isIntegerInput => normalizedType == ProjectAnswerType.integer;

  bool get isMeasurementInput =>
      normalizedType == ProjectAnswerType.measurement;

  bool get isRecordingUnitMultiInput =>
      normalizedType == ProjectAnswerType.selectMultipleRecordingUnit;

  bool get isPersonSingleInput =>
      normalizedType == ProjectAnswerType.selectOnePerson;

  bool get isPersonMultiInput =>
      normalizedType == ProjectAnswerType.selectMultiplePerson;

  /// Champ « type d’UE » (déjà choisi à la création, non modifiable à l’étape formulaire).
  bool get isRecordingUnitTypeField {
    final binding = valueBinding?.trim();
    if (binding == 'type') return true;
    final code = fieldCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) return false;
    return code == 'SIARU.TYPE' || code == 'SIARU_TYPE';
  }

  /// Champs modifiables via `PATCH /api/v1/projects/{id}`.
  bool get isPatchableOnApi {
    final binding = valueBinding?.trim();
    if (binding == null || binding.isEmpty) return false;
    return binding == 'name' ||
        binding == 'type' ||
        binding == 'beginDate' ||
        binding == 'endDate' ||
        binding == 'mainLocation' ||
        binding == 'spatialContext';
  }

  static ProjectFormField? fromEntry(String key, dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final fieldIdRaw = map['fieldId'] ?? int.tryParse(key);
    int? fieldId;
    if (fieldIdRaw is int) {
      fieldId = fieldIdRaw;
    } else if (fieldIdRaw is num) {
      fieldId = fieldIdRaw.toInt();
    }
    if (fieldId == null) return null;

    final label = (map['label'] as String?)?.trim();
    if (label == null || label.isEmpty) return null;

    int? defaultUnitId;
    var unitSymbol = 'm';
    final unitRaw = map['unit'];
    if (unitRaw is Map) {
      final unitMap = Map<String, dynamic>.from(unitRaw);
      final idRaw = unitMap['id'];
      if (idRaw is int) {
        defaultUnitId = idRaw;
      } else if (idRaw is num) {
        defaultUnitId = idRaw.toInt();
      } else {
        defaultUnitId = int.tryParse(idRaw?.toString() ?? '');
      }
      final sym = unitMap['symbol']?.toString().trim();
      if (sym != null && sym.isNotEmpty) unitSymbol = sym;
    }

    final valueBinding = (map['valueBinding'] as String?)?.trim();
    return ProjectFormField(
      key: key,
      fieldId: fieldId,
      answerType: (map['answerType'] as String?) ?? ProjectAnswerType.text,
      label: label,
      hint: (map['hint'] as String?)?.trim(),
      valueBinding: valueBinding,
      fieldCode: (map['fieldCode'] as String?)?.trim(),
      isSystemField: map['isSystemField'] == true,
      isRequired:
          _isRequiredFromApiMap(map) || _isRequiredByValueBinding(valueBinding),
      defaultUnitId: defaultUnitId,
      unitSymbol: unitSymbol,
    );
  }

  static bool _isRequiredFromApiMap(Map<String, dynamic> map) {
    return _truthy(map['isRequired']) || _truthy(map['required']);
  }

  static bool _isRequiredByValueBinding(String? binding) {
    final b = binding?.trim();
    return b == 'name' || b == 'identifier' || b == 'type';
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
}

/// Formulaire projet parsé depuis le cache local / API.
class ProjectFormDefinition {
  const ProjectFormDefinition({
    required this.fieldsById,
    required this.panels,
  });

  final Map<int, ProjectFormField> fieldsById;
  final List<ProjectFormPanelLayout> panels;

  /// Tous les champs dans l’ordre des panneaux du layout.
  List<ProjectFormField> get fieldsInLayoutOrder => panels
      .expand((p) => p.slots.map((s) => s.field))
      .toList();

  /// Compatibilité : liste plate (ordre layout).
  List<ProjectFormField> get fields => fieldsInLayoutOrder;

  /// Champ « Code » / identifiant masqué dans l’UI projet (généré côté serveur).
  static bool isCodeFieldHidden(ProjectFormField field) {
    final binding = field.valueBinding?.trim();
    if (binding == 'identifier') return true;
    return field.label.trim().toLowerCase() == 'code';
  }

  /// Panneaux sans le champ Code (création, fiche, modification).
  List<ProjectFormPanelLayout> panelsWithoutCodeField() {
    final out = <ProjectFormPanelLayout>[];
    for (final panel in panels) {
      final slots = panel.slots
          .where((slot) => !isCodeFieldHidden(slot.field))
          .toList();
      if (slots.isEmpty) continue;
      out.add(
        ProjectFormPanelLayout(
          nameKey: panel.nameKey,
          displayTitle: panel.displayTitle,
          slots: slots,
          isSystemPanel: panel.isSystemPanel,
        ),
      );
    }
    return out;
  }

  /// Alias création — même filtre que [panelsWithoutCodeField].
  List<ProjectFormPanelLayout> panelsForCreate() => panelsWithoutCodeField();

  factory ProjectFormDefinition.fromApiData(dynamic data) {
    if (data is! Map) {
      return const ProjectFormDefinition(fieldsById: {}, panels: []);
    }
    final root = Map<String, dynamic>.from(data);
    final inner = root['data'];
    final payload = inner is Map ? Map<String, dynamic>.from(inner) : root;

    final fieldsRaw = payload['fields'];
    if (fieldsRaw is! Map) {
      return const ProjectFormDefinition(fieldsById: {}, panels: []);
    }

    final fieldsById = <int, ProjectFormField>{};
    for (final entry in fieldsRaw.entries) {
      final field = ProjectFormField.fromEntry(entry.key, entry.value);
      if (field != null) {
        fieldsById[field.fieldId] = field;
      }
    }

    final layoutJson = _extractLayoutJson(payload['form']);
    final panels = ProjectFormLayoutParser.parsePanels(
      layoutJson: layoutJson,
      fieldsById: fieldsById,
    );

    return ProjectFormDefinition(
      fieldsById: fieldsById,
      panels: panels,
    );
  }

  static String? _extractLayoutJson(dynamic formRaw) {
    if (formRaw is! Map) return null;
    final form = Map<String, dynamic>.from(formRaw);
    final json = form['layoutJson'];
    if (json is String && json.trim().isNotEmpty) {
      return json;
    }
    return null;
  }
}

/// Lieu (autocomplétion `GET /api/v1/places/autocomplete`).
class SpatialUnitOption {
  const SpatialUnitOption({
    required this.id,
    required this.label,
    this.code,
  });

  final int id;
  final String label;
  final String? code;

  String get display => code != null && code!.isNotEmpty
      ? '$label ($code)'
      : label;

  static SpatialUnitOption? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final idRaw = map['id'] ?? map['resourceId'] ?? map['spatialUnitId'];
    int? id;
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is num) {
      id = idRaw.toInt();
    } else if (idRaw is String) {
      id = int.tryParse(idRaw.trim());
    }
    if (id == null) return null;
    final name = (map['name'] as String?)?.trim() ??
        (map['label'] as String?)?.trim() ??
        'Lieu $id';
    return SpatialUnitOption(
      id: id,
      label: name,
      code: (map['code'] as String?)?.trim(),
    );
  }
}

/// Corps de requête `PATCH /api/v1/projects/{id}`.
class ProjectPatchPayload {
  const ProjectPatchPayload({
    required this.name,
    required this.typeConceptId,
    this.beginDate,
    this.endDate,
    this.mainLocationId,
    this.spatialContextSpatialUnitIds = const [],
  });

  final String name;
  final int typeConceptId;
  final DateTime? beginDate;
  final DateTime? endDate;
  /// Commune / localisation principale (`mainLocation`).
  final int? mainLocationId;
  /// Localisation précise (`spatialContext`).
  final List<int> spatialContextSpatialUnitIds;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        // OpenAPI local : `typeId` ; certains serveurs acceptent aussi `typeConceptId`.
        'typeId': typeConceptId.toString(),
        'typeConceptId': typeConceptId.toString(),
        if (beginDate != null) 'beginDate': beginDate!.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
        if (mainLocationId != null) 'mainLocationId': mainLocationId.toString(),
        'spatialContextSpatialUnitIds':
            spatialContextSpatialUnitIds.map((id) => id.toString()).toList(),
      };
}

/// Corps de requête `POST /api/v1/projects` construit depuis le formulaire.
class ProjectCreatePayload {
  const ProjectCreatePayload({
    required this.organizationId,
    required this.name,
    required this.identifier,
    required this.typeConceptId,
    this.beginDate,
    this.endDate,
    this.mainLocationId,
    this.spatialContextSpatialUnitIds = const [],
    this.fieldAnswers = const {},
  });

  final int organizationId;
  final String name;
  final String identifier;
  final int typeConceptId;
  final DateTime? beginDate;
  final DateTime? endDate;
  /// Commune / localisation principale (`mainLocation`).
  final int? mainLocationId;
  /// Localisation précise (`spatialContext`).
  final List<int> spatialContextSpatialUnitIds;
  final Map<String, dynamic> fieldAnswers;

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId.toString(),
      'name': name,
      'identifier': identifier,
      'typeConceptId': typeConceptId.toString(),
      if (beginDate != null) 'beginDate': beginDate!.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
      if (mainLocationId != null) 'mainLocationId': mainLocationId.toString(),
      if (spatialContextSpatialUnitIds.isNotEmpty)
        'spatialContextSpatialUnitIds':
            spatialContextSpatialUnitIds.map((id) => id.toString()).toList(),
      if (fieldAnswers.isNotEmpty) 'fieldAnswers': fieldAnswers,
    };
  }
}

/// État des valeurs saisies (clé = [ProjectFormField.key]).
class ProjectFormState {
  ProjectFormState();

  final Map<String, String> textValues = {};
  final Map<String, DateTime?> dateValues = {};
  final Map<String, int?> conceptValues = {};
  final Map<String, List<int>> conceptMultiValues = {};
  final Map<String, SpatialUnitOption?> spatialSingleValues = {};
  final Map<String, List<SpatialUnitOption>> spatialMultiValues = {};
  final Map<String, FormMeasurementValue> measurementValues = {};
  final Map<String, List<RecordingUnitOption>> recordingUnitMultiValues = {};
  final Map<String, PersonOption?> personSingleValues = {};
  final Map<String, List<PersonOption>> personMultiValues = {};

  String? text(String key) => textValues[key];

  FormMeasurementValue? measurement(String key) => measurementValues[key];

  List<RecordingUnitOption> recordingUnits(String key) =>
      recordingUnitMultiValues[key] ?? const [];

  PersonOption? person(String key) => personSingleValues[key];

  List<PersonOption> persons(String key) =>
      personMultiValues[key] ?? const [];

  List<int> conceptMulti(String key) => conceptMultiValues[key] ?? const [];

  void setText(String key, String value) => textValues[key] = value;

  List<ConceptOption> conceptsForField(
    ProjectFormField field,
    Map<String, List<ConceptOption>> vocabByCode,
  ) {
    final code = field.fieldCode;
    if (code != null && vocabByCode.containsKey(code)) {
      return vocabByCode[code] ?? const [];
    }
    return vocabByCode['SIAAU.TYPE'] ?? const [];
  }

  ProjectCreatePayload buildPayload({
    required int organizationId,
    required ProjectFormDefinition definition,
    required Map<String, List<ConceptOption>> vocabByCode,
    bool generateIdentifierIfMissing = false,
  }) {
    final fields = definition.fieldsInLayoutOrder;
    String? name;
    String? identifier;
    int? typeConceptId;
    DateTime? beginDate;
    DateTime? endDate;
    int? mainLocationId;
    final spatialIds = <int>[];
    final fieldAnswers = <String, dynamic>{};

    for (final field in fields) {
      final binding = field.valueBinding;
      switch (field.normalizedType) {
        case ProjectAnswerType.text:
          final v = text(field.key)?.trim() ?? '';
          if (binding == 'name') {
            name = v;
          } else if (binding == 'identifier') {
            identifier = v;
          } else if (v.isNotEmpty) {
            fieldAnswers['${field.fieldId}'] = v;
          }
        case ProjectAnswerType.integer:
          final raw = text(field.key)?.trim() ?? '';
          if (raw.isNotEmpty) {
            final n = int.tryParse(raw);
            if (n == null) {
              throw FormatException(
                '« ${field.label} » doit être un nombre entier.',
              );
            }
            fieldAnswers['${field.fieldId}'] = n;
          }
        case ProjectAnswerType.dateTime:
          final d = dateValues[field.key];
          if (d != null) {
            final iso = d.toUtc().toIso8601String();
            if (binding == 'beginDate') {
              beginDate = d;
            } else if (binding == 'endDate') {
              endDate = d;
            } else {
              fieldAnswers['${field.fieldId}'] = iso;
            }
          }
        case ProjectAnswerType.selectOneFromFieldCode:
          final conceptId = conceptValues[field.key];
          if (conceptId != null) {
            if (binding == 'type') {
              typeConceptId = conceptId;
            } else {
              fieldAnswers['${field.fieldId}'] = conceptId;
            }
          }
        case ProjectAnswerType.selectOneActionCode:
        case ProjectAnswerType.selectOneSpatialUnit:
          final su = spatialSingleValues[field.key];
          if (su != null) {
            if (binding == 'mainLocation') {
              mainLocationId = su.id;
            } else {
              fieldAnswers['${field.fieldId}'] = su.id;
            }
          }
        case ProjectAnswerType.selectMultipleSpatialUnitTree:
          final list = spatialMultiValues[field.key] ?? const [];
          final ids = list.map((e) => e.id).toList();
          if (binding == 'spatialContext') {
            spatialIds.addAll(ids);
          } else if (ids.isNotEmpty) {
            fieldAnswers['${field.fieldId}'] = ids;
          }
        default:
          break;
      }
    }

    FormMeasurementPayload.appendToFieldAnswers(
      state: this,
      definition: definition,
      fieldAnswers: fieldAnswers,
    );
    FormRecordingUnitMultiPayload.appendToFieldAnswers(
      state: this,
      definition: definition,
      fieldAnswers: fieldAnswers,
    );
    _appendPersonFieldAnswers(definition, fieldAnswers);

    if (name == null || name.isEmpty) {
      throw const FormatException('Le nom du projet est obligatoire.');
    }
    if (identifier == null || identifier.isEmpty) {
      if (generateIdentifierIfMissing) {
        identifier = _generatedProjectIdentifier(name);
      } else {
        throw const FormatException('L’identifiant du projet est obligatoire.');
      }
    }
    if (typeConceptId == null) {
      throw const FormatException('Le type d’opération est obligatoire.');
    }

    return ProjectCreatePayload(
      organizationId: organizationId,
      name: name,
      identifier: identifier,
      typeConceptId: typeConceptId,
      beginDate: beginDate,
      endDate: endDate,
      mainLocationId: mainLocationId,
      spatialContextSpatialUnitIds: spatialIds,
      fieldAnswers: fieldAnswers,
    );
  }

  static String _generatedProjectIdentifier(String name) {
    final base = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch % 100000;
    if (base.isEmpty) return 'projet-$suffix';
    return '$base-$suffix';
  }

  /// Construit le corps PATCH à partir des champs modifiables du formulaire.
  ProjectPatchPayload buildPatchPayload({
    required ProjectFormDefinition definition,
  }) {
    final fields = definition.fieldsInLayoutOrder;
    String? name;
    int? typeConceptId;
    DateTime? beginDate;
    DateTime? endDate;
    int? mainLocationId;
    final spatialIds = <int>[];

    for (final field in fields) {
      if (!field.isPatchableOnApi) continue;
      final binding = field.valueBinding;
      switch (field.normalizedType) {
        case ProjectAnswerType.text:
          if (binding == 'name') {
            name = text(field.key)?.trim();
          }
        case ProjectAnswerType.dateTime:
          if (binding == 'beginDate') {
            beginDate = dateValues[field.key];
          } else if (binding == 'endDate') {
            endDate = dateValues[field.key];
          }
        case ProjectAnswerType.selectOneFromFieldCode:
          if (binding == 'type') {
            typeConceptId = conceptValues[field.key];
          }
        case ProjectAnswerType.selectOneActionCode:
        case ProjectAnswerType.selectOneSpatialUnit:
          if (binding == 'mainLocation') {
            mainLocationId = spatialSingleValues[field.key]?.id;
          }
        case ProjectAnswerType.selectMultipleSpatialUnitTree:
          if (binding == 'spatialContext') {
            final list = spatialMultiValues[field.key] ?? const [];
            spatialIds.addAll(list.map((e) => e.id));
          }
        default:
          break;
      }
    }

    if (name == null || name.isEmpty) {
      throw const FormatException('Le nom du projet est obligatoire.');
    }
    if (typeConceptId == null) {
      throw const FormatException('Le type d’opération est obligatoire.');
    }

    return ProjectPatchPayload(
      name: name,
      typeConceptId: typeConceptId,
      beginDate: beginDate,
      endDate: endDate,
      mainLocationId: mainLocationId,
      spatialContextSpatialUnitIds: spatialIds,
    );
  }

  void _appendPersonFieldAnswers(
    ProjectFormDefinition definition,
    Map<String, dynamic> fieldAnswers,
  ) {
    for (final field in definition.fieldsInLayoutOrder) {
      switch (field.normalizedType) {
        case ProjectAnswerType.selectOnePerson:
          final person = personSingleValues[field.key];
          if (person != null) {
            fieldAnswers['${field.fieldId}'] = person.id;
          }
        case ProjectAnswerType.selectMultiplePerson:
          final people = personMultiValues[field.key] ?? const [];
          if (people.isNotEmpty) {
            fieldAnswers['${field.fieldId}'] =
                people.map((p) => p.id).toList();
          }
        default:
          break;
      }
    }
  }
}
