import 'package:flutter/material.dart';

import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_select_field.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../../auth/auth_models.dart';

/// Liste déroulante des organisations dans le menu latéral.
class OrganizationDrawerDropdown extends StatelessWidget {
  const OrganizationDrawerDropdown({
    super.key,
    required this.organizations,
    required this.selectedOrganizationId,
    this.onOrganizationSelected,
    this.enabled = true,
  });

  final List<StoredOrganization> organizations;
  final int? selectedOrganizationId;
  final ValueChanged<StoredOrganization>? onOrganizationSelected;
  final bool enabled;

  StoredOrganization? get _selected {
    if (organizations.isEmpty) return null;
    for (final org in organizations) {
      if (org.id == selectedOrganizationId) return org;
    }
    return organizations.first;
  }

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) return const SizedBox.shrink();

    final selected = _selected;
    final canSwitch =
        onOrganizationSelected != null && organizations.length >= 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SiamoisSpacing.md,
        0,
        SiamoisSpacing.md,
        SiamoisSpacing.sm,
      ),
      child: InputDecorator(
        decoration: SiamoisFieldDecoration.forField(
          label: 'Organisation',
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: selected?.id,
            icon: canSwitch
                ? const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: SiamoisColors.textSecondary,
                  )
                : const SizedBox.shrink(),
            items: organizations
                .map(
                  (org) => DropdownMenuItem(
                    value: org.id,
                    child: Text(
                      org.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled && canSwitch
                ? (id) {
                    if (id == null || id == selectedOrganizationId) return;
                    for (final org in organizations) {
                      if (org.id == id) {
                        onOrganizationSelected!(org);
                        return;
                      }
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
