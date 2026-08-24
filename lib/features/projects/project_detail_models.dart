import 'form/recording_unit_option.dart';
import 'recording_units/recording_unit_type_parse.dart';

/// Document rattaché à un projet (`GET /api/v1/projects/{id}/documents`).
class ProjectDocumentItem {
  const ProjectDocumentItem({
    required this.id,
    required this.title,
    this.description,
    this.fileName,
    this.mimeType,
    this.url,
    this.fileCode,
    this.size,
    this.natureLabel,
    this.formatLabel,
  });

  final String id;
  final String title;
  final String? description;
  final String? fileName;
  final String? mimeType;
  final String? url;
  final String? fileCode;
  final int? size;
  final String? natureLabel;
  final String? formatLabel;

  String get displayTitle =>
      title.trim().isNotEmpty ? title.trim() : (fileName ?? 'Document');

  String? get subtitle {
    final parts = <String>[];
    if (fileName != null && fileName!.isNotEmpty && fileName != title) {
      parts.add(fileName!);
    }
    if (natureLabel != null && natureLabel!.isNotEmpty) {
      parts.add(natureLabel!);
    }
    if (formatLabel != null && formatLabel!.isNotEmpty) {
      parts.add(formatLabel!);
    }
    if (parts.isEmpty) return mimeType;
    return parts.join(' · ');
  }

  String? get sizeLabel {
    final bytes = size;
    if (bytes == null || bytes <= 0) return null;
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  factory ProjectDocumentItem.fromJson(Map<String, dynamic> json) {
    return ProjectDocumentItem(
      id: _string(json['resourceId']) ??
          _string(json['id']) ??
          '',
      title: _string(json['title']) ?? 'Sans titre',
      description: _string(json['description']),
      fileName: _string(json['fileName']),
      mimeType: _string(json['mimeType']),
      url: _string(json['url']),
      fileCode: _string(json['fileCode']),
      size: _int(json['size']),
      natureLabel: _relationshipLabel(json['nature']),
      formatLabel: _relationshipLabel(json['format']),
    );
  }

}

/// Unité d’enregistrement d’un projet (`GET /api/v1/projects/{id}/recording-units`).
class RecordingUnitItem {
  const RecordingUnitItem({
    required this.id,
    required this.displayCode,
    this.identifier,
    this.typeLabel,
    this.typeConceptId,
    this.placeLabel,
    this.openingDate,
    this.closingDate,
    this.matrixColor,
    this.specimenCount,
    this.stratigraphicCount,
    this.parentIds = const [],
    this.childIds = const [],
  });

  final String id;
  final String displayCode;
  final String? identifier;
  final String? typeLabel;
  final int? typeConceptId;
  final String? placeLabel;
  final DateTime? openingDate;
  final DateTime? closingDate;
  final String? matrixColor;
  final int? specimenCount;
  final int? stratigraphicCount;
  final List<String> parentIds;
  final List<String> childIds;

  factory RecordingUnitItem.fromJson(Map<String, dynamic> json) {
    final full = _string(json['fullIdentifier']);
    final short = _string(json['identifier']);
    final id = _string(json['resourceId']) ??
        _string(json['id']) ??
        short ??
        full ??
        '';

    return RecordingUnitItem(
      id: id,
      displayCode: full ?? short ?? id,
      identifier: short,
      typeLabel: _relationshipLabel(json['type']),
      typeConceptId: recordingUnitTypeConceptIdFromRelationship(json['type']) ??
          _int(json['typeConceptId']),
      placeLabel: _relationshipLabel(json['place']),
      openingDate: _parseDate(json['openingDate']),
      closingDate: _parseDate(json['closingDate']),
      matrixColor: _string(json['matrixColor']),
      specimenCount: _relationshipCount(json['specimen']),
      stratigraphicCount: _relationshipCount(json['stratigraphicRelationships']),
      parentIds: _recordingUnitRelationIds(json, _recordingUnitParentKeys),
      childIds: _recordingUnitRelationIds(json, _recordingUnitChildKeys),
    );
  }

  /// UE parentes embarquées dans un JSON API (liste ou détail).
  static List<RecordingUnitOption> parentOptionsFromJson(
    Map<String, dynamic> json,
  ) =>
      _relatedOptionsFromJson(json, _recordingUnitParentKeys);

  /// UE filles embarquées dans un JSON API (liste ou détail).
  static List<RecordingUnitOption> childOptionsFromJson(
    Map<String, dynamic> json,
  ) =>
      _relatedOptionsFromJson(json, _recordingUnitChildKeys);

  static List<RecordingUnitOption> _relatedOptionsFromJson(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final out = <RecordingUnitOption>[];
    for (final key in keys) {
      out.addAll(RecordingUnitOption.listFromCurrentValue(json[key]));
    }
    return RecordingUnitOption.dedupe(out);
  }

  /// Complète les liens parent / enfant à partir d’un JSON API (détail UE).
  RecordingUnitItem enrichHierarchyFrom(Map<String, dynamic> json) {
    final parents = _recordingUnitRelationIds(json, _recordingUnitParentKeys);
    final children = _recordingUnitRelationIds(json, _recordingUnitChildKeys);
    if (parents.isEmpty && children.isEmpty) return this;
    return RecordingUnitItem(
      id: id,
      displayCode: displayCode,
      identifier: identifier,
      typeLabel: typeLabel,
      typeConceptId: typeConceptId,
      placeLabel: placeLabel,
      openingDate: openingDate,
      closingDate: closingDate,
      matrixColor: matrixColor,
      specimenCount: specimenCount,
      stratigraphicCount: stratigraphicCount,
      parentIds: parents.isNotEmpty ? parents : parentIds,
      childIds: children.isNotEmpty ? children : childIds,
    );
  }

  String? get dateRangeLabel {
    final open = openingDate;
    final close = closingDate;
    if (open == null && close == null) return null;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (open != null && close != null) {
      return '${fmt(open)} – ${fmt(close)}';
    }
    if (open != null) return 'Ouverture : ${fmt(open)}';
    return 'Clôture : ${fmt(close!)}';
  }
}

const _recordingUnitParentKeys = [
  'parents',
  'parentRecordingUnits',
  'parentRecordingUnitList',
  'includedIn',
  'includedInRecordingUnitList',
  'partOf',
  'partOfList',
];

const _recordingUnitChildKeys = [
  'children',
  'childRecordingUnits',
  'childRecordingUnitList',
  'contains',
  'containsList',
  'containedRecordingUnits',
  'contentRecordingUnitList',
];

List<String> _recordingUnitRelationIds(
  Map<String, dynamic> json,
  List<String> keys,
) {
  final options = <RecordingUnitOption>[];
  for (final key in keys) {
    options.addAll(RecordingUnitOption.listFromCurrentValue(json[key]));
  }
  return RecordingUnitOption.dedupe(options)
      .map((option) => option.key)
      .where((key) => key.isNotEmpty)
      .toList(growable: false);
}

class RecordingUnitListResult {
  const RecordingUnitListResult({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  final List<RecordingUnitItem> items;
  final int total;
  final int offset;
  final int limit;

  bool get hasMore {
    if (items.isEmpty) return false;
    if (items.length < limit) return false;
    if (total > limit && offset + items.length >= total) return false;
    return true;
  }
}

String? _string(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  return s.isEmpty ? null : s;
}

int? _int(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
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

int? _relationshipCount(dynamic rel) {
  if (rel is! Map) return null;
  final meta = rel['meta'];
  if (meta is! Map) return null;
  return _int(meta['count']);
}
