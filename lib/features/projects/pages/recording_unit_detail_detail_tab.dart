import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_section_card.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../../auth/auth_repository.dart';
import '../form/person_directory_store.dart';
import '../form/person_option.dart';
import '../form/project_form_models.dart';
import '../form/project_form_readonly_widgets.dart';
import '../recording_units/recording_unit_detail_mapper.dart';
import '../recording_units/recording_unit_detail_models.dart';
import '../recording_units/recording_unit_form_cache.dart';
import '../vocabulary_models.dart';

/// Onglet Détail d'une unité d'enregistrement.
class RecordingUnitDetailDetailTab extends StatefulWidget {
  const RecordingUnitDetailDetailTab({
    super.key,
    required this.detail,
    required this.auth,
    required this.database,
    this.recordingUnitId,
  });

  final RecordingUnitMobileDetail detail;
  final AuthRepository auth;
  final AppDatabase database;
  final String? recordingUnitId;

  @override
  State<RecordingUnitDetailDetailTab> createState() =>
      _RecordingUnitDetailDetailTabState();
}

class _RecordingUnitDetailDetailTabState
    extends State<RecordingUnitDetailDetailTab> {
  ProjectFormDefinition? _formDefinition;
  Map<String, List<ConceptOption>> _vocabByCode = const {};
  Map<int, PersonOption> _peopleById = const {};
  bool _formLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormContext();
  }

  @override
  void didUpdateWidget(covariant RecordingUnitDetailDetailTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _loadFormContext();
    }
  }

  Future<void> _loadFormContext() async {
    setState(() => _formLoading = true);

    final cache = RecordingUnitFormCache(
      auth: widget.auth,
      db: widget.database,
    );
    int? typeId;
    final ruId = widget.recordingUnitId?.trim();
    if (ruId != null && ruId.isNotEmpty) {
      typeId = await cache.resolveTypeConceptIdForEdit(
        detail: widget.detail,
        recordingUnitId: ruId,
      );
    } else {
      typeId = widget.detail.typeConceptId;
    }
    final orgId = widget.auth.primaryOrganizationId;
    ProjectFormDefinition? definition;
    Map<String, List<ConceptOption>> vocab = const {};
    Map<int, PersonOption> peopleById = const {};

    if (typeId != null) {
      try {
        final result = await cache.loadFormForRecordingUnitType(
          typeConceptId: typeId,
        );
        definition = result.definition;
        vocab = await cache.loadVocabulariesByFieldCode();
      } catch (_) {
        // Affichage dégradé à partir des seules données API.
      }
    }

    if (orgId != null) {
      try {
        final directory = PersonDirectoryStore(
          auth: widget.auth,
          db: widget.database,
        );
        peopleById = await directory.ensureDirectoryByIdMap(orgId);
      } catch (_) {
        // Pas d’annuaire local : noms issus de l’objet API uniquement.
      }
    }

    if (!mounted) return;
    setState(() {
      _formDefinition = definition;
      _vocabByCode = vocab;
      _peopleById = peopleById;
      _formLoading = false;
    });
  }

  bool _isMultiline(RecordingUnitDetailRow row) {
    if (row.multiline) return true;
    return row.value.contains('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = RecordingUnitDetailMapper.rowsInDisplayOrder(
      widget.detail,
      formDefinition: _formDefinition,
      vocabByCode: _vocabByCode,
      peopleById: _peopleById,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.md,
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.xxl,
      ),
      children: [
        if (_formLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (rows.isEmpty)
          Text(
            'Aucune donnée à afficher pour cette unité d’enregistrement.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: SiamoisColors.textSecondary,
            ),
          )
        else
          ...rows.map((row) {
            if (row.isSection) {
              return SiamoisFormSectionHeader(title: row.label);
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ProjectFormReadOnlyField(
                label: row.label,
                value: row.value,
                multiline: _isMultiline(row),
              ),
            );
          }),
      ],
    );
  }
}
