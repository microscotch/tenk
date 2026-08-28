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

  test('un second craque barre le score d\'un seul cran (via GameEngine, pas seulement Player)', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    // A porte déjà un tiret (posé au score 700), et a depuis validé un tour
    // de 300 points (700 -> 1000, previousScore mis à jour à 700).
    engine = engine.copyWith(
      players: [
        const Player(name: 'A', totalScore: 1000, previousScore: 700, hasEntered: true, hasTiret: true),
        const Player(name: 'B'),
      ],
      currentPlayerIndex: 0,
      activeTurn: const TurnState(diceToRoll: 4, bankedScore: 0, busted: true),
    );

    final after = engine.endBustedTurn();

    expect(after.players[0].totalScore, 700, reason: 'retombe d\'un cran, au score d\'avant le dernier tour validé');
    expect(after.players[0].hasTiret, isFalse, reason: 'le tiret est consommé par le barrage');
    expect(after.currentPlayerIndex, 1);
    expect(after.nextTurnDice, 5);
  });

  test('après un score barré, un craque ultérieur redémarre un nouveau cycle de tiret', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        const Player(name: 'A', totalScore: 700, hasEntered: true), // déjà barré une fois
        const Player(name: 'B'),
      ],
      currentPlayerIndex: 0,
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 0, busted: true),
    );

    final after = engine.endBustedTurn();

    expect(after.players[0].totalScore, 700, reason: 'un simple craque ne change pas le score');
    expect(after.players[0].hasTiret, isTrue, reason: 'nouveau cycle de tiret');
  });

  group('collision de score', () {
    test('un tour réussi qui égale le score d\'un autre joueur le barre, sans tiret', () {
      var engine = GameEngine.newGame(['A', 'B']).startTurn();
      engine = engine.copyWith(
        players: [
          const Player(name: 'A', totalScore: 2000, previousScore: 1800, hasEntered: true),
          const Player(name: 'B', totalScore: 1500, hasEntered: true),
        ],
        currentPlayerIndex: 1,
        activeTurn: const TurnState(diceToRoll: 3, bankedScore: 500), // B: 1500 -> 2000
      );

      final (after, attempt) = engine.bank();

      expect(attempt.success, isTrue);
      expect(after.players[1].totalScore, 2000, reason: 'B a bien validé son tour à 2000');
      expect(after.players[0].totalScore, 1800, reason: 'A retombe à son score précédent : collision à 2000');
      expect(after.players[0].hasTiret, isFalse);
    });

    test('la collision barre aussi un joueur qui portait déjà un tiret', () {
      var engine = GameEngine.newGame(['A', 'B']).startTurn();
      engine = engine.copyWith(
        players: [
          const Player(name: 'A', totalScore: 2000, previousScore: 1800, hasEntered: true, hasTiret: true),
          const Player(name: 'B', totalScore: 1500, hasEntered: true),
        ],
        currentPlayerIndex: 1,
        activeTurn: const TurnState(diceToRoll: 3, bankedScore: 500), // B: 1500 -> 2000
      );

      final (after, _) = engine.bank();

      expect(after.players[0].totalScore, 1800);
      expect(after.players[0].hasTiret, isFalse, reason: 'la collision consomme aussi le tiret');
    });
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

  test('atteindre exactement 10000 déclenche un tour final pour les autres joueurs '
      '(sans collision, le premier arrivé gagne)', () {
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

    // C joue son tour final mais n'égale pas 10000 (pas de collision).
    after = after.startTurn().copyWith(
          activeTurn: const TurnState(diceToRoll: 3, bankedScore: 6000),
        );
    final (finalEngine, finalAttempt) = after.bank();
    expect(finalAttempt.success, isTrue);
    expect(finalEngine.players[2].totalScore, 9000);
    expect(finalEngine.gameOver, isTrue);
    expect(finalEngine.winnerIndex, 0); // A gagne, personne ne l'a égalé
  });

  test('égaler 10000 pendant le tour final barre l\'ancien détenteur et redémarre un tour final complet', () {
    var engine = GameEngine.newGame(['A', 'B', 'C']).startTurn();
    engine = engine.copyWith(
      players: [
        const Player(name: 'A', totalScore: 9800, previousScore: 9500, hasEntered: true),
        const Player(name: 'B', totalScore: 3000, hasEntered: true),
        const Player(name: 'C', totalScore: 3000, hasEntered: true),
      ],
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200), // A : 9800 -> 10000
    );
    var (after, attempt) = engine.bank();
    expect(attempt.success, isTrue);
    expect(after.triggeringWinnerIndex, 0);
    expect(after.currentPlayerIndex, 1); // au tour de B

    // B craque son tour final.
    after = after.startTurn().copyWith(
          activeTurn: const TurnState(diceToRoll: 2, bankedScore: 0, busted: true),
        );
    after = after.endBustedTurn();
    expect(after.gameOver, isFalse);
    expect(after.currentPlayerIndex, 2); // au tour de C

    // C égale 10000 sur son tour final : barre A (retombe à 9800, son score
    // d'avant son tour gagnant), devient le nouveau détenteur, et un tour
    // final complet redémarre (2 tours restants, pour A et B).
    after = after.startTurn().copyWith(
          activeTurn: const TurnState(diceToRoll: 3, bankedScore: 7000), // C : 3000 -> 10000
        );
    final (afterCollision, collisionAttempt) = after.bank();
    expect(collisionAttempt.success, isTrue);
    expect(afterCollision.players[2].totalScore, 10000);
    expect(afterCollision.players[0].totalScore, 9800, reason: 'A est barré par la collision de C sur 10000');
    expect(afterCollision.players[0].hasTiret, isFalse);
    expect(afterCollision.gameOver, isFalse, reason: 'un nouveau tour final démarre autour de C');
    expect(afterCollision.triggeringWinnerIndex, 2);
    expect(afterCollision.remainingFinalTurns, 2); // A et B ont chacun un nouveau tour final
    expect(afterCollision.currentPlayerIndex, 0); // au tour de A

    // A craque son nouveau tour final (ne reprend pas la couronne).
    var end = afterCollision.startTurn().copyWith(
          activeTurn: const TurnState(diceToRoll: 4, bankedScore: 0, busted: true),
        );
    end = end.endBustedTurn();
    expect(end.gameOver, isFalse);
    expect(end.currentPlayerIndex, 1); // au tour de B

    // B valide un tour qui n'égale pas 10000 : le tour final se termine, C gagne.
    end = end.startTurn().copyWith(
          activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200), // B : 3000 -> 3200
        );
    final (finalEngine, finalAttempt) = end.bank();
    expect(finalAttempt.success, isTrue);
    expect(finalEngine.gameOver, isTrue);
    expect(finalEngine.winnerIndex, 2); // C conserve la couronne jusqu'au bout
  });
}
