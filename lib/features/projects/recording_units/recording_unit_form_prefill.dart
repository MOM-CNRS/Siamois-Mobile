import '../form/person_option.dart';
import '../form/project_form_models.dart';
import '../form/recording_unit_option.dart';
import '../mobiliers/mobilier_form_prefill.dart';
import '../vocabulary_models.dart';
import 'recording_unit_detail_models.dart';
import 'recording_unit_hierarchy.dart';

/// Pré-remplit [ProjectFormState] pour l’édition d’une UE.
abstract final class RecordingUnitFormPrefill {
  static void applyFromDetail(
    ProjectFormState state,
    ProjectFormDefinition definition,
    RecordingUnitMobileDetail detail, {
    Map<int, PersonOption>? directoryById,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    final fieldsRaw = <String, dynamic>{};
    for (final entry in detail.fields.values) {
      final defField = _resolveDefinitionFieldForEntry(entry, definition);
      final targetId = defField?.fieldId ?? entry.fieldId;
      fieldsRaw['$targetId'] = {
        'fieldId': targetId,
        'currentValue': entry.currentValue,
        if (entry.answerType != null) 'answerType': entry.answerType,
        if (entry.valueBinding != null) 'valueBinding': entry.valueBinding,
      };
    }

    MobilierFormPrefill.applyFromApiFields(
      state,
      definition,
      fieldsRaw,
      directoryById: directoryById,
      enrichDirectory: false,
    );

    _applyRecordingUnitBindings(
      state,
      definition,
      detail,
      directoryById: directoryById,
      vocabByCode: vocabByCode,
    );

    _applyPersonFieldsFromDetailEntries(
      state,
      definition,
      detail,
      directoryById: directoryById,
    );

    _pinConceptLabelsFromDetail(
      state,
      definition,
      detail,
      vocabByCode: vocabByCode,
    );

    if (directoryById != null && directoryById.isNotEmpty) {
      PersonOption.enrichFormPersonFields(state, definition, directoryById);
    }
  }

  /// Complète les champs depuis `recordingUnit` (priorité aux liaisons système).
  static void _applyRecordingUnitBindings(
    ProjectFormState state,
    ProjectFormDefinition definition,
    RecordingUnitMobileDetail detail, {
    Map<int, PersonOption>? directoryById,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    final ru = detail.recordingUnit;
    final fields = detail.fields;

    for (final field in definition.fields) {
      if (field.isRecordingUnitTypeField) continue;

      final entry = _resolveEntryForField(field, fields);
      final binding = field.valueBinding?.trim() ?? entry?.valueBinding?.trim();

      switch (field.normalizedType) {
        case ProjectAnswerType.text:
        case ProjectAnswerType.integer:
          final text = _textValue(
            state: state,
            field: field,
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (text != null) {
            state.textValues[field.key] = text;
          }
        case ProjectAnswerType.dateTime:
          if (state.dateValues[field.key] != null) continue;
          final date = _dateValue(
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (date != null) state.dateValues[field.key] = date;
        case ProjectAnswerType.selectOneFromFieldCode:
          if (state.conceptValues[field.key] != null) continue;
          final conceptId = _conceptValue(
            field: field,
            binding: binding,
            recordingUnit: ru,
            entry: entry,
            vocabByCode: vocabByCode,
          );
          if (conceptId != null) state.conceptValues[field.key] = conceptId;
        case ProjectAnswerType.selectMultiple:
        case ProjectAnswerType.selectMultiplePhase:
          if (state.conceptMulti(field.key).isNotEmpty) continue;
          final values = _conceptMultiValues(
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (values.isNotEmpty) state.conceptMultiValues[field.key] = values;
        case ProjectAnswerType.selectOneSpatialUnit:
          if (state.spatialSingleValues[field.key] != null) continue;
          final place = _spatialSingle(
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (place != null) state.spatialSingleValues[field.key] = place;
        case ProjectAnswerType.selectMultipleSpatialUnitTree:
          final existing = state.spatialMultiValues[field.key];
          if (existing != null && existing.isNotEmpty) continue;
          final places = _spatialMulti(
            binding: binding,
            recordingUnit: ru,
            entry: entry,
          );
          if (places.isNotEmpty) state.spatialMultiValues[field.key] = places;
        case ProjectAnswerType.selectOnePerson:
          if (state.person(field.key) != null) continue;
          final person = PersonOption.resolve(
            _personRawValue(
              field: field,
              entry: entry,
              binding: binding,
              recordingUnit: ru,
            ),
            directoryById: directoryById,
          );
          if (person != null) state.personSingleValues[field.key] = person;
        case ProjectAnswerType.selectMultiplePerson:
          if (state.persons(field.key).isNotEmpty) continue;
          final people = _resolvePersonList(
            field: field,
            entry: entry,
            binding: binding,
            recordingUnit: ru,
            directoryById: directoryById,
          );
          if (people.isNotEmpty) state.personMultiValues[field.key] = people;
        case ProjectAnswerType.selectMultipleRecordingUnit:
          if (state.recordingUnits(field.key).isNotEmpty) continue;
          if (!RecordingUnitHierarchy.isHierarchyRelationField(
            label: field.label,
            valueBinding: field.valueBinding,
            fieldCode: field.fieldCode,
            answerType: field.answerType,
            hint: field.hint,
          )) {
            continue;
          }
          final units = RecordingUnitOption.listFromCurrentValue(
            _rawValue(binding: binding, recordingUnit: ru, entry: entry),
          );
          if (units.isNotEmpty) {
            state.recordingUnitMultiValues[field.key] = units;
          }
        default:
          break;
      }
    }
  }

  static String? _textValue({
    required ProjectFormState state,
    required ProjectFormField field,
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    if (binding == 'identifier') {
      final shortId = _string(recordingUnit['identifier']);
      if (shortId != null) return shortId;
      return _string(recordingUnit['fullIdentifier']) ??
          (_hasText(state, field) ? state.textValues[field.key] : null) ??
          _string(entry?.currentValue);
    }

    if (_hasText(state, field)) return null;

    if (binding == 'name') {
      return _string(recordingUnit['name']) ?? _string(entry?.currentValue);
    }

    if (binding != null && binding.isNotEmpty) {
      final fromBinding = _string(recordingUnit[binding]);
      if (fromBinding != null) return fromBinding;
    }

    return _string(entry?.currentValue);
  }

  static bool _hasText(ProjectFormState state, ProjectFormField field) {
    final value = state.textValues[field.key];
    return value != null && value.trim().isNotEmpty;
  }

  static DateTime? _dateValue({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    dynamic raw;
    if (binding == 'openingDate') {
      raw = recordingUnit['openingDate'];
    } else if (binding == 'closingDate') {
      raw = recordingUnit['closingDate'];
    } else if (binding != null && binding.isNotEmpty) {
      raw = recordingUnit[binding];
    }
    raw ??= entry?.currentValue;
    return _parseDate(raw);
  }

  static int? _conceptValue({
    required ProjectFormField field,
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    if (binding == 'type' || field.isRecordingUnitTypeField) {
      final direct = _parseInt(recordingUnit['typeConceptId']);
      if (direct != null) return direct;
      final fromType = _conceptId(recordingUnit['type']);
      if (fromType != null) return fromType;
    }

    dynamic raw = binding != null ? recordingUnit[binding] : null;
    if (raw == null && binding == 'chronologicalPhase') {
      raw = recordingUnit['chronologicalAttribution'];
    }
    raw ??= entry?.currentValue;
    final id = _conceptId(raw);
    if (id != null) return id;

    final label = _conceptLabel(raw);
    if (label != null && vocabByCode != null) {
      return _matchConceptByLabel(label, field, vocabByCode);
    }
    return null;
  }

  static List<int> _conceptMultiValues({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    dynamic raw = binding != null ? recordingUnit[binding] : null;
    raw ??= entry?.currentValue;
    final list = raw is List
        ? raw
        : (raw is Map && raw['data'] is List ? raw['data'] as List : const []);
    final out = <int>[];
    for (final item in list) {
      final id = _conceptId(item);
      if (id != null) out.add(id);
    }
    return out;
  }

  static SpatialUnitOption? _spatialSingle({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    dynamic raw;
    if (binding == 'place') {
      raw = recordingUnit['place'];
    } else if (binding != null && binding.isNotEmpty) {
      raw = recordingUnit[binding];
    }
    raw ??= entry?.currentValue;
    return SpatialUnitOption.fromJson(raw);
  }

  static List<SpatialUnitOption> _spatialMulti({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    dynamic raw;
    if (binding == 'spatialContext') {
      raw = recordingUnit['spatialContext'];
    } else if (binding != null && binding.isNotEmpty) {
      raw = recordingUnit[binding];
    }
    raw ??= entry?.currentValue;

    if (raw is List) {
      return raw
          .map(SpatialUnitOption.fromJson)
          .whereType<SpatialUnitOption>()
          .toList();
    }

    if (raw is Map) {
      final data = raw['data'];
      if (data is List) {
        return data
            .map(SpatialUnitOption.fromJson)
            .whereType<SpatialUnitOption>()
            .toList();
      }
    }

    final single = SpatialUnitOption.fromJson(raw);
    return single != null ? [single] : const [];
  }

  static dynamic _rawValue({
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    required RecordingUnitFormFieldEntry? entry,
  }) {
    if (binding != null && binding.isNotEmpty) {
      final fromBinding = recordingUnit[binding];
      if (fromBinding != null && !_isEmptyRawValue(fromBinding)) {
        return fromBinding;
      }
    }
    final current = entry?.currentValue;
    if (current != null && !_isEmptyRawValue(current)) return current;
    return null;
  }

  /// Repli si le cache formulaire n’expose pas le bon `answerType` ou `fieldId`.
  static void _applyPersonFieldsFromDetailEntries(
    ProjectFormState state,
    ProjectFormDefinition definition,
    RecordingUnitMobileDetail detail, {
    Map<int, PersonOption>? directoryById,
  }) {
    final fields = detail.fields;
    final appliedKeys = <String>{};

    for (final field in definition.fields) {
      final entry = _resolveEntryForField(field, fields);
      final entryType = ProjectAnswerType.normalize(
        entry?.answerType ?? field.answerType,
      );

      if (entryType == ProjectAnswerType.selectOnePerson ||
          (entryType != ProjectAnswerType.selectMultiplePerson &&
              field.normalizedType == ProjectAnswerType.selectOnePerson)) {
        if (state.person(field.key) != null) continue;
        final person = PersonOption.resolve(
          _personRawValue(
            field: field,
            entry: entry,
            binding: field.valueBinding?.trim() ?? entry?.valueBinding?.trim(),
            recordingUnit: detail.recordingUnit,
          ),
          directoryById: directoryById,
        );
        if (person != null) {
          state.personSingleValues[field.key] = person;
          appliedKeys.add(field.key);
        }
        continue;
      }

      final isMultiPerson = entryType == ProjectAnswerType.selectMultiplePerson ||
          field.normalizedType == ProjectAnswerType.selectMultiplePerson ||
          _isContributorField(field, entry);
      if (!isMultiPerson) continue;
      if (state.persons(field.key).isNotEmpty) {
        appliedKeys.add(field.key);
        continue;
      }

      final people = _resolvePersonList(
        field: field,
        entry: entry,
        binding: field.valueBinding?.trim() ?? entry?.valueBinding?.trim(),
        recordingUnit: detail.recordingUnit,
        directoryById: directoryById,
      );
      if (people.isNotEmpty) {
        state.personMultiValues[field.key] = people;
        appliedKeys.add(field.key);
      }
    }

    for (final entry in fields.values) {
      final entryType = ProjectAnswerType.normalize(entry.answerType);
      if (entryType != ProjectAnswerType.selectMultiplePerson &&
          entryType != ProjectAnswerType.selectOnePerson) {
        continue;
      }

      final field = _resolveDefinitionFieldForEntry(entry, definition);
      if (field == null || appliedKeys.contains(field.key)) continue;

      if (entryType == ProjectAnswerType.selectOnePerson) {
        if (state.person(field.key) != null) continue;
        final person = PersonOption.resolve(
          _personRawValue(
            field: field,
            entry: entry,
            binding: field.valueBinding?.trim() ?? entry.valueBinding?.trim(),
            recordingUnit: detail.recordingUnit,
          ),
          directoryById: directoryById,
        );
        if (person != null) state.personSingleValues[field.key] = person;
        continue;
      }

      if (state.persons(field.key).isNotEmpty) continue;
      final people = _resolvePersonList(
        field: field,
        entry: entry,
        binding: field.valueBinding?.trim() ?? entry.valueBinding?.trim(),
        recordingUnit: detail.recordingUnit,
        directoryById: directoryById,
      );
      if (people.isNotEmpty) state.personMultiValues[field.key] = people;
    }
  }

  static bool _isContributorField(
    ProjectFormField field,
    RecordingUnitFormFieldEntry? entry,
  ) {
    final binding = field.valueBinding?.trim() ?? entry?.valueBinding?.trim();
    if (binding == 'contributors' || binding == 'excavators') return true;

    final label = (field.label.trim().isNotEmpty
            ? field.label
            : entry?.label ?? '')
        .trim()
        .toLowerCase();
    return label.contains('contributeur');
  }

  static RecordingUnitFormFieldEntry? _resolveEntryForField(
    ProjectFormField field,
    Map<String, RecordingUnitFormFieldEntry> fields,
  ) {
    final direct = fields['${field.fieldId}'];
    if (direct != null) return direct;

    final binding = field.valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      for (final entry in fields.values) {
        if (entry.valueBinding?.trim() == binding) return entry;
      }
    }

    final label = field.label.trim().toLowerCase();
    if (label.isEmpty) return null;
    for (final entry in fields.values) {
      final entryLabel = entry.label.trim().toLowerCase();
      if (entryLabel.isEmpty) continue;
      if (entryLabel == label) return entry;
      if (label.contains('contributeur') && entryLabel.contains('contributeur')) {
        return entry;
      }
      if (label.contains('auteur') &&
          entryLabel.contains('auteur') &&
          !label.contains('contributeur')) {
        return entry;
      }
    }
    return null;
  }

  static ProjectFormField? _resolveDefinitionFieldForEntry(
    RecordingUnitFormFieldEntry entry,
    ProjectFormDefinition definition,
  ) {
    for (final field in definition.fields) {
      if (field.fieldId == entry.fieldId) return field;
    }

    final binding = entry.valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      for (final field in definition.fields) {
        if (field.valueBinding?.trim() == binding) return field;
      }
    }

    final label = entry.label.trim().toLowerCase();
    if (label.isEmpty) return null;
    for (final field in definition.fields) {
      final fieldLabel = field.label.trim().toLowerCase();
      if (fieldLabel.isEmpty) continue;
      if (fieldLabel == label) return field;
      if (label.contains('contributeur') && fieldLabel.contains('contributeur')) {
        return field;
      }
      if (label.contains('auteur') &&
          fieldLabel.contains('auteur') &&
          !label.contains('contributeur')) {
        return field;
      }
    }
    return null;
  }

  static List<PersonOption> _resolvePersonList({
    required ProjectFormField field,
    required RecordingUnitFormFieldEntry? entry,
    required String? binding,
    required Map<String, dynamic> recordingUnit,
    Map<int, PersonOption>? directoryById,
  }) {
    return PersonOption.listFromDynamic(
      _personRawValue(
        field: field,
        entry: entry,
        binding: binding,
        recordingUnit: recordingUnit,
      ),
    )
        .map((p) => PersonOption.resolve(p, directoryById: directoryById))
        .whereType<PersonOption>()
        .toList();
  }

  static dynamic _personRawValue({
    required ProjectFormField field,
    required RecordingUnitFormFieldEntry? entry,
    required Map<String, dynamic> recordingUnit,
    String? binding,
  }) {
    for (final key in _personCandidateKeys(field: field, entry: entry, binding: binding)) {
      final raw = recordingUnit[key];
      if (raw != null && !_isEmptyRawValue(raw)) return raw;
    }

    final current = entry?.currentValue;
    if (current != null && !_isEmptyRawValue(current)) return current;
    return null;
  }

  static Iterable<String> _personCandidateKeys({
    required ProjectFormField field,
    RecordingUnitFormFieldEntry? entry,
    String? binding,
  }) {
    final keys = <String>{};
    void add(String? value) {
      if (value != null && value.trim().isNotEmpty) keys.add(value.trim());
    }

    add(binding);
    add(field.valueBinding);
    add(entry?.valueBinding);
    add(field.fieldCode);
    add(entry?.fieldCode);

    final label = (field.label.trim().isNotEmpty
            ? field.label
            : entry?.label ?? '')
        .trim()
        .toLowerCase();
    if (label.contains('auteur')) add('author');
    if (label.contains('contributeur')) add('contributors');

    return keys;
  }

  static bool _isEmptyRawValue(dynamic raw) {
    if (raw is List) return raw.isEmpty;
    if (raw is Map) return raw.isEmpty;
    return false;
  }

  static int? _matchConceptByLabel(
    String label,
    ProjectFormField field,
    Map<String, List<ConceptOption>> vocabByCode,
  ) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final code = field.fieldCode?.trim();
    final options = (code != null && code.isNotEmpty)
        ? ConceptOption.optionsForFieldCode(vocabByCode, code)
        : ConceptOption.optionsForFieldCode(vocabByCode, 'SIARU.CHRONO');

    for (final option in options) {
      if (option.label.trim().toLowerCase() == normalized) return option.id;
    }
    return null;
  }

  static void _pinConceptLabelsFromDetail(
    ProjectFormState state,
    ProjectFormDefinition definition,
    RecordingUnitMobileDetail detail, {
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    final fields = detail.fields;
    final ru = detail.recordingUnit;

    for (final field in definition.fields) {
      final entry = _resolveEntryForField(field, fields);
      final entryCode = entry?.fieldCode?.trim();
      if (entryCode != null &&
          entryCode.isNotEmpty &&
          (field.fieldCode?.trim().isEmpty ?? true)) {
        state.fieldCodeOverrides[field.key] = entryCode;
      }

      final binding = field.valueBinding?.trim() ?? entry?.valueBinding?.trim();
      final entryType = ProjectAnswerType.normalize(entry?.answerType);
      final fieldType = field.normalizedType;

      if (fieldType == ProjectAnswerType.selectOneFromFieldCode ||
          entryType == ProjectAnswerType.selectOneFromFieldCode) {
        final conceptId = state.conceptValues[field.key];
        if (conceptId == null) continue;
        _pinConceptOption(
          state: state,
          fieldKey: field.key,
          conceptId: conceptId,
          raw: _conceptRawValue(
            field: field,
            entry: entry,
            binding: binding,
            recordingUnit: ru,
          ),
          field: field,
          vocabByCode: vocabByCode,
        );
        continue;
      }

      if (fieldType == ProjectAnswerType.selectMultiple ||
          fieldType == ProjectAnswerType.selectMultiplePhase ||
          entryType == ProjectAnswerType.selectMultiple ||
          entryType == ProjectAnswerType.selectMultiplePhase) {
        final ids = state.conceptMulti(field.key);
        if (ids.isEmpty) continue;
        final raw = _conceptRawValue(
          field: field,
          entry: entry,
          binding: binding,
          recordingUnit: ru,
        );
        final items = raw is List ? raw : (raw != null ? [raw] : const []);
        for (final id in ids) {
          dynamic itemRaw;
          for (final candidate in items) {
            if (_conceptId(candidate) == id) {
              itemRaw = candidate;
              break;
            }
          }
          _pinConceptOption(
            state: state,
            fieldKey: field.key,
            conceptId: id,
            raw: itemRaw ?? id,
            field: field,
            vocabByCode: vocabByCode,
          );
        }
      }
    }
  }

  static void _pinConceptOption({
    required ProjectFormState state,
    required String fieldKey,
    required int conceptId,
    required dynamic raw,
    required ProjectFormField field,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    final label = _resolveConceptLabel(
      state: state,
      fieldKey: fieldKey,
      field: field,
      conceptId: conceptId,
      raw: raw,
      vocabByCode: vocabByCode,
    );
    if (label == null) return;

    final option = ConceptOption(id: conceptId, label: label);
    final existing = state.extraConceptOptionsByField[fieldKey] ?? const [];
    if (existing.any((o) => o.id == conceptId)) return;
    state.extraConceptOptionsByField[fieldKey] = [option, ...existing];
  }

  static String? _resolveConceptLabel({
    required ProjectFormState state,
    required String fieldKey,
    required ProjectFormField field,
    required int conceptId,
    required dynamic raw,
    Map<String, List<ConceptOption>>? vocabByCode,
  }) {
    final code = state.effectiveFieldCode(field);
    if (vocabByCode != null && code != null) {
      for (final option in ConceptOption.optionsForFieldCode(vocabByCode, code)) {
        if (option.id == conceptId) return option.label;
      }
    }
    return _conceptDisplayLabel(raw, conceptId);
  }

  static dynamic _conceptRawValue({
    required ProjectFormField field,
    RecordingUnitFormFieldEntry? entry,
    required Map<String, dynamic> recordingUnit,
    String? binding,
  }) {
    for (final key in _conceptCandidateKeys(
      field: field,
      entry: entry,
      binding: binding,
    )) {
      final raw = recordingUnit[key];
      if (raw != null && !_isEmptyRawValue(raw)) return raw;
    }
    final current = entry?.currentValue;
    if (current != null && !_isEmptyRawValue(current)) return current;
    return null;
  }

  static Iterable<String> _conceptCandidateKeys({
    required ProjectFormField field,
    RecordingUnitFormFieldEntry? entry,
    String? binding,
  }) {
    final keys = <String>{};
    void add(String? value) {
      if (value != null && value.trim().isNotEmpty) keys.add(value.trim());
    }

    add(binding);
    add(field.valueBinding);
    add(entry?.valueBinding);
    add(field.fieldCode);
    add(entry?.fieldCode);

    final label = (field.label.trim().isNotEmpty
            ? field.label
            : entry?.label ?? '')
        .trim()
        .toLowerCase();
    if (label.contains('nature') || label.contains('géomorpho')) {
      add('geomorphologicalCycle');
    }
    if (label.contains('agent')) add('geomorphologicalAgent');
    if (label.contains('interprétation') || label.contains('interpretation')) {
      add('normalizedInterpretation');
    }
    if (label.contains('chronologique') || label.contains('chrono')) {
      add('chronologicalPhase');
      add('chronologicalAttribution');
    }

    return keys;
  }

  static String? _conceptDisplayLabel(dynamic raw, int conceptId) {
    final fromMap = _conceptLabel(raw);
    if (fromMap != null && !_looksLikeConceptIdentifier(fromMap, conceptId)) {
      return fromMap;
    }
    return null;
  }

  static bool _looksLikeConceptIdentifier(String label, int conceptId) {
    final trimmed = label.trim();
    if (trimmed == conceptId.toString()) return true;
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return true;
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  static String? _conceptLabel(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return _string(map['displayLabel']) ??
        _string(map['resolvedLabel']) ??
        _string(map['label']);
  }

  static int? _conceptId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    for (final key in const ['conceptId', 'id', 'resourceId']) {
      final parsed = _parseInt(map[key]);
      if (parsed != null) return parsed;
    }

    final data = map['data'];
    if (data is Map) return _conceptId(data);
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static String? _string(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}
