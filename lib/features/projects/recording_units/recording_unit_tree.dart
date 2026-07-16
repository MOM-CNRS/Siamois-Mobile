import '../project_detail_models.dart';

/// Entrée aplatie pour l’affichage hiérarchique des UE.
class RecordingUnitTreeEntry {
  const RecordingUnitTreeEntry({
    required this.unit,
    required this.depth,
  });

  final RecordingUnitItem unit;
  final int depth;
}

/// Construit l’arborescence des UE d’un projet à partir des liens parent / enfant.
abstract final class RecordingUnitTree {
  /// Aplatit les UE en ordre préfixe (racines puis descendants indentés).
  ///
  /// Les favoris ([favoriteIds]) sont triés avant les autres au même niveau
  /// (racines et frères / sœurs).
  static List<RecordingUnitTreeEntry> flatten(
    List<RecordingUnitItem> items, {
    Set<String> favoriteIds = const {},
  }) {
    if (items.isEmpty) return const [];

    final byId = <String, RecordingUnitItem>{};
    for (final item in items) {
      byId[item.id] = item;
    }

    final childrenByParent = <String, List<RecordingUnitItem>>{};
    final assignedChild = <String>{};

    void linkChild(String parentId, RecordingUnitItem child) {
      final parent = _resolveItem(parentId, byId, items);
      if (parent == null) return;
      final bucket = childrenByParent.putIfAbsent(parent.id, () => []);
      if (bucket.any((u) => u.id == child.id)) return;
      bucket.add(child);
      assignedChild.add(child.id);
    }

    for (final item in items) {
      for (final parentId in item.parentIds) {
        linkChild(parentId, item);
      }
    }

    for (final item in items) {
      for (final childId in item.childIds) {
        final child = _resolveItem(childId, byId, items);
        if (child != null) {
          linkChild(item.id, child);
        }
      }
    }

    int compare(RecordingUnitItem a, RecordingUnitItem b) =>
        _compareUnits(a, b, favoriteIds);

    for (final list in childrenByParent.values) {
      list.sort(compare);
    }

    final roots = items.where((u) => !assignedChild.contains(u.id)).toList()
      ..sort(compare);

    final visited = <String>{};
    final result = <RecordingUnitTreeEntry>[];

    void walk(RecordingUnitItem unit, int depth) {
      if (!visited.add(unit.id)) return;
      result.add(RecordingUnitTreeEntry(unit: unit, depth: depth));
      final children = childrenByParent[unit.id] ?? const [];
      for (final child in children) {
        walk(child, depth + 1);
      }
    }

    for (final root in roots) {
      walk(root, 0);
    }

    final orphans = items.where((u) => !visited.contains(u.id)).toList()
      ..sort(compare);
    for (final orphan in orphans) {
      walk(orphan, 0);
    }

    return result;
  }

  /// Tri plat (recherche) : favoris d’abord, puis code.
  static List<RecordingUnitItem> sortFlat(
    List<RecordingUnitItem> items, {
    Set<String> favoriteIds = const {},
  }) {
    final copy = List<RecordingUnitItem>.from(items);
    copy.sort((a, b) => _compareUnits(a, b, favoriteIds));
    return copy;
  }

  static RecordingUnitItem? _resolveItem(
    String rawId,
    Map<String, RecordingUnitItem> byId,
    List<RecordingUnitItem> items,
  ) {
    final trimmed = rawId.trim();
    if (trimmed.isEmpty) return null;
    final direct = byId[trimmed];
    if (direct != null) return direct;

    for (final item in items) {
      if (_idsMatch(trimmed, item.id)) return item;
      final identifier = item.identifier;
      if (identifier != null && _idsMatch(trimmed, identifier)) return item;
      if (_idsMatch(trimmed, item.displayCode)) return item;
    }
    return null;
  }

  static bool _idsMatch(String a, String b) {
    if (a == b) return true;
    final na = int.tryParse(a);
    final nb = int.tryParse(b);
    return na != null && nb != null && na == nb;
  }

  static bool _isFavorite(RecordingUnitItem unit, Set<String> favoriteIds) {
    if (favoriteIds.isEmpty) return false;
    if (favoriteIds.contains(unit.id)) return true;
    for (final id in favoriteIds) {
      if (_idsMatch(id, unit.id)) return true;
    }
    return false;
  }

  static int _compareUnits(
    RecordingUnitItem a,
    RecordingUnitItem b,
    Set<String> favoriteIds,
  ) {
    final aFav = _isFavorite(a, favoriteIds);
    final bFav = _isFavorite(b, favoriteIds);
    if (aFav != bFav) return aFav ? -1 : 1;

    final code = a.displayCode.toLowerCase().compareTo(
          b.displayCode.toLowerCase(),
        );
    if (code != 0) return code;
    return a.id.compareTo(b.id);
  }
}
