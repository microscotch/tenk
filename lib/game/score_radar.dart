import 'player.dart';

/// Les indices de [playerCount] joueurs à partir de [currentIndex] puis dans
/// l'ordre de jeu : la liste des joueurs de l'écran de jeu « tourne » pour
/// garder celui dont c'est le tour en tête.
List<int> rotatedOrder(int playerCount, int currentIndex) => [
  for (var k = 0; k < playerCount; k++) (currentIndex + k) % playerCount,
];

/// Le « radar » d'un adversaire : ses lignes de grille que le joueur courant
/// peut encore barrer ce tour-ci. Une collision barre toute ligne non barrée de
/// même valeur, pas seulement la ligne courante (voir
/// [Player.applyScoreCollisionBarAt]) : ce sont donc ses lignes non barrées à
/// partir de [reachFrom] — le score du joueur courant plus le minimum d'un
/// tour, sans descendre sous son total potentiel (sa main ne fait que grossir :
/// une ligne déjà dépassée n'est plus atteignable) —, hors ligne courante (son
/// score est déjà affiché à côté), de la plus proche à la plus lointaine, sans
/// doublon, au plus [limit]. Voir [radarReachFrom].
List<int> collisionTargets(Player other, int reachFrom, {int limit = 3}) {
  final values = {
    for (final entry in other.grid)
      if (!entry.isBarred && entry.value > 0 && entry.value != other.totalScore && entry.value >= reachFrom)
        entry.value,
  }.toList()..sort();
  return values.take(limit).toList();
}

/// D'où partent les lignes atteignables du radar : le score du joueur courant
/// ([currentTotal]) plus le minimum d'un tour ([minimum] : 200 une fois entré,
/// 500 avant), sans descendre sous son total potentiel ([potentialTotal]).
int radarReachFrom({required int currentTotal, required int minimum, required int potentialTotal}) {
  final fromScore = currentTotal + minimum;
  return potentialTotal > fromScore ? potentialTotal : fromScore;
}

/// L'écart entre le score de [other] et [potentialTotal] : ce qu'affiche le
/// radar quand il n'y a plus rien d'atteignable chez ce joueur.
int radarGap(Player other, int potentialTotal) => other.totalScore - potentialTotal;

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
