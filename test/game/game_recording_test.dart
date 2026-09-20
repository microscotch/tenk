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
}
