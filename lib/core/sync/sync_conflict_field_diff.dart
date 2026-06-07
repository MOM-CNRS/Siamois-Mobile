import 'dart:convert';

import '../../features/projects/form/person_option.dart';
import '../../features/projects/form/project_form_models.dart';
import '../../features/projects/form/recording_unit_option.dart';
import '../../features/projects/recording_units/recording_unit_detail_mapper.dart';
import '../../features/projects/recording_units/recording_unit_detail_models.dart';
import 'sync_action_models.dart';
import 'sync_conflict_payload.dart';

/// Nature de l’écart constaté sur un champ.
enum SyncFieldConflictKind {
  /// Modifié localement et sur le serveur (valeurs différentes).
  trueConflict,

  /// Modifié sur le serveur seulement (pas dans vos changements en attente).
  serverOnly,

  /// Modifié localement seulement — en attente d’envoi, pas un conflit de champ.
  localOnly,

  /// Même valeur locale et serveur.
  aligned,
}

/// Comparaison d’un champ entre la base, le local et le serveur.
class SyncConflictFieldDiff {
  const SyncConflictFieldDiff({
    required this.fieldLabel,
    required this.localValue,
    required this.serverValue,
    required this.kind,
  });

  final String fieldLabel;
  final String localValue;
  final String serverValue;
  final SyncFieldConflictKind kind;

  bool get hasConflict => kind == SyncFieldConflictKind.trueConflict;

  String get kindLabel => switch (kind) {
        SyncFieldConflictKind.trueConflict => 'Conflit',
        SyncFieldConflictKind.serverOnly => 'Modifié sur le serveur',
        SyncFieldConflictKind.localOnly => 'Vos modifications',
        SyncFieldConflictKind.aligned => 'Identique',
      };
}

/// Construit la comparaison locale / serveur pour un conflit de sync.
abstract final class SyncConflictFieldDiffBuilder {
  static List<SyncConflictFieldDiff> build({
    required SyncActionEntry action,
    SyncConflictPayload? payload,
    required Map<int, String> fieldLabels,
    Map<int, String> fieldAnswerTypes = const {},
    RecordingUnitMobileDetail? serverDetail,
    RecordingUnitMobileDetail? baseDetail,
  }) {
    if (action.entityType != SyncEntityType.recordingUnit) {
      return const [];
    }

    final fieldAnswers = action.payload['fieldAnswers'];
    if (fieldAnswers is! Map || fieldAnswers.isEmpty) {
      return _serverOnlyDiffs(
        fieldLabels: fieldLabels,
        fieldAnswerTypes: fieldAnswerTypes,
        baseDetail: baseDetail,
        serverDetail: serverDetail ??
            (payload?.serverState != null
                ? RecordingUnitMobileDetail.fromApiData(payload!.serverState!)
                : null),
      );
    }

    final server = serverDetail ??
        (payload?.serverState != null
            ? RecordingUnitMobileDetail.fromApiData(payload!.serverState!)
            : null);

    return _buildDiffs(
      fieldAnswers: Map<String, dynamic>.from(fieldAnswers),
      fieldLabels: fieldLabels,
      fieldAnswerTypes: fieldAnswerTypes,
      baseDetail: baseDetail,
      serverDetail: server,
    );
  }

  static List<SyncConflictFieldDiff> buildFromFieldAnswers({
    required Map<String, dynamic> fieldAnswers,
    required Map<int, String> fieldLabels,
    Map<int, String> fieldAnswerTypes = const {},
    RecordingUnitMobileDetail? serverDetail,
    RecordingUnitMobileDetail? baseDetail,
  }) {
    if (fieldAnswers.isEmpty || serverDetail == null) return const [];

    return _buildDiffs(
      fieldAnswers: fieldAnswers,
      fieldLabels: fieldLabels,
      fieldAnswerTypes: fieldAnswerTypes,
      baseDetail: baseDetail,
      serverDetail: serverDetail,
    );
  }

  static List<SyncConflictFieldDiff> _buildDiffs({
    required Map<String, dynamic> fieldAnswers,
    required Map<int, String> fieldLabels,
    Map<int, String> fieldAnswerTypes = const {},
    RecordingUnitMobileDetail? baseDetail,
    required RecordingUnitMobileDetail? serverDetail,
  }) {
    final diffs = <SyncConflictFieldDiff>[];
    final handledKeys = <String>{};

    for (final entry in fieldAnswers.entries) {
      final fieldKey = entry.key.toString();
      handledKeys.add(fieldKey);
      final fieldId = int.tryParse(fieldKey);
      final label = fieldId != null
          ? fieldLabels[fieldId] ?? 'Champ $fieldId'
          : fieldKey;

      diffs.add(
        _diffForField(
          fieldLabel: label,
          fieldId: fieldId,
          fieldKey: fieldKey,
          answerType: fieldId != null ? fieldAnswerTypes[fieldId] : null,
          localRaw: entry.value,
          baseDetail: baseDetail,
          serverDetail: serverDetail,
        ),
      );
    }

    diffs.addAll(
      _serverOnlyDiffs(
        fieldLabels: fieldLabels,
        fieldAnswerTypes: fieldAnswerTypes,
        baseDetail: baseDetail,
        serverDetail: serverDetail,
        skipKeys: handledKeys,
      ),
    );

    return _sortedByKind(diffs);
  }

  static List<SyncConflictFieldDiff> _serverOnlyDiffs({
    required Map<int, String> fieldLabels,
    Map<int, String> fieldAnswerTypes = const {},
    RecordingUnitMobileDetail? baseDetail,
    RecordingUnitMobileDetail? serverDetail,
    Set<String> skipKeys = const {},
  }) {
    if (baseDetail == null || serverDetail == null) return const [];

    final diffs = <SyncConflictFieldDiff>[];
    for (final fieldId in fieldLabels.keys) {
      final fieldKey = '$fieldId';
      if (skipKeys.contains(fieldKey)) continue;

      final label = fieldLabels[fieldId] ?? 'Champ $fieldId';
      final answerType = fieldAnswerTypes[fieldId];
      final compareByPersonId = _isScientificPersonField(
        fieldLabel: label,
        answerType: answerType,
      );
      final baseRaw = _rawValueForField(baseDetail, fieldId, fieldKey);
      final serverRaw = _rawValueForField(serverDetail, fieldId, fieldKey);
      if (_valuesEqual(
        baseRaw,
        serverRaw,
        comparePersonIds: compareByPersonId,
      )) {
        continue;
      }

      diffs.add(
        SyncConflictFieldDiff(
          fieldLabel: label,
          localValue: _displayFieldValue(
            baseRaw,
            compareByPersonId: compareByPersonId,
            emptyLabel: 'Inchangé',
          ),
          serverValue: _displayFieldValue(
            serverRaw,
            detail: serverDetail,
            fieldId: fieldId,
            fieldKey: fieldKey,
            compareByPersonId: compareByPersonId,
            emptyLabel: 'Non renseigné',
          ),
          kind: SyncFieldConflictKind.serverOnly,
        ),
      );
    }
    return diffs;
  }

  static SyncConflictFieldDiff _diffForField({
    required String fieldLabel,
    required int? fieldId,
    required String fieldKey,
    String? answerType,
    required dynamic localRaw,
    RecordingUnitMobileDetail? baseDetail,
    RecordingUnitMobileDetail? serverDetail,
  }) {
    final compareByPersonId = _isScientificPersonField(
      fieldLabel: fieldLabel,
      answerType: answerType,
    );
    final baseRaw =
        baseDetail != null ? _rawValueForField(baseDetail, fieldId, fieldKey) : null;
    final serverRaw = serverDetail != null
        ? _rawValueForField(serverDetail, fieldId, fieldKey)
        : null;

    final kind = _classifyField(
      localRaw: localRaw,
      baseRaw: baseRaw,
      serverRaw: serverRaw,
      comparePersonIds: compareByPersonId,
    );

    return SyncConflictFieldDiff(
      fieldLabel: fieldLabel,
      localValue: _displayFieldValue(
        localRaw,
        compareByPersonId: compareByPersonId,
      ),
      serverValue: serverDetail == null
          ? 'Indisponible'
          : _displayFieldValue(
              serverRaw,
              detail: serverDetail,
              fieldId: fieldId,
              fieldKey: fieldKey,
              compareByPersonId: compareByPersonId,
              emptyLabel: 'Non renseigné',
            ),
      kind: kind,
    );
  }

  static SyncFieldConflictKind _classifyField({
    required dynamic localRaw,
    required dynamic baseRaw,
    required dynamic serverRaw,
    bool comparePersonIds = false,
  }) {
    if (_valuesEqual(
      localRaw,
      serverRaw,
      comparePersonIds: comparePersonIds,
    )) {
      return SyncFieldConflictKind.aligned;
    }

    if (baseRaw == null) {
      return SyncFieldConflictKind.localOnly;
    }

    final localChanged = !_valuesEqual(
      localRaw,
      baseRaw,
      comparePersonIds: comparePersonIds,
    );
    final serverChanged = !_valuesEqual(
      serverRaw,
      baseRaw,
      comparePersonIds: comparePersonIds,
    );

    if (localChanged && serverChanged) {
      return SyncFieldConflictKind.trueConflict;
    }
    if (localChanged) {
      return SyncFieldConflictKind.localOnly;
    }
    if (serverChanged) {
      return SyncFieldConflictKind.serverOnly;
    }

    return SyncFieldConflictKind.aligned;
  }

  static List<SyncConflictFieldDiff> _sortedByKind(
    List<SyncConflictFieldDiff> diffs,
  ) {
    int rank(SyncFieldConflictKind kind) => switch (kind) {
          SyncFieldConflictKind.trueConflict => 0,
          SyncFieldConflictKind.serverOnly => 1,
          SyncFieldConflictKind.localOnly => 2,
          SyncFieldConflictKind.aligned => 3,
        };

    final sorted = [...diffs]..sort((a, b) => rank(a.kind).compareTo(rank(b.kind)));
    return sorted;
  }

  static Map<int, String> labelsFromDefinition(ProjectFormDefinition definition) {
    return {
      for (final field in definition.fieldsById.values)
        field.fieldId: field.label.trim().isNotEmpty
            ? field.label.trim()
            : 'Champ ${field.fieldId}',
    };
  }

  static Map<int, String> answerTypesFromDefinition(
    ProjectFormDefinition definition,
  ) {
    return {
      for (final field in definition.fieldsById.values)
        field.fieldId: field.normalizedType,
    };
  }

  /// Auteur / contributeur scientifique ou technique : comparaison par identifiant.
  static bool _isScientificPersonField({
    required String fieldLabel,
    String? answerType,
  }) {
    if (answerType != null) {
      final type = ProjectAnswerType.normalize(answerType);
      if (type == ProjectAnswerType.selectOnePerson ||
          type == ProjectAnswerType.selectMultiplePerson) {
        return _isScientificPersonLabel(fieldLabel);
      }
    }
    return _isScientificPersonLabel(fieldLabel);
  }

  static bool _isScientificPersonLabel(String fieldLabel) {
    final label = fieldLabel.trim().toLowerCase();
    final role = label.contains('auteur') || label.contains('contributeur');
    final domain =
        label.contains('scientifique') || label.contains('technique');
    return role && domain;
  }

  static dynamic _rawValueForField(
    RecordingUnitMobileDetail detail,
    int? fieldId,
    String fieldKey,
  ) {
    final entry = detail.fields[fieldKey] ??
        (fieldId != null ? detail.fields['$fieldId'] : null);
    if (entry == null) return null;

    if (_isScientificPersonField(
      fieldLabel: entry.label,
      answerType: entry.answerType,
    )) {
      final fromUnit = _personPayloadFromRecordingUnit(
        entry,
        detail.recordingUnit,
      );
      if (fromUnit != null) return fromUnit;
    }

    return entry.currentValue;
  }

  static dynamic _personPayloadFromRecordingUnit(
    RecordingUnitFormFieldEntry entry,
    Map<String, dynamic> recordingUnit,
  ) {
    for (final key in _personCandidateKeys(entry)) {
      final raw = recordingUnit[key];
      if (raw != null) return raw;
    }
    return null;
  }

  static Iterable<String> _personCandidateKeys(
    RecordingUnitFormFieldEntry entry,
  ) {
    final keys = <String>{};
    void add(String? value) {
      if (value != null && value.trim().isNotEmpty) keys.add(value.trim());
    }

    add(entry.valueBinding);
    add(entry.fieldCode);

    final label = entry.label.trim().toLowerCase();
    if (label.contains('auteur')) add('author');
    if (label.contains('contributeur')) add('contributors');

    return keys;
  }

  static bool _valuesEqual(
    dynamic a,
    dynamic b, {
    bool comparePersonIds = false,
  }) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (comparePersonIds) return _personIdsEqual(a, b);
    try {
      return jsonEncode(_normalizeValue(a)) == jsonEncode(_normalizeValue(b));
    } catch (_) {
      return a.toString().trim() == b.toString().trim();
    }
  }

  static bool _personIdsEqual(dynamic a, dynamic b) {
    final idsA = _sortedPersonIds(a);
    final idsB = _sortedPersonIds(b);
    if (idsA.isEmpty && idsB.isEmpty) return true;
    if (idsA.length != idsB.length) return false;
    for (var i = 0; i < idsA.length; i++) {
      if (idsA[i] != idsB[i]) return false;
    }
    return true;
  }

  static List<int> _sortedPersonIds(dynamic raw) {
    final people = PersonOption.listFromDynamic(raw);
    if (people.isNotEmpty) {
      return people.map((person) => person.id).toList()..sort();
    }
    final id = PersonOption.extractId(raw);
    if (id != null) return [id];
    return const [];
  }

  static String _displayFieldValue(
    dynamic raw, {
    RecordingUnitMobileDetail? detail,
    int? fieldId,
    String? fieldKey,
    bool compareByPersonId = false,
    String emptyLabel = '—',
  }) {
    if (compareByPersonId) {
      final label = _personDisplayLabel(raw);
      if (label != null && label.isNotEmpty) return label;
    }

    if (detail != null && fieldId != null && fieldKey != null) {
      final entry = detail.fields[fieldKey] ??
          detail.fields['$fieldId'];
      if (entry != null) {
        final display = RecordingUnitDetailMapper.displayValueForField(
          entry,
          detail.recordingUnit,
        );
        if (display != null && display.trim().isNotEmpty) {
          return display.trim();
        }
      }
    }

    return _displayValue(raw, emptyLabel: emptyLabel);
  }

  static String? _personDisplayLabel(dynamic raw) {
    final people = PersonOption.listFromDynamic(raw);
    if (people.isNotEmpty) {
      return people
          .map((person) {
            if (person.display.trim().isNotEmpty) return person.display.trim();
            return 'Personne n°${person.id}';
          })
          .join('\n');
    }

    final id = PersonOption.extractId(raw);
    if (id == null) return null;

    final person = PersonOption.fromDynamic(raw);
    if (person != null && person.display.trim().isNotEmpty) {
      return person.display.trim();
    }
    return 'Personne n°$id';
  }

  static dynamic _normalizeValue(dynamic raw) {
    if (raw is Map) {
      final map = <String, dynamic>{};
      for (final entry in raw.entries) {
        map[entry.key.toString()] = _normalizeValue(entry.value);
      }
      final keys = map.keys.toList()..sort();
      return {for (final key in keys) key: map[key]};
    }
    if (raw is List) {
      return raw.map(_normalizeValue).toList();
    }
    if (raw is String) return raw.trim();
    if (raw is num) return raw;
    if (raw is bool) return raw;
    return raw;
  }

  static String _displayValue(dynamic raw, {String emptyLabel = '—'}) {
    if (raw == null) return emptyLabel;

    final units = RecordingUnitOption.listFromCurrentValue(raw);
    if (units.isNotEmpty) {
      return units.map((u) => u.display).join('\n');
    }

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return emptyLabel;
      final asDate = DateTime.tryParse(trimmed);
      if (asDate != null && trimmed.contains('-')) {
        return _formatDateTime(asDate);
      }
      return trimmed;
    }

    if (raw is num || raw is bool) return raw.toString();

    if (raw is List) {
      if (raw.isEmpty) return 'Aucune valeur';
      if (raw.every((e) => e is String || e is num)) {
        return raw.map((e) => e.toString()).join(', ');
      }
      return '${raw.length} élément${raw.length > 1 ? 's' : ''}';
    }

    if (raw is Map) {
      final label = raw['fullIdentifier'] ??
          raw['label'] ??
          raw['name'] ??
          raw['displayLabel'];
      if (label != null && label.toString().trim().isNotEmpty) {
        return label.toString().trim();
      }
      final text = raw['value'] ?? raw['text'];
      if (text != null && text.toString().trim().isNotEmpty) {
        return text.toString().trim();
      }
    }

    final text = raw.toString().trim();
    return text.isEmpty ? emptyLabel : text;
  }

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} à $h:$m';
  }
}
