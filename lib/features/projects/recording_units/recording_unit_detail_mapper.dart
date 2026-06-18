import 'dart:convert';

import '../form/project_form_layout.dart';
import '../form/project_form_models.dart';
import '../form/person_option.dart';
import '../form/recording_unit_option.dart';
import '../vocabulary_models.dart';
import 'recording_unit_detail_models.dart';

/// Valeurs affichables pour le détail d'une UE.
abstract final class RecordingUnitDetailMapper {
  static List<RecordingUnitDetailRow> rowsInDisplayOrder(
    RecordingUnitMobileDetail detail, {
    ProjectFormDefinition? formDefinition,
    Map<String, List<ConceptOption>>? vocabByCode,
    Map<int, PersonOption>? peopleById,
  }) {
    final vocab = _mergeVocabularies(detail, vocabByCode);
    final apiFields = _apiFieldsById(detail);

    if (formDefinition != null && formDefinition.panels.isNotEmpty) {
      return _rowsFromFormDefinition(
        detail,
        formDefinition,
        apiFields,
        vocab,
        peopleById,
      );
    }

    final layoutRows = _rowsFromLayout(detail, apiFields, vocab, peopleById);
    if (layoutRows.isNotEmpty) return layoutRows;

    return _rowsFallback(detail, apiFields, vocab, peopleById);
  }

  static Map<int, RecordingUnitFormFieldEntry> _apiFieldsById(
    RecordingUnitMobileDetail detail,
  ) {
    return {
      for (final e in detail.fields.entries)
        if (e.value.fieldId > 0) e.value.fieldId: e.value,
    };
  }

  static Map<String, List<ConceptOption>> _mergeVocabularies(
    RecordingUnitMobileDetail detail,
    Map<String, List<ConceptOption>>? cached,
  ) {
    final merged = <String, List<ConceptOption>>{};
    if (cached != null) merged.addAll(cached);

    final fromDetail = detail.vocabulariesByFieldCode;
    if (fromDetail != null) {
      merged.addAll(ConceptOption.vocabulariesFromApiMap(fromDetail));
    }
    return merged;
  }

  static List<RecordingUnitDetailRow> _rowsFromFormDefinition(
    RecordingUnitMobileDetail detail,
    ProjectFormDefinition definition,
    Map<int, RecordingUnitFormFieldEntry> apiFields,
    Map<String, List<ConceptOption>> vocab,
    Map<int, PersonOption>? peopleById,
  ) {
    final rows = <RecordingUnitDetailRow>[];
    final used = <int>{};

    for (final panel in definition.panels) {
      if (panel.slots.isEmpty) continue;
      rows.add(RecordingUnitDetailRow.section(panel.displayTitle));

      for (final slot in panel.slots) {
        final formField = slot.field;
        used.add(formField.fieldId);
        final entry = _entryForField(formField, apiFields);
        rows.add(_rowForEntry(entry, detail.recordingUnit, vocab, peopleById));
      }
    }

    final orphans = apiFields.values
        .where((e) => !used.contains(e.fieldId))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    if (orphans.isNotEmpty) {
      rows.add(RecordingUnitDetailRow.section('Autres'));
      for (final entry in orphans) {
        rows.add(_rowForEntry(entry, detail.recordingUnit, vocab, peopleById));
      }
    }

    return rows;
  }

  static RecordingUnitFormFieldEntry _entryForField(
    ProjectFormField formField,
    Map<int, RecordingUnitFormFieldEntry> apiFields,
  ) {
    final existing = apiFields[formField.fieldId];
    if (existing != null) return existing;

    return RecordingUnitFormFieldEntry(
      fieldId: formField.fieldId,
      label: formField.label,
      hint: formField.hint,
      answerType: formField.answerType,
      valueBinding: formField.valueBinding,
      fieldCode: formField.fieldCode,
    );
  }

  static RecordingUnitDetailRow _rowForEntry(
    RecordingUnitFormFieldEntry entry,
    Map<String, dynamic> recordingUnit,
    Map<String, List<ConceptOption>> vocab,
    Map<int, PersonOption>? peopleById,
  ) {
    final value = displayValueForField(
      entry,
      recordingUnit,
      vocabByCode: vocab,
      peopleById: peopleById,
    );
    return RecordingUnitDetailRow(
      label: entry.label,
      value: value ?? '—',
      multiline: _isMultiline(value),
    );
  }

  static List<RecordingUnitDetailRow> _rowsFromLayout(
    RecordingUnitMobileDetail detail,
    Map<int, RecordingUnitFormFieldEntry> fieldsById,
    Map<String, List<ConceptOption>> vocab,
    Map<int, PersonOption>? peopleById,
  ) {
    final layoutJson = detail.layoutJson;
    if (layoutJson == null || layoutJson.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(layoutJson);
      if (decoded is! List) return const [];

      final rows = <RecordingUnitDetailRow>[];
      final used = <int>{};

      for (final panelRaw in decoded) {
        if (panelRaw is! Map) continue;
        final panelMap = Map<String, dynamic>.from(panelRaw);
        final panelTitle = _panelTitle(panelMap['name']);
        if (panelTitle != null) {
          rows.add(RecordingUnitDetailRow.section(panelTitle));
        }

        final panelRows = panelMap['rows'];
        if (panelRows is! List) continue;

        for (final rowRaw in panelRows) {
          if (rowRaw is! Map) continue;
          final columns = rowRaw['columns'];
          if (columns is! List) continue;

          for (final colRaw in columns) {
            if (colRaw is! Map) continue;
            final col = Map<String, dynamic>.from(colRaw);
            final fieldId = _int(col['fieldId']);
            if (fieldId == null) continue;
            used.add(fieldId);

            final entry = fieldsById[fieldId];
            if (entry == null) continue;

            rows.add(_rowForEntry(entry, detail.recordingUnit, vocab, peopleById));
          }
        }
      }

      for (final entry in fieldsById.values) {
        if (used.contains(entry.fieldId)) continue;
        final value = displayValueForField(
          entry,
          detail.recordingUnit,
          vocabByCode: vocab,
          peopleById: peopleById,
        );
        if (value == null || value.trim().isEmpty) continue;
        rows.add(
          RecordingUnitDetailRow(
            label: entry.label,
            value: value,
            multiline: _isMultiline(value),
          ),
        );
      }

      return rows;
    } catch (_) {
      return const [];
    }
  }

  static List<RecordingUnitDetailRow> _rowsFallback(
    RecordingUnitMobileDetail detail,
    Map<int, RecordingUnitFormFieldEntry> fieldsById,
    Map<String, List<ConceptOption>> vocab,
    Map<int, PersonOption>? peopleById,
  ) {
    final ru = detail.recordingUnit;
    final rows = <RecordingUnitDetailRow>[];

    void addSystem(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      rows.add(RecordingUnitDetailRow(label: label, value: value.trim()));
    }

    addSystem('Type', _relationshipLabel(ru['type']));
    addSystem('Lieu', _relationshipLabel(ru['place']));
    addSystem('Ouverture', _formatDate(ru['openingDate']));
    addSystem('Clôture', _formatDate(ru['closingDate']));
    addSystem('Couleur matrice', _asString(ru['matrixColor']));
    addSystem('Description', _asString(ru['description']));

    final sortedFields = fieldsById.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    for (final field in sortedFields) {
      final value = displayValueForField(
        field,
        ru,
        vocabByCode: vocab,
        peopleById: peopleById,
      );
      if (value == null || value.trim().isEmpty) continue;
      rows.add(
        RecordingUnitDetailRow(
          label: field.label,
          value: value,
          multiline: _isMultiline(value),
        ),
      );
    }

    return rows;
  }

  static String headerTitle(RecordingUnitMobileDetail detail) {
    final code = detail.displayCode.trim();
    return code.isEmpty ? 'Unité d’enregistrement' : code;
  }

  static String? headerSubtitle(RecordingUnitMobileDetail detail) {
    final ru = detail.recordingUnit;
    final parts = <String>[];
    final type = _relationshipLabel(ru['type']);
    if (type != null) parts.add(type);
    final place = _relationshipLabel(ru['place']);
    if (place != null) parts.add(place);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String? displayValueForField(
    RecordingUnitFormFieldEntry field,
    Map<String, dynamic> recordingUnit, {
    Map<String, List<ConceptOption>>? vocabByCode,
    Map<int, PersonOption>? peopleById,
  }) {
    final binding = field.valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      final fromBinding = _fromBinding(
        binding,
        recordingUnit,
        vocabByCode,
        peopleById,
      );
      if (fromBinding != null && fromBinding.isNotEmpty) return fromBinding;
    }

    final fromAnswerType = _fromAnswerType(
      field,
      recordingUnit,
      vocabByCode,
      peopleById,
    );
    if (fromAnswerType != null && fromAnswerType.isNotEmpty) {
      return fromAnswerType;
    }

    final fromRelationships = _recordingUnitsFromRecordingUnit(
      recordingUnit,
      field,
    );
    if (fromRelationships != null && fromRelationships.isNotEmpty) {
      return fromRelationships;
    }

    return formatCurrentValue(
      field.currentValue,
      peopleById: peopleById,
    );
  }

  static String? _fromAnswerType(
    RecordingUnitFormFieldEntry field,
    Map<String, dynamic> recordingUnit,
    Map<String, List<ConceptOption>>? vocabByCode,
    Map<int, PersonOption>? peopleById,
  ) {
    final raw = _rawValueForField(field, recordingUnit);
    if (raw == null) return null;

    switch (ProjectAnswerType.normalize(field.answerType)) {
      case ProjectAnswerType.text:
      case ProjectAnswerType.integer:
        return formatCurrentValue(raw, peopleById: peopleById);
      case ProjectAnswerType.dateTime:
        return _formatDate(raw) ??
            formatCurrentValue(raw, peopleById: peopleById);
      case ProjectAnswerType.measurement:
        return formatCurrentValue(raw, peopleById: peopleById);
      case ProjectAnswerType.selectOneFromFieldCode:
        return _conceptLabel(raw, field.fieldCode, vocabByCode);
      case ProjectAnswerType.selectMultiple:
        return _conceptListLabel(raw, field.fieldCode, vocabByCode);
      case ProjectAnswerType.selectOneActionCode:
      case ProjectAnswerType.selectOneSpatialUnit:
        return SpatialUnitOption.fromJson(raw)?.display ??
            _spatialFromRelationship(raw);
      case ProjectAnswerType.selectMultipleSpatialUnitTree:
        return _spatialListDisplay(raw);
      case ProjectAnswerType.selectOnePerson:
        return PersonOption.resolveDisplay(
          raw,
          directoryById: peopleById,
        );
      case ProjectAnswerType.selectMultiplePerson:
        return PersonOption.resolveDisplayList(
          raw,
          directoryById: peopleById,
        );
      case ProjectAnswerType.selectMultipleRecordingUnit:
        return _recordingUnitMultiDisplay(raw);
      default:
        if (_isRecordingUnitMultiField(field)) {
          final fromList = _recordingUnitMultiDisplay(raw);
          if (fromList != null) return fromList;
        }
        return formatCurrentValue(raw, peopleById: peopleById);
    }
  }

  static dynamic _rawValueForField(
    RecordingUnitFormFieldEntry field,
    Map<String, dynamic> recordingUnit,
  ) {
    if (_isPersonField(field)) {
      final fromUnit = _personPayloadFromRecordingUnit(field, recordingUnit);
      if (fromUnit != null && !_isBarePersonReference(fromUnit)) {
        return fromUnit;
      }
      final current = field.currentValue;
      if (current != null) return current;
      if (fromUnit != null) return fromUnit;
    }

    final current = field.currentValue;
    if (current != null) return current;

    for (final key in _candidateKeys(field)) {
      final raw = recordingUnit[key];
      if (raw != null) return raw;
    }
    return null;
  }

  static bool _isPersonField(RecordingUnitFormFieldEntry field) {
    final type = ProjectAnswerType.normalize(field.answerType ?? '');
    return type == ProjectAnswerType.selectOnePerson ||
        type == ProjectAnswerType.selectMultiplePerson;
  }

  static bool _isBarePersonReference(dynamic raw) {
    if (raw is num) return true;
    if (raw is String) return int.tryParse(raw.trim()) != null;
    if (raw is! Map) return false;
    final map = Map<String, dynamic>.from(raw);
    if (_mapIsPersonPayload(map)) return false;
    return PersonOption.extractId(map) != null;
  }

  static dynamic _personPayloadFromRecordingUnit(
    RecordingUnitFormFieldEntry field,
    Map<String, dynamic> recordingUnit,
  ) {
    for (final key in _personCandidateKeys(field)) {
      final raw = recordingUnit[key];
      if (raw != null) return raw;
    }
    return null;
  }

  static Iterable<String> _personCandidateKeys(
    RecordingUnitFormFieldEntry field,
  ) {
    final keys = <String>{};
    void add(String? value) {
      if (value != null && value.trim().isNotEmpty) keys.add(value.trim());
    }

    add(field.valueBinding);
    add(field.fieldCode);

    final label = field.label.trim().toLowerCase();
    if (label.contains('auteur')) add('author');
    if (label.contains('contributeur')) add('contributors');

    return keys;
  }

  static Iterable<String> _candidateKeys(RecordingUnitFormFieldEntry field) {
    final keys = <String>{};
    void add(String? value) {
      if (value != null && value.trim().isNotEmpty) keys.add(value.trim());
    }

    add(field.valueBinding);
    add(field.fieldCode);

    final label = field.label.trim().toLowerCase();
    if (label.contains('partie')) {
      add('partOf');
      add('partOfList');
      add('includedIn');
      add('includedInRecordingUnitList');
      add('parentRecordingUnitList');
      add('parentRecordingUnits');
    }
    if (label.contains('contient')) {
      add('contains');
      add('containsList');
      add('containedRecordingUnits');
      add('childRecordingUnitList');
      add('childRecordingUnits');
      add('contentRecordingUnitList');
    }

    return keys;
  }

  static bool _isRecordingUnitMultiField(RecordingUnitFormFieldEntry field) {
    if (ProjectAnswerType.normalize(field.answerType) ==
        ProjectAnswerType.selectMultipleRecordingUnit) {
      return true;
    }
    final label = field.label.trim().toLowerCase();
    return label.contains('partie') || label.contains('contient');
  }

  static String? _recordingUnitMultiDisplay(dynamic raw) {
    final units = RecordingUnitOption.listFromCurrentValue(raw);
    if (units.isEmpty) return null;
    return units.map((u) => u.display).join('\n');
  }

  static String? _recordingUnitsFromRecordingUnit(
    Map<String, dynamic> recordingUnit,
    RecordingUnitFormFieldEntry field,
  ) {
    if (!_isRecordingUnitMultiField(field)) return null;
    return _recordingUnitMultiDisplay(_rawValueForField(field, recordingUnit));
  }

  static String? _fromBinding(
    String binding,
    Map<String, dynamic> ru,
    Map<String, List<ConceptOption>>? vocabByCode,
    Map<int, PersonOption>? peopleById,
  ) {
    switch (binding) {
      case 'identifier':
        return _asString(ru['identifier']) ?? _asString(ru['fullIdentifier']);
      case 'name':
        return _asString(ru['name']);
      case 'type':
        return _relationshipLabel(ru['type']);
      case 'place':
        return _relationshipLabel(ru['place']);
      case 'openingDate':
        return _formatDate(ru['openingDate']);
      case 'closingDate':
        return _formatDate(ru['closingDate']);
      case 'matrixColor':
        return _asString(ru['matrixColor']);
      case 'description':
        return _asString(ru['description']);
      case 'spatialContext':
        return _spatialContextFromRecordingUnit(ru);
      case 'author':
        return PersonOption.resolveDisplay(
          ru['author'],
          directoryById: peopleById,
        );
      case 'contributors':
        return PersonOption.resolveDisplayList(
          ru['contributors'],
          directoryById: peopleById,
        );
      case 'taq':
      case 'tpq':
        return _asString(ru[binding]) ?? formatCurrentValue(ru[binding]);
      case 'chronologicalPhase':
        return _conceptLabel(
          ru[binding],
          'SIARU.CHRONO',
          vocabByCode,
        );
      default:
        final raw = ru[binding];
        if (raw == null) return null;
        final fromRuList = _recordingUnitMultiDisplay(raw);
        if (fromRuList != null && fromRuList.isNotEmpty) return fromRuList;
        if (raw is List) {
          return _conceptListLabel(raw, null, vocabByCode) ??
              formatCurrentValue(raw, peopleById: peopleById);
        }
        if (raw is Map && _conceptId(raw) != null) {
          return _conceptLabel(raw, null, vocabByCode);
        }
        return formatCurrentValue(raw, peopleById: peopleById);
    }
  }

  static String? _spatialContextFromRecordingUnit(Map<String, dynamic> ru) {
    final rel = ru['spatialContext'];
    if (rel is Map) {
      final data = rel['data'];
      if (data is List && data.isNotEmpty) {
        final labels = <String>[];
        for (final item in data) {
          final unit = SpatialUnitOption.fromJson(item);
          if (unit != null) {
            labels.add(unit.display);
            continue;
          }
          final label = _spatialFromRelationship(item);
          if (label != null) labels.add(label);
        }
        if (labels.isNotEmpty) return labels.join('\n');
      }
    }
    return null;
  }

  static String? _spatialListDisplay(dynamic raw) {
    if (raw is List) {
      final labels = <String>[];
      for (final item in raw) {
        final unit = SpatialUnitOption.fromJson(item);
        if (unit != null) {
          labels.add(unit.display);
          continue;
        }
        final label = _spatialFromRelationship(item);
        if (label != null) labels.add(label);
      }
      if (labels.isNotEmpty) return labels.join('\n');
    }
    final single = SpatialUnitOption.fromJson(raw);
    if (single != null) return single.display;
    return _spatialFromRelationship(raw);
  }

  static String? _spatialFromRelationship(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is Map) {
      return SpatialUnitOption.fromJson(data)?.display ??
          _asString(data['name']) ??
          _asString(data['label']);
    }
    return SpatialUnitOption.fromJson(map)?.display;
  }

  static String? _conceptLabel(
    dynamic raw,
    String? fieldCode,
    Map<String, List<ConceptOption>>? vocabByCode,
  ) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final embedded = _asString(map['displayLabel']) ??
          _relationshipLabel(map) ??
          _asString(map['label']);
      if (embedded != null && embedded.isNotEmpty) return embedded;
    }

    final conceptId = _conceptId(raw);
    if (conceptId != null &&
        fieldCode != null &&
        vocabByCode != null &&
        vocabByCode.containsKey(fieldCode)) {
      for (final option in vocabByCode[fieldCode]!) {
        if (option.id == conceptId) return option.label;
      }
    }

    if (conceptId != null) return conceptId.toString();
    return formatCurrentValue(raw);
  }

  static String? _conceptListLabel(
    dynamic raw,
    String? fieldCode,
    Map<String, List<ConceptOption>>? vocabByCode,
  ) {
    if (raw is! List || raw.isEmpty) return null;
    final labels = <String>[];
    for (final item in raw) {
      final label = _conceptLabel(item, fieldCode, vocabByCode);
      if (label != null && label.isNotEmpty) labels.add(label);
    }
    return labels.isEmpty ? null : labels.join('\n');
  }

  static int? _conceptId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final id = map['id'] ?? map['conceptId'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      return int.tryParse(id?.toString() ?? '');
    }
    return int.tryParse(raw?.toString() ?? '');
  }

  static String? formatCurrentValue(
    Object? raw, {
    Map<int, PersonOption>? peopleById,
  }) {
    if (raw == null) return null;
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      final asDate = _formatDate(t);
      return asDate ?? t;
    }
    if (raw is num || raw is String && int.tryParse(raw.trim()) != null) {
      final personLabel = PersonOption.resolveDisplay(
        raw,
        directoryById: peopleById,
      );
      if (personLabel != null && personLabel.isNotEmpty) return personLabel;
      if (peopleById != null && peopleById.isNotEmpty) return null;
      if (raw is num) return raw.toString();
    }
    if (raw is bool) return raw.toString();
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (_mapIsRecordingUnitRelation(map)) {
        final fromRuList = _recordingUnitMultiDisplay(map);
        if (fromRuList != null && fromRuList.isNotEmpty) return fromRuList;
      }
      if (_mapIsPersonPayload(map)) {
        return PersonOption.resolveDisplay(map, directoryById: peopleById);
      }
      final numeric = map['numericValue'];
      if (numeric != null) {
        final unit = map['unit'];
        var suffix = ' m';
        if (unit is Map) {
          final sym = unit['symbol']?.toString().trim();
          if (sym != null && sym.isNotEmpty) suffix = ' $sym';
        }
        final comment = map['comment']?.toString().trim();
        final size = numeric.toString();
        if (comment != null && comment.isNotEmpty) {
          return '$size$suffix — $comment';
        }
        return '$size$suffix';
      }
      return _asString(map['displayLabel']) ??
          _relationshipLabel(map) ??
          _asString(map['name']) ??
          _asString(map['label']) ??
          _asString(map['fullIdentifier']);
    }
    if (raw is List) {
      final personList = PersonOption.resolveDisplayList(
        raw,
        directoryById: peopleById,
      );
      if (personList != null && personList.isNotEmpty) return personList;

      final ruLabels = <String>[];
      for (final item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final label = _asString(map['fullIdentifier']) ??
              _asString(map['identifier']) ??
              _asString(map['resourceId']);
          if (label != null) {
            ruLabels.add(label);
            continue;
          }
        }
        final formatted = formatCurrentValue(item, peopleById: peopleById);
        if (formatted != null && formatted.isNotEmpty) {
          ruLabels.add(formatted);
        }
      }
      if (ruLabels.isNotEmpty) return ruLabels.join('\n');

      final parts = raw
          .map((e) => formatCurrentValue(e, peopleById: peopleById))
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join('\n');
    }
    return raw.toString();
  }

  static bool _mapIsPersonPayload(Map<String, dynamic> map) {
    return map.containsKey('lastname') ||
        map.containsKey('lastName') ||
        map.containsKey('nom') ||
        (map.containsKey('name') && !map.containsKey('fullIdentifier')) ||
        map.containsKey('prenom');
  }

  static String? _panelTitle(dynamic name) {
    if (name is! String) return null;
    final key = name.trim();
    if (key.isEmpty) return null;
    return ProjectFormLayoutParser.panelTitleFromKey(key);
  }

  static bool _isMultiline(String? value) =>
      value != null && value.contains('\n');

  static String? _asString(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return null;
    }
  }

  static String? _relationshipLabel(dynamic rel) {
    if (rel is! Map) return null;
    final data = rel['data'];
    if (data is Map) {
      return _asString(data['displayLabel']) ??
          _asString(data['name']) ??
          _asString(data['label']);
    }
    return null;
  }

  static bool _mapIsRecordingUnitRelation(Map<String, dynamic> map) {
    if (map.containsKey('fullIdentifier') || map.containsKey('recordingUnitId')) {
      return true;
    }
    final data = map['data'];
    if (data is! List || data.isEmpty) return false;
    final first = data.first;
    if (first is! Map) return false;
    final m = Map<String, dynamic>.from(first);
    final type = m['type']?.toString().toLowerCase() ?? '';
    if (type.contains('recording')) return true;
    final attrs = m['attributes'];
    if (attrs is Map) {
      final a = Map<String, dynamic>.from(attrs);
      return a.containsKey('fullIdentifier') || a.containsKey('identifier');
    }
    return m.containsKey('fullIdentifier') ||
        m.containsKey('identifier') ||
        m.containsKey('resourceId');
  }

  static int? _int(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}

class RecordingUnitDetailRow {
  const RecordingUnitDetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
    this.isSection = false,
  });

  factory RecordingUnitDetailRow.section(String title) {
    return RecordingUnitDetailRow(
      label: title,
      value: '',
      isSection: true,
    );
  }

  final String label;
  final String value;
  final bool multiline;
  final bool isSection;
}
