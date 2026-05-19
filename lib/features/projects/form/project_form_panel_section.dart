import 'package:flutter/material.dart';

import '../../../core/widgets/ui/siamois_section_card.dart';
import 'project_form_layout.dart';

/// Section visuelle d’un panneau du formulaire projet.
class ProjectFormPanelSection extends StatelessWidget {
  const ProjectFormPanelSection({
    super.key,
    required this.panel,
    required this.fieldBuilder,
  });

  final ProjectFormPanelLayout panel;
  final Widget Function(ProjectFormFieldSlot slot) fieldBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SiamoisFormSectionHeader(title: panel.displayTitle),
        ...panel.slots.map(
          (slot) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: fieldBuilder(slot),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
