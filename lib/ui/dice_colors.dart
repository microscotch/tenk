import 'package:flutter/material.dart';

import '../state/settings_providers.dart';

/// Palette "set de dés de casino" pour le mode panaché : des teintes assez
/// claires pour que les pips sombres restent lisibles sur toutes (on évite
/// donc un dé noir, qui demanderait des pips clairs séparément).
const List<Color> kDiceColorPalette = [
  Color(0xFFF7F2E7), // ivoire (couleur par défaut du mode uniforme)
  Color(0xFFE0796B), // corail
  Color(0xFF7FA8D9), // bleu ciel
  Color(0xFF8FC17A), // vert sauge
  Color(0xFFE8CE7A), // sable doré
  Color(0xFFC7A2D9), // violet clair
];

/// Couleur de corps à appliquer au dé d'index [diceIndex] (position dans la
/// rangée affichée) selon le mode choisi dans les préférences. Null en mode
/// uniforme : chaque dé garde alors la couleur par défaut de [DieWidget].
Color? diceBodyColorFor(DiceColorMode mode, int diceIndex) {
  if (mode == DiceColorMode.uniform) return null;
  return kDiceColorPalette[diceIndex % kDiceColorPalette.length];
}
