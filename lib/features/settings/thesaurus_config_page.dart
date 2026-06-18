import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' hide Form;
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/ui/siamois_form_action_fab.dart';
import '../../core/widgets/ui/siamois_messenger.dart';
import '../../core/widgets/ui/siamois_message_banner.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import '../auth/auth_repository.dart';
import 'thesaurus_settings_scope.dart';
import 'thesaurus_settings_service.dart';

/// Formulaire partagé : thésaurus utilisateur ou organisation.
class ThesaurusConfigPage extends StatefulWidget {
  const ThesaurusConfigPage({
    super.key,
    required this.auth,
    required this.database,
    required this.scope,
    required this.organisationId,
    required this.organisationName,
    required this.pageTitle,
    required this.heading,
    required this.infoMessage,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final ThesaurusSettingsScope scope;
  final int organisationId;
  final String organisationName;
  final String pageTitle;
  final String heading;
  final String infoMessage;

  @override
  State<ThesaurusConfigPage> createState() => _ThesaurusConfigPageState();
}

class _ThesaurusConfigPageState extends State<ThesaurusConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final ThesaurusSettingsService _service;

  bool _loading = true;
  bool _saving = false;
  int _progress = 0;
  DateTime? _serverSyncedAt;
  bool _pendingServerSync = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _service = ThesaurusSettingsService(
      auth: widget.auth,
      database: widget.database,
    );
    _load();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final state = await _service.load(
        organisationId: widget.organisationId,
        scope: widget.scope,
      );
      if (!mounted) return;
      _urlController.text = state.thesaurusUrl;
      setState(() {
        _serverSyncedAt = state.serverSyncedAt;
        _pendingServerSync = state.pendingServerSync;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is AuthException
          ? e.message
          : e is FormatException
              ? e.message
              : e.toString();
      setState(() {
        _loading = false;
        _loadError = message;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() {
      _saving = true;
      _progress = 0;
    });

    try {
      await _service.validateAndSaveLocal(
        organisationId: widget.organisationId,
        scope: widget.scope,
        thesaurusUrl: _urlController.text,
      );
      if (!mounted) return;

      setState(() {
        _pendingServerSync = true;
        _serverSyncedAt = null;
      });

      if (!await widget.auth.canUseProjectsApi()) {
        if (!mounted) return;
        context.showInfoMessage('URL enregistrée sur cet appareil.');
        await _load();
        return;
      }

      try {
        await _service.syncToServer(
          organisationId: widget.organisationId,
          scope: widget.scope,
          thesaurusUrl: _urlController.text,
          onProgress: (pct) {
            if (mounted) setState(() => _progress = pct);
          },
        );
        if (!mounted) return;
        context.showInfoMessage(
          'Configuration synchronisée avec le serveur.',
        );
      } on FormatException catch (e) {
        if (!mounted) return;
        context.showInfoMessage(e.message);
      } on AuthException catch (e) {
        if (!mounted) return;
        context.showErrorMessage(e.message);
      }

      await _load();
    } on FormatException catch (e) {
      if (!mounted) return;
      context.showInfoMessage(e.message);
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showErrorMessage('Erreur : $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = 0;
        });
      }
    }
  }

  String? _validateUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Veuillez renseigner le lien permanent vers le thésaurus.';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'URL de thésaurus invalide.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: SiamoisColors.surface,
      appBar: SiamoisTitleBar(
        title: widget.pageTitle,
        showBrandMark: false,
        leading: const BackButton(),
      ),
      floatingActionButton: _loading
          ? null
          : SiamoisFormActionFab(
              label: 'Enregistrer',
              icon: Icons.save_rounded,
              submitting: _saving,
              onPressed: _save,
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _ErrorBody(message: _loadError!, onRetry: _load)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      SiamoisSpacing.pageHorizontal,
                      SiamoisSpacing.lg,
                      SiamoisSpacing.pageHorizontal,
                      kSiamoisFormFabListBottomPadding,
                    ),
                    children: [
                      Text(
                        widget.organisationName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: SiamoisColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: SiamoisSpacing.sm),
                      Text(
                        widget.heading,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: SiamoisSpacing.md),
                      SiamoisMessageBanner(
                        kind: SiamoisMessageKind.info,
                        message: widget.infoMessage,
                      ),
                      const SizedBox(height: SiamoisSpacing.lg),
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL du thésaurus',
                          hintText: 'https://opentheso.mom.fr/?idc=…&idt=…',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        enabled: !_saving,
                        validator: _validateUrl,
                      ),
                      if (_saving) ...[
                        const SizedBox(height: SiamoisSpacing.lg),
                        Text(
                          'Import des concepts depuis le thésaurus…',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: SiamoisColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: SiamoisSpacing.sm),
                        LinearProgressIndicator(
                          value: _progress > 0 ? _progress / 100 : null,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        if (_progress > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$_progress %',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: SiamoisColors.textTertiary,
                              ),
                            ),
                          ),
                      ],
                      if (!_saving && _serverSyncedAt != null) ...[
                        const SizedBox(height: SiamoisSpacing.lg),
                        Row(
                          children: [
                            const Icon(
                              Icons.cloud_done_rounded,
                              size: 18,
                              color: SiamoisColors.success,
                            ),
                            const SizedBox(width: SiamoisSpacing.sm),
                            Expanded(
                              child: Text(
                                'Synchronisé avec le serveur le '
                                '${_formatDate(_serverSyncedAt!)}.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: SiamoisColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!_saving && _pendingServerSync) ...[
                        const SizedBox(height: SiamoisSpacing.md),
                        const SiamoisMessageBanner(
                          kind: SiamoisMessageKind.info,
                          message:
                              'URL enregistrée localement. '
                              'Relancez l’enregistrement en ligne pour l’appliquer au serveur.',
                        ),
                      ],
                      const SizedBox(height: SiamoisSpacing.lg),
                      Text(
                        'Exemple de lien permanent',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: SiamoisSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(SiamoisSpacing.md),
                        decoration: BoxDecoration(
                          color: SiamoisColors.surfaceCard,
                          borderRadius:
                              BorderRadius.circular(SiamoisSpacing.radiusMd),
                          border: Border.all(color: SiamoisColors.border),
                        ),
                        child: Text(
                          'Sur OpenTheso, ouvrez votre thésaurus puis copiez '
                          'l’URL permanente du concept racine ou du thésaurus '
                          '(paramètres « URI » / lien permanent).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: SiamoisColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y à $h:$min';
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SiamoisSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: SiamoisColors.error,
            ),
            const SizedBox(height: SiamoisSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: SiamoisSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
