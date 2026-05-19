import '../project_detail_models.dart';

/// Résultat du chargement des options UE pour le sélecteur.
class RecordingUnitOptionsLoad {
  const RecordingUnitOptionsLoad({
    required this.options,
    required this.fromCache,
  });

  final List<RecordingUnitOption> options;
  final bool fromCache;
}

/// Option UE pour `SELECT_MULTIPLE_RECORDING_UNIT`.
class RecordingUnitOption {
  const RecordingUnitOption({
    required this.key,
    required this.label,
    this.numericId,
    this.identifier,
    this.typeLabel,
  });

  /// Identifiant stable (resourceId ou fullIdentifier).
  final String key;
  final String label;
  final int? numericId;
  final String? identifier;
  final String? typeLabel;

  String get display {
    final parts = <String>[label];
    if (typeLabel != null && typeLabel!.trim().isNotEmpty) {
      parts.add(typeLabel!.trim());
    }
    return parts.join(' · ');
  }

  factory RecordingUnitOption.fromItem(RecordingUnitItem item) {
    final numeric = int.tryParse(item.id);
    return RecordingUnitOption(
      key: item.id,
      label: item.displayCode,
      numericId: numeric,
      identifier: item.identifier,
      typeLabel: item.typeLabel,
    );
  }

  static List<RecordingUnitOption> listFromCurrentValue(dynamic raw) {
    if (raw is! List) return const [];
    final out = <RecordingUnitOption>[];
    for (final entry in raw) {
      final option = fromDynamic(entry);
      if (option != null) out.add(option);
    }
    return out;
  }

  static RecordingUnitOption? fromDynamic(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      final id = raw.toInt();
      return RecordingUnitOption(
        key: id.toString(),
        label: id.toString(),
        numericId: id,
      );
    }
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    int? numericId;
    final idRaw = map['id'] ?? map['recordingUnitId'];
    if (idRaw is int) {
      numericId = idRaw;
    } else if (idRaw is num) {
      numericId = idRaw.toInt();
    } else {
      numericId = int.tryParse(idRaw?.toString() ?? '');
    }

    final full = _string(map['fullIdentifier']);
    final short = _string(map['identifier']);
    final resourceId = _string(map['resourceId']);
    final key = resourceId ?? full ?? short ?? numericId?.toString();
    if (key == null || key.isEmpty) return null;

    final type = map['type'];
    String? typeLabel;
    if (type is Map) {
      final data = type['data'];
      if (data is Map) {
        typeLabel = _string(data['label']) ?? _string(data['name']);
      }
    }

    return RecordingUnitOption(
      key: key,
      label: full ?? short ?? key,
      numericId: numericId,
      identifier: short,
      typeLabel: typeLabel,
    );
  }

  Map<String, dynamic> toFieldAnswerJson() {
    return {
      if (numericId != null) 'id': numericId,
      if (identifier != null && identifier!.isNotEmpty) 'identifier': identifier,
      'fullIdentifier': label,
    };
  }

  /// Deux options désignent la même UE (comparaison stricte sur l’identifiant).
  static bool refersToSameUnit(RecordingUnitOption a, RecordingUnitOption b) {
    if (a.key == b.key) return true;
    final aNum = a.numericId;
    final bNum = b.numericId;
    if (aNum != null && bNum != null && aNum == bNum) return true;
    return false;
  }

  bool isSameAs(String? otherId) {
    if (otherId == null || otherId.trim().isEmpty) return false;
    final o = otherId.trim();
    if (key == o) return true;
    final n = int.tryParse(o);
    if (numericId != null && n != null && numericId == n) return true;
    return false;
  }

  static String? _string(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}
