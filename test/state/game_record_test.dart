import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_statistics.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/scripted_game.dart';

/// `GameNotifier.gameRecord` : LE point d'entrée qui dit quelle partie est à
/// l'écran, dont dépendent la courbe des scores et les statistiques de fin.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
    ]);
  });

  tearDown(() => container.dispose());

  const setup = GameSetup(playerNames: ['A', 'B']);

  /// Une partie terminée, journal entier compris (départage inclus).
  SavedGame finishedGame(int seed) => SavedGame(
        seed: seed,
        setup: setup,
        alias: 'test',
        createdAt: DateTime(2026, 1, 1),
        actions: playScriptedGame(setup, seed).actions,
      );

  GameRecordingHandoff emptyHandoff() => GameRecordingHandoff(
        seed: 0,
        random: Random(0),
        originalSetup: setup,
        alias: '',
        createdAt: DateTime(2026, 1, 1),
        actions: const [],
      );

  /// Joue une vraie partie à travers le notifier, comme l'écran de jeu, avec
  /// les mêmes décisions simples que `playScriptedGame`, jusqu'à la victoire.
  void playLiveGame(GameNotifier notifier, int seed) {
    final diceOff = playScriptedGame(setup, seed)
        .actions
        .takeWhile((a) => a.type.isDiceOff)
        .toList();
    final replayed = replayGame(setup, seed, diceOff);
    notifier.startGame(
      replayed.orderedSetup!,
      handoff: GameRecordingHandoff(
        seed: seed,
        random: replayed.random,
        originalSetup: setup,
        alias: '',
        createdAt: DateTime(2026, 1, 1),
        actions: diceOff,
      ),
    );
    for (var guard = 0; guard < 4000 && !container.read(gameProvider)!.gameOver; guard++) {
      final engine = container.read(gameProvider)!;
      final turn = engine.activeTurn;
      if (turn == null) {
        notifier.startTurn(useFullHand: true);
      } else if (turn.busted) {
        notifier.endBustedTurn();
      } else if (turn.pendingRoll != null) {
        notifier.applyKeep();
      } else if (!turn.mustContinue &&
          tryBank(turn,
                  minimumRequired: engine.minimumForCurrentPlayer,
                  currentTotal: engine.currentPlayer.totalScore)
              .success) {
        notifier.bank();
      } else {
        notifier.roll();
      }
    }
  }

  test('au moment où la partie se termine, son journal contient déjà son dernier coup', () {
    // L'écran de jeu lit le journal dans un `ref.listen`, c'est-à-dire À
    // L'INSTANT où le moteur devient `gameOver`. Un journal auquel il manque
    // encore le coup qui vient de gagner décrit une partie inachevée : ses
    // statistiques sont alors toutes à zéro, et son rejeu n'arrive jamais à la
    // victoire.
    final notifier = container.read(gameProvider.notifier);
    SavedGame? atGameOver;
    container.listen(gameProvider, (previous, next) {
      if (next != null && next.gameOver) atGameOver = notifier.gameRecord;
    });

    playLiveGame(notifier, 21);

    expect(container.read(gameProvider)!.gameOver, isTrue, reason: 'prémisse : la partie est allée au bout');
    expect(atGameOver, isNotNull);
    expect(atGameOver!.actions, hasLength(notifier.gameRecord!.actions.length),
        reason: 'le dernier coup était déjà journalisé quand la victoire a été annoncée');

    final stats = collectGameStatistics(
      setup: atGameOver!.setup,
      seed: atGameOver!.seed,
      actions: atGameOver!.actions,
    );
    expect(stats.bySeat.fold<int>(0, (sum, p) => sum + p.gamesWon), 1,
        reason: 'une partie terminée a un vainqueur : ses statistiques ne sont pas vides');
    expect(stats.bySeat.fold<int>(0, (sum, p) => sum + p.turnsTotal), greaterThan(0));
  });

  test('un état chargé sans journal (debugLoadState) n\'a pas de journal', () {
    container.read(gameProvider.notifier).debugLoadState(GameEngine.newGame(['A', 'B']), setup);

    expect(container.read(gameProvider.notifier).gameRecord, isNull);
  });

  test('une partie reprise expose son journal entier, départage compris', () {
    final saved = finishedGame(11);
    final notifier = container.read(gameProvider.notifier);

    notifier.resumeFromSave(saved);

    final record = notifier.gameRecord!;
    expect(record.seed, 11);
    expect(record.setup.playerNames, ['A', 'B']);
    expect(record.actions.take(saved.actions.length).map((a) => a.type),
        saved.actions.map((a) => a.type),
        reason: 'le journal commence par le départage, sans quoi la seed ne rejoue rien');
  });

  test('un rejeu expose le run archivé rejoué', () {
    final saved = finishedGame(12);
    final notifier = container.read(gameProvider.notifier);

    notifier.startGameReplay(setup, emptyHandoff(), source: saved);

    expect(notifier.gameRecord, same(saved));
  });

  test('un rejeu ne reprend pas la partie jouée juste avant', () {
    // Régression visée : `seed`/`actions` gardaient la dernière partie jouée de
    // la session. Un rejeu sans source les aurait exposés, et la courbe de fin
    // aurait tracé une autre partie que celle regardée.
    final notifier = container.read(gameProvider.notifier);
    notifier.resumeFromSave(finishedGame(13));
    expect(notifier.gameRecord, isNotNull, reason: 'prémisse : une partie vient d\'être jouée');

    notifier.startGameReplay(setup, emptyHandoff());

    expect(notifier.gameRecord, isNull);
  });

  test('une nouvelle partie remplace le rejeu précédent', () {
    final notifier = container.read(gameProvider.notifier);
    notifier.startGameReplay(setup, emptyHandoff(), source: finishedGame(14));

    notifier.startGame(
      setup,
      handoff: GameRecordingHandoff(
        seed: 15,
        random: Random(15),
        originalSetup: setup,
        alias: 'neuve',
        createdAt: DateTime(2026, 1, 2),
        actions: const [],
      ),
    );

    expect(notifier.gameRecord!.seed, 15, reason: 'la partie jouée, pas le rejeu qui la précédait');
  });

  group('rejeu : navigation par tour', () {
    List<int> scoresOf(GameNotifier n) => n.state!.players.map((p) => p.totalScore).toList();

    /// Ce que la partie jouée a donné, telle que le journal la rejoue d'un coup.
    List<int> playedScores(SavedGame saved) =>
        replayGame(saved.setup, saved.seed, saved.actions).engine!.players.map((p) => p.totalScore).toList();

    void playToEnd(GameNotifier n) {
      while (n.hasNextReplayAction) {
        n.applyNextReplayAction();
      }
    }

    test('le rejeu d\'un run démarre sur la partie, sans passer par le départage', () {
      final saved = finishedGame(21);
      final notifier = container.read(gameProvider.notifier);

      notifier.startReplay(saved);

      expect(notifier.isReplay, isTrue);
      expect(notifier.gameRecord?.seed, 21, reason: 'c\'est ce run-là qui est à l\'écran');
      expect(notifier.state!.gameOver, isFalse);
      expect(notifier.state!.activeTurn, isNull, reason: 'le premier tour n\'est pas encore lancé');
      expect(notifier.orderedSetup!.playerNames, replayGame(saved.setup, saved.seed, saved.actions).orderedSetup!.playerNames,
          reason: 'le vainqueur du départage joue en premier, comme dans la partie');
      expect(notifier.nextReplayAction?.type, GameActionType.startTurn);
    });

    test('la progression compte les tours de la partie et suit le rejeu', () {
      final saved = finishedGame(21);
      final notifier = container.read(gameProvider.notifier);
      notifier.startReplay(saved);

      final count = replayTurnStarts(saved.setup, saved.seed, saved.actions).length;
      expect(notifier.replayProgress.count, count);
      expect(notifier.replayProgress.turn, 1);

      var turns = <int>[1];
      while (notifier.hasNextReplayAction) {
        notifier.applyNextReplayAction();
        final turn = notifier.replayProgress.turn;
        if (turn != turns.last) turns.add(turn);
      }
      expect(turns, List.generate(count, (i) => i + 1), reason: 'un tour après l\'autre, sans en sauter');
      expect(notifier.replayProgress.turn, count);
    });

    test('aller à un tour donne l\'état de la partie à ce moment-là', () {
      final saved = finishedGame(21);
      final starts = replayTurnStarts(saved.setup, saved.seed, saved.actions);
      final notifier = container.read(gameProvider.notifier);
      notifier.startReplay(saved);

      for (final turn in [5, 12, starts.length]) {
        notifier.seekReplay(turn);

        final expected = replayGame(saved.setup, saved.seed, saved.actions.sublist(0, starts[turn - 1])).engine!;
        expect(notifier.replayProgress.turn, turn);
        expect(scoresOf(notifier), expected.players.map((p) => p.totalScore).toList(), reason: 'tour $turn');
        expect(notifier.state!.currentPlayerIndex, expected.currentPlayerIndex, reason: 'tour $turn');
      }
    });

    test('aller à un tour puis laisser jouer mène au même résultat que la partie', () {
      // Le point délicat : le générateur de dés doit reprendre là où le journal
      // l'a laissé. Un générateur neuf ferait tomber d'autres dés, et une
      // partie qui ne finit pas comme celle qu'on regarde.
      final saved = finishedGame(21);
      final played = playedScores(saved);
      final notifier = container.read(gameProvider.notifier);

      for (final turn in [1, 7, 20]) {
        notifier.startReplay(saved);
        notifier.seekReplay(turn);
        playToEnd(notifier);

        expect(notifier.state!.gameOver, isTrue, reason: 'à partir du tour $turn');
        expect(scoresOf(notifier), played, reason: 'à partir du tour $turn');
      }
    });

    test('on peut revenir en arrière', () {
      final saved = finishedGame(21);
      final notifier = container.read(gameProvider.notifier);
      notifier.startReplay(saved);
      notifier.seekReplay(15);
      for (var i = 0; i < 12; i++) {
        notifier.applyNextReplayAction();
      }

      notifier.seekReplay(3);

      expect(notifier.replayProgress.turn, 3);
      playToEnd(notifier);
      expect(scoresOf(notifier), playedScores(saved));
    });

    test('sans run source, il n\'y a ni progression ni navigation', () {
      final saved = finishedGame(21);
      final diceOff = diceOffActionCount(saved.actions);
      final afterDiceOff = replayGame(saved.setup, saved.seed, saved.actions.sublist(0, diceOff));
      final notifier = container.read(gameProvider.notifier);
      notifier.startGameReplay(
        afterDiceOff.orderedSetup!,
        GameRecordingHandoff(
          seed: 0,
          random: afterDiceOff.random,
          originalSetup: saved.setup,
          alias: '',
          createdAt: DateTime(2026, 1, 1),
          actions: saved.actions.sublist(diceOff),
        ),
      );

      expect(notifier.replayProgress.count, 0);
      notifier.seekReplay(5);
      expect(notifier.state!.activeTurn, isNull, reason: 'rien n\'a bougé');
    });
  });
}
