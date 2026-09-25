import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/state/dice_off_providers.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/scripted_game.dart';

/// Une partie peut être mise en pause avant son premier lancer : pendant le
/// départage (qui sauvegarde dès son premier round), ou sur son résultat,
/// avant « Commencer la partie ». Sa reprise doit rester jouable.
void main() {
  const setup = GameSetup(playerNames: ['Anna', 'Bob', 'Chloé']);

  ProviderContainer newContainer() {
    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  SavedGame save(int seed, List<GameAction> actions) =>
      SavedGame(seed: seed, setup: setup, alias: 'Pause', createdAt: DateTime(2026), actions: actions);

  /// La première seed dont le départage demande au moins deux rounds.
  int seedWithTie() {
    for (var seed = 0;; seed++) {
      if (playDiceOff(3, Random(seed), []).roundHistory.length >= 2) return seed;
    }
  }

  test('départage tranché mais premier tour jamais lancé : la reprise le démarre', () {
    final container = newContainer();
    final actions = <GameAction>[];
    playDiceOff(3, Random(4), actions);

    container.read(gameProvider.notifier).resumeFromSave(save(4, actions));

    final engine = container.read(gameProvider)!;
    expect(engine.activeTurn, isNotNull, reason: 'sinon aucun bouton : rien ne lancerait ce tour');
    expect(engine.activeTurn!.diceToRoll, 5);
    final journal = container.read(gameProvider.notifier).gameRecord!.actions;
    expect(journal.skip(actions.length).map((a) => a.type), [GameActionType.resume, GameActionType.startTurn]);
    expect(replayGame(setup, 4, journal).engine!.activeTurn, isNotNull, reason: 'le journal le rejoue à l\'identique');
  });

  test('un départage se dit inachevé tant qu\'il n\'est pas tranché', () {
    final seed = seedWithTie();
    final full = <GameAction>[];
    playDiceOff(3, Random(seed), full);

    expect(DiceOffNotifier.isUnfinished(save(seed, const [])), isTrue, reason: 'aucun round joué');
    expect(DiceOffNotifier.isUnfinished(save(seed, full.sublist(0, 2))), isTrue, reason: 'une égalité à départager');
    expect(DiceOffNotifier.isUnfinished(save(seed, full)), isFalse);
  });

  test('un départage interrompu reprend là où il était, sur le même tirage', () {
    final seed = seedWithTie();
    final full = <GameAction>[];
    final uninterrupted = playDiceOff(3, Random(seed), full);

    final container = newContainer();
    final notifier = container.read(diceOffProvider.notifier);
    notifier.resumeFromSave(save(seed, full.sublist(0, 2)));
    expect(container.read(diceOffProvider)!.roundHistory, hasLength(1), reason: 'le premier round est retrouvé');

    while (!container.read(diceOffProvider)!.isResolved) {
      notifier.rollRound();
    }

    final resumed = container.read(diceOffProvider)!;
    expect(resumed.roundHistory, uninterrupted.roundHistory, reason: 'mêmes dés : même générateur, repris');
    expect(resumed.playOrder, uninterrupted.playOrder);
    final journal = notifier.handoff().actions.where((a) => a.type != GameActionType.resume);
    expect(journal.map((a) => a.type), full.map((a) => a.type));
    expect(notifier.handoff().alias, 'Pause', reason: 'la même partie, pas une nouvelle');
  });

  test('un round d\'une ancienne version, lancé à moitié, se finit un joueur à la fois', () {
    final legacy = <GameAction>[];
    final expected = playDiceOff(3, Random(9), legacy, legacy: true);

    final container = newContainer();
    final notifier = container.read(diceOffProvider.notifier);
    // Seul le premier joueur avait lancé son dé.
    notifier.resumeFromSave(save(9, legacy.sublist(0, 1)));
    notifier.rollRound();

    final afterFirstRound = container.read(diceOffProvider)!;
    expect(afterFirstRound.roundHistory.first, expected.roundHistory.first, reason: 'mêmes dés, même ordre de tirage');
    expect(
      notifier.handoff().actions.skip(2).take(2).map((a) => a.type),
      [GameActionType.diceOffRoll, GameActionType.diceOffRoll],
      reason: 'le round se finit au format qui l\'a commencé',
    );

    while (!container.read(diceOffProvider)!.isResolved) {
      notifier.rollRound();
    }
    final replayed = replayGame(setup, 9, notifier.handoff().actions).diceOff;
    expect(replayed.roundHistory, container.read(diceOffProvider)!.roundHistory, reason: 'journal rejouable');
    expect(replayed.isResolved, isTrue);
  });
}
