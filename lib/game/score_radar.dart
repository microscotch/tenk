import 'player.dart';

/// Le premier score de la grille de [player], en remontant depuis sa ligne
/// courante, qui soit non barré et strictement inférieur à [potentialTotal] :
/// ce que la ligne du joueur courant affiche, en petit, à côté de son total
/// potentiel. Nulle s'il n'y en a pas.
ScoreEntry? firstEntryBelow(Player player, int potentialTotal) {
  for (var i = player.grid.length - 1; i >= 0; i--) {
    final entry = player.grid[i];
    if (!entry.isBarred && entry.value < potentialTotal) return entry;
  }
  return null;
}

/// Le premier score barrable de [other] à partir de [potentialTotal] : sa plus
/// petite ligne non barrée de valeur au moins égale (une collision barre toute
/// ligne non barrée de même valeur, voir [Player.applyScoreCollisionBarAt]).
/// Nul si [other] n'en a aucune.
int? nextBarrableScore(Player other, int potentialTotal) {
  int? best;
  for (final entry in other.grid) {
    if (entry.isBarred || entry.value <= 0 || entry.value < potentialTotal) continue;
    if (best == null || entry.value < best) best = entry.value;
  }
  return best;
}

/// L'écart signé que la ligne d'un adversaire affiche : son score moins
/// [potentialTotal] quand le total potentiel du joueur courant le dépasse (donc
/// négatif), sinon la distance de [potentialTotal] à son premier score barrable
/// (voir [nextBarrableScore]). Nul quand il n'a plus rien à barrer.
///
/// [score] remplace le score de [other] quand sa ligne montre un total potentiel
/// (le joueur dont c'est le tour, vu depuis un autre siège).
int? radarDifference(Player other, int potentialTotal, {int? score}) {
  final shown = score ?? other.totalScore;
  if (potentialTotal > shown) return shown - potentialTotal;
  final next = nextBarrableScore(other, potentialTotal);
  return next == null ? null : next - potentialTotal;
}

/// Vrai si s'arrêter sur [potentialTotal] barrerait un autre joueur que
/// [currentIndex] : l'une de ses lignes non barrées a exactement cette valeur
/// (voir [Player.applyScoreCollisionBarAt]).
bool barsAnotherPlayer(List<Player> players, int currentIndex, int potentialTotal) {
  if (potentialTotal <= 0) return false;
  for (var i = 0; i < players.length; i++) {
    if (i == currentIndex) continue;
    if (players[i].grid.any((e) => !e.isBarred && e.value == potentialTotal)) return true;
  }
  return false;
}

/// Un écart signé, le moins typographique (−950) plutôt que le trait d'union.
String signedGap(int value) => value < 0 ? '\u2212${-value}' : (value == 0 ? '0' : '+$value');
