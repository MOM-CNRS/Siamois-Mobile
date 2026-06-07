import 'package:flutter/material.dart';

import '../../../core/widgets/ui/siamois_spacing.dart';
import '../form/project_detail_mapper.dart';
import '../form/project_form_models.dart';
import '../form/project_form_panel_section.dart';
import '../form/project_form_readonly_widgets.dart';

/// Onglet Fiche : champs du formulaire en lecture seule.
class ProjectDetailFicheTab extends StatelessWidget {
  const ProjectDetailFicheTab({
    super.key,
    required this.project,
    required this.definition,
  });

  final Map<String, dynamic> project;
  final ProjectFormDefinition definition;

  bool _isMultiline(ProjectFormField field, String? value) {
    if (field.normalizedType == ProjectAnswerType.selectMultipleSpatialUnitTree) {
      return true;
    }
    return (value ?? '').contains('\n');
  }

  @override
  Widget build(BuildContext context) {
    final mapper = ProjectDetailMapper(project);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.md,
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.xxl,
      ),
      children: [
        ...definition.panels.map(
          (panel) => ProjectFormPanelSection(
            panel: panel,
            fieldBuilder: (slot) {
              final field = slot.field;
              final value = mapper.displayValue(field);
              return ProjectFormReadOnlyField(
                label: field.label,
                value: value,
                hint: field.hint,
                multiline: _isMultiline(field, value),
              );
            },
          ),
        ),
      ],
    );
  }
}
