import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_statistics.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

void main() {
  late FakeGameSaveStore archive;
  late FakePlayerStore players;

  setUp(() {
    archive = FakeGameSaveStore();
    players = FakePlayerStore();
  });

  /// Une partie terminée, archivée telle qu'elle le serait en vrai.
  Future<SavedGame> archiveFinishedGame({
    required int seed,
    required GameSetup setup,
  }) async {
    final played = playScriptedGame(setup, seed);
    final game = SavedGame(
      seed: seed,
      setup: setup,
      alias: 'Partie $seed',
      createdAt: DateTime(2026, 1, 1),
      actions: played.actions,
    );
    await archive.write(game);
    return game;
  }

  group('amorçage', () {
    test('crée une fiche par nom humain distinct trouvé dans les archives', () async {
      const setup = GameSetup(playerNames: ['Alice', 'Bruno']);
      await archiveFinishedGame(seed: 1, setup: setup);
      await archiveFinishedGame(seed: 2, setup: setup);

      final created = await syncPlayerStatistics(archive: archive, players: players);

      expect(created, 2, reason: 'Alice et Bruno, une seule fois chacun');
      expect((await players.list()).map((p) => p.name), ['Alice', 'Bruno']);
    });

    test('les noms d\'IA ne créent aucune fiche', () async {
      await archiveFinishedGame(
        seed: 3,
        setup: const GameSetup(playerNames: ['Alice', 'HAL'], aiPlayers: {1: AiDifficulty.prudent}),
      );

      await syncPlayerStatistics(archive: archive, players: players);

      expect((await players.list()).map((p) => p.name), ['Alice'],
          reason: 'la base ne contient que des humains');
    });

    test('un second passage ne recrée rien', () async {
      await archiveFinishedGame(seed: 1, setup: const GameSetup(playerNames: ['Alice', 'Bruno']));

      await syncPlayerStatistics(archive: archive, players: players);
      final created = await syncPlayerStatistics(archive: archive, players: players);

      expect(created, 0);
      expect(await players.list(), hasLength(2));
    });
  });

  group('recalcul', () {
    test('attribue des statistiques rétroactives aux fiches créées', () async {
      await archiveFinishedGame(seed: 42, setup: const GameSetup(playerNames: ['Alice', 'Bruno']));

      await syncPlayerStatistics(archive: archive, players: players);

      final list = await players.list();
      expect(list.every((p) => p.stats.gamesPlayed == 1), isTrue);
      expect(list.where((p) => p.stats.gamesWon == 1), hasLength(1),
          reason: 'une partie, un vainqueur');
    });

    test('recalculer deux fois donne exactement le même résultat', () async {
      await archiveFinishedGame(seed: 42, setup: const GameSetup(playerNames: ['Alice', 'Bruno']));
      await archiveFinishedGame(seed: 7, setup: const GameSetup(playerNames: ['Alice', 'Bruno']));

      await syncPlayerStatistics(archive: archive, players: players);
      final once = {for (final p in await players.list()) p.name: p.stats.toJson()};
      await syncPlayerStatistics(archive: archive, players: players);
      final twice = {for (final p in await players.list()) p.name: p.stats.toJson()};

      expect(twice, once,
          reason: 'le recalcul remplace au lieu d\'additionner : c\'est ce qui le rend idempotent');
      expect((await players.list()).first.stats.gamesPlayed, 2);
    });

    test('une partie non terminée ne compte pas', () async {
      const setup = GameSetup(playerNames: ['Alice', 'Bruno']);
      await archive.write(buildResumableSavedGame(seed: 9, alias: 'En cours', playerNames: setup.playerNames));

      await syncPlayerStatistics(archive: archive, players: players);

      expect((await players.list()).every((p) => p.stats.gamesPlayed == 0), isTrue);
    });

    test('le rattachement suit l\'identifiant quand il existe', () async {
      final alice = PlayerProfile.create(name: 'Alice');
      await players.write(alice);
      // Le nom enregistré dans la partie ne correspond plus à la fiche : seul
      // l'identifiant les relie.
      await archiveFinishedGame(
        seed: 42,
        setup: GameSetup(playerNames: const ['Autre orthographe', 'Bruno'], playerIds: {0: alice.id}),
      );

      await syncPlayerStatistics(archive: archive, players: players);

      final reloaded = await players.read(alice.id);
      expect(reloaded!.stats.gamesPlayed, 1, reason: 'l\'identifiant prime sur le nom');
    });

    test('un ancien nom retrouve la fiche après un renommage', () async {
      await archiveFinishedGame(seed: 42, setup: const GameSetup(playerNames: ['Alice', 'Bruno']));
      await syncPlayerStatistics(archive: archive, players: players);

      final alice = (await players.list()).firstWhere((p) => p.name == 'Alice');
      await players.write(alice.renamedTo('Alice Dupont'));

      await syncPlayerStatistics(archive: archive, players: players);

      final reloaded = await players.read(alice.id);
      expect(reloaded!.name, 'Alice Dupont');
      expect(reloaded.stats.gamesPlayed, 1,
          reason: 'sans les anciens noms, le renommage effacerait tout son historique');
    });

    test('une partie au journal incohérent est sautée sans tout vider', () async {
      await archiveFinishedGame(seed: 42, setup: const GameSetup(playerNames: ['Alice', 'Bruno']));
      // Journal impossible : des actions de partie sans départage résolu.
      await archive.write(SavedGame(
        seed: 99,
        setup: const GameSetup(playerNames: ['Alice', 'Bruno']),
        alias: 'Corrompue',
        createdAt: DateTime(2026, 1, 1),
        actions: [GameAction.roll(at: DateTime(2026, 1, 1))],
      ));

      await syncPlayerStatistics(archive: archive, players: players);

      expect((await players.list()).first.stats.gamesPlayed, 1,
          reason: 'la partie saine compte toujours');
    });
  });
}
