import 'package:flutter/material.dart';

/// Les entités métier de Siamois : une couleur et une icône chacune, reprises de
/// l'interface web (`_variables.scss` : contexte `#068DA9`, terrain `#7E1717`,
/// tiers `#E55807` ; icônes Bootstrap du serveur, avec l'équivalent Material le
/// plus proche).
enum SiamoisEntityKind {
  /// Web : `bi-arrow-down-square`, couleur « contexte ».
  project(
    icon: Icons.move_to_inbox_outlined,
    color: Color(0xFF068DA9),
    container: Color(0xFFCDE8EE),
  ),

  /// Web : `bi-pencil-square`, couleur « terrain ».
  recordingUnit(
    icon: Icons.edit_square,
    color: Color(0xFF7E1717),
    container: Color(0xFFE5D1D1),
  ),

  /// Web : `bi-bucket` (approché par un diamant), couleur « terrain » (comme l'UE).
  find(
    icon: Icons.diamond_outlined,
    color: Color(0xFF7E1717),
    container: Color(0xFFE5D1D1),
  ),

  /// Web : `bi-file-earmark-text`, couleur « tiers ».
  document(
    icon: Icons.description_outlined,
    color: Color(0xFFE55807),
    container: Color(0xFFFADECD),
  ),

  /// Web : `bi-geo-alt`, couleur « contexte ».
  place(
    icon: Icons.location_on_outlined,
    color: Color(0xFF068DA9),
    container: Color(0xFFCDE8EE),
  );

  const SiamoisEntityKind({
    required this.icon,
    required this.color,
    required this.container,
  });

  final IconData icon;

  /// Couleur franche : icône, barre d'accent.
  final Color color;

  /// Fond clair assorti : pastille derrière l'icône.
  final Color container;
}

/// Entité affichée par l'écran courant : les widgets partagés (en-têtes de
/// section, bandeaux compteur) y prennent leur couleur sans qu'on la leur passe.
class SiamoisEntityScope extends InheritedWidget {
  const SiamoisEntityScope({
    super.key,
    required this.kind,
    required super.child,
  });

  final SiamoisEntityKind kind;

  static SiamoisEntityKind? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiamoisEntityScope>()?.kind;

  @override
  bool updateShouldNotify(SiamoisEntityScope oldWidget) =>
      kind != oldWidget.kind;
}

/// Titre d'écran précédé de l'icône colorée de l'entité.
class SiamoisEntityTitle extends StatelessWidget {
  const SiamoisEntityTitle(
      {super.key, required this.kind, required this.child});

  final SiamoisEntityKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(kind.icon, size: 22, color: kind.color),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      );
}
