import 'package:flutter/material.dart';

/// Bouton d’action principal flottant pour les formulaires (comme « Modifier »).
class SiamoisFormActionFab extends StatelessWidget {
  const SiamoisFormActionFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.submitting = false,
    this.icon = Icons.save_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool submitting;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: submitting ? null : onPressed,
      icon: submitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

/// Marge basse des listes de formulaire pour ne pas masquer le FAB.
const double kSiamoisFormFabListBottomPadding = 88;
