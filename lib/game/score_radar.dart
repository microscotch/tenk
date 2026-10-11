import 'player.dart';

/// Les indices de [playerCount] joueurs à partir de [currentIndex] puis dans
/// l'ordre de jeu : la liste des joueurs de l'écran de jeu « tourne » pour
/// garder celui dont c'est le tour en tête.
List<int> rotatedOrder(int playerCount, int currentIndex) => [
  for (var k = 0; k < playerCount; k++) (currentIndex + k) % playerCount,
];

/// L'écart minimal entre le total potentiel et une ligne pour qu'elle compte
/// comme atteignable : le minimum d'un tour.
const int radarMinimumReach = 200;

/// Le « radar » d'un adversaire : ses lignes de grille que le joueur courant
/// pourrait encore barrer plus tard, vues depuis le total qu'il aurait en
/// s'arrêtant maintenant ([potentialTotal] = son score + sa main courante). Ce
/// sont les lignes non barrées — une collision barre toute ligne non barrée de
/// même valeur, pas seulement la ligne courante (voir
/// [Player.applyScoreCollisionBarAt]) — à au moins [radarMinimumReach] au-dessus
/// de [potentialTotal], hors ligne courante (son score est déjà affiché à côté),
/// de la plus proche à la plus lointaine, sans doublon, au plus [limit].
List<int> collisionTargets(Player other, int potentialTotal, {int limit = 3}) {
  final values = {
    for (final entry in other.grid)
      if (!entry.isBarred &&
          entry.value > 0 &&
          entry.value != other.totalScore &&
          entry.value - potentialTotal >= radarMinimumReach)
        entry.value,
  }.toList()..sort();
  return values.take(limit).toList();
}

/// Les écarts entre les plus hautes lignes non barrées de [other] (sa ligne
/// courante d'abord) et [potentialTotal] : ce qu'affiche le radar quand il n'y a
/// plus rien d'atteignable chez ce joueur, au plus [limit]. Un joueur sans ligne
/// marquée donne l'écart de son score (0).
List<int> radarGaps(Player other, int potentialTotal, {int limit = 3}) {
  final values = {
    for (final entry in other.grid)
      if (!entry.isBarred && entry.value > 0) entry.value,
  }.toList()..sort((a, b) => b.compareTo(a));
  if (values.isEmpty) return [other.totalScore - potentialTotal];
  return [for (final value in values.take(limit)) value - potentialTotal];
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
