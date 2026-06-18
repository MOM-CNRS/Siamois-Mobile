import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' hide Form;
import '../../core/routes.dart';
import '../../core/sync/app_sync_status_scope.dart';
import '../../core/sync/sync_progress.dart';
import '../../core/sync/sync_route_args.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/app_version_label.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/sync/sync_timestamp_format.dart';
import '../../core/widgets/ui/siamois_messenger.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import 'clear_cache.dart';

/// Synchronisation : dernière sync, file d’attente et lancement manuel.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    final scope = AppSyncStatusScope.of(context);
    final service = scope.notifier!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: SiamoisColors.surface,
      appBar: SiamoisTitleBar(
        title: 'Synchronisation',
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
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.syncQueue,
                ),
              ),
              const SizedBox(height: SiamoisSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.syncQueue,
                ),
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Voir les actions à synchroniser'),
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
                'Données locales',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SiamoisSpacing.md),
              OutlinedButton.icon(
                onPressed: service.isSyncing
                    ? null
                    : () => clearApplicationCache(
                          context: context,
                          database: database,
                        ),
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Vider le cache'),
              ),
              const SizedBox(height: SiamoisSpacing.xl),
              Text(
                formatLastSyncTimestamp(service.lastSuccessfulSyncAt),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SiamoisColors.textTertiary,
                ),
              ),
              const SizedBox(height: 6),
              const AppVersionLabel(),
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
      context.showInfoMessage(
        'Serveur injoignable. Connectez-vous au réseau pour synchroniser.',
      );
      return;
    }

    final result = await Navigator.of(context).pushNamed<SyncRunResult?>(
      AppRoutes.sync,
      arguments: const SyncRouteArgs(
        cameFromOnlineLogin: true,
        manual: true,
      ),
    );

    if (!context.mounted) return;
    await service.refresh();
    if (!context.mounted) return;

    final message = switch (result) {
      SyncRunResult.success => 'Synchronisation terminée.',
      SyncRunResult.conflicts =>
        'Synchronisation terminée avec des conflits à résoudre.',
      SyncRunResult.failures =>
        'Synchronisation terminée avec des erreurs.',
      null => null,
    };
    if (message != null) {
      if (result == SyncRunResult.failures) {
        context.showErrorMessage(message);
      } else {
        context.showInfoMessage(message);
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

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
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded)
            : null,
        onTap: onTap,
      ),
    );
  }
}
