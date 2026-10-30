import 'package:flutter/material.dart';

import '../../../core/theme/siamois_entity_style.dart';
import '../../../core/widgets/ui/siamois_list_summary_bar.dart';

/// Bandeau compteur compact au-dessus de la liste des projets (pleine largeur).
class ProjectsSummaryBar extends StatelessWidget {
  const ProjectsSummaryBar({
    super.key,
    required this.projectCount,
    this.isSearching = false,
    this.searchQuery,
  });

  final int projectCount;
  final bool isSearching;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    return SiamoisListSummaryBar(
      count: projectCount,
      singularLabel: 'projet',
      pluralLabel: 'projets',
      kind: SiamoisEntityKind.project,
      isSearching: isSearching,
      searchQuery: searchQuery,
    );
  }
}
