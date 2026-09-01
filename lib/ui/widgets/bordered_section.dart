import 'package:flutter/material.dart';

/// Une zone à fine bordure, avec son libellé incrusté dans cette même
/// bordure (effet `<fieldset><legend>`) : le libellé porte la même couleur
/// de bordure que la zone qu'il caractérise, positionné en chevauchement du
/// trait supérieur. Le libellé est tappable pour ouvrir/fermer la zone (voir
/// [isExpanded]/[onHeaderTap]) : le contenu reste monté en permanence (pas
/// de perte d'état des champs/providers qu'il contient) mais se réduit à une
/// hauteur nulle avec un effet "zoom" (échelle + fondu) quand fermé, plutôt
/// qu'un simple collapse linéaire.
class BorderedSection extends StatelessWidget {
  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.easeOutCubic;

  final String label;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onHeaderTap;

  const BorderedSection({
    super.key,
    required this.label,
    required this.child,
    required this.isExpanded,
    required this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.primary, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRect(
              child: AnimatedAlign(
                duration: _duration,
                curve: _curve,
                alignment: Alignment.topCenter,
                heightFactor: isExpanded ? 1 : 0,
                child: AnimatedOpacity(
                  duration: _duration,
                  curve: _curve,
                  opacity: isExpanded ? 1 : 0,
                  child: AnimatedScale(
                    duration: _duration,
                    curve: _curve,
                    alignment: Alignment.topCenter,
                    scale: isExpanded ? 1 : 0.92,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: -10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onHeaderTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    border: Border.all(color: scheme.primary, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        duration: _duration,
                        curve: _curve,
                        turns: isExpanded ? 0.5 : 0,
                        child: Icon(Icons.expand_more, size: 14, color: scheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
