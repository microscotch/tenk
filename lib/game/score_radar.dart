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

/// Ce que la ligne d'un adversaire affiche sous son score : [near], l'écart
/// signé à la ligne de sa grille que vise le total potentiel, et [far], l'écart
/// à la ligne voisine, un cran plus loin (nul quand sa grille n'en a pas).
///
/// Devant (positifs) : [near] vers son premier score barrable N, [far] vers sa
/// ligne non barrée suivante N+1 — écrit « N+1, N devant ». Derrière
/// (négatifs) : [near] vers son score N, [far] vers sa ligne non barrée
/// précédente N-1 — écrit « N, N-1 derrière ».
typedef RadarGap = ({int near, int? far});

/// L'écart que la ligne d'un adversaire affiche (voir [RadarGap]). [RadarGap.near]
/// est son score moins [potentialTotal] quand le total potentiel du joueur
/// courant le dépasse (donc négatif), sinon la distance de [potentialTotal] à
/// son premier score barrable (voir [nextBarrableScore]) ; [RadarGap.far] fait
/// de même avec la ligne non barrée voisine, de valeur juste inférieure
/// (derrière) ou juste supérieure (devant). Nul quand il n'a plus rien à barrer.
///
/// [score] remplace le score de [other] quand sa ligne montre un total potentiel
/// (le joueur dont c'est le tour, vu depuis un autre siège) : l'écart est alors
/// simplement [score] moins [potentialTotal], signé, et suit sa main lancer après
/// lancer, sans ligne voisine.
RadarGap? radarDifference(Player other, int potentialTotal, {int? score}) {
  // Une ligne en direct n'a pas de « premier score barrable » à viser : seul
  // compte son avance (ou son retard) sur [potentialTotal], qui bouge à chaque lancer.
  if (score != null) return (near: score - potentialTotal, far: null);
  final shown = other.totalScore;
  if (potentialTotal > shown) {
    final previous = _lineBelow(other, shown);
    return (near: shown - potentialTotal, far: previous == null ? null : previous - potentialTotal);
  }
  final next = nextBarrableScore(other, potentialTotal);
  if (next == null) return null;
  // La ligne non barrée suivante : le premier score barrable juste au-dessus.
  final following = nextBarrableScore(other, next + 1);
  return (near: next - potentialTotal, far: following == null ? null : following - potentialTotal);
}

/// La ligne non barrée de [player], de valeur strictement positive, la plus
/// proche de [value] en dessous. Une ligne à 0 n'est jamais barrable (on ne
/// s'arrête jamais sur 0) : elle ne compte pas.
int? _lineBelow(Player player, int value) {
  int? best;
  for (final entry in player.grid) {
    if (entry.isBarred || entry.value <= 0 || entry.value >= value) continue;
    if (best == null || entry.value > best) best = entry.value;
  }
  return best;
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
