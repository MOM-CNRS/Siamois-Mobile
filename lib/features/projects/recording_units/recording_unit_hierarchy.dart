import '../form/project_form_models.dart';
import '../form/recording_unit_option.dart';
import '../project_detail_models.dart';
import 'recording_unit_detail_models.dart';

/// Parents et enfants d’une UE pour la fiche détail.
class RecordingUnitHierarchy {
  RecordingUnitHierarchy({
    required List<RecordingUnitOption> parents,
    required List<RecordingUnitOption> children,
  })  : parents = RecordingUnitOption.sortAscending(parents),
        children = RecordingUnitOption.sortAscending(children);

  final List<RecordingUnitOption> parents;
  final List<RecordingUnitOption> children;

  bool get isEmpty => parents.isEmpty && children.isEmpty;

  static RecordingUnitHierarchy resolve(RecordingUnitMobileDetail detail) {
    final parents = <RecordingUnitOption>[
      ...RecordingUnitItem.parentOptionsFromJson(detail.recordingUnit),
    ];
    final children = <RecordingUnitOption>[
      ...RecordingUnitItem.childOptionsFromJson(detail.recordingUnit),
    ];

    void addParents(Iterable<RecordingUnitOption> options) {
      for (final option in options) {
        if (!RecordingUnitOption.listContainsUnit(parents, option)) {
          parents.add(option);
        }
      }
    }

    void addChildren(Iterable<RecordingUnitOption> options) {
      for (final option in options) {
        if (!RecordingUnitOption.listContainsUnit(children, option)) {
          children.add(option);
        }
      }
    }

    for (final entry in detail.fields.values) {
      if (!_isHierarchyField(entry)) continue;

      final raw = entry.currentValue ??
          (entry.valueBinding != null
              ? detail.recordingUnit[entry.valueBinding]
              : null);
      final isParent = isParentRelationField(
        label: entry.label,
        valueBinding: entry.valueBinding,
        fieldCode: entry.fieldCode,
        answerType: entry.answerType,
        hint: entry.hint,
      );
      final isChild = isChildRelationField(
        label: entry.label,
        valueBinding: entry.valueBinding,
        fieldCode: entry.fieldCode,
        answerType: entry.answerType,
        hint: entry.hint,
      );
      if (!isParent && !isChild) continue;

      final options = RecordingUnitOption.listFromCurrentValue(raw);
      if (isParent) addParents(options);
      if (isChild) addChildren(options);
    }

    return RecordingUnitHierarchy(
      parents: RecordingUnitOption.dedupe(parents),
      children: RecordingUnitOption.dedupe(children),
    );
  }

  static bool _isHierarchyField(RecordingUnitFormFieldEntry field) {
    return isParentRelationField(
          label: field.label,
          valueBinding: field.valueBinding,
          fieldCode: field.fieldCode,
          answerType: field.answerType,
        ) ||
        isChildRelationField(
          label: field.label,
          valueBinding: field.valueBinding,
          fieldCode: field.fieldCode,
          answerType: field.answerType,
        );
  }

  static bool isParentRelationField({
    required String label,
    String? valueBinding,
    String? fieldCode,
    String? answerType,
    String? hint,
  }) {
    if (_matchesRelationKey(valueBinding, _parentRelationBindings) ||
        _matchesRelationKey(fieldCode, _parentRelationBindings)) {
      return true;
    }
    if (!_isRecordingUnitRelationAnswerType(answerType, label, hint: hint)) {
      return false;
    }
    return _labelLooksLikeParent(label) || _labelLooksLikeParent(hint ?? '');
  }

  static bool isChildRelationField({
    required String label,
    String? valueBinding,
    String? fieldCode,
    String? answerType,
    String? hint,
  }) {
    if (_matchesRelationKey(valueBinding, _childRelationBindings) ||
        _matchesRelationKey(fieldCode, _childRelationBindings)) {
      return true;
    }
    if (!_isRecordingUnitRelationAnswerType(answerType, label, hint: hint)) {
      return false;
    }
    return _labelLooksLikeChild(label) || _labelLooksLikeChild(hint ?? '');
  }

  static bool _labelLooksLikeParent(String raw) {
    final label = raw.trim().toLowerCase();
    if (label.isEmpty) return false;
    return label.contains('partie') ||
        label.contains('parent') ||
        label.contains('mère') ||
        label.contains('mere') ||
        label.contains('supérieur') ||
        label.contains('superieur') ||
        label.contains('inclu') ||
        label.contains('rattach');
  }

  static bool _labelLooksLikeChild(String raw) {
    final label = raw.trim().toLowerCase();
    if (label.isEmpty) return false;
    return label.contains('contient') ||
        label.contains('child') ||
        label.contains('fille') ||
        label.contains('fils') ||
        label.contains('enfant') ||
        label.contains('inférieur') ||
        label.contains('inferieur') ||
        label.contains('descendant');
  }

  static bool _isRecordingUnitRelationAnswerType(
    String? answerType,
    String label, {
    String? hint,
  }) {
    final normalized = ProjectAnswerType.normalize(answerType);
    if (normalized == ProjectAnswerType.selectMultipleRecordingUnit) {
      return true;
    }
    if (normalized.isNotEmpty) return false;
    return _labelLooksLikeParent(label) ||
        _labelLooksLikeChild(label) ||
        _labelLooksLikeParent(hint ?? '') ||
        _labelLooksLikeChild(hint ?? '');
  }

  /// Valeurs actuelles d’un champ parent / enfant (formulaire ou `recordingUnit`).
  static List<RecordingUnitOption> currentValuesForField(
    RecordingUnitMobileDetail detail,
    ProjectFormField field,
  ) {
    final out = <RecordingUnitOption>[];

    void addAll(Iterable<RecordingUnitOption> options) {
      for (final option in options) {
        if (!RecordingUnitOption.listContainsUnit(out, option)) {
          out.add(option);
        }
      }
    }

    final entry = detail.fields['${field.fieldId}'];
    if (entry?.currentValue != null) {
      addAll(RecordingUnitOption.listFromCurrentValue(entry!.currentValue));
    }

    final binding = field.valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      addAll(
        RecordingUnitOption.listFromCurrentValue(detail.recordingUnit[binding]),
      );
    }

    if (isParentRelationField(
      label: field.label,
      valueBinding: field.valueBinding,
      fieldCode: field.fieldCode,
      answerType: field.answerType,
      hint: field.hint,
    )) {
      addAll(RecordingUnitItem.parentOptionsFromJson(detail.recordingUnit));
    }
    if (isChildRelationField(
      label: field.label,
      valueBinding: field.valueBinding,
      fieldCode: field.fieldCode,
      answerType: field.answerType,
      hint: field.hint,
    )) {
      addAll(RecordingUnitItem.childOptionsFromJson(detail.recordingUnit));
    }

    return RecordingUnitOption.dedupe(out);
  }

  /// Met à jour les clés `parents` / `children` du JSON UE après modification locale.
  static void writeRelationsToRecordingUnit(
    Map<String, dynamic> recordingUnit, {
    required bool asParent,
    required List<RecordingUnitOption> options,
    required List<Map<String, dynamic>> answerJson,
    String? valueBinding,
  }) {
    final unique = RecordingUnitOption.uniqueRelationList(options);
    options = unique.options;
    answerJson = unique.answerJson;

    final binding = valueBinding?.trim();
    if (binding != null && binding.isNotEmpty) {
      recordingUnit[binding] = answerJson;
    }

    final keys = asParent ? _parentRelationBindings : _childRelationBindings;
    for (final key in keys) {
      recordingUnit[key] = answerJson;
    }

    if (asParent) {
      recordingUnit['parents'] = _asRelationshipData(options, answerJson);
    } else {
      recordingUnit['children'] = _asRelationshipData(options, answerJson);
    }
  }

  static Map<String, dynamic> _asRelationshipData(
    List<RecordingUnitOption> options,
    List<Map<String, dynamic>> answerJson,
  ) {
    final data = <Map<String, dynamic>>[];
    for (var i = 0; i < options.length; i++) {
      final option = options[i];
      final attrs = i < answerJson.length
          ? Map<String, dynamic>.from(answerJson[i])
          : option.toFieldAnswerJson();
      data.add({
        'id': option.numericId ?? int.tryParse(option.key),
        'resourceId': option.key,
        'fullIdentifier': option.label,
        if (option.identifier != null) 'identifier': option.identifier,
        'attributes': attrs,
      });
    }
    return {'data': data};
  }

  static bool _matchesRelationKey(String? raw, Set<String> keys) {
    if (raw == null) return false;
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return false;
    return keys.contains(key);
  }

  static const _parentRelationBindings = {
    'partof',
    'partoflist',
    'includedin',
    'includedinrecordingunitlist',
    'parentrecordingunitlist',
    'parentrecordingunits',
    'parents',
  };

  static const _childRelationBindings = {
    'contains',
    'containslist',
    'containedrecordingunits',
    'contentrecordingunitlist',
    'childrecordingunitlist',
    'childrecordingunits',
    'children',
  };

  /// Complète code / type à partir du catalogue projet (cache SQLite).
  static List<RecordingUnitOption> enrichFromCatalog(
    List<RecordingUnitOption> options,
    List<RecordingUnitItem> catalog,
  ) {
    if (options.isEmpty || catalog.isEmpty) return options;

    final byKey = <String, RecordingUnitItem>{};
    for (final item in catalog) {
      byKey[item.id] = item;
      final identifier = item.identifier?.trim();
      if (identifier != null && identifier.isNotEmpty) {
        byKey[identifier] = item;
      }
    }

    return options.map((option) {
      final item = byKey[option.key] ??
          (option.numericId != null
              ? byKey[option.numericId.toString()]
              : null);
      if (item != null) return RecordingUnitOption.fromItem(item);
      return option;
    }).toList();
  }

  static List<RecordingUnitOption> optionsFromIdList(
    List<String> ids,
    List<RecordingUnitItem> catalog,
  ) {
    if (ids.isEmpty) return const [];

    final out = <RecordingUnitOption>[];
    for (final rawId in ids) {
      final key = rawId.trim();
      if (key.isEmpty) continue;
      final item = _resolveCatalogItem(key, catalog);
      if (item != null) {
        out.add(RecordingUnitOption.fromItem(item));
      } else {
        out.add(RecordingUnitOption(key: key, label: key));
      }
    }
    return RecordingUnitOption.dedupe(out);
  }

  /// Fusionne détail UE, fiche catalogue projet et liens inverses (comme l’arborescence).
  static RecordingUnitHierarchy enrichWithCatalog({
    required RecordingUnitHierarchy base,
    required List<RecordingUnitItem> catalog,
    String? currentRecordingUnitId,
    RecordingUnitItem? summary,
  }) {
    var parents = enrichFromCatalog(base.parents, catalog);
    var children = enrichFromCatalog(base.children, catalog);

    final currentId = currentRecordingUnitId?.trim();
    RecordingUnitItem? self;
    if (currentId != null && currentId.isNotEmpty) {
      self = _resolveCatalogItem(currentId, catalog);
    }
    self ??= summary;

    if (self != null) {
      if (self.parentIds.isNotEmpty) {
        parents = _mergeOptions(
          parents,
          optionsFromIdList(self.parentIds, catalog),
        );
      }
      if (self.childIds.isNotEmpty) {
        children = _mergeOptions(
          children,
          optionsFromIdList(self.childIds, catalog),
        );
      }
    }

    if (currentId != null && currentId.isNotEmpty && catalog.isNotEmpty) {
      final invertedChildren = catalog
          .where(
            (item) =>
                !_itemRefersToId(item, currentId) &&
                item.parentIds.any(
                  (parentId) => _catalogIdRefersToUnit(
                    parentId,
                    currentId,
                    catalog,
                    self,
                  ),
                ),
          )
          .map(RecordingUnitOption.fromItem)
          .toList();
      children = _mergeOptions(children, invertedChildren);

      final invertedParents = catalog
          .where(
            (item) =>
                !_itemRefersToId(item, currentId) &&
                item.childIds.any(
                  (childId) => _catalogIdRefersToUnit(
                    childId,
                    currentId,
                    catalog,
                    self,
                  ),
                ),
          )
          .map(RecordingUnitOption.fromItem)
          .toList();
      parents = _mergeOptions(parents, invertedParents);
    }

    parents = _withoutSelf(parents, currentId);
    children = _withoutSelf(children, currentId);

    return RecordingUnitHierarchy(
      parents: RecordingUnitOption.dedupe(parents),
      children: RecordingUnitOption.dedupe(children),
    );
  }

  static List<RecordingUnitOption> _mergeOptions(
    List<RecordingUnitOption> existing,
    List<RecordingUnitOption> extra,
  ) {
    if (extra.isEmpty) return existing;
    if (existing.isEmpty) return RecordingUnitOption.dedupe(extra);
    return RecordingUnitOption.dedupe([...existing, ...extra]);
  }

  static RecordingUnitItem? _resolveCatalogItem(
    String rawId,
    List<RecordingUnitItem> catalog,
  ) {
    final trimmed = rawId.trim();
    if (trimmed.isEmpty) return null;

    for (final item in catalog) {
      if (_itemRefersToId(item, trimmed)) return item;
    }
    return null;
  }

  static bool _itemRefersToId(RecordingUnitItem item, String rawId) {
    if (_idMatches(item.id, rawId)) return true;
    final identifier = item.identifier?.trim();
    if (identifier != null &&
        identifier.isNotEmpty &&
        _idMatches(identifier, rawId)) {
      return true;
    }
    if (_idMatches(item.displayCode, rawId)) return true;
    return false;
  }

  static bool _catalogIdRefersToUnit(
    String candidateId,
    String targetUnitId,
    List<RecordingUnitItem> catalog,
    RecordingUnitItem? targetItem,
  ) {
    final target = targetItem ?? _resolveCatalogItem(targetUnitId, catalog);
    if (target != null) {
      return _itemRefersToId(target, candidateId);
    }
    return _idMatches(candidateId, targetUnitId);
  }

  static List<RecordingUnitOption> _withoutSelf(
    List<RecordingUnitOption> options,
    String? currentId,
  ) {
    if (currentId == null || currentId.trim().isEmpty) return options;
    return options.where((o) => !o.isSameAs(currentId)).toList();
  }

  static bool _idMatches(String candidate, String currentId) {
    if (candidate == currentId) return true;
    final candidateNum = int.tryParse(candidate);
    final currentNum = int.tryParse(currentId);
    if (candidateNum != null &&
        currentNum != null &&
        candidateNum == currentNum) {
      return true;
    }
    return false;
  }

  static RecordingUnitItem summaryItem(RecordingUnitOption option) {
    return RecordingUnitItem(
      id: option.key,
      displayCode: option.label,
      identifier: option.identifier,
      typeLabel: option.typeLabel,
    );
  }

  /// Option UE source pour le lien inverse (UE courante → autre fiche).
  /// Conserve les liens présents en cache local mais absents de la réponse API.
  static RecordingUnitMobileDetail mergeCachedHierarchy({
    required RecordingUnitMobileDetail apiDetail,
    required RecordingUnitMobileDetail cachedDetail,
  }) {
    final apiHierarchy = resolve(apiDetail);
    final cachedHierarchy = resolve(cachedDetail);

    final parents = RecordingUnitOption.dedupe([
      ...apiHierarchy.parents,
      ...cachedHierarchy.parents,
    ]);
    final children = RecordingUnitOption.dedupe([
      ...apiHierarchy.children,
      ...cachedHierarchy.children,
    ]);

    if (parents.length == apiHierarchy.parents.length &&
        children.length == apiHierarchy.children.length) {
      return apiDetail;
    }

    var recordingUnit = Map<String, dynamic>.from(apiDetail.recordingUnit);
    if (parents.isNotEmpty) {
      final answerJson = parents.map((e) => e.toFieldAnswerJson()).toList();
      writeRelationsToRecordingUnit(
        recordingUnit,
        asParent: true,
        options: parents,
        answerJson: answerJson,
        valueBinding: 'parents',
      );
    }
    if (children.isNotEmpty) {
      final answerJson = children.map((e) => e.toFieldAnswerJson()).toList();
      writeRelationsToRecordingUnit(
        recordingUnit,
        asParent: false,
        options: children,
        answerJson: answerJson,
        valueBinding: 'children',
      );
    }

    return RecordingUnitMobileDetail(
      recordingUnit: recordingUnit,
      formName: apiDetail.formName,
      layoutJson: apiDetail.layoutJson,
      fields: apiDetail.fields,
    );
  }

  static RecordingUnitOption sourceOptionFromDetail(
    RecordingUnitMobileDetail detail,
    String recordingUnitId,
  ) {
    return RecordingUnitOption(
      key: recordingUnitId.trim(),
      label: detail.displayCode,
      numericId: detail.numericRecordingUnitId,
      identifier: _string(detail.recordingUnit['identifier']),
      typeLabel: detail.typeLabel,
    );
  }

  static String? _string(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}
