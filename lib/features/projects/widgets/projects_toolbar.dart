import 'package:flutter/material.dart';

import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';

/// Barre sous la barre de titre : recherche + création de projet.
class ProjectsToolbar extends StatefulWidget {
  const ProjectsToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCreateProject,
    this.createEnabled = true,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreateProject;
  final bool createEnabled;

  @override
  State<ProjectsToolbar> createState() => _ProjectsToolbarState();
}

class _ProjectsToolbarState extends State<ProjectsToolbar> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ProjectsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onControllerChanged);
      widget.searchController.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _clearSearch() {
    widget.searchController.clear();
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = widget.searchController.text.isNotEmpty;

    return Material(
      color: SiamoisColors.surfaceCard,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: SiamoisColors.borderSubtle),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SiamoisSpacing.pageHorizontal,
            SiamoisSpacing.sm,
            SiamoisSpacing.pageHorizontal,
            SiamoisSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SearchBar(
                  controller: widget.searchController,
                  hintText: 'Rechercher un projet…',
                  leading: const Icon(Icons.search_rounded, size: 22),
                  trailing: hasQuery
                      ? [
                          IconButton(
                            tooltip: 'Effacer',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded, size: 20),
                          ),
                        ]
                      : const [],
                  onChanged: widget.onSearchChanged,
                  onSubmitted: widget.onSearchChanged,
                ),
              ),
              const SizedBox(width: SiamoisSpacing.sm),
              FilledButton.icon(
                onPressed: widget.createEnabled ? widget.onCreateProject : null,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nouveau'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
