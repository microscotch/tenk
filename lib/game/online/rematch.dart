/// L'ordre des sièges d'une revanche en ligne : ceux de [remaining] (les
/// joueurs qui l'ont acceptée, bots exclus), dans l'ordre de jeu de la partie
/// précédente ([previousPlayOrder], des sièges), tourné pour commencer par celui
/// qui y avait le meilleur score final ([finalScoreBySeat]). À égalité — à 0,
/// seule égalité possible, la règle de collision séparant tous les autres
/// scores — le premier dans l'ancien ordre de jeu commence.
///
/// Pas de nouveau tirage au sort : la revanche reprend le sens de la partie
/// précédente, en sautant les absents.
List<int> rematchSeatOrder({
  required List<int> previousPlayOrder,
  required Map<int, int> finalScoreBySeat,
  required Set<int> remaining,
}) {
  final kept = [for (final seat in previousPlayOrder) if (remaining.contains(seat)) seat];
  if (kept.isEmpty) return const [];
  var start = 0;
  for (var k = 1; k < kept.length; k++) {
    if ((finalScoreBySeat[kept[k]] ?? 0) > (finalScoreBySeat[kept[start]] ?? 0)) start = k;
  }
  return [for (var k = 0; k < kept.length; k++) kept[(start + k) % kept.length]];
}
