import 'dart:math';

import 'dice_roll.dart';

/// Détermine qui commence la partie : chaque joueur lance un seul dé, le
/// score le plus faible commence. En cas d'égalité sur le score le plus
/// faible, seuls les joueurs à égalité relancent, jusqu'à dégager un seul
/// vainqueur.
class DiceOffState {
  /// Index des joueurs (dans l'ordre de la partie) encore en lice pour ce
  /// round de départage.
  final List<int> activeIndices;

  /// Valeurs lancées ce round, par index de joueur (uniquement ceux ayant
  /// déjà lancé ce round).
  final Map<int, int> rollsThisRound;

  /// Historique de tous les rounds joués (pour affichage), dans l'ordre.
  final List<Map<int, int>> roundHistory;

  /// Index du joueur qui commencera la partie, une fois déterminé.
  final int? winnerIndex;

  const DiceOffState({
    required this.activeIndices,
    this.rollsThisRound = const {},
    this.roundHistory = const [],
    this.winnerIndex,
  });

  factory DiceOffState.start(int playerCount) {
    assert(playerCount >= 2);
    return DiceOffState(activeIndices: List.generate(playerCount, (i) => i));
  }

  bool get isResolved => winnerIndex != null;

  /// Le prochain joueur (parmi les actifs) qui doit encore lancer son dé ce
  /// round, ou null si tous ont déjà lancé ou si le départage est résolu.
  int? get nextToRoll {
    if (winnerIndex != null) return null;
    for (final i in activeIndices) {
      if (!rollsThisRound.containsKey(i)) return i;
    }
    return null;
  }

  bool get roundComplete => nextToRoll == null;

  DiceOffState rollFor(int index, {Random? random}) {
    assert(activeIndices.contains(index));
    assert(!rollsThisRound.containsKey(index));
    final value = rollDice(1, random).single;
    return DiceOffState(
      activeIndices: activeIndices,
      rollsThisRound: {...rollsThisRound, index: value},
      roundHistory: roundHistory,
    );
  }

  /// Une fois le round complet (tous les joueurs actifs ont lancé), calcule
  /// le(s) plus petit(s) score(s) : s'il n'y en a qu'un, la partie est
  /// tranchée ; sinon un nouveau round démarre entre les joueurs à égalité.
  DiceOffState resolveRound() {
    assert(roundComplete);
    final minValue = activeIndices.map((i) => rollsThisRound[i]!).reduce((a, b) => a < b ? a : b);
    final tied = activeIndices.where((i) => rollsThisRound[i] == minValue).toList(growable: false);
    final newHistory = [...roundHistory, rollsThisRound];

    if (tied.length == 1) {
      return DiceOffState(
        activeIndices: activeIndices,
        roundHistory: newHistory,
        winnerIndex: tied.single,
      );
    }
    return DiceOffState(activeIndices: tied, roundHistory: newHistory);
  }
}
