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
    this.placeLabel,
    this.openingDate,
    this.closingDate,
    this.matrixColor,
    this.specimenCount,
    this.stratigraphicCount,
  });

  final String id;
  final String displayCode;
  final String? identifier;
  final String? typeLabel;
  final String? placeLabel;
  final DateTime? openingDate;
  final DateTime? closingDate;
  final String? matrixColor;
  final int? specimenCount;
  final int? stratigraphicCount;

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
      placeLabel: _relationshipLabel(json['place']),
      openingDate: _parseDate(json['openingDate']),
      closingDate: _parseDate(json['closingDate']),
      matrixColor: _string(json['matrixColor']),
      specimenCount: _relationshipCount(json['specimen']),
      stratigraphicCount: _relationshipCount(json['stratigraphicRelationships']),
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

  bool get hasMore => offset + items.length < total;
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
