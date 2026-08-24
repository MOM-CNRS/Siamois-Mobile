import 'package:flutter/material.dart';

import '../../features/auth/auth_models.dart';
import '../../features/projects/widgets/organization_switcher.dart';
import '../routes.dart';
import '../sync/app_sync_status_scope.dart';
import '../theme/siamois_colors.dart';
import 'app_version_label.dart';
import 'sync/sync_timestamp_format.dart';
import 'ui/siamois_spacing.dart';

/// Demande confirmation avant déconnexion.
Future<bool> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        icon: Icon(Icons.logout_rounded, color: SiamoisColors.error),
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Votre session sera fermée sur cet appareil. '
          'Vous devrez vous reconnecter pour accéder à vos projets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: SiamoisColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

/// Menu latéral gauche (navigation drawer).
class SiamoisNavigationDrawer extends StatelessWidget {
  const SiamoisNavigationDrawer({
    super.key,
    this.headerTitle,
    this.headerSubtitle,
    required this.onLogout,
    this.organizations = const [],
    this.selectedOrganizationId,
    this.onOrganizationSelected,
    this.organizationsEnabled = true,
  });

  final String? headerTitle;
  final String? headerSubtitle;
  final Future<void> Function() onLogout;
  final List<StoredOrganization> organizations;
  final int? selectedOrganizationId;
  final ValueChanged<StoredOrganization>? onOrganizationSelected;
  final bool organizationsEnabled;

  Future<void> _handleLogout(BuildContext context) async {
    if (!await confirmLogout(context)) return;
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = AppSyncStatusScope.maybeOf(context);
    final service = scope?.notifier;
    final hasHeader = (headerTitle ?? '').trim().isNotEmpty ||
        (headerSubtitle ?? '').trim().isNotEmpty;

    Widget buildFooter() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          SiamoisSpacing.lg,
          SiamoisSpacing.sm,
          SiamoisSpacing.lg,
          SiamoisSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (service != null)
              ListenableBuilder(
                listenable: service,
                builder: (context, _) {
                  return Text(
                    'Dernière sync : '
                    '${formatLastSyncTimestamp(service.lastSuccessfulSyncAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SiamoisColors.textTertiary,
                    ),
                  );
                },
              ),
            if (service != null) const SizedBox(height: 4),
            const AppVersionLabel(textAlign: TextAlign.start),
          ],
        ),
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasHeader)
              Container(
                padding: const EdgeInsets.fromLTRB(
                  SiamoisSpacing.lg,
                  SiamoisSpacing.xl,
                  SiamoisSpacing.lg,
                  SiamoisSpacing.lg,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SiamoisColors.primaryContainer.withValues(alpha: 0.7),
                      SiamoisColors.surfaceCard,
                    ],
                  ),
                  border: const Border(
                    bottom: BorderSide(color: SiamoisColors.borderSubtle),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            SiamoisColors.primary,
                            SiamoisColors.primaryLight,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(SiamoisSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: SiamoisSpacing.md),
                    if ((headerTitle ?? '').trim().isNotEmpty)
                      Text(
                        headerTitle!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if ((headerSubtitle ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        headerSubtitle!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: SiamoisColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: SiamoisSpacing.md),
            OrganizationDrawerDropdown(
              organizations: organizations,
              selectedOrganizationId: selectedOrganizationId,
              enabled: organizationsEnabled,
              onOrganizationSelected: onOrganizationSelected,
            ),
            ListTile(
              leading: const Icon(
                Icons.folder_copy_outlined,
                color: SiamoisColors.primary,
              ),
              title: const Text('Projets'),
              subtitle: const Text('Liste de vos projets'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.projects,
                  (route) => route.isFirst,
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.place_outlined,
                color: SiamoisColors.primary,
              ),
              title: const Text('Gestion des lieux'),
              subtitle: const Text('Lieux de l’organisation'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.placesManagement);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.sync_rounded,
                color: SiamoisColors.primary,
              ),
              title: const Text('Synchronisation'),
              subtitle: const Text('Dernière synchronisation'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.settings);
              },
            ),
            const Spacer(),
            buildFooter(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: SiamoisColors.error,
              ),
              title: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: SiamoisColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SiamoisSpacing.radiusMd),
              ),
              onTap: () => _handleLogout(context),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        ),
      ),
    );
  }
}

/// Bouton menu ouvrant le [Drawer] du [Scaffold] parent.
class SiamoisMenuButton extends StatelessWidget {
  const SiamoisMenuButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Menu',
      onPressed: onPressed ?? () => Scaffold.of(context).openDrawer(),
      icon: const Icon(Icons.menu_rounded),
      style: IconButton.styleFrom(
        foregroundColor: SiamoisColors.textPrimary,
      ),
    );
  }
}
