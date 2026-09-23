import 'dart:math';

import 'dice_roll.dart';

/// Détermine qui commence la partie, et dans quel sens elle tourne : chaque
/// joueur lance un seul dé, le score le plus faible commence. En cas
/// d'égalité sur le score le plus faible, seuls les joueurs à égalité
/// relancent, jusqu'à dégager un seul vainqueur.
///
/// Deux formats coexistent, parce que les parties archivées se rejouent depuis
/// leur journal : l'ancien, où chacun lançait à son tour ([rollFor]) et où la
/// partie tournait toujours dans le sens de la liste, et l'actuel, où tous les
/// dés d'un round partent ensemble ([rollAll]) et où un duel final entre
/// voisins peut inverser le sens (voir [playOrder]). Appliquer la règle
/// actuelle à un ancien journal changerait en silence qui occupe quel siège.
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

  /// Nombre de joueurs de la partie (pas seulement ceux encore en lice).
  final int playerCount;

  /// Vrai dès qu'un round a été lancé d'un bloc ([rollAll]) : c'est ce qui
  /// distingue un départage au format actuel d'un ancien journal.
  final bool simultaneous;

  const DiceOffState({
    required this.activeIndices,
    required this.playerCount,
    this.rollsThisRound = const {},
    this.roundHistory = const [],
    this.winnerIndex,
    this.simultaneous = false,
  });

  factory DiceOffState.start(int playerCount) {
    assert(playerCount >= 2);
    return DiceOffState(activeIndices: List.generate(playerCount, (i) => i), playerCount: playerCount);
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

  DiceOffState _copy({Map<int, int>? rollsThisRound, bool? simultaneous}) => DiceOffState(
        activeIndices: activeIndices,
        playerCount: playerCount,
        rollsThisRound: rollsThisRound ?? this.rollsThisRound,
        roundHistory: roundHistory,
        simultaneous: simultaneous ?? this.simultaneous,
      );

  /// Ancien format : un seul joueur lance. Conservé pour rejouer les journaux
  /// enregistrés avant [rollAll].
  DiceOffState rollFor(int index, {Random? random}) {
    assert(activeIndices.contains(index));
    assert(!rollsThisRound.containsKey(index));
    final value = rollDice(1, random).single;
    return _copy(rollsThisRound: {...rollsThisRound, index: value});
  }

  /// Tous les joueurs encore en lice lancent leur dé en même temps. Les dés
  /// sont tirés dans l'ordre des sièges, exactement comme autant de [rollFor]
  /// successifs : seul le format du journal change, pas le flux de tirages.
  DiceOffState rollAll({Random? random}) {
    assert(rollsThisRound.isEmpty && !isResolved);
    // Un dé par joueur plutôt qu'un seul `rollDice(n)` : il en plafonne le
    // nombre à 5, alors qu'une partie compte jusqu'à 6 joueurs.
    return _copy(
      rollsThisRound: {for (final i in activeIndices) i: rollDice(1, random).single},
      simultaneous: true,
    );
  }

  /// Une fois le round complet (tous les joueurs actifs ont lancé), calcule
  /// le(s) plus petit(s) score(s) : s'il n'y en a qu'un, la partie est
  /// tranchée ; sinon un nouveau round démarre entre les joueurs à égalité.
  ///
  /// Un départage tranché garde les [activeIndices] de son dernier round :
  /// [playOrder] en a besoin pour reconnaître un duel final.
  DiceOffState resolveRound() {
    assert(roundComplete);
    final minValue = activeIndices.map((i) => rollsThisRound[i]!).reduce((a, b) => a < b ? a : b);
    final tied = activeIndices.where((i) => rollsThisRound[i] == minValue).toList(growable: false);
    final newHistory = [...roundHistory, rollsThisRound];

    return DiceOffState(
      activeIndices: tied.length == 1 ? activeIndices : tied,
      playerCount: playerCount,
      roundHistory: newHistory,
      winnerIndex: tied.length == 1 ? tied.single : null,
      simultaneous: simultaneous,
    );
  }

  /// Vrai quand la partie tournera à rebours de la liste : le dernier round
  /// était un duel entre deux voisins (table circulaire, le dernier joueur
  /// étant voisin du premier) et c'est le second des deux dans le sens de la
  /// liste qui l'a gagné. La partie part alors du vainqueur vers le perdant.
  /// À deux joueurs, chacun est à la fois le suivant et le précédent de
  /// l'autre : les deux sens se confondent, il n'y a rien à inverser.
  bool get reversesOrder {
    if (!isResolved || !simultaneous || playerCount < 3 || activeIndices.length != 2) return false;
    final loser = activeIndices.firstWhere((i) => i != winnerIndex);
    return (loser + 1) % playerCount == winnerIndex;
  }

  /// L'ordre de jeu, en index de la configuration d'origine : le vainqueur
  /// d'abord, puis dans le sens de la liste — ou à rebours, voir
  /// [reversesOrder].
  List<int> get playOrder {
    final w = winnerIndex!;
    final step = reversesOrder ? -1 : 1;
    return [for (var k = 0; k < playerCount; k++) (w + step * k) % playerCount];
  }
}
