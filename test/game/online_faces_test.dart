import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/dice_off.dart';
import 'package:le10000/game/dice_roll.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';

import '../test_helpers/scripted_game.dart';

/// Ce que fait un serveur en ligne : rejoue le journal d'une partie contre le
/// vrai générateur (seed) mais y écrit, sur chaque lancer, les faces obtenues.
List<GameAction> journalWithFaces(GameSetup setup, int seed, List<GameAction> actions) {
  final recorder = RecordingRandom(Random(seed));
  var diceOff = DiceOffState.start(setup.playerNames.length);
  GameEngine? engine;
  final out = <GameAction>[];
  for (final action in actions) {
    recorder.clear();
    switch (action.type) {
      case GameActionType.diceOffRollAll:
        diceOff = diceOff.rollAll(random: recorder);
        out.add(GameAction.diceOffRollAll(faces: recorder.faces, at: action.at));
      case GameActionType.diceOffResolveRound:
        diceOff = diceOff.resolveRound();
        if (diceOff.isResolved) {
          engine = GameEngine.newGame(setup.reordered(diceOff.playOrder).playerNames);
        }
        out.add(action);
      case GameActionType.roll:
        engine = engine!.roll(random: recorder);
        out.add(GameAction.roll(faces: recorder.faces, at: action.at));
      default:
        engine = applyGameAction(engine!, action, recorder);
        out.add(action);
    }
  }
  return out;
}

void main() {
  const setup = GameSetup(playerNames: ['Anna', 'Bob', 'Chloé', 'Dan']);

  test('le journal avec faces rejoue la même partie sans connaître la seed', () {
    const seed = 424242;
    final played = playScriptedGame(setup, seed);
    final withFaces = journalWithFaces(setup, seed, played.actions);

    expect(withFaces.where((a) => a.type == GameActionType.roll).every((a) => a.faces != null), isTrue);

    // Une seed sans rapport : si un lancer consommait le générateur au lieu des
    // faces, l'état divergerait.
    final replay = replayGame(setup, 999, withFaces);

    expect(replay.engine!.gameOver, isTrue);
    expect(replay.engine!.winnerIndex, played.engine.winnerIndex);
    for (var i = 0; i < setup.playerNames.length; i++) {
      expect(replay.engine!.players[i].totalScore, played.engine.players[i].totalScore, reason: 'joueur $i');
    }
  });

  test('un journal sans faces (parties locales) se rejoue comme avant', () {
    final played = playScriptedGame(setup, 7);
    final replay = replayGame(setup, 7, played.actions);
    expect(replay.engine!.winnerIndex, played.engine.winnerIndex);
    expect(played.actions.any((a) => a.faces != null), isFalse);
  });

  test('les faces survivent au passage par JSON', () {
    final action = GameAction.roll(faces: [1, 5, 6]);
    expect(GameAction.fromJson(action.toJson()).faces, [1, 5, 6]);
    expect(GameAction.fromJson(GameAction.roll().toJson()).faces, isNull);
  });

  test('des faces qui ne collent pas à l\'état sont un désaccord signalé, pas absorbé', () {
    final engine = GameEngine.newGame(['A', 'B']).startTurn(); // 5 dés à lancer
    expect(() => rollFor(engine, GameAction.roll(faces: [1, 2]), Random(1)), throwsStateError, reason: 'trop peu');
    expect(
      () => rollFor(engine, GameAction.roll(faces: [1, 2, 3, 4, 5, 6]), Random(1)),
      throwsStateError,
      reason: 'trop de faces',
    );
  });

  group('RecordingRandom / ScriptedRandom', () {
    test('RecordingRandom mémorise les faces (1 à 6) dans l\'ordre et se vide', () {
      final rec = RecordingRandom(Random(3));
      final rolled = rollDice(5, rec);
      expect(rec.faces, rolled);
      rec.clear();
      expect(rec.faces, isEmpty);
    });

    test('ScriptedRandom rend exactement les faces données', () {
      expect(rollDice(3, ScriptedRandom([6, 1, 4])), [6, 1, 4]);
    });

    test('ScriptedRandom refuse une face hors de 1 à 6', () {
      expect(() => ScriptedRandom([0]), throwsArgumentError);
      expect(() => ScriptedRandom([7]), throwsArgumentError);
    });
  });
}
