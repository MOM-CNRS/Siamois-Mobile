import 'recording_unit_type_parse.dart';

/// Détail UE (`GET /api/v1/recording-units/{id}`).
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
        typeConcept['conceptId'] ?? typeConcept['id'] ?? typeConcept['resourceId'],
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
  final data = rel['data'];
  if (data is Map) {
    return _string(data['displayLabel']) ??
        _string(data['name']) ??
        _string(data['label']);
  }
  return null;
}
