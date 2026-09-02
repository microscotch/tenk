import 'package:flutter/material.dart';

/// Une zone à fine bordure, avec son libellé incrusté dans cette même
/// bordure (effet `<fieldset><legend>`) : le libellé porte la même couleur
/// de bordure que la zone qu'il caractérise, positionné en chevauchement du
/// trait supérieur. Toujours visible (pas de repli).
class BorderedSection extends StatelessWidget {
  final String label;
  final Widget child;

  /// Si `true` (défaut), la zone occupe tout l'espace vertical alloué par le
  /// parent (typiquement un `Expanded`, cf. l'écran d'accueil) via
  /// `Positioned.fill`. Si `false`, elle se dimensionne à son contenu (un
  /// `Stack` ne force jamais un enfant non positionné à remplir son espace
  /// disponible) — nécessaire dans un `Column` non contraint, où des
  /// contraintes entrantes non bornées empêcheraient un `Positioned.fill`
  /// (sans enfant non-positionné) de se dimensionner.
  final bool fillAvailableSpace;

  const BorderedSection({
    super.key,
    required this.label,
    required this.child,
    this.fillAvailableSpace = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bordered = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.primary, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          fillAvailableSpace ? Positioned.fill(child: bordered) : bordered,
          Positioned(
            left: 16,
            top: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                border: Border.all(color: scheme.primary, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(label, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
