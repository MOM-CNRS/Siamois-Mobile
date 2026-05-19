import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes.dart';
import '../../core/sync/app_sync_status_service.dart';
import '../../core/sync/sync_orchestrator.dart';
import '../../core/sync/sync_progress.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/siamois_sync_animation.dart';
import '../../core/widgets/ui/siamois_spacing.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({
    super.key,
    required this.sync,
    required this.syncStatus,
    required this.cameFromOnlineLogin,
    this.manual = false,
  });

  final SyncOrchestrator sync;
  final AppSyncStatusService syncStatus;
  final bool cameFromOnlineLogin;
  final bool manual;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  SyncProgress? _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.sync.progressStream.listen((p) {
      if (!mounted) return;
      setState(() => _progress = p);
      if (p.isComplete && !p.hasError) {
        unawaited(widget.syncStatus.recordSuccessfulSync());
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          if (widget.manual) {
            Navigator.of(context).pop(true);
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.projects);
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    await widget.syncStatus.setSyncing(true);
    try {
      await widget.sync.runBootstrap(
        cameFromOnlineLogin: widget.cameFromOnlineLogin,
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
    final hasError = progress?.hasError == true;
    final isComplete = progress?.isComplete == true && !hasError;

    return Scaffold(
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
                        'Préparation de vos données',
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
                              maxHeight: maxH * 0.55,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SiamoisSyncAnimation(
                                  size: animSize,
                                  hasError: hasError,
                                  isComplete: isComplete,
                                ),
                                SizedBox(height: maxH * 0.03),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  child: Text(
                                    _statusMessage(hasError, isComplete),
                                    key: ValueKey(
                                      _statusMessage(hasError, isComplete),
                                    ),
                                    textAlign: TextAlign.center,
                                    style:
                                        theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: hasError
                                          ? SiamoisColors.error
                                          : isComplete
                                              ? SiamoisColors.success
                                              : SiamoisColors.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: maxH * 0.012),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  child: Text(
                                    _subtitle(hasError, isComplete),
                                    key: ValueKey(
                                      _subtitle(hasError, isComplete),
                                    ),
                                    textAlign: TextAlign.center,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: SiamoisColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                                if (hasError &&
                                    (progress?.errorMessage ?? '')
                                        .isNotEmpty) ...[
                                  SizedBox(height: maxH * 0.02),
                                  Container(
                                    padding: const EdgeInsets.all(
                                      SiamoisSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SiamoisColors.error
                                          .withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(
                                        SiamoisSpacing.radiusMd,
                                      ),
                                      border: Border.all(
                                        color: SiamoisColors.error
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      progress!.errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: SiamoisColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (hasError)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (widget.manual) {
                                    Navigator.of(context).pop(false);
                                  } else {
                                    Navigator.of(context).pushReplacementNamed(
                                      AppRoutes.login,
                                    );
                                  }
                                },
                                child: Text(widget.manual ? 'Fermer' : 'Retour'),
                              ),
                            ),
                            const SizedBox(width: SiamoisSpacing.sm),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _started = false;
                                    _progress = null;
                                  });
                                  _start();
                                },
                                child: const Text('Réessayer'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _statusMessage(bool hasError, bool isComplete) {
    if (hasError) return 'Échec de la synchronisation';
    if (isComplete) return 'Synchronisation terminée';
    return 'Synchronisation en cours…';
  }

  String _subtitle(bool hasError, bool isComplete) {
    if (hasError) {
      return 'Vérifiez votre connexion puis réessayez.';
    }
    if (isComplete) {
      return 'Vos projets et données locales sont prêts.';
    }
    return 'Téléchargement des vocabulaires, formulaires et projets…';
  }
}
