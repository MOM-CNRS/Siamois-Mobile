import '../../features/projects/form/project_form_models.dart';
import '../../features/projects/form/recording_unit_option.dart';
import '../../features/projects/recording_units/recording_unit_detail_mapper.dart';
import '../../features/projects/recording_units/recording_unit_detail_models.dart';
import 'sync_action_models.dart';
import 'sync_conflict_payload.dart';

/// Un champ en conflit avec sa valeur locale et celle du serveur.
class SyncConflictFieldDiff {
  const SyncConflictFieldDiff({
    required this.fieldLabel,
    required this.localValue,
    required this.serverValue,
  });

  final String fieldLabel;
  final String localValue;
  final String serverValue;

  /// `true` si la valeur locale diffère de celle du serveur.
  bool get hasConflict => localValue.trim() != serverValue.trim();
}

/// Construit la comparaison locale / serveur pour un conflit de sync.
abstract final class SyncConflictFieldDiffBuilder {
  static List<SyncConflictFieldDiff> build({
    required SyncActionEntry action,
    SyncConflictPayload? payload,
    required Map<int, String> fieldLabels,
    RecordingUnitMobileDetail? serverDetail,
  }) {
    if (action.entityType != SyncEntityType.recordingUnit) {
      return const [];
    }

    final fieldAnswers = action.payload['fieldAnswers'];
    if (fieldAnswers is! Map || fieldAnswers.isEmpty) {
      return const [];
    }

    final server = serverDetail ??
        (payload?.serverState != null
            ? RecordingUnitMobileDetail.fromApiData(payload!.serverState!)
            : null);

    final diffs = <SyncConflictFieldDiff>[];
    for (final entry in fieldAnswers.entries) {
      final fieldId = int.tryParse(entry.key.toString());
      final label = fieldId != null
          ? fieldLabels[fieldId] ?? 'Champ $fieldId'
          : entry.key.toString();

      final localValue = _displayValue(entry.value);
      final serverValue = _serverValueForField(
        server,
        fieldId,
        entry.key.toString(),
      );

      diffs.add(
        SyncConflictFieldDiff(
          fieldLabel: label,
          localValue: localValue,
          serverValue: serverValue,
        ),
      );
    }
    return _sortedByConflictFirst(diffs);
  }

  static List<SyncConflictFieldDiff> buildFromFieldAnswers({
    required Map<String, dynamic> fieldAnswers,
    required Map<int, String> fieldLabels,
    RecordingUnitMobileDetail? serverDetail,
  }) {
    if (fieldAnswers.isEmpty || serverDetail == null) return const [];

    final diffs = <SyncConflictFieldDiff>[];
    for (final entry in fieldAnswers.entries) {
      final fieldId = int.tryParse(entry.key.toString());
      final label = fieldId != null
          ? fieldLabels[fieldId] ?? 'Champ $fieldId'
          : entry.key.toString();

      diffs.add(
        SyncConflictFieldDiff(
          fieldLabel: label,
          localValue: _displayValue(entry.value),
          serverValue: _serverValueForField(
            serverDetail,
            fieldId,
            entry.key.toString(),
          ),
        ),
      );
    }
    return _sortedByConflictFirst(diffs);
  }

  static List<SyncConflictFieldDiff> _sortedByConflictFirst(
    List<SyncConflictFieldDiff> diffs,
  ) {
    if (diffs.length <= 1) return diffs;
    return [
      ...diffs.where((d) => d.hasConflict),
      ...diffs.where((d) => !d.hasConflict),
    ];
  }

  static Map<int, String> labelsFromDefinition(ProjectFormDefinition definition) {
    return {
      for (final field in definition.fieldsById.values)
        field.fieldId: field.label.trim().isNotEmpty
            ? field.label.trim()
            : 'Champ ${field.fieldId}',
    };
  }

  static String _serverValueForField(
    RecordingUnitMobileDetail? server,
    int? fieldId,
    String fieldKey,
  ) {
    if (server == null) return 'Indisponible';

    final entry = server.fields[fieldKey] ??
        (fieldId != null ? server.fields['$fieldId'] : null);
    if (entry == null) return 'Non renseigné';

    final display = RecordingUnitDetailMapper.displayValueForField(
      entry,
      server.recordingUnit,
    );
    if (display != null && display.trim().isNotEmpty) {
      return display.trim();
    }

    return _displayValue(entry.currentValue, emptyLabel: 'Non renseigné');
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
