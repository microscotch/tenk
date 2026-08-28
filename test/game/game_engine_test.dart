import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';

void main() {
  test('la partie démarre avec 5 dés pour le premier joueur', () {
    final engine = GameEngine.newGame(['A', 'B']).startTurn();
    expect(engine.activeTurn!.diceToRoll, 5);
    expect(engine.currentPlayerIndex, 0);
  });

  test('un tour validé fait hériter les dés restants au joueur suivant', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    // On force un état de tour "banquable" avec 3 dés restants, sans passer
    // par de vrais lancers aléatoires : seule la logique d'héritage/avance
    // du GameEngine est ici sous test.
    engine = engine.copyWith(
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 500),
    );
    final (after, attempt) = engine.bank();
    expect(attempt.success, isTrue);
    expect(after.currentPlayerIndex, 1);
    expect(after.nextTurnDice, 3); // hérité du tour précédent
    expect(after.players[0].totalScore, 500);
  });

  test('un craque réinitialise les dés à 5 pour le joueur suivant', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        const Player(name: 'A', totalScore: 300, hasEntered: true),
        const Player(name: 'B'),
      ],
      activeTurn: const TurnState(diceToRoll: 2, bankedScore: 0, busted: true),
    );
    final after = engine.endBustedTurn();
    expect(after.currentPlayerIndex, 1);
    expect(after.nextTurnDice, 5);
    expect(after.players[0].hasTiret, isTrue);
    expect(after.players[0].totalScore, 300); // le tiret ne change pas le score
  });

  test('dépasser 10000 fait craquer le tour même sans intervention du joueur', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        const Player(name: 'A', totalScore: 9900, hasEntered: true),
        const Player(name: 'B'),
      ],
      // Un lancer de deux 1 (200 points) en attente de décision : une fois
      // appliqué, 9900 + 200 = 10100 > 10000, donc craque.
      activeTurn: TurnState(diceToRoll: 2, pendingRoll: analyzeRoll([1, 1])),
    );
    final result = engine.applyKeep();
    expect(result.activeTurn!.busted, isTrue);
  });

  test('atteindre exactement 10000 déclenche un tour final pour les autres joueurs', () {
    var engine = GameEngine.newGame(['A', 'B', 'C']).startTurn();
    engine = engine.copyWith(
      players: [
        const Player(name: 'A', totalScore: 9800, hasEntered: true),
        const Player(name: 'B', totalScore: 3000, hasEntered: true),
        const Player(name: 'C', totalScore: 3000, hasEntered: true),
      ],
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200),
    );
    var (after, attempt) = engine.bank();
    expect(attempt.success, isTrue);
    expect(after.players[0].totalScore, 10000);
    expect(after.isInFinalRound, isTrue);
    expect(after.gameOver, isFalse);
    expect(after.currentPlayerIndex, 1); // au tour de B

    // B joue son tour final (échoue à égaler).
    after = after.startTurn().copyWith(
          activeTurn: const TurnState(diceToRoll: 2, bankedScore: 0, busted: true),
        );
    after = after.endBustedTurn();
    expect(after.gameOver, isFalse);
    expect(after.currentPlayerIndex, 2); // au tour de C

    // C joue son tour final et égale même 10000 : ne doit pas gagner à la
    // place de A, qui a atteint le score en premier.
    after = after.startTurn().copyWith(
          activeTurn: const TurnState(diceToRoll: 3, bankedScore: 7000),
        );
    final (finalEngine, finalAttempt) = after.bank();
    expect(finalAttempt.success, isTrue);
    expect(finalEngine.players[2].totalScore, 10000);
    expect(finalEngine.gameOver, isTrue);
    expect(finalEngine.winnerIndex, 0); // A gagne malgré l'égalité de C
  });
}
