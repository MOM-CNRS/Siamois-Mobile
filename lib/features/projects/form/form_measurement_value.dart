/// Valeur saisie pour un champ `MEASUREMENT` (taille + commentaire).
class FormMeasurementValue {
  const FormMeasurementValue({
    this.numericValue,
    this.comment = '',
    this.unitId,
    this.unitSymbol = 'm',
  });

  final double? numericValue;
  final String comment;
  final int? unitId;
  final String unitSymbol;

  bool get isEmpty =>
      numericValue == null && comment.trim().isEmpty;

  Map<String, dynamic> toFieldAnswerJson({
    int? defaultUnitId,
    String unitSymbol = 'm',
  }) {
    final map = <String, dynamic>{};
    if (numericValue != null) {
      map['numericValue'] = numericValue;
    }
    final trimmedComment = comment.trim();
    if (trimmedComment.isNotEmpty) {
      map['comment'] = trimmedComment;
    }
    final unit = <String, dynamic>{};
    final id = unitId ?? defaultUnitId;
    if (id != null) {
      unit['id'] = id;
    }
    final symbol =
        (this.unitSymbol.isNotEmpty ? this.unitSymbol : unitSymbol);
    if (symbol.isNotEmpty) {
      unit['symbol'] = symbol;
    }
    if (unit.isNotEmpty) {
      map['unit'] = unit;
    }
    return map;
  }

  static FormMeasurementValue? fromDynamic(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final numeric = parseDouble(map['numericValue']?.toString());
    final comment = map['comment']?.toString().trim() ?? '';

    int? unitId;
    var unitSymbol = 'm';
    final unitRaw = map['unit'];
    if (unitRaw is Map) {
      final unitMap = Map<String, dynamic>.from(unitRaw);
      unitId = _parseInt(unitMap['id']);
      unitSymbol = unitMap['symbol']?.toString().trim() ?? unitSymbol;
    }

    if (numeric == null && comment.isEmpty) return null;

    return FormMeasurementValue(
      numericValue: numeric,
      comment: comment,
      unitId: unitId,
      unitSymbol: unitSymbol.isEmpty ? 'm' : unitSymbol,
    );
  }

  static double? parseDouble(dynamic raw) {
    if (raw == null) return null;
    final normalized = raw.toString().trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  static int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}
