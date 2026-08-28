import 'dart:math';

import 'player.dart';
import 'turn_result.dart';
import 'turn_state.dart';

/// Orchestre une partie complète : ordre des joueurs, héritage des dés entre
/// tours, et condition de victoire (arrivée exacte à 10000 puis tour final
/// accordé aux autres joueurs).
class GameEngine {
  final List<Player> players;
  final int currentPlayerIndex;

  /// Nombre de dés avec lesquels le prochain tour doit démarrer (hérité du
  /// tour précédent s'il a été validé, ou 5 après un craque / en tout début
  /// de partie).
  final int nextTurnDice;

  final TurnState? activeTurn;
  final bool gameOver;
  final int? winnerIndex;

  /// Index du joueur détenant actuellement le score exact de 10000 (celui
  /// autour duquel tourne le tour final). Peut changer de main en cours de
  /// partie : si un autre joueur égale 10000 pendant le tour final, il barre
  /// l'ancien détenteur (voir la collision de score dans [bank]), devient le
  /// nouveau détenteur, et un tour final complet redémarre pour lui. Null
  /// tant que personne n'a jamais atteint 10000.
  final int? triggeringWinnerIndex;

  /// Nombre de tours restant à jouer par les autres joueurs avant la fin de
  /// la partie, dans le tour final en cours autour de [triggeringWinnerIndex].
  /// Repart à `players.length - 1` à chaque fois que le détenteur change.
  final int? remainingFinalTurns;

  const GameEngine({
    required this.players,
    required this.currentPlayerIndex,
    required this.nextTurnDice,
    this.activeTurn,
    this.gameOver = false,
    this.winnerIndex,
    this.triggeringWinnerIndex,
    this.remainingFinalTurns,
  });

  factory GameEngine.newGame(List<String> playerNames) {
    assert(playerNames.length >= 2, 'Il faut au moins 2 joueurs');
    return GameEngine(
      players: [for (final n in playerNames) Player(name: n)],
      currentPlayerIndex: 0,
      nextTurnDice: 5,
    );
  }

  Player get currentPlayer => players[currentPlayerIndex];
  int get minimumForCurrentPlayer => currentPlayer.minimumForNextTurn;
  bool get isInFinalRound => triggeringWinnerIndex != null;

  GameEngine copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    int? nextTurnDice,
    TurnState? activeTurn,
    bool clearActiveTurn = false,
    bool? gameOver,
    int? winnerIndex,
    int? triggeringWinnerIndex,
    int? remainingFinalTurns,
  }) {
    return GameEngine(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      nextTurnDice: nextTurnDice ?? this.nextTurnDice,
      activeTurn: clearActiveTurn ? null : (activeTurn ?? this.activeTurn),
      gameOver: gameOver ?? this.gameOver,
      winnerIndex: winnerIndex ?? this.winnerIndex,
      triggeringWinnerIndex: triggeringWinnerIndex ?? this.triggeringWinnerIndex,
      remainingFinalTurns: remainingFinalTurns ?? this.remainingFinalTurns,
    );
  }

  /// Démarre le tour du joueur courant.
  GameEngine startTurn() {
    assert(!gameOver);
    return copyWith(activeTurn: TurnState.initial(nextTurnDice));
  }

  /// Lance les dés disponibles du tour en cours.
  GameEngine roll({Random? random}) {
    final t = rollTurn(activeTurn!, random: random);
    return copyWith(activeTurn: t);
  }

  /// Applique la décision de garde du joueur sur le lancer en attente.
  /// Un craque est déclenché si le score total dépasserait 10000.
  GameEngine applyKeep({int declineFivesCount = 0}) {
    var t = applyKeepDecision(activeTurn!, declineFivesCount: declineFivesCount);
    if (currentPlayer.totalScore + t.bankedScore > winningScore) {
      t = t.copyWith(busted: true);
    }
    return copyWith(activeTurn: t);
  }

  /// À appeler une fois qu'un craque (activeTurn.busted) a été affiché à
  /// l'utilisateur : applique les conséquences au joueur et passe la main.
  GameEngine endBustedTurn() {
    assert(activeTurn != null && activeTurn!.busted);
    final updatedPlayer = currentPlayer.applyBust();
    final newPlayers = [...players];
    newPlayers[currentPlayerIndex] = updatedPlayer;
    return _advance(newPlayers, diceForNext: 5);
  }

  /// Tente de banquer le score du tour en cours. En cas de succès, applique
  /// le score au joueur et passe la main (les dés non utilisés sont hérités
  /// par le joueur suivant). En cas d'échec, retourne l'état inchangé avec
  /// la raison de l'échec.
  ///
  /// Si le nouveau score égale celui d'un autre joueur, ce dernier se
  /// retrouve barré (collision de score), qu'il porte ou non un tiret — y
  /// compris si le score en question est 10000.
  (GameEngine, BankAttempt) bank() {
    final attempt = tryBank(activeTurn!, minimumRequired: minimumForCurrentPlayer);
    if (!attempt.success) return (this, attempt);

    final updatedPlayer = currentPlayer.applySuccessfulTurn(attempt.bankedPoints!);
    final newPlayers = [...players];
    newPlayers[currentPlayerIndex] = updatedPlayer;

    for (var i = 0; i < newPlayers.length; i++) {
      if (i == currentPlayerIndex) continue;
      if (newPlayers[i].totalScore == updatedPlayer.totalScore) {
        newPlayers[i] = newPlayers[i].applyScoreCollisionBar();
      }
    }

    final leftoverDice = activeTurn!.diceToRoll;
    return (_advance(newPlayers, diceForNext: leftoverDice), attempt);
  }

  GameEngine _advance(List<Player> newPlayers, {required int diceForNext}) {
    var triggering = triggeringWinnerIndex;
    var remaining = remainingFinalTurns;

    // Le joueur courant vient d'atteindre (ou de reprendre, après avoir
    // barré l'ancien détenteur) exactement 10000 : il devient le détenteur
    // et un tour final complet redémarre pour lui, que ce soit la toute
    // première fois ou un changement de main en cours de tour final.
    if (newPlayers[currentPlayerIndex].totalScore == winningScore) {
      triggering = currentPlayerIndex;
      remaining = newPlayers.length - 1;
    } else if (remaining != null) {
      remaining = remaining - 1;
    }

    if (remaining != null && remaining <= 0) {
      return copyWith(
        players: newPlayers,
        clearActiveTurn: true,
        gameOver: true,
        winnerIndex: triggering,
        triggeringWinnerIndex: triggering,
        remainingFinalTurns: remaining,
      );
    }

    final nextIndex = (currentPlayerIndex + 1) % newPlayers.length;
    return copyWith(
      players: newPlayers,
      currentPlayerIndex: nextIndex,
      nextTurnDice: diceForNext,
      clearActiveTurn: true,
      triggeringWinnerIndex: triggering,
      remainingFinalTurns: remaining,
    );
  }
}
