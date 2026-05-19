import 'package:flutter/material.dart';

import '../../../core/widgets/ui/siamois_entity_tile.dart';
import '../project_models.dart';

/// Ligne projet : titre, identifiant, pastille discrète du nombre d’UE.
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
      subtitle: project.displayCode,
      onTap: onTap,
      leading: SiamoisEntityAvatar(label: project.name),
      trailing: project.recordingUnitCount != null
          ? SiamoisCountBadge(
              icon: Icons.layers_outlined,
              label: project.recordingUnitCount == 1
                  ? '1 UE'
                  : '${project.recordingUnitCount} UE',
              tooltip: project.recordingUnitCountSemanticLabel,
            )
          : null,
    );
  }
}
