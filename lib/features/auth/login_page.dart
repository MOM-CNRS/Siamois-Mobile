import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes.dart';
import '../../core/sync/sync_orchestrator.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/ui/siamois_spacing.dart';
import 'auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth, required this.sync});

  final AuthRepository auth;
  final SyncOrchestrator sync;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  bool _resumeChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryResumeSession());
  }

  Future<void> _tryResumeSession() async {
    if (_resumeChecked) return;
    _resumeChecked = true;
    try {
      if (await widget.auth.resumeSessionIfValid() && mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.sync,
          arguments: false,
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final online = await widget.auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.sync,
        arguments: online,
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: SiamoisColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: SiamoisSpacing.xl,
                vertical: SiamoisSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: SiamoisSpacing.lg),
                  Text(
                    'Siamois',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: SiamoisColors.primaryDark,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestion de projets archéologiques',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SiamoisColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: SiamoisSpacing.xxl),
                  Text(
                    'Connexion',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connectez-vous pour synchroniser vos projets '
                    'et travailler hors ligne.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SiamoisColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: SiamoisSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(SiamoisSpacing.xl),
                    decoration: BoxDecoration(
                      color: SiamoisColors.surfaceCard,
                      borderRadius:
                          BorderRadius.circular(SiamoisSpacing.radiusXl),
                      border: Border.all(color: SiamoisColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: SiamoisColors.shadow,
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            enableSuggestions: false,
                            spellCheckConfiguration:
                                const SpellCheckConfiguration.disabled(),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return 'L\'e-mail est obligatoire';
                              if (!s.contains('@')) return 'E-mail invalide';
                              return null;
                            },
                          ),
                          const SizedBox(height: SiamoisSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enableSuggestions: false,
                            spellCheckConfiguration:
                                const SpellCheckConfiguration.disabled(),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                _submitting ? null : _onSubmit(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Afficher le mot de passe'
                                    : 'Masquer le mot de passe',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Le mot de passe est obligatoire';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: SiamoisSpacing.xl),
                          FilledButton(
                            onPressed: _submitting ? null : _onSubmit,
                            child: _submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Se connecter'),
                          ),
                        ],
                      ),
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
