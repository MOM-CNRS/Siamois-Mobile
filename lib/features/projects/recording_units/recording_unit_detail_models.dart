import 'recording_unit_type_parse.dart';

/// Détail UE (`GET /api/v1/recording-units/{id}`).
///
/// Accepte l’ancien envelope `{ recordingUnit, form, fields }` et la resource
/// OpenAPI plate `{ id, answers, type, ... }`.
class RecordingUnitMobileDetail {
  const RecordingUnitMobileDetail({
    required this.recordingUnit,
    this.formName,
    this.layoutJson,
    this.fields = const {},
  });

  final Map<String, dynamic> recordingUnit;
  final String? formName;
  final String? layoutJson;
  final Map<String, RecordingUnitFormFieldEntry> fields;

  String get displayCode =>
      _string(recordingUnit['fullIdentifier']) ??
      _string(recordingUnit['identifier']) ??
      _string(recordingUnit['resourceId']) ??
      _string(recordingUnit['id']) ??
      '';

  /// Identifiant numérique pour DELETE (si disponible).
  int? get numericRecordingUnitId {
    final raw = recordingUnit['recordingUnitId'] ??
        recordingUnit['recording_unit_id'] ??
        recordingUnit['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  /// Identifiant du concept « type d’UE » (plusieurs formes JSON possibles).
  int? get typeConceptId {
    final direct = recordingUnit['typeConceptId'] ??
        recordingUnit['type_concept_id'];
    final fromDirect = _parseId(direct);
    if (fromDirect != null) return fromDirect;

    final typeConcept = recordingUnit['typeConcept'];
    if (typeConcept is Map) {
      final fromTc = _parseId(
        typeConcept['conceptId'] ??
            typeConcept['id'] ??
            typeConcept['resourceId'],
      );
      if (fromTc != null) return fromTc;
    }

    return recordingUnitTypeConceptIdFromRelationship(recordingUnit['type']);
  }

  /// Libellé du type d’UE (relation `type` ou attributs embarqués).
  String? get typeLabel => _relationshipLabel(recordingUnit['type']);

  /// Type depuis le détail API, avec repli sur la colonne SQLite si besoin.
  int? resolveTypeConceptId({int? fallback}) => typeConceptId ?? fallback;

  Map<String, dynamic>? get vocabulariesByFieldCode {
    final vocabs = recordingUnit['_vocabulariesByFieldCode'];
    if (vocabs is Map) return Map<String, dynamic>.from(vocabs);
    return null;
  }

  factory RecordingUnitMobileDetail.fromApiData(Map<String, dynamic> data) {
    if (_isFlatRecordingUnitResource(data)) {
      return _fromFlatResource(data);
    }
    return _fromLegacyEnvelope(data);
  }

  static bool _isFlatRecordingUnitResource(Map<String, dynamic> data) {
    if (data.containsKey('recordingUnit') || data.containsKey('fields')) {
      return false;
    }
    if (data.containsKey('answers')) return true;
    final resourceType = data['resourceType']?.toString();
    if (resourceType == 'recording-units') return true;
    return data.containsKey('fullIdentifier') || data.containsKey('identifier');
  }

  static RecordingUnitMobileDetail _fromLegacyEnvelope(
    Map<String, dynamic> data,
  ) {
    final ruRaw = data['recordingUnit'];
    final ru = ruRaw is Map
        ? Map<String, dynamic>.from(ruRaw)
        : <String, dynamic>{};

    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is Map && !ru.containsKey('_vocabulariesByFieldCode')) {
      ru['_vocabulariesByFieldCode'] = Map<String, dynamic>.from(vocabs);
    }

    String? layoutJson;
    String? formName;
    final form = data['form'];
    if (form is Map) {
      layoutJson = _string(form['layoutJson']);
      formName = _string(form['name']);
    }

    final fields = <String, RecordingUnitFormFieldEntry>{};
    final fieldsRaw = data['fields'];
    if (fieldsRaw is Map) {
      for (final entry in fieldsRaw.entries) {
        if (entry.value is Map) {
          fields[entry.key] = RecordingUnitFormFieldEntry.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    return RecordingUnitMobileDetail(
      recordingUnit: ru,
      formName: formName,
      layoutJson: layoutJson,
      fields: fields,
    );
  }

  static RecordingUnitMobileDetail _fromFlatResource(Map<String, dynamic> data) {
    final ru = <String, dynamic>{
      for (final e in data.entries)
        if (e.key != 'answers' &&
            e.key != 'form' &&
            e.key != 'fields' &&
            e.key != 'vocabulariesByFieldCode')
          e.key: e.value,
    };

    final type = data['type'];
    if (type is Map) {
      final typeMap = Map<String, dynamic>.from(type);
      final typeId = _parseId(
        typeMap['id'] ?? typeMap['resourceId'] ?? typeMap['conceptId'],
      );
      if (typeId != null) {
        ru['typeConceptId'] = typeId;
      }
      final label = _string(typeMap['resolvedLabel']) ??
          _string(typeMap['displayLabel']) ??
          _string(typeMap['label']);
      ru['type'] = {
        ...typeMap,
        if (typeId != null) 'conceptId': typeId,
        if (typeId != null) 'resourceId': typeId.toString(),
        if (label != null) 'displayLabel': label,
        if (label != null) 'resolvedLabel': label,
        'data': {
          if (typeId != null) 'id': typeId,
          if (typeId != null) 'conceptId': typeId,
          if (label != null) 'displayLabel': label,
          if (label != null) 'resolvedLabel': label,
        },
      };
    }

    final fields = <String, RecordingUnitFormFieldEntry>{};
    final answersRaw = data['answers'];
    if (answersRaw is Map) {
      for (final entry in answersRaw.entries) {
        final parsed = _fieldEntryFromAnswer(
          key: entry.key.toString(),
          raw: entry.value,
        );
        if (parsed == null) continue;
        fields['${parsed.fieldId}'] = parsed;

        final binding = parsed.valueBinding?.trim();
        if (binding != null &&
            binding.isNotEmpty &&
            parsed.currentValue != null &&
            !ru.containsKey(binding)) {
          ru[binding] = parsed.currentValue;
        }
      }
    }

    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is Map) {
      ru['_vocabulariesByFieldCode'] = Map<String, dynamic>.from(vocabs);
    }

    if (!ru.containsKey('chronologicalPhase') &&
        ru['chronologicalAttribution'] != null) {
      ru['chronologicalPhase'] = ru['chronologicalAttribution'];
    }

    return RecordingUnitMobileDetail(
      recordingUnit: ru,
      fields: fields,
    );
  }

  static RecordingUnitFormFieldEntry? _fieldEntryFromAnswer({
    required String key,
    required Object? raw,
  }) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final fieldRaw = map['field'];
    final field = fieldRaw is Map
        ? Map<String, dynamic>.from(fieldRaw)
        : <String, dynamic>{};

    final fieldId = _parseId(field['id']) ??
        _parseId(map['fieldId']) ??
        _parseId(key) ??
        0;
    if (fieldId <= 0) return null;

    final answerType =
        _string(map['answerType']) ?? _string(field['answerType']);

    return RecordingUnitFormFieldEntry(
      fieldId: fieldId,
      label: _string(field['label']) ?? _string(map['label']) ?? 'Champ',
      hint: _string(field['hint']) ?? _string(map['hint']),
      answerType: answerType,
      valueBinding:
          _string(field['valueBinding']) ?? _string(map['valueBinding']),
      fieldCode: _string(field['fieldCode']) ?? _string(map['fieldCode']),
      currentValue: _currentValueFromAnswer(map, answerType),
    );
  }

  static Object? _currentValueFromAnswer(
    Map<String, dynamic> answer,
    String? answerType,
  ) {
    final type = (answerType ?? '').trim().toUpperCase();
    if (type.startsWith('SELECT_MULTIPLE') || answer.containsKey('values')) {
      final values = answer['values'];
      if (values is! List) return null;
      return values.map(_normalizeResourceRef).toList();
    }

    final value = answer['value'];
    if (value == null) return null;

    if (type == 'MEASUREMENT' && value is Map) {
      final measure = Map<String, dynamic>.from(value);
      final symbol = _string(measure['symbol']);
      final comment = _string(measure['comment']);
      return {
        'numericValue': measure['numericValue'],
        if (measure['normalizedValue'] != null)
          'normalizedValue': measure['normalizedValue'],
        if (comment != null) 'comment': comment,
        if (symbol != null) 'unit': {'symbol': symbol},
        if (symbol != null) 'symbol': symbol,
      };
    }

    return _normalizeResourceRef(value);
  }

  static Object? _normalizeResourceRef(Object? raw) {
    if (raw is! Map) return raw;
    final map = Map<String, dynamic>.from(raw);
    final resourceId = map['resourceId'] ?? map['id'];
    final label = _string(map['label']) ??
        _string(map['resolvedLabel']) ??
        _string(map['displayLabel']) ??
        _string(map['fullIdentifier']) ??
        _string(map['name']);
    final resourceType = _string(map['resourceType']);

    return {
      ...map,
      if (resourceId != null) 'id': resourceId,
      if (resourceId != null) 'resourceId': resourceId,
      if (label != null) 'label': label,
      if (label != null) 'displayLabel': label,
      if (label != null &&
          (resourceType == null ||
              resourceType.contains('recording') ||
              resourceType.contains('spatial') ||
              resourceType.contains('action')))
        'fullIdentifier': map['fullIdentifier'] ?? label,
      if (label != null &&
          resourceType != null &&
          resourceType.contains('person'))
        'name': label,
    };
  }

  Map<String, dynamic> toApiData() {
    return {
      'recordingUnit': recordingUnit,
      'form': {
        if (formName != null) 'name': formName,
        if (layoutJson != null) 'layoutJson': layoutJson,
      },
      'fields': {
        for (final entry in fields.entries)
          entry.key: {
            'fieldId': entry.value.fieldId,
            'label': entry.value.label,
            if (entry.value.hint != null) 'hint': entry.value.hint,
            if (entry.value.answerType != null)
              'answerType': entry.value.answerType,
            if (entry.value.valueBinding != null)
              'valueBinding': entry.value.valueBinding,
            if (entry.value.fieldCode != null)
              'fieldCode': entry.value.fieldCode,
            if (entry.value.currentValue != null)
              'currentValue': entry.value.currentValue,
          },
      },
    };
  }
}

/// Champ de formulaire UE avec valeur courante.
class RecordingUnitFormFieldEntry {
  const RecordingUnitFormFieldEntry({
    required this.fieldId,
    required this.label,
    this.hint,
    this.answerType,
    this.valueBinding,
    this.fieldCode,
    this.currentValue,
  });

  final int fieldId;
  final String label;
  final String? hint;
  final String? answerType;
  final String? valueBinding;
  final String? fieldCode;
  final Object? currentValue;

  factory RecordingUnitFormFieldEntry.fromJson(Map<String, dynamic> json) {
    final idRaw = json['fieldId'];
    int fieldId = 0;
    if (idRaw is int) {
      fieldId = idRaw;
    } else if (idRaw is num) {
      fieldId = idRaw.toInt();
    } else {
      fieldId = int.tryParse(idRaw?.toString() ?? '') ?? 0;
    }

    return RecordingUnitFormFieldEntry(
      fieldId: fieldId,
      label: _string(json['label']) ?? 'Champ',
      hint: _string(json['hint']),
      answerType: _string(json['answerType']),
      valueBinding: _string(json['valueBinding']),
      fieldCode: _string(json['fieldCode']),
      currentValue: json['currentValue'],
    );
  }
}

/// Mobilier / find (`GET /api/v1/recording-units/{id}/mobiliers`).
class MobilierItem {
  const MobilierItem({
    required this.id,
    required this.displayCode,
    this.typeLabel,
    this.collectionDate,
  });

  final String id;
  final String displayCode;
  final String? typeLabel;
  final DateTime? collectionDate;

  /// Identifiant numérique requis pour PATCH/DELETE.
  int? get numericSpecimenId {
    final parsed = int.tryParse(id);
    if (parsed != null) return parsed;
    return int.tryParse(id.replaceAll(RegExp(r'\D'), ''));
  }

  factory MobilierItem.fromJson(Map<String, dynamic> json) {
    final full = _string(json['fullIdentifier']);
    final short = _string(json['identifier']);
    final id = _string(json['resourceId']) ??
        _string(json['id']) ??
        short ??
        full ??
        '';

    return MobilierItem(
      id: id,
      displayCode: full ?? short ?? id,
      typeLabel: _relationshipLabel(json['type']),
      collectionDate: _parseDate(json['collectionDate']),
    );
  }

  String? get collectionDateLabel {
    final d = collectionDate;
    if (d == null) return null;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}

class MobilierListResult {
  const MobilierListResult({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  final List<MobilierItem> items;
  final int total;
  final int offset;
  final int limit;

  bool get hasMore => offset + items.length < total;
}

int? _parseId(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
}

String? _string(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  try {
    return DateTime.parse(raw.toString()).toLocal();
  } catch (_) {
    return null;
  }
}

String? _relationshipLabel(dynamic rel) {
  if (rel is! Map) return null;
  final map = Map<String, dynamic>.from(rel);
  final data = map['data'];
  if (data is Map) {
    final nested = Map<String, dynamic>.from(data);
    final fromNested = _string(nested['displayLabel']) ??
        _string(nested['resolvedLabel']) ??
        _string(nested['name']) ??
        _string(nested['label']);
    if (fromNested != null) return fromNested;
  }
  return _string(map['resolvedLabel']) ??
      _string(map['displayLabel']) ??
      _string(map['name']) ??
      _string(map['label']);
}
