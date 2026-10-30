import 'package:flutter/material.dart';

import '../../../core/widgets/ui/siamois_entity_tile.dart';
import '../project_models.dart';
import '../validation_status.dart';

/// Ligne projet : titre et identifiant.
class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    super.key,
    required this.project,
    required this.onTap,
  });

  final ProjectSummary project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SiamoisEntityTile(
      title: project.name,
      subtitle: [
        project.displayCode,
        if (ValidationStatus.listLabel(project.validationStatus)
            case final status?)
          status,
      ].join(' · '),
      onTap: onTap,
      leading: SiamoisEntityAvatar(label: project.name),
    );
  }
}
