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

  /// Identifiant numérique `recording_unit_id` pour les endpoints hiérarchie.
  int? get serverRecordingUnitId {
    if (numericId != null) return numericId;
    return int.tryParse(key);
  }

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
    final entries = _unwrapEntries(raw);
    if (entries == null || entries.isEmpty) return const [];
    final out = <RecordingUnitOption>[];
    for (final entry in entries) {
      final option = fromDynamic(entry);
      if (option != null) out.add(option);
    }
    return dedupe(out);
  }

  /// Liste unique + JSON champ aligné (aucun doublon d’UE).
  static ({
    List<RecordingUnitOption> options,
    List<Map<String, dynamic>> answerJson,
  }) uniqueRelationList(List<RecordingUnitOption> options) {
    final unique = dedupe(options);
    final answerJson = unique
        .map((option) => option.toFieldAnswerJson())
        .toList(growable: false);
    return (options: unique, answerJson: answerJson);
  }

  /// Déduplique une valeur de champ `SELECT_MULTIPLE_RECORDING_UNIT`.
  static dynamic dedupeFieldAnswerValue(dynamic raw) {
    if (raw is! List || raw.isEmpty) return raw;
    final options = listFromCurrentValue(raw);
    if (options.isEmpty) return raw;
    return uniqueRelationList(options).answerJson;
  }

  /// Extrait les entrées UE d’une liste plate ou d’une relation API (`data`, `items`…).
  static List<dynamic>? _unwrapEntries(dynamic raw) {
    if (raw is List) return raw;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is List) return data;
    if (data is Map) return [data];
    final items = map['items'];
    if (items is List) return items;
    final content = map['content'];
    if (content is List) return content;
    return null;
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

    final attributes = map['attributes'];
    if (attributes is Map) {
      final merged = Map<String, dynamic>.from(attributes);
      final id = map['id'] ?? map['resourceId'];
      if (id != null) {
        merged['id'] = id;
        merged['resourceId'] = id;
      }
      return fromDynamic(merged);
    }

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
    final id = serverRecordingUnitId;
    return {
      if (id != null) 'id': id,
      if (identifier != null && identifier!.isNotEmpty) 'identifier': identifier,
      'fullIdentifier': label,
    };
  }

  /// Deux options désignent la même UE (clé, id numérique ou identifiant court).
  static bool refersToSameUnit(RecordingUnitOption a, RecordingUnitOption b) {
    if (a.key == b.key) return true;
    if (a.isSameAs(b.key) || b.isSameAs(a.key)) return true;

    final aNum = a.numericId;
    final bNum = b.numericId;
    if (aNum != null && bNum != null && aNum == bNum) return true;
    if (aNum != null && b.isSameAs(aNum.toString())) return true;
    if (bNum != null && a.isSameAs(bNum.toString())) return true;

    final aShort = a.identifier?.trim();
    final bShort = b.identifier?.trim();
    if (aShort != null &&
        aShort.isNotEmpty &&
        bShort != null &&
        aShort == bShort) {
      return true;
    }

    final aLabel = a.label.trim();
    final bLabel = b.label.trim();
    if (aLabel.isNotEmpty && bLabel.isNotEmpty && aLabel == bLabel) {
      return true;
    }
    if (aShort != null && aShort.isNotEmpty && aShort == bLabel) return true;
    if (bShort != null && bShort.isNotEmpty && bShort == aLabel) return true;

    return false;
  }

  /// Supprime les doublons en conservant la première occurrence.
  static List<RecordingUnitOption> dedupe(Iterable<RecordingUnitOption> options) {
    final out = <RecordingUnitOption>[];
    for (final option in options) {
      if (out.any((existing) => refersToSameUnit(existing, option))) continue;
      out.add(option);
    }
    return out;
  }

  /// Liste unique triée par libellé croissant (puis clé).
  static List<RecordingUnitOption> sortAscending(
    Iterable<RecordingUnitOption> options,
  ) {
    final list = dedupe(options);
    list.sort(_compareAscending);
    return list;
  }

  static int _compareAscending(RecordingUnitOption a, RecordingUnitOption b) {
    final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
    if (byLabel != 0) return byLabel;
    return a.key.compareTo(b.key);
  }

  static bool listContainsUnit(
    Iterable<RecordingUnitOption> options,
    RecordingUnitOption candidate,
  ) {
    return options.any((o) => refersToSameUnit(o, candidate));
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
