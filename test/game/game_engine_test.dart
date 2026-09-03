import 'dart:math';
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
      activeTurn: const TurnState(
        diceToRoll: 3,
        bankedScore: 500,
        keptDiceThisTurn: [KeptDie(value: 5, points: 500 ~/ 2, isExtended: false)],
        hasRolledThisTurn: true,
      ),
    );
    final (after, attempt) = engine.bank();
    expect(attempt.success, isTrue);
    expect(after.currentPlayerIndex, 1);
    expect(after.nextTurnDice, 3); // hérité du tour précédent
    expect(after.players[0].totalScore, 500);
    // Le score et les dés déjà gardés par A sont transmis à B comme base
    // possible pour son propre tour, sans que cela retire quoi que ce soit
    // à A (déjà crédité ci-dessus).
    expect(after.inheritedScore, 500);
    expect(after.inheritedKeptDice, hasLength(1));
  });

  test('continuer avec les dés hérités reprend le score déjà accumulé comme base', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: const TurnState(
        diceToRoll: 3,
        bankedScore: 500,
        extendedValues: {5},
        keptDiceThisTurn: [KeptDie(value: 5, points: 500 ~/ 2, isExtended: false)],
        hasRolledThisTurn: true,
      ),
    );
    final (after, _) = engine.bank();

    final continued = after.startTurn();
    expect(continued.activeTurn!.bankedScore, 500);
    expect(continued.activeTurn!.extendedValues, {5});
    expect(continued.activeTurn!.keptDiceThisTurn, hasLength(1));

    final fresh = after.startTurn(useFullHand: true);
    expect(fresh.activeTurn!.bankedScore, 0);
    expect(fresh.activeTurn!.keptDiceThisTurn, isEmpty);
  });

  test('startTurn(useFullHand: true) ignore les dés hérités et repart à 5', () {
    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(nextTurnDice: 3); // dés hérités d'un tour précédent

    final withInherited = engine.startTurn();
    expect(withInherited.activeTurn!.diceToRoll, 3);

    final withFullHand = engine.startTurn(useFullHand: true);
    expect(withFullHand.activeTurn!.diceToRoll, 5);
  });

  test('un craque réinitialise les dés à 5 pour le joueur suivant', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 300, hasEntered: true),
        Player(name: 'B'),
      ],
      activeTurn: const TurnState(diceToRoll: 2, bankedScore: 0, busted: true),
    );
    final after = engine.endBustedTurn();
    expect(after.currentPlayerIndex, 1);
    expect(after.nextTurnDice, 5);
    expect(after.players[0].hasTiret, isTrue);
    expect(after.players[0].totalScore, 300); // le tiret ne change pas le score
  });

  test('un craque n\'offre jamais de reprise de main : aucun score ni dé hérité, même si un tour précédent en avait laissé', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    // On simule un engine qui portait encore des dés/score hérités d'un tour
    // réussi antérieur (résidu), pour vérifier qu'un craque les efface bien :
    // la reprise de main n'est possible qu'après un tour RÉUSSI, jamais après
    // un craque.
    engine = engine.copyWith(
      inheritedScore: 500,
      inheritedKeptDice: const [KeptDie(value: 5, points: 500, isExtended: false)],
      inheritedExtendedValues: const {5},
      activeTurn: const TurnState(diceToRoll: 2, bankedScore: 0, busted: true),
    );
    final after = engine.endBustedTurn();
    expect(after.nextTurnDice, 5);
    expect(after.inheritedScore, 0);
    expect(after.inheritedKeptDice, isEmpty);
    expect(after.inheritedExtendedValues, isEmpty);

    // Et le tour suivant démarre bien avec 5 dés neufs, sans le résidu.
    final next = after.startTurn();
    expect(next.activeTurn!.diceToRoll, 5);
    expect(next.activeTurn!.bankedScore, 0);
    expect(next.activeTurn!.keptDiceThisTurn, isEmpty);
  });

  test('un second craque barre le score d\'un seul cran (via GameEngine, pas seulement Player)', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    // A porte déjà un tiret (posé au score 700), et a depuis validé un tour
    // de 300 points (700 -> 1000, previousScore mis à jour à 700).
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 1000, previousScore: 700, hasEntered: true, hasTiret: true),
        Player(name: 'B'),
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
        Player(name: 'A', totalScore: 700, hasEntered: true), // déjà barré une fois
        Player(name: 'B'),
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
          Player(name: 'A', totalScore: 2000, previousScore: 1800, hasEntered: true),
          Player(name: 'B', totalScore: 1500, hasEntered: true),
        ],
        currentPlayerIndex: 1,
        activeTurn: const TurnState(diceToRoll: 3, bankedScore: 500, hasRolledThisTurn: true), // B: 1500 -> 2000
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
          Player(name: 'A', totalScore: 2000, previousScore: 1800, hasEntered: true, hasTiret: true),
          Player(name: 'B', totalScore: 1500, hasEntered: true),
        ],
        currentPlayerIndex: 1,
        activeTurn: const TurnState(diceToRoll: 3, bankedScore: 500, hasRolledThisTurn: true), // B: 1500 -> 2000
      );

      final (after, _) = engine.bank();

      expect(after.players[0].totalScore, 1800);
      expect(after.players[0].hasTiret, isFalse, reason: 'la collision consomme aussi le tiret');
    });

    // Régression signalée en jeu : A passe par 700 puis progresse à 900 ;
    // quand B banque ensuite exactement 700, la collision passait inaperçue
    // car seul le score COURANT de A (900) était comparé, jamais son
    // historique de grille.
    test('un tour réussi qui égale un ancien score (déjà dépassé) d\'un autre joueur barre cette ligne, sans toucher à son score courant', () {
      var engine = GameEngine.newGame(['A', 'B']).startTurn();
      engine = engine.copyWith(
        players: [
          Player(name: 'A', totalScore: 700, hasEntered: true).applySuccessfulTurn(200), // A: 0 -> 700 -> 900
          Player(name: 'B', totalScore: 500, hasEntered: true),
        ],
        currentPlayerIndex: 1,
        activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200, hasRolledThisTurn: true), // B: 500 -> 700
      );

      final (after, attempt) = engine.bank();

      expect(attempt.success, isTrue);
      expect(after.players[1].totalScore, 700, reason: 'B a bien validé son tour à 700');
      expect(after.players[0].totalScore, 900, reason: 'A garde sa progression : seule son ancienne ligne 700 est barrée');
      expect(after.players[0].grid.firstWhere((e) => e.value == 700).isBarred, isTrue);
    });
  });

  test('un lancer qui ne peut que dépasser 10000 craque dès le lancer, dés conservés à l\'écran', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 9900, hasEntered: true),
        Player(name: 'B'),
      ],
      activeTurn: const TurnState(diceToRoll: 2),
    );

    // Deux 1 : 200 points incompressibles (aucun 5 à écarter), 9900 + 200
    // dépasserait 10000 quoi que le joueur décide.
    final result = engine.roll(random: _ScriptedRandom([1, 1]));

    expect(result.activeTurn!.busted, isTrue);
    expect(result.activeTurn!.bustReason, BustReason.exceedsTarget);
    expect(
      result.activeTurn!.pendingRoll,
      isNotNull,
      reason: 'les dés restent affichables : le craque est annoncé après leur révélation',
    );
  });

  test('un lancer qui peut encore tomber juste ne craque pas au lancer', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 9800, hasEntered: true),
        Player(name: 'B'),
      ],
      activeTurn: const TurnState(diceToRoll: 3),
    );

    // Deux 5 + un dé non-marquant : garder les deux amène pile à 10000.
    final result = engine.roll(random: _ScriptedRandom([5, 5, 2]));

    expect(result.activeTurn!.busted, isFalse);
    expect(result.activeTurn!.bustReason, isNull);
  });

  test('dépasser 10000 fait craquer le tour même sans intervention du joueur', () {
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 9900, hasEntered: true),
        Player(name: 'B'),
      ],
      // Un lancer de deux 1 (200 points) en attente de décision : une fois
      // appliqué, 9900 + 200 = 10100 > 10000, donc craque.
      activeTurn: TurnState(diceToRoll: 2, pendingRoll: analyzeRoll([1, 1])),
    );
    final result = engine.applyKeep();
    expect(result.activeTurn!.busted, isTrue);
    // La décision de garde a déjà été appliquée avant la détection du
    // dépassement : il n'y a donc plus de lancer en attente à ce stade (l'UI
    // doit gérer ce cas sans planter, voir game_flow_test.dart).
    expect(result.activeTurn!.pendingRoll, isNull);
  });

  test('inheritedHandExceedsWinningScore détecte qu\'une reprise dépasserait déjà 10000', () {
    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 9700, hasEntered: true), Player(name: 'B')],
      nextTurnDice: 3,
      inheritedScore: 700, // 9700 + 700 = 10400 > 10000
    );
    expect(engine.inheritedHandExceedsWinningScore, isTrue);

    final safer = engine.copyWith(inheritedScore: 200); // 9700 + 200 = 9900 <= 10000
    expect(safer.inheritedHandExceedsWinningScore, isFalse);
  });

  test('atteindre exactement 10000 déclenche un tour final pour les autres joueurs '
      '(sans collision, le premier arrivé gagne)', () {
    var engine = GameEngine.newGame(['A', 'B', 'C']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 9800, hasEntered: true),
        Player(name: 'B', totalScore: 3000, hasEntered: true),
        Player(name: 'C', totalScore: 3000, hasEntered: true),
      ],
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200, hasRolledThisTurn: true),
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
          activeTurn: const TurnState(diceToRoll: 3, bankedScore: 6000, hasRolledThisTurn: true),
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
        Player(name: 'A', totalScore: 9800, previousScore: 9500, hasEntered: true),
        Player(name: 'B', totalScore: 3000, hasEntered: true),
        Player(name: 'C', totalScore: 3000, hasEntered: true),
      ],
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200, hasRolledThisTurn: true), // A : 9800 -> 10000
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
          activeTurn: const TurnState(diceToRoll: 3, bankedScore: 7000, hasRolledThisTurn: true), // C : 3000 -> 10000
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
          activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200, hasRolledThisTurn: true), // B : 3000 -> 3200
        );
    final (finalEngine, finalAttempt) = end.bank();
    expect(finalAttempt.success, isTrue);
    expect(finalEngine.gameOver, isTrue);
    expect(finalEngine.winnerIndex, 2); // C conserve la couronne jusqu'au bout
  });
}

/// Random rejouant une séquence de faces fixée, pour provoquer un lancer
/// précis (voir `rollDice`, qui appelle `nextInt(6)` et ajoute 1).
class _ScriptedRandom implements Random {
  final List<int> _faces;
  int _index = 0;

  _ScriptedRandom(this._faces);

  @override
  int nextInt(int max) => _faces[_index++] - 1;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}
