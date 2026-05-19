import 'package:flutter/material.dart';

import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_section_card.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../form/project_form_readonly_widgets.dart';
import '../recording_units/recording_unit_detail_mapper.dart';
import '../recording_units/recording_unit_detail_models.dart';

/// Onglet Détail d'une unité d'enregistrement.
class RecordingUnitDetailDetailTab extends StatelessWidget {
  const RecordingUnitDetailDetailTab({
    super.key,
    required this.detail,
  });

  final RecordingUnitMobileDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = RecordingUnitDetailMapper.rowsInDisplayOrder(detail);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.md,
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.xxl,
      ),
      children: [
        SiamoisSectionCard(
          title: RecordingUnitDetailMapper.headerTitle(detail),
          subtitle: RecordingUnitDetailMapper.headerSubtitle(detail),
          footer: detail.formName?.trim().isNotEmpty == true
              ? detail.formName
              : null,
        ),
        const SizedBox(height: SiamoisSpacing.lg),
        if (rows.isEmpty)
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
                multiline: row.multiline,
              ),
            );
          }),
      ],
    );
  }
}
