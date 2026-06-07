import 'package:flutter/material.dart';

import '../../core/config/server_config.dart';
import '../../core/routes.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/ui/siamois_form_action_fab.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import '../auth/auth_repository.dart';

/// Configuration de l’URL du serveur backend (accessible avant connexion).
class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _testing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: widget.auth.configuredServerBaseUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _testing = true);
    try {
      final url = AuthRepository.normalizeBaseUrl(_urlController.text);
      final ok = await widget.auth.connectivity.canReachServer(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Serveur joignable.'
                : 'Serveur injoignable. Vérifiez l’URL et le réseau.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.auth.setServerBaseUrl(_urlController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL du serveur enregistrée.')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: SiamoisColors.surface,
      appBar: AppBar(
        title: const Text('Paramètres serveur'),
        leading: const BackButton(),
      ),
      floatingActionButton: SiamoisFormActionFab(
        label: 'Enregistrer',
        submitting: _saving,
        onPressed: _saving || _testing ? null : _save,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                SiamoisSpacing.pageHorizontal,
                SiamoisSpacing.pageHorizontal,
                SiamoisSpacing.pageHorizontal,
                kSiamoisFormFabListBottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: SiamoisSpacing.md),
                  Center(
                    child: SiamoisLayersMark(size: 72),
                  ),
                  const SizedBox(height: SiamoisSpacing.xl),
                  Text(
                    'URL du serveur',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adresse de l’API Siamois utilisée pour la connexion et '
                    'la synchronisation. Exemple : '
                    '${AuthRepository.normalizeBaseUrl(kSiamoisServerBaseUrl)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SiamoisColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: SiamoisSpacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'URL de base',
                            hintText: 'https://serveur.example.com/siamois',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) {
                              return 'L’URL du serveur est obligatoire.';
                            }
                            if (!s.contains('://')) {
                              return 'L’URL doit commencer par http:// ou https://';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: SiamoisSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: _testing || _saving ? null : _testConnection,
                          icon: _testing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_find_rounded),
                          label: const Text('Tester la connexion'),
                        ),
                        const SizedBox(height: SiamoisSpacing.sm),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed(
                            AppRoutes.login,
                          ),
                          child: const Text('Retour à la connexion'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
