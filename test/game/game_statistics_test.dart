import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_statistics.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/player_stats.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/turn_state.dart';

import '../test_helpers/scripted_game.dart';

/// Les dés d'un rejeu sont déterminés par la seed : vérifier chaque figure en
/// cherchant une seed qui la produise serait de l'archéologie. On pilote donc
/// le collecteur directement, en lui donnant les deux états du moteur qu'on
/// veut lui faire observer — c'est exactement ce que `replayGame` lui passe.
void main() {
  late GameStatisticsCollector collector;

  setUp(() => collector = GameStatisticsCollector(2));

  /// Un moteur au tour du siège [seat], avec [banked] déjà banqué ce tour et
  /// [totalScore] au compteur.
  GameEngine engineAtTurn({
    int seat = 0,
    int banked = 0,
    int totalScore = 0,
    int diceToRoll = 5,
    List<Player>? players,
  }) {
    return GameEngine.newGame(const ['A', 'B']).copyWith(
      players: players ??
          [
            Player(name: 'A', totalScore: totalScore, hasEntered: totalScore > 0),
            Player(name: 'B'),
          ],
      currentPlayerIndex: seat,
      activeTurn: TurnState(diceToRoll: diceToRoll, bankedScore: banked, hasRolledThisTurn: true),
    );
  }

  /// Joue un lancer : le moteur passe d'« en attente » à « lancer posé ».
  void roll(GameEngine before, List<int> faces) {
    final after = before.copyWith(
      activeTurn: before.activeTurn!.copyWith(pendingRoll: analyzeRoll(faces)),
    );
    collector.apply(before, after, GameAction.roll());
  }

  PlayerStats stats(int seat) => collector.statsFor(seat, activeSeconds: 100, won: false);

  group('figures', () {
    test('brelan, carré et quinte sont ventilés par valeur', () {
      roll(engineAtTurn(), [4, 4, 4, 2, 3]);
      roll(engineAtTurn(), [6, 6, 6, 6, 2]);
      roll(engineAtTurn(totalScore: 500), [2, 2, 2, 2, 2]);

      expect(stats(0).brelans, {4: 1});
      expect(stats(0).carres, {6: 1});
      expect(stats(0).quintes, {2: 1});
    });

    test('la petite et la grande suite se distinguent par les faces tombées', () {
      roll(engineAtTurn(), [1, 2, 3, 4, 5]);
      roll(engineAtTurn(), [2, 3, 4, 5, 6]);
      roll(engineAtTurn(), [2, 3, 4, 5, 6]);

      expect(stats(0).petitesSuites, 1);
      expect(stats(0).grandesSuites, 2);
      expect(stats(0).suitesTotal, 3,
          reason: 'une suite est toujours value:0, seules les faces les séparent');
    });

    test('un dé isolé que seule la règle d\'extension fait marquer n\'est pas une figure', () {
      // Un 4 isolé ne marque que parce qu'un brelan de 4 a déjà été encaissé :
      // le groupe a une valeur quelconque mais un seul dé.
      final before = engineAtTurn(banked: 400).copyWith(
        activeTurn: TurnState(
          diceToRoll: 2,
          bankedScore: 400,
          hasRolledThisTurn: true,
          extendedValues: const {4},
        ),
      );
      final after = before.copyWith(
        activeTurn: before.activeTurn!.copyWith(
          pendingRoll: analyzeRoll([4, 3], extendedValues: const {4}),
        ),
      );
      collector.apply(before, after, GameAction.roll());

      expect(stats(0).brelans, isEmpty, reason: 'seul diceCount >= 3 fait une figure');
      expect(stats(0).carres, isEmpty);
    });

    test('une figure compte même sur un lancer qui fait craquer par dépassement', () {
      // Le moteur craque au lancer ; la figure est quand même sortie.
      final before = engineAtTurn(totalScore: 9500);
      final after = before.copyWith(
        activeTurn: before.activeTurn!.copyWith(
          pendingRoll: analyzeRoll([6, 6, 6, 2, 3]),
          busted: true,
          bustReason: BustReason.exceedsTarget,
        ),
      );
      collector.apply(before, after, GameAction.roll());

      expect(stats(0).brelans, {6: 1});
    });
  });

  group('quinte d\'as', () {
    test('réussie quand le joueur est à la niche', () {
      roll(engineAtTurn(totalScore: 0, banked: 0), [1, 1, 1, 1, 1]);

      expect(stats(0).quintesDAsReussies, 1);
      expect(stats(0).quintesDAsPerdues, 0);
      expect(stats(0).quintes, {1: 1}, reason: 'elle reste aussi une quinte');
    });

    test('perdue dès que le joueur a des points au compteur', () {
      roll(engineAtTurn(totalScore: 2400), [1, 1, 1, 1, 1]);

      expect(stats(0).quintesDAsPerdues, 1);
      expect(stats(0).quintesDAsReussies, 0);
    });

    test('perdue aussi si le tour a déjà banqué des points', () {
      roll(engineAtTurn(totalScore: 0, banked: 300), [1, 1, 1, 1, 1]);

      expect(stats(0).quintesDAsPerdues, 1);
    });
  });

  group('as et 5 isolés gardés', () {
    void applyKeep(GameEngine before, List<int> faces, {int declined = 0}) {
      final withRoll = before.copyWith(
        activeTurn: before.activeTurn!.copyWith(pendingRoll: analyzeRoll(faces)),
      );
      final after = withRoll.copyWith(
        activeTurn: applyKeepDecision(withRoll.activeTurn!, declineFivesCount: declined),
      );
      collector.apply(withRoll, after, GameAction.applyKeep(declineFivesCount: declined));
    }

    test('comptés par dé et non par figure', () {
      applyKeep(engineAtTurn(), [1, 1, 5, 2, 3]);

      expect(stats(0).keptLoneAces, 2, reason: 'deux as isolés en font deux');
      expect(stats(0).keptLoneFives, 1);
    });

    test('un 5 décliné n\'est pas gardé, donc pas compté', () {
      // Pas [1,5,2,3,4] : ce serait une petite suite, donc aucun 5 déclinable.
      applyKeep(engineAtTurn(), [1, 5, 2, 3, 3], declined: 1);

      expect(stats(0).keptLoneAces, 1);
      expect(stats(0).keptLoneFives, 0, reason: 'il repart au relancer');
    });

    test('les as d\'une quinte d\'as ne sont pas des as isolés', () {
      applyKeep(engineAtTurn(), [1, 1, 1, 1, 1]);

      expect(stats(0).keptLoneAces, 0, reason: 'diceCount 5, c\'est une figure');
    });
  });

  group('mains pleines et meilleur tour', () {
    test('la plus longue série de mains pleines d\'un tour est retenue', () {
      final before = engineAtTurn();
      GameEngine hotDice(GameEngine e) => e.copyWith(
            activeTurn: e.activeTurn!.copyWith(mustContinue: true, diceToRoll: 5),
          );

      collector.apply(before, hotDice(before), GameAction.applyKeep(declineFivesCount: 0));
      collector.apply(before, hotDice(before), GameAction.applyKeep(declineFivesCount: 0));
      collector.apply(before, hotDice(before), GameAction.applyKeep(declineFivesCount: 0));
      // Le tour se termine : la série repart de zéro.
      collector.apply(before, before.copyWith(clearActiveTurn: true), GameAction.bank());
      collector.apply(before, hotDice(before), GameAction.applyKeep(declineFivesCount: 0));

      expect(stats(0).longestHotDiceRun, 3);
    });

    test('le meilleur tour retient le score banqué le plus élevé', () {
      final small = engineAtTurn(banked: 450);
      final big = engineAtTurn(banked: 1800);

      collector.apply(small, small.copyWith(clearActiveTurn: true), GameAction.bank());
      collector.apply(big, big.copyWith(clearActiveTurn: true), GameAction.bank());

      expect(stats(0).bestBankedTurn, 1800);
    });

    test('un applyKeep qui banque sur place compte aussi (quinte d\'as)', () {
      final before = engineAtTurn(banked: 10000);

      collector.apply(before, before.copyWith(clearActiveTurn: true), GameAction.applyKeep(declineFivesCount: 0));

      expect(stats(0).bestBankedTurn, 10000,
          reason: '_advance vide activeTurn : c\'est le signe d\'un banquage');
    });
  });

  group('craquages', () {
    test('comptés, avec la plus longue série et le nombre de séries', () {
      final e = engineAtTurn();
      void bust() => collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.endBustedTurn());
      void bank() => collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.bank());

      bust();
      bust();
      bank();
      bust();
      bust();
      bust();

      final s = stats(0);
      expect(s.bustsTotal, 5);
      expect(s.longestBustStreak, 3);
      expect(s.bustStreakCount, 2);
      expect(s.averageBustStreak, 2.5);
    });
  });

  group('lancers et tours', () {
    test('chaque lancer compte, y compris celui qui fait craquer', () {
      final e = engineAtTurn();
      roll(e, [1, 2, 3, 4, 6]);
      roll(e, [2, 3, 4, 6, 2]); // ne marque rien : le lancer fatal compte aussi

      expect(stats(0).rollsTotal, 2);
      expect(stats(1).rollsTotal, 0, reason: 'les lancers sont ceux du siège dont c\'est le tour');
    });

    test('un tour se termine par un banquage comme par un craque', () {
      final e = engineAtTurn();
      collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.bank());
      collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.endBustedTurn());

      expect(stats(0).turnsTotal, 2);
    });

    test('la quinte d\'as, qui banque sur place, termine aussi son tour', () {
      // Seule figure autorisée à conclure une main pleine : `applyKeep` laisse
      // alors `activeTurn` nul, sans action `bank` derrière.
      final e = engineAtTurn();
      collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.applyKeep(declineFivesCount: 0));

      expect(stats(0).turnsTotal, 1);
    });

    test('une garde qui laisse le tour ouvert ne le termine pas', () {
      final e = engineAtTurn();
      collector.apply(e, e, GameAction.applyKeep(declineFivesCount: 0));

      expect(stats(0).turnsTotal, 0);
    });

    test('la moyenne est celle des lancers rapportés aux tours', () {
      final e = engineAtTurn();
      for (var i = 0; i < 6; i++) {
        roll(e, [1, 2, 3, 4, 6]);
      }
      collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.bank());
      collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.endBustedTurn());
      collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.bank());
      collector.apply(e, e.copyWith(clearActiveTurn: true), GameAction.bank());

      expect(stats(0).averageRollsPerTurn, 1.5, reason: '6 lancers sur 4 tours');
    });
  });

  group('barrés', () {
    test('un second craque consécutif barre sa propre ligne', () {
      final before = GameEngine.newGame(const ['A', 'B']).copyWith(
        players: [Player(name: 'A', totalScore: 700, hasTiret: true), Player(name: 'B')],
        currentPlayerIndex: 0,
        activeTurn: const TurnState(diceToRoll: 3, busted: true),
      );
      final after = before.copyWith(
        players: [before.players[0].applyBust(), before.players[1]],
        clearActiveTurn: true,
      );

      collector.apply(before, after, GameAction.endBustedTurn());

      expect(stats(0).selfBarsTotal, 1);
      expect(stats(0).barsInflictedTotal, 0);
      expect(stats(1).barsInflictedTotal, 0);
    });

    test('une collision de score barre chez l\'adversaire, au crédit de l\'auteur', () {
      final victim = Player(name: 'B', totalScore: 1500, hasEntered: true);
      final before = GameEngine.newGame(const ['A', 'B']).copyWith(
        players: [Player(name: 'A', totalScore: 1000, hasEntered: true), victim],
        currentPlayerIndex: 0,
        activeTurn: const TurnState(diceToRoll: 2, bankedScore: 500, hasRolledThisTurn: true),
      );
      final after = before.copyWith(
        players: [
          before.players[0],
          victim.applyScoreCollisionBarAt(1500, barredByName: 'A'),
        ],
        clearActiveTurn: true,
      );

      collector.apply(before, after, GameAction.bank());

      expect(stats(0).barsInflictedTotal, 1, reason: 'barredBy porte le nom de l\'auteur');
      expect(stats(1).selfBarsTotal, 0, reason: 'la victime ne s\'est pas barrée elle-même');
    });
  });

  test('un siège sans rien fait reste vierge', () {
    roll(engineAtTurn(seat: 0), [4, 4, 4, 2, 3]);

    expect(stats(1).brelans, isEmpty);
    expect(stats(1).bustsTotal, 0);
  });

  group('sur une partie complète', () {
    const setup = GameSetup(playerNames: ['Alice', 'Bruno', 'Chloé']);

    test('chaque siège compte une partie, et un seul l\'a gagnée', () {
      final played = playScriptedGame(setup, 42);

      final result = collectGameStatistics(setup: setup, seed: 42, actions: played.actions);

      expect(result.bySeat, hasLength(3));
      expect(result.bySeat.every((s) => s.gamesPlayed == 1), isTrue);
      expect(result.bySeat.where((s) => s.gamesWon == 1), hasLength(1));
      expect(result.bySeat.fold<int>(0, (a, s) => a + s.gamesLost), 2);
    });

    test('les lancers et les tours des sièges retombent sur ceux du journal', () {
      // Attendus lus dans le journal lui-même, sans passer par le collecteur :
      // chaque `roll` est un lancer, chaque `bank` ou `endBustedTurn` un tour.
      for (final seed in const [3, 7, 42, 123]) {
        final played = playScriptedGame(setup, seed);
        final actions = played.actions;
        final result = collectGameStatistics(setup: setup, seed: seed, actions: actions);

        final rolls = actions.where((a) => a.type == GameActionType.roll).length;
        final turns = actions
            .where((a) => a.type == GameActionType.bank || a.type == GameActionType.endBustedTurn)
            .length;

        expect(result.bySeat.fold<int>(0, (sum, s) => sum + s.rollsTotal), rolls, reason: 'seed $seed');
        expect(result.bySeat.fold<int>(0, (sum, s) => sum + s.turnsTotal), turns, reason: 'seed $seed');
        expect(result.bySeat.every((s) => s.rollsTotal >= s.turnsTotal), isTrue,
            reason: 'un tour compte au moins un lancer (seed $seed)');
      }
    });

    test('deux calculs de la même partie donnent le même résultat', () {
      final played = playScriptedGame(setup, 7);

      final a = collectGameStatistics(setup: setup, seed: 7, actions: played.actions);
      final b = collectGameStatistics(setup: setup, seed: 7, actions: played.actions);

      expect(
        a.bySeat.map((s) => s.toJson()).toList(),
        b.bySeat.map((s) => s.toJson()).toList(),
        reason: 'un recalcul rétroactif doit être reproductible',
      );
    });

    test('la victoire est attribuée au siège D\'ORIGINE, pas au siège réordonné', () {
      // Le départage réordonne les joueurs : tout ce que le moteur expose est
      // dans ce nouvel ordre, alors que les fiches se rattachent à l'ordre de
      // la config d'origine. Les confondre attribuerait les statistiques au
      // mauvais joueur dans toute partie que le départage a fait tourner.
      var rotationExercised = false;

      for (final seed in const [1, 7, 42, 123, 2024]) {
        final played = playScriptedGame(setup, seed);
        final replay = replayGame(setup, seed, played.actions);
        if (replay.playOrder!.first != 0) rotationExercised = true;

        final result = collectGameStatistics(setup: setup, seed: seed, actions: played.actions);

        final winnerName = played.engine.players[played.engine.winnerIndex!].name;
        final expectedSeat = setup.playerNames.indexOf(winnerName);
        for (var seat = 0; seat < setup.playerNames.length; seat++) {
          expect(result.bySeat[seat].gamesWon, seat == expectedSeat ? 1 : 0,
              reason: 'seed $seed : «$winnerName» occupe le siège d\'origine $expectedSeat');
        }
      }

      expect(rotationExercised, isTrue,
          reason: 'au moins une seed doit faire gagner le départage à un autre que le siège 0, '
              'sans quoi ce test passerait sans jamais exercer la traduction');
    });

    test('la victoire suit son joueur aussi quand le départage inverse le sens', () {
      // Le vainqueur doit en plus occuper un siège que l'inversion déplace
      // (pas le premier) : sinon ce test passerait même sans en tenir compte.
      late int seed;
      late ({GameEngine engine, List<GameAction> actions}) played;
      for (seed = 0; seed < 1000; seed++) {
        played = playScriptedGame(setup, seed);
        final replay = replayGame(setup, seed, played.actions);
        if (replay.diceOff.reversesOrder && played.engine.winnerIndex != 0) break;
      }
      expect(seed, lessThan(1000), reason: 'aucune seed ne produit d\'inversion');

      final result = collectGameStatistics(setup: setup, seed: seed, actions: played.actions);

      final winnerName = played.engine.players[played.engine.winnerIndex!].name;
      final expectedSeat = setup.playerNames.indexOf(winnerName);
      for (var seat = 0; seat < setup.playerNames.length; seat++) {
        expect(result.bySeat[seat].gamesWon, seat == expectedSeat ? 1 : 0,
            reason: 'seed $seed : «$winnerName» occupe le siège d\'origine $expectedSeat');
      }
    });

    test('une partie non terminée ne compte pour rien', () {
      final log = buildResumableActionLog(seed: 5, playerNames: setup.playerNames);

      final result = collectGameStatistics(setup: setup, seed: 5, actions: log.actions);

      expect(result.activeSeconds, 0);
      expect(result.bySeat.every((s) => s.gamesPlayed == 0), isTrue);
      expect(result.bySeat.every((s) => s.brelansTotal == 0), isTrue,
          reason: 'ses figures seraient comptées une seconde fois le jour où elle s\'achève');
    });
  });
}
