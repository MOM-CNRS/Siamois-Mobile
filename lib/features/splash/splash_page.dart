import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes.dart';
import '../../core/theme/siamois_colors.dart';
import '../../core/widgets/app_version_label.dart';
import '../../core/widgets/siamois_title_bar.dart';
import '../../core/widgets/ui/siamois_spacing.dart';

/// Écran d’accueil (logo obligatoire, 2 secondes) avant la connexion.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _goToLogin);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SiamoisColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SiamoisLayersMark(size: 160),
                    const SizedBox(height: SiamoisSpacing.lg),
                    Text(
                      'Siamois',
                      style: GoogleFonts.lora(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: SiamoisColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestion de projets archéologiques',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SiamoisColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: SiamoisSpacing.lg),
              child: AppVersionLabel(),
            ),
          ],
        ),
      ),
    );
  }
}
