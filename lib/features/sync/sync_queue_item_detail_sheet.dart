import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/database/app_database.dart';
import '../../core/sync/sync_action_models.dart';
import '../../core/sync/sync_conflict_field_diff.dart';
import '../../core/sync/sync_conflict_payload.dart';
import '../../core/sync/sync_queue_item_detail_resolver.dart';
import '../../core/sync/sync_queue_models.dart';
import '../../core/sync/sync_queue_service.dart';
import '../auth/auth_repository.dart';
import '../../core/widgets/ui/siamois_messenger.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/sync/sync_conflict_fields_list.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import '../projects/documents/document_tmp_models.dart';
import '../projects/form/recording_unit_option.dart';
import '../projects/mobiliers/mobilier_local_id.dart';
import '../projects/recording_units/recording_unit_local_id.dart';

/// Affiche le détail d’une action de la file de synchronisation.
Future<void> showSyncQueueItemDetailSheet({
  required BuildContext context,
  required SyncQueueService queue,
  required SyncQueueItem item,
  required AppDatabase database,
  required AuthRepository auth,
}) async {
  SyncActionEntry? action;
  DocumentTmpEntry? document;

  if (item.source == SyncQueueItemSource.outbox) {
    action = await queue.outboxActionForItem(item);
  } else {
    document = await queue.documentForItem(item);
  }

  final resolved = await SyncQueueItemDetailResolver(auth: auth, db: database)
      .resolve(item: item, action: action, document: document);

  if (!context.mounted) return;

  final content = _SyncQueueItemDetailContent.build(
    item: item,
    action: action,
    document: document,
    resolved: resolved,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: SiamoisColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(SiamoisSpacing.radiusXl),
      ),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              SiamoisSpacing.lg,
              0,
              SiamoisSpacing.lg,
              SiamoisSpacing.xxl,
            ),
            children: [
              Text(
                content.headline,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (content.subheadline != null) ...[
                const SizedBox(height: 6),
                Text(
                  content.subheadline!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SiamoisColors.textSecondary,
                        height: 1.45,
                      ),
                ),
              ],
              const SizedBox(height: SiamoisSpacing.lg),
              _SummaryCard(content: content),
              if (content.element != null) ...[
                const SizedBox(height: SiamoisSpacing.lg),
                _ElementInfoCard(
                  title: 'Élément concerné',
                  element: content.element!,
                ),
              ],
              if (content.parentElement != null) ...[
                const SizedBox(height: SiamoisSpacing.lg),
                _ElementInfoCard(
                  title: 'Rattaché à',
                  element: content.parentElement!,
                ),
              ],
              if (content.project != null &&
                  content.project != content.parentElement) ...[
                const SizedBox(height: SiamoisSpacing.lg),
                _ElementInfoCard(
                  title: 'Projet concerné',
                  element: content.project!,
                ),
              ],
              const SizedBox(height: SiamoisSpacing.lg),
              _Section(
                title: 'État actuel',
                children: [
                  _PlainRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Statut',
                    value: content.statusLabel,
                    accent: content.statusAccent,
                  ),
                  _PlainRow(
                    icon: Icons.schedule_rounded,
                    label: 'Enregistré sur l’appareil',
                    value: content.recordedAtLabel,
                  ),
                  if (content.nextStepLabel != null)
                    _PlainRow(
                      icon: Icons.arrow_forward_rounded,
                      label: 'Prochaine étape',
                      value: content.nextStepLabel!,
                    ),
                ],
              ),
              if (content.conflictFieldDiffs.isNotEmpty) ...[
                const SizedBox(height: SiamoisSpacing.lg),
                SyncConflictFieldsList(diffs: content.conflictFieldDiffs),
              ] else if (content.changeLines.isNotEmpty) ...[
                const SizedBox(height: SiamoisSpacing.lg),
                _Section(
                  title: 'Champs modifiés',
                  children: content.changeLines
                      .map(
                        (line) => _PlainRow(
                          icon: Icons.edit_note_rounded,
                          label: line.label,
                          value: line.value,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (content.problemTitle != null) ...[
                const SizedBox(height: SiamoisSpacing.lg),
                _ProblemCard(
                  title: content.problemTitle!,
                  message: content.problemMessage ?? '',
                  hint: content.problemHint,
                ),
              ],
              if (content.technicalLines.isNotEmpty) ...[
                const SizedBox(height: SiamoisSpacing.lg),
                _TechnicalSection(
                  lines: content.technicalLines,
                  payload: action?.payload,
                ),
              ],
            ],
          );
        },
      );
    },
  );
}

class _DetailLine {
  const _DetailLine({
    required this.label,
    required this.value,
    this.icon = Icons.label_outline_rounded,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _SyncQueueItemDetailContent {
  const _SyncQueueItemDetailContent({
    required this.headline,
    this.subheadline,
    required this.summaryTitle,
    required this.summaryBody,
    required this.summaryIcon,
    required this.statusLabel,
    required this.statusAccent,
    required this.recordedAtLabel,
    this.nextStepLabel,
    this.changeLines = const [],
    this.conflictFieldDiffs = const [],
    this.problemTitle,
    this.problemMessage,
    this.problemHint,
    this.technicalLines = const [],
    this.element,
    this.project,
    this.parentElement,
  });

  final String headline;
  final String? subheadline;
  final String summaryTitle;
  final String summaryBody;
  final IconData summaryIcon;
  final String statusLabel;
  final Color statusAccent;
  final String recordedAtLabel;
  final String? nextStepLabel;
  final List<_DetailLine> changeLines;
  final List<SyncConflictFieldDiff> conflictFieldDiffs;
  final String? problemTitle;
  final String? problemMessage;
  final String? problemHint;
  final List<_DetailLine> technicalLines;
  final SyncQueueResolvedElement? element;
  final SyncQueueResolvedElement? project;
  final SyncQueueResolvedElement? parentElement;

  factory _SyncQueueItemDetailContent.build({
    required SyncQueueItem item,
    SyncActionEntry? action,
    DocumentTmpEntry? document,
    SyncQueueResolvedContext? resolved,
  }) {
    if (document != null) {
      return _fromDocument(item, document, resolved);
    }
    if (action != null) {
      return _fromAction(item, action, resolved);
    }
    return _fromItemOnly(item, resolved);
  }

  static _SyncQueueItemDetailContent _fromItemOnly(
    SyncQueueItem item,
    SyncQueueResolvedContext? resolved,
  ) {
    final status = _statusPresentation(item.status);
    return _SyncQueueItemDetailContent(
      headline: item.title,
      subheadline: _subheadlineForElement(resolved?.element) ?? item.subtitle,
      summaryTitle: 'Modification en attente',
      summaryBody:
          'Cette opération a été enregistrée sur votre appareil et attend '
          'd’être envoyée au serveur Siamois.',
      summaryIcon: Icons.cloud_upload_outlined,
      statusLabel: status.label,
      statusAccent: status.color,
      recordedAtLabel: _formatDateTime(item.createdAt),
      nextStepLabel: status.nextStep,
      problemTitle: item.errorMessage != null ? 'Un problème est survenu' : null,
      problemMessage: _humanErrorMessage(item.errorMessage),
      problemHint: status.problemHint,
      element: resolved?.element,
      project: resolved?.project,
      parentElement: resolved?.parentElement,
      changeLines: _changeLinesFromResolved(resolved),
      conflictFieldDiffs: resolved?.conflictFieldDiffs ?? const [],
    );
  }

  static _SyncQueueItemDetailContent _fromAction(
    SyncQueueItem item,
    SyncActionEntry action,
    SyncQueueResolvedContext? resolved,
  ) {
    final status = _statusPresentation(action.status);
    final entity = _entityPresentation(action);
    final operation = _operationPresentation(action.operation, action.entityType);
    final payload = action.payload;
    final reference = _friendlyReference(
      actionUnitId: payload['actionUnitId']?.toString(),
      localId: action.localEntityId,
      serverId: action.serverEntityId,
      entityType: action.entityType,
    );

    final conflictFieldDiffs = resolved?.conflictFieldDiffs ?? const [];
    var changeLines = _changeLinesFromResolved(resolved);
    if (changeLines.isEmpty && conflictFieldDiffs.isEmpty) {
      changeLines = _humanizeFieldAnswers(payload['fieldAnswers']);
    }

    return _SyncQueueItemDetailContent(
      headline: operation.headline,
      subheadline:
          _subheadlineForElement(resolved?.element) ?? entity.subheadline,
      summaryTitle: operation.summaryTitle,
      summaryBody: operation.summaryBody(
        reference: resolved?.element.code ?? reference,
      ),
      summaryIcon: operation.icon,
      statusLabel: status.label,
      statusAccent: status.color,
      recordedAtLabel: _formatDateTime(action.createdAt ?? item.createdAt),
      nextStepLabel: status.nextStep,
      changeLines: changeLines,
      conflictFieldDiffs: conflictFieldDiffs,
      problemTitle: _problemTitle(action.status, action.errorMessage),
      problemMessage: _humanErrorMessage(action.errorMessage),
      problemHint: status.problemHint,
      technicalLines: _technicalLinesForAction(action),
      element: resolved?.element,
      project: resolved?.project,
      parentElement: resolved?.parentElement,
    );
  }

  static _SyncQueueItemDetailContent _fromDocument(
    SyncQueueItem item,
    DocumentTmpEntry document,
    SyncQueueResolvedContext? resolved,
  ) {
    final status = _statusPresentation(document.status);
    final isProject =
        document.parentType == DocumentTmpParentType.project;
    final parentLabel =
        isProject ? 'Projet' : 'Unité d’enregistrement';

    return _SyncQueueItemDetailContent(
      headline: 'Envoi d’un document',
      subheadline:
          _subheadlineForElement(resolved?.element) ?? document.title,
      summaryTitle: 'Document à envoyer au serveur',
      summaryBody:
          'Le fichier « ${document.title} » a été ajouté sur votre appareil. '
          'Il sera transféré vers Siamois lors de la prochaine synchronisation, '
          'puis rattaché au $parentLabel indiqué ci-dessous.',
      summaryIcon: Icons.description_outlined,
      statusLabel: status.label,
      statusAccent: status.color,
      recordedAtLabel: _formatDateTime(document.createdAt ?? item.createdAt),
      nextStepLabel: status.nextStep,
      changeLines: _changeLinesFromResolved(resolved),
      conflictFieldDiffs: resolved?.conflictFieldDiffs ?? const [],
      problemTitle: document.uploadError != null ? 'L’envoi a échoué' : null,
      problemMessage: _humanErrorMessage(document.uploadError),
      problemHint: status.problemHint,
      element: resolved?.element,
      project: resolved?.project,
      parentElement: resolved?.parentElement,
      technicalLines: [
        if (document.mimeType != null && document.mimeType!.isNotEmpty)
          _DetailLine(label: 'Type de fichier', value: document.mimeType!),
        if (document.fileCode != null && document.fileCode!.isNotEmpty)
          _DetailLine(label: 'Code document', value: document.fileCode!),
      ],
    );
  }
}

List<_DetailLine> _changeLinesFromResolved(SyncQueueResolvedContext? resolved) {
  if (resolved == null || resolved.changedFields.isEmpty) return const [];
  return [
    for (final field in resolved.changedFields)
      _DetailLine(
        label: field.fieldLabel,
        value: field.value,
        icon: Icons.edit_outlined,
      ),
  ];
}

String? _subheadlineForElement(SyncQueueResolvedElement? element) {
  if (element == null) return null;
  final parts = <String>[element.kind];
  if (element.hasCode) parts.add(element.code!);
  if (element.hasName && element.name != element.code) {
    return '${parts.join(' · ')}\n${element.name}';
  }
  return parts.join(' · ');
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.color,
    required this.nextStep,
    this.problemHint,
  });

  final String label;
  final Color color;
  final String nextStep;
  final String? problemHint;
}

class _OperationPresentation {
  const _OperationPresentation({
    required this.headline,
    required this.summaryTitle,
    required this.summaryBody,
    required this.icon,
  });

  final String headline;
  final String summaryTitle;
  final String Function({String? reference}) summaryBody;
  final IconData icon;
}

class _EntityPresentation {
  const _EntityPresentation({
    required this.subheadline,
    required this.referenceLabel,
  });

  final String subheadline;
  final String referenceLabel;
}

_StatusPresentation _statusPresentation(String status) {
  return switch (status) {
    SyncActionStatus.pending || DocumentTmpStatus.pending => _StatusPresentation(
        label: 'En attente d’envoi',
        color: SiamoisColors.warning,
        nextStep:
            'Lancez une synchronisation lorsque vous êtes connecté au réseau. '
            'L’application enverra alors cette modification au serveur.',
      ),
    SyncActionStatus.uploading || DocumentTmpStatus.uploading =>
      _StatusPresentation(
        label: 'Envoi en cours',
        color: SiamoisColors.primary,
        nextStep:
            'Patientez pendant le transfert. Ne fermez pas l’application.',
      ),
    SyncActionStatus.failed || DocumentTmpStatus.failed => _StatusPresentation(
        label: 'Échec de l’envoi',
        color: SiamoisColors.error,
        nextStep:
            'Corrigez le problème indiqué ci-dessous, puis relancez la synchronisation. '
            'Vous pouvez aussi retirer l’opération de la file si elle n’est plus utile.',
        problemHint:
            'Si le problème persiste, contactez votre responsable technique '
            'en lui indiquant la date et le contenu de cette action.',
      ),
    SyncActionStatus.conflict => _StatusPresentation(
        label: 'Conflit à résoudre',
        color: SiamoisColors.warning,
        nextStep:
            'Fermez ce détail, puis appuyez sur l’icône de résolution dans la liste. '
            'Vous pourrez choisir entre vos modifications locales et la version du serveur.',
        problemHint:
            'Un conflit signifie que la même fiche a été modifiée ailleurs '
            '(autre appareil, autre utilisateur ou session web) pendant que vous '
            'travailliez hors ligne.',
      ),
    SyncActionStatus.synced || DocumentTmpStatus.synced => _StatusPresentation(
        label: 'Synchronisé',
        color: SiamoisColors.primary,
        nextStep: 'Cette opération a déjà été envoyée avec succès.',
      ),
    _ => _StatusPresentation(
        label: status,
        color: SiamoisColors.textSecondary,
        nextStep: 'Relancez la synchronisation si nécessaire.',
      ),
  };
}

_OperationPresentation _operationPresentation(
  String operation,
  String entityType,
) {
  return switch ((operation, entityType)) {
    (SyncOperation.create, SyncEntityType.recordingUnit) =>
      _OperationPresentation(
        headline: 'Création d’une unité d’enregistrement',
        summaryTitle: 'Nouvelle unité à créer sur le serveur',
        summaryBody: ({reference}) =>
            reference == null
                ? 'Une nouvelle unité d’enregistrement sera créée sur Siamois '
                    'lors de la synchronisation.'
                : 'L’unité d’enregistrement « $reference » sera créée sur Siamois '
                    'lors de la synchronisation. Elle existe pour l’instant uniquement '
                    'sur votre appareil.',
        icon: Icons.add_circle_outline_rounded,
      ),
    (SyncOperation.update, SyncEntityType.recordingUnit) =>
      _OperationPresentation(
        headline: 'Modification d’une unité d’enregistrement',
        summaryTitle: 'Mise à jour d’une fiche existante',
        summaryBody: ({reference}) =>
            reference == null
                ? 'Des informations d’une unité d’enregistrement seront mises à jour '
                    'sur le serveur.'
                : 'La fiche « $reference » sera mise à jour sur le serveur avec les '
                    'changements effectués sur votre appareil.',
        icon: Icons.edit_outlined,
      ),
    (SyncOperation.create, SyncEntityType.mobilier) => _OperationPresentation(
        headline: 'Ajout d’un mobilier',
        summaryTitle: 'Nouveau mobilier à enregistrer',
        summaryBody: ({reference}) =>
            'Un mobilier sera ajouté sur le serveur et rattaché à l’unité '
            'd’enregistrement concernée.',
        icon: Icons.inventory_2_outlined,
      ),
    (SyncOperation.delete, _) => _OperationPresentation(
        headline: 'Suppression',
        summaryTitle: 'Élément à supprimer sur le serveur',
        summaryBody: ({reference}) =>
            'Une suppression sera appliquée sur le serveur lors de la synchronisation.',
        icon: Icons.delete_outline_rounded,
      ),
    (_, SyncEntityType.project) => _OperationPresentation(
        headline: 'Modification d’un projet',
        summaryTitle: 'Mise à jour du projet',
        summaryBody: ({reference}) =>
            'Des informations du projet seront envoyées au serveur.',
        icon: Icons.folder_outlined,
      ),
    (_, SyncEntityType.document) => _OperationPresentation(
        headline: 'Modification d’un document',
        summaryTitle: 'Mise à jour du document',
        summaryBody: ({reference}) =>
            'Des informations du document seront envoyées au serveur.',
        icon: Icons.description_outlined,
      ),
    _ => _OperationPresentation(
        headline: 'Modification en attente',
        summaryTitle: 'Opération à synchroniser',
        summaryBody: ({reference}) =>
            'Cette modification sera envoyée au serveur Siamois.',
        icon: Icons.cloud_upload_outlined,
      ),
  };
}

_EntityPresentation _entityPresentation(SyncActionEntry action) {
  return switch (action.entityType) {
    SyncEntityType.recordingUnit => const _EntityPresentation(
        subheadline: 'Unité d’enregistrement (fouille, couche, secteur…)',
        referenceLabel: 'Unité concernée',
      ),
    SyncEntityType.mobilier => const _EntityPresentation(
        subheadline: 'Mobilier archéologique rattaché à une unité',
        referenceLabel: 'Mobilier concerné',
      ),
    SyncEntityType.project => const _EntityPresentation(
        subheadline: 'Projet archéologique',
        referenceLabel: 'Projet concerné',
      ),
    SyncEntityType.document => const _EntityPresentation(
        subheadline: 'Document (plan, photo, rapport…)',
        referenceLabel: 'Document concerné',
      ),
    _ => const _EntityPresentation(
        subheadline: 'Élément à synchroniser',
        referenceLabel: 'Référence',
      ),
  };
}

String? _friendlyReference({
  String? actionUnitId,
  String? localId,
  String? serverId,
  required String entityType,
}) {
  final code = actionUnitId?.trim();
  if (code != null && code.isNotEmpty) return code;

  final server = serverId?.trim();
  if (server != null && server.isNotEmpty && !_looksLikeOpaqueId(server)) {
    return _friendlyId(server);
  }
  if (server != null && server.isNotEmpty) {
    return _friendlyId(server);
  }

  final local = localId?.trim();
  if (local != null && local.isNotEmpty) {
    if (entityType == SyncEntityType.recordingUnit &&
        RecordingUnitLocalId.isLocalListId(local)) {
      return 'Brouillon local (pas encore sur le serveur)';
    }
    if (entityType == SyncEntityType.mobilier &&
        MobilierLocalId.isLocalListId(local)) {
      return 'Brouillon local (pas encore sur le serveur)';
    }
    return _friendlyId(local);
  }

  return null;
}

bool _looksLikeOpaqueId(String value) {
  return value.length > 24 && !value.contains('-') && !value.contains('/');
}

String _friendlyId(String raw) {
  final id = raw.trim();
  if (id.isEmpty) return '—';
  if (RecordingUnitLocalId.isLocalListId(id) ||
      MobilierLocalId.isLocalListId(id) ||
      DocumentTmpEntry.isLocalListId(id)) {
    return 'Brouillon local';
  }
  if (id.length <= 32) return id;
  return '${id.substring(0, 14)}…${id.substring(id.length - 6)}';
}

List<_DetailLine> _humanizeFieldAnswers(dynamic raw) {
  if (raw is! Map) return const [];

  final lines = <_DetailLine>[];
  for (final entry in raw.entries) {
    final label = _guessFieldLabel(entry.key.toString(), entry.value);
    final value = _humanizeFieldValue(entry.value);
    if (value.trim().isEmpty) continue;
    lines.add(_DetailLine(label: label, value: value));
  }
  return lines;
}

String _guessFieldLabel(String fieldKey, dynamic value) {
  final units = RecordingUnitOption.listFromCurrentValue(value);
  if (units.isNotEmpty) {
    return units.length == 1
        ? 'Unité liée'
        : 'Unités liées (${units.length})';
  }
  if (value is List) {
    return value.length == 1 ? 'Valeur sélectionnée' : 'Valeurs sélectionnées';
  }
  if (value is Map) return 'Informations complémentaires';
  return 'Champ modifié';
}

String _humanizeFieldValue(dynamic raw) {
  if (raw == null) return '';

  final units = RecordingUnitOption.listFromCurrentValue(raw);
  if (units.isNotEmpty) {
    return units.map((u) => u.display).join('\n');
  }

  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final asDate = DateTime.tryParse(trimmed);
    if (asDate != null && trimmed.contains('-')) {
      return _formatDateTime(asDate);
    }
    return trimmed;
  }

  if (raw is num || raw is bool) return raw.toString();

  if (raw is List) {
    if (raw.isEmpty) return 'Aucune valeur';
    if (raw.every((e) => e is String || e is num)) {
      return raw.map((e) => e.toString()).join(', ');
    }
    return '${raw.length} élément${raw.length > 1 ? 's' : ''}';
  }

  if (raw is Map) {
    final label = raw['fullIdentifier'] ??
        raw['label'] ??
        raw['name'] ??
        raw['displayLabel'];
    if (label != null && label.toString().trim().isNotEmpty) {
      return label.toString().trim();
    }
    final text = raw['value'] ?? raw['text'];
    if (text != null && text.toString().trim().isNotEmpty) {
      return text.toString().trim();
    }
  }

  return raw.toString();
}

String? _problemTitle(String status, String? errorMessage) {
  if (errorMessage == null || errorMessage.trim().isEmpty) return null;
  return switch (status) {
    SyncActionStatus.conflict => 'Conflit détecté',
    SyncActionStatus.failed || DocumentTmpStatus.failed =>
      'L’envoi n’a pas abouti',
    _ => 'Information importante',
  };
}

String? _humanErrorMessage(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;

  final conflict = SyncConflictPayload.tryParse(raw);
  if (conflict != null) {
    return conflict.message?.trim().isNotEmpty == true
        ? conflict.message!.trim()
        : 'La fiche a été modifiée sur le serveur depuis votre dernière '
            'synchronisation. Vos changements locaux n’ont pas pu être appliqués '
            'automatiquement.';
  }

  final trimmed = raw.trim();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    return 'Une erreur technique s’est produite lors de l’envoi. '
        'Relancez la synchronisation ou contactez le support si le problème continue.';
  }

  return trimmed;
}

List<_DetailLine> _technicalLinesForAction(SyncActionEntry action) {
  return [
    _DetailLine(label: 'N° dans la file', value: '${action.sequence}'),
    if (action.actionId.isNotEmpty)
      _DetailLine(label: 'Référence interne', value: action.actionId),
    if (action.localEntityId?.trim().isNotEmpty == true)
      _DetailLine(label: 'Identifiant local', value: action.localEntityId!),
    if (action.serverEntityId?.trim().isNotEmpty == true)
      _DetailLine(label: 'Identifiant serveur', value: action.serverEntityId!),
    if (action.baseServerRevision != null)
      _DetailLine(
        label: 'Version serveur attendue',
        value: '${action.baseServerRevision}',
      ),
  ];
}

String _formatDateTime(DateTime? dt) {
  if (dt == null) return 'Date inconnue';
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} à $h:$m';
}

class _ElementInfoCard extends StatelessWidget {
  const _ElementInfoCard({
    required this.title,
    required this.element,
  });

  final String title;
  final SyncQueueResolvedElement element;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(SiamoisSpacing.md),
      decoration: BoxDecoration(
        color: SiamoisColors.surface,
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
        border: Border.all(color: SiamoisColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SiamoisSpacing.sm),
          _InfoLine(label: 'Type', value: element.kind),
          if (element.hasCode) _InfoLine(label: 'Code', value: element.code!),
          if (element.hasName) _InfoLine(label: 'Nom', value: element.name!),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: SiamoisColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.content});

  final _SyncQueueItemDetailContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(SiamoisSpacing.md),
      decoration: BoxDecoration(
        color: SiamoisColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
        border: Border.all(
          color: SiamoisColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SiamoisColors.surfaceCard.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              content.summaryIcon,
              color: SiamoisColors.primary,
            ),
          ),
          const SizedBox(width: SiamoisSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.summaryTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content.summaryBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: SiamoisColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: SiamoisSpacing.sm),
        ...children,
      ],
    );
  }
}

class _PlainRow extends StatelessWidget {
  const _PlainRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SiamoisSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent ?? SiamoisColors.textTertiary),
          const SizedBox(width: SiamoisSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: SiamoisColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: accent ?? SiamoisColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.title,
    required this.message,
    this.hint,
  });

  final String title;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SiamoisSpacing.md),
      decoration: BoxDecoration(
        color: SiamoisColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
        border: Border.all(color: SiamoisColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: SiamoisColors.error,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: SiamoisColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 10),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: SiamoisColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TechnicalSection extends StatefulWidget {
  const _TechnicalSection({
    required this.lines,
    this.payload,
  });

  final List<_DetailLine> lines;
  final Map<String, dynamic>? payload;

  @override
  State<_TechnicalSection> createState() => _TechnicalSectionState();
}

class _TechnicalSectionState extends State<_TechnicalSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: SiamoisColors.surface,
      borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(SiamoisSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(SiamoisSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent_outlined,
                    size: 20,
                    color: SiamoisColors.textTertiary,
                  ),
                  const SizedBox(width: SiamoisSpacing.sm),
                  Expanded(
                    child: Text(
                      'Informations pour le support technique',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SiamoisColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: SiamoisColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(SiamoisSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ces informations ne sont utiles qu’en cas de problème '
                    'avec l’assistance technique.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SiamoisColors.textTertiary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: SiamoisSpacing.md),
                  for (final line in widget.lines) ...[
                    _PlainRow(
                      icon: Icons.tag_outlined,
                      label: line.label,
                      value: line.value,
                    ),
                  ],
                  if (widget.payload != null && widget.payload!.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          final text = const JsonEncoder.withIndent('  ')
                              .convert(widget.payload);
                          Clipboard.setData(ClipboardData(text: text));
                          context.showInfoMessage(
                            'Informations techniques copiées.',
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copier pour le support'),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(SiamoisSpacing.sm),
                      decoration: BoxDecoration(
                        color: SiamoisColors.surfaceCard,
                        borderRadius:
                            BorderRadius.circular(SiamoisSpacing.radiusMd),
                        border:
                            Border.all(color: SiamoisColors.borderSubtle),
                      ),
                      child: SelectableText(
                        const JsonEncoder.withIndent('  ')
                            .convert(widget.payload),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
