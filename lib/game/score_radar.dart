import 'player.dart';

/// Les indices de [playerCount] joueurs à partir de [currentIndex] puis dans
/// l'ordre de jeu : la liste des joueurs de l'écran de jeu « tourne » pour
/// garder celui dont c'est le tour en tête.
List<int> rotatedOrder(int playerCount, int currentIndex) => [
  for (var k = 0; k < playerCount; k++) (currentIndex + k) % playerCount,
];

/// Le « radar » d'un adversaire : ses lignes de grille que le joueur courant
/// pourrait encore barrer, vues depuis le total qu'il aurait en s'arrêtant
/// maintenant ([potentialTotal] = son score + sa main courante). Ce sont les
/// lignes non barrées de valeur ≥ [potentialTotal] — une collision barre toute
/// ligne non barrée de même valeur, pas seulement la ligne courante (voir
/// [Player.applyScoreCollisionBarAt]) —, de la plus proche à la plus lointaine,
/// sans doublon, au plus [limit].
///
/// Une ligne n'est jamais au-dessus du score courant de son joueur : la liste
/// est donc vide exactement quand [potentialTotal] le dépasse (voir
/// [radarGap]).
List<int> collisionTargets(Player other, int potentialTotal, {int limit = 3}) {
  final values = {
    for (final entry in other.grid)
      if (!entry.isBarred && entry.value > 0 && entry.value >= potentialTotal) entry.value,
  }.toList()..sort();
  return values.take(limit).toList();
}

/// L'écart entre le score de [other] et [potentialTotal] : ce qu'affiche le
/// radar quand il n'y a plus rien à barrer chez ce joueur (négatif dans ce cas).
int radarGap(Player other, int potentialTotal) => other.totalScore - potentialTotal;
