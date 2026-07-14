import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes.dart';
import '../../core/sync/app_sync_status_service.dart';
import '../../core/sync/sync_orchestrator.dart';
import '../../core/sync/sync_progress.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/siamois_sync_animation.dart';
import '../../core/widgets/ui/siamois_message_banner.dart';
import '../../core/widgets/ui/siamois_spacing.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({
    super.key,
    required this.sync,
    required this.syncStatus,
    required this.cameFromOnlineLogin,
    this.manual = false,
    this.queueOnly = false,
    this.cacheOnly = false,
  });

  final SyncOrchestrator sync;
  final AppSyncStatusService syncStatus;
  final bool cameFromOnlineLogin;
  final bool manual;
  final bool queueOnly;
  final bool cacheOnly;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  SyncProgress? _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.sync.progressStream.listen(_onProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _onProgress(SyncProgress p) {
    if (!mounted) return;
    setState(() => _progress = p);

    if (!p.isComplete) return;

    final outcome = p.completionOutcome;
    if (outcome == SyncCompletionOutcome.success) {
      unawaited(widget.syncStatus.recordSuccessfulSync());
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _finishSync(SyncRunResult.success);
      });
      return;
    }

    if (!widget.manual) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        _finishSync(p.runResult ?? SyncRunResult.failures);
      });
    }
  }

  void _finishSync(SyncRunResult result) {
    if (widget.manual) {
      Navigator.of(context).pop(result);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.projects);
  }

  void _closeOnProblem() {
    _finishSync(_progress?.runResult ?? SyncRunResult.failures);
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    await widget.syncStatus.setSyncing(true);
    try {
      await widget.sync.runBootstrap(
        cameFromOnlineLogin: widget.cameFromOnlineLogin,
        queueOnly: widget.queueOnly,
        cacheOnly: widget.cacheOnly,
      );
    } catch (_) {
    } finally {
      await widget.syncStatus.setSyncing(false);
      await widget.syncStatus.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _progress;
    final bootstrapError = progress?.isBootstrapError == true;
    final outcome = progress?.completionOutcome;
    final isSuccess = outcome == SyncCompletionOutcome.success;
    final hasWarnings = outcome == SyncCompletionOutcome.hasConflicts;
    final hasFailures = outcome == SyncCompletionOutcome.hasFailures;
    final isComplete = progress?.isComplete == true;
    final canLeaveOnError = bootstrapError || (widget.manual && isComplete && !isSuccess);
    final statusColor = bootstrapError || hasFailures
        ? SiamoisColors.error
        : hasWarnings
            ? SiamoisColors.warning
            : isSuccess
                ? SiamoisColors.success
                : SiamoisColors.textPrimary;
    final statusKey = _statusMessage(
      bootstrapError: bootstrapError,
      outcome: outcome,
      isComplete: isComplete,
    );

    return PopScope(
      canPop: canLeaveOnError,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !canLeaveOnError) return;
        _closeOnProblem();
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight;
            final maxW = constraints.maxWidth;
            final animSize = (maxW * 0.44).clamp(120.0, 220.0);
            final topPad = (maxH * 0.06).clamp(16.0, 48.0);
            final bottomPad = (maxH * 0.04).clamp(12.0, 32.0);

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFDFAF7),
                    SiamoisColors.surface,
                    Color(0xFFE8EEF2),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: maxW,
                  height: maxH,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      SiamoisSpacing.pageHorizontal,
                      topPad,
                      SiamoisSpacing.pageHorizontal,
                      bottomPad,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Siamois',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lora(
                            fontSize: (maxW * 0.07).clamp(22.0, 30.0),
                            fontWeight: FontWeight.w700,
                            color: SiamoisColors.primaryDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.cacheOnly
                              ? 'Rechargement du cache'
                              : widget.manual
                                  ? 'Synchronisation'
                                  : 'Préparation de vos données',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: SiamoisColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxW * 0.92,
                                maxHeight: maxH * 0.62,
                              ),
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SiamoisSyncAnimation(
                                      size: animSize,
                                      hasError: bootstrapError || hasFailures,
                                      hasWarning: hasWarnings,
                                      isComplete: isSuccess,
                                    ),
                                    SizedBox(height: maxH * 0.03),
                                    if (progress != null &&
                                        progress.totalActions > 0 &&
                                        !bootstrapError) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          SiamoisSpacing.radiusSm,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: progress.progress.clamp(0.0, 1.0),
                                          minHeight: 6,
                                          backgroundColor: SiamoisColors
                                              .primaryDark
                                              .withValues(alpha: 0.08),
                                          color: statusColor,
                                        ),
                                      ),
                                      SizedBox(height: maxH * 0.02),
                                    ],
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 350),
                                      child: Text(
                                        statusKey,
                                        key: ValueKey(statusKey),
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    if (!isComplete &&
                                        (progress?.currentActionLabel ?? '')
                                            .isNotEmpty) ...[
                                      const SizedBox(height: SiamoisSpacing.sm),
                                      Text(
                                        progress!.currentActionLabel!,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: SiamoisColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: maxH * 0.012),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 350),
                                      child: Text(
                                        _subtitle(
                                          bootstrapError: bootstrapError,
                                          outcome: outcome,
                                          progress: progress,
                                        ),
                                        key: ValueKey(
                                          _subtitle(
                                            bootstrapError: bootstrapError,
                                            outcome: outcome,
                                            progress: progress,
                                          ),
                                        ),
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: SiamoisColors.textSecondary,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                    if (bootstrapError &&
                                        (progress?.errorMessage ?? '')
                                            .isNotEmpty) ...[
                                      SizedBox(height: maxH * 0.02),
                                      SiamoisMessageBanner(
                                        message: progress!.errorMessage!,
                                        kind: SiamoisMessageKind.error,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                    if (isComplete &&
                                        (hasWarnings || hasFailures)) ...[
                                      SizedBox(height: maxH * 0.02),
                                      Container(
                                        padding: const EdgeInsets.all(
                                          SiamoisSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(
                                            SiamoisSpacing.radiusMd,
                                          ),
                                          border: Border.all(
                                            color: statusColor.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          _issueSummary(progress!),
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: statusColor,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (bootstrapError ||
                            (widget.manual && isComplete && !isSuccess))
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _closeOnProblem,
                              child: const Text('Fermer'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _statusMessage({
    required bool bootstrapError,
    required SyncCompletionOutcome? outcome,
    required bool isComplete,
  }) {
    if (bootstrapError) return 'Échec de la synchronisation';
    return switch (outcome) {
      SyncCompletionOutcome.success => 'Synchronisation terminée',
      SyncCompletionOutcome.hasConflicts =>
        'Synchronisation terminée avec des conflits',
      SyncCompletionOutcome.hasFailures =>
        'Synchronisation terminée avec des erreurs',
      null => isComplete
          ? 'Synchronisation terminée'
          : 'Synchronisation en cours…',
    };
  }

  String _subtitle({
    required bool bootstrapError,
    required SyncCompletionOutcome? outcome,
    required SyncProgress? progress,
  }) {
    if (bootstrapError) {
      return 'Vérifiez votre connexion puis réessayez, ou revenez en arrière.';
    }
    return switch (outcome) {
      SyncCompletionOutcome.success =>
        'Vos projets et données locales sont à jour.',
      SyncCompletionOutcome.hasConflicts =>
        'Certaines fiches doivent être comparées dans la file d’attente.',
      SyncCompletionOutcome.hasFailures =>
        'Certaines actions n’ont pas pu être envoyées. '
            'Consultez la file d’attente.',
      null => widget.cacheOnly
          ? 'Téléchargement des données depuis le serveur…'
          : widget.queueOnly
              ? 'Envoi des actions en attente vers le serveur…'
              : progress?.totalActions != null && progress!.totalActions > 0
                  ? 'Étape ${progress.completedActions + 1} sur ${progress.totalActions}'
                  : 'Téléchargement des vocabulaires, formulaires et projets…',
    };
  }

  String _issueSummary(SyncProgress progress) {
    final parts = <String>[];
    if (progress.conflictCount > 0) {
      parts.add(
        '${progress.conflictCount} conflit'
        '${progress.conflictCount > 1 ? 's' : ''}',
      );
    }
    if (progress.failedActionCount > 0) {
      parts.add(
        '${progress.failedActionCount} échec'
        '${progress.failedActionCount > 1 ? 's' : ''}',
      );
    }
    return parts.join(' · ');
  }
}
