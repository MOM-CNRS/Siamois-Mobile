import '../form/recording_unit_option.dart';
import 'recording_unit_hierarchy.dart';

/// Mappe les relations hiérarchiques UE (`/relations` ou `/children`).
abstract final class RecordingUnitRelationsMapper {
  static RecordingUnitHierarchy fromApiData(Map<String, dynamic> data) {
    final parents = optionsFromList(data['parents']);
    final children = optionsFromList(data['children']);
    return RecordingUnitHierarchy(
      parents: parents,
      children: children,
    );
  }

  static List<RecordingUnitOption> optionsFromList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <RecordingUnitOption>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final option = _optionFromSummary(Map<String, dynamic>.from(entry));
      if (option != null) out.add(option);
    }
    return RecordingUnitOption.dedupe(out);
  }

  static RecordingUnitOption? _optionFromSummary(Map<String, dynamic> map) {
    final numericId = _parseInt(map['id']);
    final full = _string(map['fullIdentifier']);
    final identifier = _string(map['identifier']);
    final key = full ?? identifier ?? (numericId != null ? '$numericId' : null);
    if (key == null || key.isEmpty) return null;

    final typeRaw = map['type'];
    String? typeLabel;
    if (typeRaw is Map) {
      typeLabel = _string(typeRaw['label']) ??
          _string(typeRaw['externalId']) ??
          _string(typeRaw['name']);
    }

    return RecordingUnitOption(
      key: key,
      label: full ?? identifier ?? key,
      numericId: numericId,
      identifier: identifier,
      typeLabel: typeLabel,
    );
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
