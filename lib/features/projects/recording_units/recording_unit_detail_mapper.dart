import 'dart:convert';

import 'recording_unit_detail_models.dart';

/// Valeurs affichables pour le détail d'une UE.
abstract final class RecordingUnitDetailMapper {
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

  static List<RecordingUnitDetailRow> rowsInDisplayOrder(
    RecordingUnitMobileDetail detail,
  ) {
    final ru = detail.recordingUnit;
    final fieldsById = {
      for (final e in detail.fields.entries)
        if (e.value.fieldId > 0) e.value.fieldId: e.value,
    };

    final layoutRows = _rowsFromLayout(detail, fieldsById);
    if (layoutRows.isNotEmpty) return layoutRows;

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

    final sortedFields = detail.fields.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    for (final field in sortedFields) {
      final value = displayValueForField(field, ru);
      if (value == null || value.trim().isEmpty) continue;
      rows.add(RecordingUnitDetailRow(label: field.label, value: value));
    }

    return rows;
  }

  static List<RecordingUnitDetailRow> _rowsFromLayout(
    RecordingUnitMobileDetail detail,
    Map<int, RecordingUnitFormFieldEntry> fieldsById,
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

            final value = displayValueForField(entry, detail.recordingUnit);
            rows.add(
              RecordingUnitDetailRow(
                label: entry.label,
                value: value ?? '—',
                multiline: _isMultiline(value),
              ),
            );
          }
        }
      }

      for (final entry in fieldsById.values) {
        if (used.contains(entry.fieldId)) continue;
        final value = displayValueForField(entry, detail.recordingUnit);
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

  static String? displayValueForField(
    RecordingUnitFormFieldEntry field,
    Map<String, dynamic> recordingUnit,
  ) {
    final binding = field.valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      final fromBinding = _fromBinding(binding, recordingUnit);
      if (fromBinding != null && fromBinding.isNotEmpty) return fromBinding;
    }
    return formatCurrentValue(field.currentValue);
  }

  static String? _fromBinding(String binding, Map<String, dynamic> ru) {
    switch (binding) {
      case 'identifier':
        return _asString(ru['identifier']) ?? _asString(ru['fullIdentifier']);
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
      default:
        return null;
    }
  }

  static String? formatCurrentValue(Object? raw) {
    if (raw == null) return null;
    if (raw is String) {
      final t = raw.trim();
      return t.isEmpty ? null : t;
    }
    if (raw is num || raw is bool) return raw.toString();
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map.containsKey('lastname') || map.containsKey('name')) {
        final parts = <String>[
          if (_asString(map['name']) != null) _asString(map['name'])!,
          if (_asString(map['lastname']) != null) _asString(map['lastname'])!,
        ];
        if (parts.isNotEmpty) {
          final email = _asString(map['email']);
          final name = parts.join(' ');
          if (email != null && email.isNotEmpty) {
            return '$name ($email)';
          }
          return name;
        }
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
          _asString(map['name']) ??
          _asString(map['label']) ??
          _asString(map['fullIdentifier']);
    }
    if (raw is List) {
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
        final formatted = formatCurrentValue(item);
        if (formatted != null && formatted.isNotEmpty) {
          ruLabels.add(formatted);
        }
      }
      if (ruLabels.isNotEmpty) return ruLabels.join('\n');

      final parts = raw
          .map(formatCurrentValue)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join('\n');
    }
    return raw.toString();
  }

  static String? _panelTitle(dynamic name) {
    if (name is! String) return null;
    final key = name.trim();
    if (key.isEmpty) return null;
    if (key.startsWith('common.')) {
      final last = key.split('.').last;
      if (last == 'general') return 'Général';
      if (last == 'location') return 'Localisation';
      return last;
    }
    return key;
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
