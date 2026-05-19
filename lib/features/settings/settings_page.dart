import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/sync/app_sync_status_scope.dart';
import '../../core/sync/sync_route_args.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/sync/sync_timestamp_format.dart';
import '../../core/widgets/ui/siamois_spacing.dart';

/// Paramètres : dernière synchronisation et file d’attente.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppSyncStatusScope.of(context);
    final service = scope.notifier!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: SiamoisColors.surface,
      appBar: SiamoisTitleBar(
        title: 'Paramètres',
        showBrandMark: false,
        leading: Navigator.canPop(context)
            ? const BackButton()
            : null,
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(SiamoisSpacing.pageHorizontal),
            children: [
              Text(
                'Synchronisation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SiamoisSpacing.md),
              _InfoCard(
                icon: Icons.schedule_rounded,
                title: 'Dernière synchronisation réussie',
                value: formatLastSyncTimestamp(service.lastSuccessfulSyncAt),
              ),
              const SizedBox(height: SiamoisSpacing.sm),
              _InfoCard(
                icon: Icons.pending_actions_rounded,
                title: 'Opérations en attente ou en erreur',
                value: service.queueCount == 0
                    ? 'Aucune'
                    : '${service.queueCount} opération'
                        '${service.queueCount > 1 ? 's' : ''}',
              ),
              const SizedBox(height: SiamoisSpacing.lg),
              FilledButton.icon(
                onPressed: service.isSyncing
                    ? null
                    : () => _runManualSync(context),
                icon: const Icon(Icons.sync_rounded),
                label: Text(
                  service.isSyncing
                      ? 'Synchronisation…'
                      : 'Synchroniser maintenant',
                ),
              ),
              const SizedBox(height: SiamoisSpacing.xl),
              Text(
                formatLastSyncTimestamp(service.lastSuccessfulSyncAt),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SiamoisColors.textTertiary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _runManualSync(BuildContext context) async {
    final scope = AppSyncStatusScope.of(context);
    final service = scope.notifier!;

    if (!service.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Serveur injoignable. Connectez-vous au réseau pour synchroniser.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.sync,
      arguments: const SyncRouteArgs(
        cameFromOnlineLogin: true,
        manual: true,
      ),
    );

    if (!context.mounted) return;
    if (result == true) {
      await service.refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisation terminée.')),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: SiamoisColors.primary),
        title: Text(title, style: theme.textTheme.labelLarge),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
