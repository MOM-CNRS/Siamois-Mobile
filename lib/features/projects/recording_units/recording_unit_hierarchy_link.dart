import '../../../core/database/app_database.dart' hide Form;
import '../../../core/sync/entity_snapshot_store.dart';
import '../../../core/sync/outbox_store.dart';
import '../../auth/auth_repository.dart';
import '../form/project_form_models.dart';
import '../form/recording_unit_option.dart';
import '../project_detail_models.dart';
import 'recording_unit_detail_models.dart';
import 'recording_unit_detail_store.dart';
import 'recording_unit_form_cache.dart';
import 'recording_unit_hierarchy.dart';
import 'recording_unit_list_store.dart';

/// Ajout / retrait d’une UE parente ou fille depuis la fiche détail.
class RecordingUnitHierarchyLink {
  RecordingUnitHierarchyLink({
    required AuthRepository auth,
    required AppDatabase database,
  })  : _auth = auth,
        _database = database,
        _detailStore = RecordingUnitDetailStore(auth: auth, db: database),
        _listStore = RecordingUnitListStore(auth: auth, db: database);

  final AuthRepository _auth;
  final AppDatabase _database;
  final RecordingUnitDetailStore _detailStore;
  final RecordingUnitListStore _listStore;

  Future<RecordingUnitMobileDetail> addRelatedUnit({
    required String recordingUnitId,
    required RecordingUnitMobileDetail detail,
    required ProjectFormField field,
    required bool asParent,
    required RecordingUnitOption toAdd,
    String? projectId,
  }) async {
    final existing = RecordingUnitOption.dedupe(
      RecordingUnitHierarchy.currentValuesForField(detail, field),
    );
    if (RecordingUnitOption.listContainsUnit(existing, toAdd)) {
      throw const FormatException('Cette UE est déjà liée à cette unité.');
    }

    final unique = RecordingUnitOption.uniqueRelationList([
      ...existing,
      toAdd,
    ]);
    final merged = unique.options;
    final answerJson = unique.answerJson;
    final fieldAnswers = <String, dynamic>{
      '${field.fieldId}': answerJson,
    };

    final online = await _auth.canUseProjectsApi();
    if (!online) {
      final snapshotStore = EntitySnapshotStore(_database);
      final baseRevision =
          await snapshotStore.recordingUnitBaseRevision(recordingUnitId);

      await OutboxStore(_database).enqueueRecordingUnitUpdate(
        recordingUnitId: recordingUnitId,
        fieldAnswers: fieldAnswers,
        baseServerRevision: baseRevision,
        projectId: projectId,
      );

      final localDetail = applyFieldMutation(
        detail: detail,
        field: field,
        asParent: asParent,
        merged: merged,
        answerJson: answerJson,
      );
      await _persist(localDetail, projectId: projectId);
      await _saveOfflineSnapshot(
        recordingUnitId: recordingUnitId,
        detail: localDetail,
        baseRevision: baseRevision,
      );
      await _syncInverseLink(
        sourceDetail: localDetail,
        sourceRecordingUnitId: recordingUnitId,
        relatedOption: toAdd,
        asParentOnSource: asParent,
        projectId: projectId,
        online: false,
      );
      return localDetail;
    }

    final relatedNumericId = toAdd.serverRecordingUnitId;
    if (relatedNumericId == null) {
      throw const FormatException(
        'Identifiant numérique de l’unité à lier introuvable.',
      );
    }

    final updated = asParent
        ? await _auth.linkRecordingUnitParent(
            childRecordingUnitId: recordingUnitId,
            parentRecordingUnitId: relatedNumericId,
          )
        : await _auth.linkRecordingUnitChild(
            parentRecordingUnitId: recordingUnitId,
            childRecordingUnitId: relatedNumericId,
          );

    await _persist(updated, projectId: projectId);

    await EntitySnapshotStore(_database).saveRecordingUnitSnapshot(
      entityId: recordingUnitId,
      serverRevision: readRecordingUnitSyncRevision(updated.recordingUnit),
      detailApiData: updated.toApiData(),
    );

    await _syncInverseLink(
      sourceDetail: updated,
      sourceRecordingUnitId: recordingUnitId,
      relatedOption: toAdd,
      asParentOnSource: asParent,
      projectId: projectId,
      online: true,
    );

    return updated;
  }

  Future<RecordingUnitMobileDetail> removeRelatedUnit({
    required String recordingUnitId,
    required RecordingUnitMobileDetail detail,
    required ProjectFormField field,
    required bool asParent,
    required RecordingUnitOption toRemove,
    String? projectId,
  }) async {
    final existing = RecordingUnitOption.dedupe(
      RecordingUnitHierarchy.currentValuesForField(detail, field),
    );
    if (!RecordingUnitOption.listContainsUnit(existing, toRemove)) {
      throw const FormatException('Cette UE n’est pas liée à cette unité.');
    }

    final unique = RecordingUnitOption.uniqueRelationList(
      existing
          .where((e) => !RecordingUnitOption.refersToSameUnit(e, toRemove))
          .toList(),
    );
    final merged = unique.options;
    final answerJson = unique.answerJson;
    final fieldAnswers = <String, dynamic>{
      '${field.fieldId}': answerJson,
    };

    final online = await _auth.canUseProjectsApi();
    if (!online) {
      final snapshotStore = EntitySnapshotStore(_database);
      final baseRevision =
          await snapshotStore.recordingUnitBaseRevision(recordingUnitId);

      await OutboxStore(_database).enqueueRecordingUnitUpdate(
        recordingUnitId: recordingUnitId,
        fieldAnswers: fieldAnswers,
        baseServerRevision: baseRevision,
        projectId: projectId,
      );

      final localDetail = applyFieldMutation(
        detail: detail,
        field: field,
        asParent: asParent,
        merged: merged,
        answerJson: answerJson,
      );
      await _persist(localDetail, projectId: projectId);
      await _saveOfflineSnapshot(
        recordingUnitId: recordingUnitId,
        detail: localDetail,
        baseRevision: baseRevision,
      );
      await _removeInverseLink(
        sourceDetail: localDetail,
        sourceRecordingUnitId: recordingUnitId,
        relatedOption: toRemove,
        asParentOnSource: asParent,
        projectId: projectId,
        online: false,
      );
      return localDetail;
    }

    final relatedNumericId = toRemove.serverRecordingUnitId;
    if (relatedNumericId == null) {
      throw const FormatException(
        'Identifiant numérique de l’unité à délier introuvable.',
      );
    }

    final updated = asParent
        ? await _auth.unlinkRecordingUnitParent(
            childRecordingUnitId: recordingUnitId,
            parentRecordingUnitId: relatedNumericId,
          )
        : await _auth.unlinkRecordingUnitChild(
            parentRecordingUnitId: recordingUnitId,
            childRecordingUnitId: relatedNumericId,
          );

    await _persist(updated, projectId: projectId);

    await EntitySnapshotStore(_database).saveRecordingUnitSnapshot(
      entityId: recordingUnitId,
      serverRevision: readRecordingUnitSyncRevision(updated.recordingUnit),
      detailApiData: updated.toApiData(),
    );

    await _removeInverseLink(
      sourceDetail: updated,
      sourceRecordingUnitId: recordingUnitId,
      relatedOption: toRemove,
      asParentOnSource: asParent,
      projectId: projectId,
      online: true,
    );

    return updated;
  }

  /// Met à jour la fiche de l’UE liée (parent ↔ enfant réciproque).
  Future<void> _syncInverseLink({
    required RecordingUnitMobileDetail sourceDetail,
    required String sourceRecordingUnitId,
    required RecordingUnitOption relatedOption,
    required bool asParentOnSource,
    String? projectId,
    required bool online,
  }) async {
    final relatedId = relatedOption.key.trim();
    if (relatedId.isEmpty) return;

    final sourceOption = RecordingUnitHierarchy.sourceOptionFromDetail(
      sourceDetail,
      sourceRecordingUnitId,
    );
    if (RecordingUnitOption.refersToSameUnit(sourceOption, relatedOption)) return;

    // A ajoute B comme parente → B doit lister A comme fille, et inversement.
    final mirrorAsParent = !asParentOnSource;

    if (online) {
      await _refreshRelatedDetailFromServer(
        relatedId: relatedId,
        projectId: projectId,
      );
      return;
    }

    await _mirrorRelatedDetail(
      relatedOption: relatedOption,
      sourceOption: sourceOption,
      mirrorAsParent: mirrorAsParent,
      projectId: projectId,
      online: online,
      add: true,
    );
  }

  /// Retire le lien réciproque sur l’UE associée.
  Future<void> _removeInverseLink({
    required RecordingUnitMobileDetail sourceDetail,
    required String sourceRecordingUnitId,
    required RecordingUnitOption relatedOption,
    required bool asParentOnSource,
    String? projectId,
    required bool online,
  }) async {
    final relatedId = relatedOption.key.trim();
    if (relatedId.isEmpty) return;

    final sourceOption = RecordingUnitHierarchy.sourceOptionFromDetail(
      sourceDetail,
      sourceRecordingUnitId,
    );
    if (RecordingUnitOption.refersToSameUnit(sourceOption, relatedOption)) return;

    final mirrorAsParent = !asParentOnSource;

    if (online) {
      await _refreshRelatedDetailFromServer(
        relatedId: relatedId,
        projectId: projectId,
      );
      return;
    }

    await _mirrorRelatedDetail(
      relatedOption: relatedOption,
      sourceOption: sourceOption,
      mirrorAsParent: mirrorAsParent,
      projectId: projectId,
      online: online,
      add: false,
    );
  }

  Future<void> _refreshRelatedDetailFromServer({
    required String relatedId,
    String? projectId,
  }) async {
    try {
      final refreshed = await _auth.fetchRecordingUnitDetail(relatedId);
      await _persist(refreshed, projectId: projectId);
      await EntitySnapshotStore(_database).saveRecordingUnitSnapshot(
        entityId: relatedId,
        serverRevision: readRecordingUnitSyncRevision(refreshed.recordingUnit),
        detailApiData: refreshed.toApiData(),
      );
    } catch (_) {
      // Le cache local de l’UE liée reste inchangé.
    }
  }

  Future<void> _mirrorRelatedDetail({
    required RecordingUnitOption relatedOption,
    required RecordingUnitOption sourceOption,
    required bool mirrorAsParent,
    String? projectId,
    required bool online,
    required bool add,
  }) async {
    final relatedId = relatedOption.key.trim();
    final relatedSummary = await _summaryForRelated(relatedOption, projectId);
    var relatedDetail = await _detailStore.loadFromCache(
      relatedId,
      summary: relatedSummary,
    );
    relatedDetail ??= _minimalDetailFromOption(relatedOption);

    final formCache = RecordingUnitFormCache(
      auth: _auth,
      db: _database,
    );
    ProjectFormDefinition? definition;
    final typeId = await formCache.resolveTypeConceptIdForEdit(
      detail: relatedDetail,
      recordingUnitId: relatedId,
    );
    if (typeId != null && projectId != null && projectId.trim().isNotEmpty) {
      try {
        final form = await formCache.loadFormForRecordingUnitType(
          projectId: projectId,
          typeConceptId: typeId,
        );
        definition = form.definition;
      } catch (_) {
        // Mise à jour JSON seule si le formulaire est indisponible.
      }
    }

    final hierarchyFields = RecordingUnitHierarchyFields.resolve(
      definition: definition,
      detail: relatedDetail,
    );
    final mirrorField = mirrorAsParent
        ? hierarchyFields.parentField
        : hierarchyFields.childField;

    RecordingUnitMobileDetail updated;
    Map<String, dynamic>? mirrorFieldAnswers;

    if (mirrorField == null) {
      updated = add
          ? _mirrorWithoutFormField(
              detail: relatedDetail,
              sourceOption: sourceOption,
              asParent: mirrorAsParent,
            )
          : _unmirrorWithoutFormField(
              detail: relatedDetail,
              sourceOption: sourceOption,
              asParent: mirrorAsParent,
            );
    } else {
      final existing = RecordingUnitOption.dedupe(
        RecordingUnitHierarchy.currentValuesForField(relatedDetail, mirrorField),
      );
      late final ({
        List<RecordingUnitOption> options,
        List<Map<String, dynamic>> answerJson,
      }) uniqueMerged;
      if (add) {
        if (RecordingUnitOption.listContainsUnit(existing, sourceOption)) {
          return;
        }
        uniqueMerged = RecordingUnitOption.uniqueRelationList([
          ...existing,
          sourceOption,
        ]);
      } else {
        if (!RecordingUnitOption.listContainsUnit(existing, sourceOption)) {
          return;
        }
        uniqueMerged = RecordingUnitOption.uniqueRelationList(
          existing
              .where(
                (e) => !RecordingUnitOption.refersToSameUnit(e, sourceOption),
              )
              .toList(),
        );
      }

      final merged = uniqueMerged.options;
      final answerJson = uniqueMerged.answerJson;
      mirrorFieldAnswers = {'${mirrorField.fieldId}': answerJson};
      updated = applyFieldMutation(
        detail: relatedDetail,
        field: mirrorField,
        asParent: mirrorAsParent,
        merged: merged,
        answerJson: answerJson,
      );
    }

    await _persist(updated, projectId: projectId);

    if (!online) {
      final snapshotStore = EntitySnapshotStore(_database);
      final baseRevision =
          await snapshotStore.recordingUnitBaseRevision(relatedId);
      await _saveOfflineSnapshot(
        recordingUnitId: relatedId,
        detail: updated,
        baseRevision: baseRevision,
      );
      if (mirrorField != null && mirrorFieldAnswers != null) {
        await OutboxStore(_database).enqueueRecordingUnitUpdate(
          recordingUnitId: relatedId,
          fieldAnswers: mirrorFieldAnswers,
          baseServerRevision: baseRevision,
          projectId: projectId,
        );
      }
    }
  }

  Future<void> _saveOfflineSnapshot({
    required String recordingUnitId,
    required RecordingUnitMobileDetail detail,
    required int? baseRevision,
  }) async {
    await EntitySnapshotStore(_database).saveRecordingUnitSnapshot(
      entityId: recordingUnitId.trim(),
      serverRevision: baseRevision ?? 0,
      detailApiData: detail.toApiData(),
    );
  }

  Future<RecordingUnitItem?> _summaryForRelated(
    RecordingUnitOption relatedOption,
    String? projectId,
  ) async {
    final projectKey = projectId?.trim();
    if (projectKey == null || projectKey.isEmpty) {
      return RecordingUnitHierarchy.summaryItem(relatedOption);
    }

    final catalog =
        await _listStore.loadAllFromCacheForProject(projectKey);
    for (final item in catalog) {
      if (item.id == relatedOption.key ||
          item.identifier == relatedOption.key ||
          relatedOption.isSameAs(item.id)) {
        return item;
      }
    }
    return RecordingUnitHierarchy.summaryItem(relatedOption);
  }

  static RecordingUnitMobileDetail _minimalDetailFromOption(
    RecordingUnitOption option,
  ) {
    return RecordingUnitMobileDetail(
      recordingUnit: {
        'resourceId': option.key,
        'id': option.numericId ?? option.key,
        'fullIdentifier': option.label,
        if (option.identifier != null) 'identifier': option.identifier,
      },
      fields: const {},
    );
  }

  static RecordingUnitMobileDetail _mirrorWithoutFormField({
    required RecordingUnitMobileDetail detail,
    required RecordingUnitOption sourceOption,
    required bool asParent,
  }) {
    final existing = asParent
        ? RecordingUnitItem.parentOptionsFromJson(detail.recordingUnit)
        : RecordingUnitItem.childOptionsFromJson(detail.recordingUnit);
    if (RecordingUnitOption.listContainsUnit(existing, sourceOption)) {
      return detail;
    }

    final unique = RecordingUnitOption.uniqueRelationList([
      ...existing,
      sourceOption,
    ]);
    final recordingUnit = Map<String, dynamic>.from(detail.recordingUnit);
    RecordingUnitHierarchy.writeRelationsToRecordingUnit(
      recordingUnit,
      asParent: asParent,
      options: unique.options,
      answerJson: unique.answerJson,
      valueBinding: asParent ? 'parents' : 'children',
    );

    return RecordingUnitMobileDetail(
      recordingUnit: recordingUnit,
      formName: detail.formName,
      layoutJson: detail.layoutJson,
      fields: detail.fields,
    );
  }

  static RecordingUnitMobileDetail _unmirrorWithoutFormField({
    required RecordingUnitMobileDetail detail,
    required RecordingUnitOption sourceOption,
    required bool asParent,
  }) {
    final existing = asParent
        ? RecordingUnitItem.parentOptionsFromJson(detail.recordingUnit)
        : RecordingUnitItem.childOptionsFromJson(detail.recordingUnit);
    if (!RecordingUnitOption.listContainsUnit(existing, sourceOption)) {
      return detail;
    }

    final unique = RecordingUnitOption.uniqueRelationList(
      existing
          .where((e) => !RecordingUnitOption.refersToSameUnit(e, sourceOption))
          .toList(),
    );
    final recordingUnit = Map<String, dynamic>.from(detail.recordingUnit);
    RecordingUnitHierarchy.writeRelationsToRecordingUnit(
      recordingUnit,
      asParent: asParent,
      options: unique.options,
      answerJson: unique.answerJson,
      valueBinding: asParent ? 'parents' : 'children',
    );

    return RecordingUnitMobileDetail(
      recordingUnit: recordingUnit,
      formName: detail.formName,
      layoutJson: detail.layoutJson,
      fields: detail.fields,
    );
  }

  Future<void> _persist(
    RecordingUnitMobileDetail detail, {
    String? projectId,
  }) async {
    await _detailStore.saveAfterMutation(detail, projectId: projectId);

    final item = RecordingUnitItem.fromJson(detail.recordingUnit);
    if (item.id.isNotEmpty && projectId != null && projectId.trim().isNotEmpty) {
      await _listStore.upsertLocal(
        item: item,
        projectId: projectId.trim(),
        typeConceptId: detail.typeConceptId,
      );
    }
  }

  static RecordingUnitMobileDetail applyFieldMutation({
    required RecordingUnitMobileDetail detail,
    required ProjectFormField field,
    required bool asParent,
    required List<RecordingUnitOption> merged,
    required List<Map<String, dynamic>> answerJson,
  }) {
    final unique = RecordingUnitOption.uniqueRelationList(merged);
    merged = unique.options;
    answerJson = unique.answerJson;

    final fields = Map<String, RecordingUnitFormFieldEntry>.from(detail.fields);
    final fieldKey = '${field.fieldId}';
    final existing = fields[fieldKey];
    fields[fieldKey] = RecordingUnitFormFieldEntry(
      fieldId: field.fieldId,
      label: existing?.label ?? field.label,
      hint: existing?.hint ?? field.hint,
      answerType:
          existing?.answerType ?? field.answerType,
      valueBinding: existing?.valueBinding ?? field.valueBinding,
      fieldCode: existing?.fieldCode ?? field.fieldCode,
      currentValue: answerJson,
    );

    final recordingUnit = Map<String, dynamic>.from(detail.recordingUnit);
    RecordingUnitHierarchy.writeRelationsToRecordingUnit(
      recordingUnit,
      asParent: asParent,
      options: merged,
      answerJson: answerJson,
      valueBinding: field.valueBinding,
    );

    return RecordingUnitMobileDetail(
      recordingUnit: recordingUnit,
      formName: detail.formName,
      layoutJson: detail.layoutJson,
      fields: fields,
    );
  }
}

/// Champs formulaire « partie de » / « contient » pour lier des UE.
class RecordingUnitHierarchyFields {
  const RecordingUnitHierarchyFields({
    this.parentField,
    this.childField,
  });

  final ProjectFormField? parentField;
  final ProjectFormField? childField;

  bool get canLinkParent => parentField != null;
  bool get canLinkChild => childField != null;
  bool get canLink => canLinkParent || canLinkChild;

  static RecordingUnitHierarchyFields resolve({
    ProjectFormDefinition? definition,
    RecordingUnitMobileDetail? detail,
  }) {
    ProjectFormField? parent;
    ProjectFormField? child;

    void consider(ProjectFormField field) {
      if (RecordingUnitHierarchy.isParentRelationField(
        label: field.label,
        valueBinding: field.valueBinding,
        fieldCode: field.fieldCode,
        answerType: field.answerType,
        hint: field.hint,
      )) {
        parent ??= field;
      }
      if (RecordingUnitHierarchy.isChildRelationField(
        label: field.label,
        valueBinding: field.valueBinding,
        fieldCode: field.fieldCode,
        answerType: field.answerType,
        hint: field.hint,
      )) {
        child ??= field;
      }
    }

    if (definition != null) {
      for (final field in definition.fieldsById.values) {
        consider(field);
      }
    }

    if ((parent == null || child == null) && detail != null) {
      for (final entry in detail.fields.values) {
        consider(_fieldFromEntry(entry));
      }
    }

    return RecordingUnitHierarchyFields(
      parentField: parent,
      childField: child,
    );
  }

  static ProjectFormField _fieldFromEntry(RecordingUnitFormFieldEntry entry) {
    return ProjectFormField(
      key: '${entry.fieldId}',
      fieldId: entry.fieldId,
      answerType:
          entry.answerType ?? ProjectAnswerType.selectMultipleRecordingUnit,
      label: entry.label,
      hint: entry.hint,
      valueBinding: entry.valueBinding,
      fieldCode: entry.fieldCode,
    );
  }
}
