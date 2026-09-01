import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/state/game_save_store.dart';

void main() {
  late Directory tempDir;
  late GameSaveStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tenk_save_store_test_');
    store = GameSaveStore(rootDirectory: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  SavedGame sampleGame(int seed, {String alias = 'Alias Test', DateTime? createdAt}) {
    return SavedGame(
      seed: seed,
      setup: const GameSetup(playerNames: ['A', 'B']),
      alias: alias,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      actions: [GameAction.diceOffRoll(0, at: DateTime(2026, 1, 1, 0, 0, 1))],
    );
  }

  test('write puis read retrouve exactement la même partie', () async {
    await store.write(sampleGame(42));
    final read = await store.read(42);

    expect(read, isNotNull);
    expect(read!.seed, 42);
    expect(read.alias, 'Alias Test');
    expect(read.setup.playerNames, ['A', 'B']);
    expect(read.actions, hasLength(1));
    expect(read.actions.single.type, GameActionType.diceOffRoll);
  });

  test('read sur une seed inconnue renvoie null', () async {
    expect(await store.read(999), isNull);
  });

  test('exists reflète la présence du fichier', () async {
    expect(await store.exists(7), isFalse);
    await store.write(sampleGame(7));
    expect(await store.exists(7), isTrue);
  });

  test('delete supprime le fichier', () async {
    await store.write(sampleGame(7));
    await store.delete(7);
    expect(await store.exists(7), isFalse);
    expect(await store.read(7), isNull);
  });

  test('delete sur une seed inexistante ne plante pas', () async {
    await store.delete(123456);
  });

  test('list trie par date de dernière modification décroissante', () async {
    await store.write(sampleGame(1, alias: 'Premier'));
    // Un écart artificiel garantit un mtime strictement postérieur (le
    // système de fichiers peut avoir une résolution grossière).
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await store.write(sampleGame(2, alias: 'Deuxième'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await store.write(sampleGame(3, alias: 'Troisième'));

    final games = await store.list();
    expect(games.map((g) => g.alias).toList(), ['Troisième', 'Deuxième', 'Premier']);
  });

  test('list ignore un fichier corrompu sans planter', () async {
    await store.write(sampleGame(1));
    final corrupt = File('${tempDir.path}/game-999.run');
    await corrupt.writeAsString('{ceci n\'est pas du json valide');

    final games = await store.list();
    expect(games.map((g) => g.seed).toList(), [1]);
  });

  test('list sur un dossier vide (jamais créé) renvoie une liste vide', () async {
    final freshDir = Directory('${tempDir.path}/nested/not-yet-created');
    final freshStore = GameSaveStore(rootDirectory: () async => freshDir);
    expect(await freshStore.list(), isEmpty);
  });
}
