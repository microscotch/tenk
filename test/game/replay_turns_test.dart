import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';

import '../test_helpers/scripted_game.dart';

/// `replayTurnStarts` : où commence chaque tour dans le journal, ce dont le
/// curseur du rejeu se sert pour aller droit à un tour.
void main() {
  const setup = GameSetup(playerNames: ['A', 'B', 'C']);

  List<GameAction> journal(int seed) => playScriptedGame(setup, seed).actions;

  GameEngine engineAfter(int seed, List<GameAction> actions, int consumed) =>
      replayGame(setup, seed, actions.sublist(0, consumed)).engine!;

  test('il y a autant de débuts de tour que de tours joués', () {
    for (final seed in [3, 8, 21, 44]) {
      final actions = journal(seed);
      final turns = actions
          .where((a) => a.type == GameActionType.bank || a.type == GameActionType.endBustedTurn)
          .length;

      final starts = replayTurnStarts(setup, seed, actions);

      expect(starts, hasLength(turns), reason: 'seed $seed : un début par tour, le dernier compris');
    }
  });

  test('les débuts se suivent dans l\'ordre, et chacun est un tour qui n\'a pas commencé', () {
    for (final seed in [3, 8, 21, 44]) {
      final actions = journal(seed);
      final starts = replayTurnStarts(setup, seed, actions);

      expect(starts.first, greaterThanOrEqualTo(diceOffActionCount(actions)));
      for (var i = 1; i < starts.length; i++) {
        expect(starts[i], greaterThan(starts[i - 1]), reason: 'seed $seed, tour ${i + 1}');
      }
      for (var i = 0; i < starts.length; i++) {
        final engine = engineAfter(seed, actions, starts[i]);
        expect(engine.gameOver, isFalse, reason: 'seed $seed, tour ${i + 1}');
        final turn = engine.activeTurn;
        if (turn == null) {
          // Un choix de reprise : la main héritée existe et peut encore banquer.
          expect(engine.nextTurnDice, lessThan(5), reason: 'seed $seed, tour ${i + 1}');
          expect(engine.inheritedHandCannotBank, isFalse, reason: 'seed $seed, tour ${i + 1}');
        } else {
          expect(turn.hasRolledThisTurn, isFalse, reason: 'seed $seed, tour ${i + 1} déjà entamé');
        }
      }
    }
  });

  test('le dernier tour mène à la victoire', () {
    for (final seed in [3, 8, 21]) {
      final actions = journal(seed);
      final starts = replayTurnStarts(setup, seed, actions);

      expect(replayGame(setup, seed, actions).engine!.gameOver, isTrue);
      expect(engineAfter(seed, actions, starts.last).gameOver, isFalse);
    }
  });

  test('une reprise glissée dans le journal ne déplace aucun tour', () {
    final seed = 21;
    final actions = journal(seed);
    final base = replayTurnStarts(setup, seed, actions);

    // Une reprise juste avant la partie, une autre au beau milieu.
    final split = diceOffActionCount(actions);
    final middle = base[base.length ~/ 2] + 1;
    final withResumes = [
      ...actions.sublist(0, split),
      GameAction.resume(),
      ...actions.sublist(split, middle),
      GameAction.resume(),
      ...actions.sublist(middle),
    ];

    final shifted = replayTurnStarts(setup, seed, withResumes);

    expect(shifted, hasLength(base.length));
    for (var i = 0; i < base.length; i++) {
      final resumesBefore = (base[i] >= split ? 1 : 0) + (base[i] >= middle ? 1 : 0);
      expect(shifted[i], base[i] + resumesBefore, reason: 'tour ${i + 1}');
    }
  });
}
