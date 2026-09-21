import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
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
}
