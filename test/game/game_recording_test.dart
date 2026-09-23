import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';

import '../test_helpers/scripted_game.dart';

void main() {
  test('rejouer le journal depuis la seed reproduit exactement le même état final', () {
    const seed = 20260901;
    const setup = GameSetup(playerNames: ['A', 'B', 'C']);

    final played = playScriptedGame(setup, seed);
    final replay = replayGame(setup, seed, played.actions);

    expect(replay.engine, isNotNull);
    final live = played.engine;
    final replayedEngine = replay.engine!;

    expect(replayedEngine.gameOver, live.gameOver);
    expect(replayedEngine.winnerIndex, live.winnerIndex);
    expect(replayedEngine.currentPlayerIndex, live.currentPlayerIndex);
    expect(replayedEngine.players.length, live.players.length);

    for (var i = 0; i < live.players.length; i++) {
      expect(replayedEngine.players[i].name, live.players[i].name, reason: 'nom joueur $i');
      expect(replayedEngine.players[i].totalScore, live.players[i].totalScore, reason: 'score joueur $i');
      expect(replayedEngine.players[i].hasEntered, live.players[i].hasEntered, reason: 'hasEntered joueur $i');
      expect(
        replayedEngine.players[i].grid.map((e) => (e.value, e.hasTiret, e.isBarred)).toList(),
        live.players[i].grid.map((e) => (e.value, e.hasTiret, e.isBarred)).toList(),
        reason: 'grille joueur $i',
      );
    }
  });

  test('deux seeds différentes produisent des tirages différents (le test précédent teste bien quelque chose)', () {
    const setup = GameSetup(playerNames: ['A', 'B']);
    final a = playScriptedGame(setup, 111).engine;
    final b = playScriptedGame(setup, 222).engine;

    // Pas garanti à 100% en théorie (deux seeds pourraient coïncidentellement
    // produire la même issue), mais extrêmement improbable sur une partie
    // complète : sert surtout à détecter une seed ignorée par erreur (auquel
    // cas les deux résultats seraient toujours strictement identiques).
    final samePlayerScores = List.generate(setup.playerNames.length, (i) => a.players[i].totalScore).toString() ==
        List.generate(setup.playerNames.length, (i) => b.players[i].totalScore).toString();
    expect(samePlayerScores, isFalse);
  });

  test(
      'reprendre une partie à mi-chemin (journal partiel) puis continuer avec le Random du rejeu '
      "ne répète jamais un tirage déjà consommé par le rejeu", () {
    const seed = 20260901;
    const setup = GameSetup(playerNames: ['A', 'B']);

    // Journal complet d'une partie de référence, pour en extraire un
    // journal PARTIEL représentatif d'une sauvegarde en cours de tour.
    final full = playScriptedGame(setup, seed).actions;
    final cut = full.length ~/ 2;
    final partialActions = full.sublist(0, cut);

    final replay = replayGame(setup, seed, partialActions);
    expect(replay.engine, isNotNull, reason: 'le découpage doit tomber après la résolution du départage');

    // Ce que ferait GameNotifier après reprise : continuer à consommer
    // replay.random (pas un Random(seed) frais) pour les lancers suivants.
    final continued = List.generate(8, (_) => replay.random.nextInt(6));

    // Un Random(seed) frais reproduirait exactement le tout début de la
    // seed : si la reprise utilisait par erreur un Random(seed) neuf plutôt
    // que replay.random, cette séquence serait identique (probabilité de
    // coïncidence sur 8 valeurs : 6⁻⁸, négligeable).
    final fresh = Random(seed);
    final freshSequence = List.generate(8, (_) => fresh.nextInt(6));
    expect(continued, isNot(equals(freshSequence)));
  });

  group('durée active', () {
    GameAction at(int minutesFromStart) =>
        GameAction.roll(at: DateTime(2026, 1, 1, 12, minutesFromStart));

    test('plafonne chaque écart à deux minutes', () {
      // Trois écarts : 1 min, 30 min (une pause), 2 min.
      final actions = [at(0), at(1), at(31), at(33)];

      expect(durationSecondsFor(actions), 33 * 60, reason: 'le calcul historique compte tout');
      expect(activePlayingSecondsFor(actions), 60 + 120 + 120,
          reason: 'la pause de 30 min est ramenée au plafond');
    });

    test('un écart plus court que le plafond est compté tel quel', () {
      final actions = [at(0), at(1), at(2)];

      expect(activePlayingSecondsFor(actions), 120);
      expect(activePlayingSecondsFor(actions), durationSecondsFor(actions),
          reason: 'sans pause, les deux calculs coïncident');
    });

    test('le plafond est réglable', () {
      final actions = [at(0), at(10)];

      expect(activePlayingSecondsFor(actions, maxGap: const Duration(minutes: 5)), 5 * 60);
    });

    test('un journal vide ou à une seule action dure zéro', () {
      expect(activePlayingSecondsFor(const []), 0);
      expect(activePlayingSecondsFor([at(0)]), 0);
    });

    test('l\'écart qui précède une reprise ne compte pas du tout', () {
      // 30 min hors du jeu, puis la reprise, puis 1 min de jeu.
      final actions = [
        at(0),
        GameAction.resume(at: DateTime(2026, 1, 1, 12, 30)),
        at(31),
      ];

      expect(activePlayingSecondsFor(actions), 60,
          reason: 'le marqueur dit précisément que la partie était fermée');
      expect(durationSecondsFor(actions), 31 * 60);
    });

    test('durationSecondsFor garde son comportement d\'origine', () {
      final actions = [at(0), at(1), at(31)];

      expect(durationSecondsFor(actions), 31 * 60,
          reason: 'la durée persistée dans les sauvegardes ne change pas de sens');
    });
  });

  group('marqueur de reprise', () {
    const setup = GameSetup(playerNames: ['A', 'B']);

    test('ne modifie pas l\'état rejoué', () {
      final played = playScriptedGame(setup, 42);
      final withResume = [...played.actions]..insert(
          played.actions.length ~/ 2,
          GameAction.resume(),
        );

      final plain = replayGame(setup, 42, played.actions);
      final resumed = replayGame(setup, 42, withResume);

      expect(resumed.engine!.gameOver, plain.engine!.gameOver);
      expect(resumed.engine!.winnerIndex, plain.engine!.winnerIndex);
      expect(
        resumed.engine!.players.map((p) => p.totalScore),
        plain.engine!.players.map((p) => p.totalScore),
        reason: 'une reprise ne consomme aucun tirage : le flux de dés est intact',
      );
    });

    test('n\'est pas transmise à onGameAction', () {
      final played = playScriptedGame(setup, 42);
      final withResume = [...played.actions]..insert(2, GameAction.resume());

      final seen = <GameActionType>[];
      replayGame(setup, 42, withResume, onGameAction: (_, _, action) => seen.add(action.type));

      expect(seen, isNot(contains(GameActionType.resume)),
          reason: 'une reprise n\'est pas un coup : aucun consommateur ne doit la voir');
    });
  });

  group('ordre de jeu tranché par le départage', () {
    const setup = GameSetup(playerNames: ['J1', 'J2', 'J3', 'J4', 'J5']);

    /// La première seed dont le départage, joué au format actuel, finit en
    /// duel entre voisins gagné par le second.
    int reversingSeed() {
      for (var seed = 0; seed < 1000; seed++) {
        if (playDiceOff(5, Random(seed), []).reversesOrder) return seed;
      }
      fail('aucune seed ne produit d\'inversion');
    }

    test('un journal au format actuel rejoue l\'ordre inversé', () {
      final seed = reversingSeed();
      final actions = <GameAction>[];
      final played = playDiceOff(5, Random(seed), actions);

      final replay = replayGame(setup, seed, actions);

      expect(replay.playOrder, played.playOrder);
      expect(replay.orderedSetup!.playerNames, [for (final i in played.playOrder) setup.playerNames[i]]);
      expect(replay.orderedSetup!.playerNames[1], setup.playerNames[played.playOrder[1]]);
      expect((played.playOrder[0] - played.playOrder[1]) % 5, 1, reason: 'le second joueur est le voisin d\'avant');
    });

    test('un ancien journal (un joueur à la fois) garde sa rotation, même tirage à l\'appui', () {
      // Même seed, donc mêmes dés et même duel final : seule la forme du
      // journal diffère. Un ancien journal inversé à son rejeu changerait en
      // silence qui occupe quel siège, et fausserait les statistiques.
      final seed = reversingSeed();
      final legacy = <GameAction>[];
      final played = playDiceOff(5, Random(seed), legacy, legacy: true);

      final replay = replayGame(setup, seed, legacy);

      final w = played.winnerIndex!;
      expect(replay.playOrder, [for (var k = 0; k < 5; k++) (w + k) % 5]);
      expect(legacy.map((a) => a.type), isNot(contains(GameActionType.diceOffRollAll)));
    });

    test('les deux formats tirent les mêmes dés : la partie qui suit est identique', () {
      final seed = reversingSeed();
      final current = playDiceOff(5, Random(seed), []);
      final legacy = playDiceOff(5, Random(seed), [], legacy: true);

      expect(current.roundHistory, legacy.roundHistory);
    });
  });
}
