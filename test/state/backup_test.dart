import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/state/backup_archive.dart';
import 'package:le10000/state/backup_service.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Peu d'itérations : la dérivation de production (600 000) prend plusieurs
/// secondes, et ce qu'on vérifie ici n'en dépend pas.
const _iterations = 1000;
const _password = 'correct horse battery';

void main() {
  SavedGame game(int seed, {String alias = 'Partie'}) => SavedGame(
        seed: seed,
        setup: const GameSetup(playerNames: ['A', 'B']),
        alias: alias,
        createdAt: DateTime(2026, 1, 1),
        actions: [GameAction.diceOffRoll(0, at: DateTime(2026, 1, 1, 0, 0, 1))],
      );

  String gameJson(int seed, {String alias = 'Partie'}) => jsonEncode(game(seed, alias: alias).toJson());
  String playerJson(PlayerProfile p) => jsonEncode(p.toJson());

  group('enveloppe', () {
    final archive = BackupArchive(
      createdAt: DateTime.utc(2026, 10, 31, 12),
      settings: {
        'settings.theme': 'dark',
        'settings.count': 3,
        'settings.ratio': 0.5,
        'settings.on': true,
        'settings.list': ['a', 'b'],
      },
      players: {'player-abc.json': '{"p":1}'},
      paused: {'game-1.run': '{"g":1}'},
      finished: {'game-2.run': '{"g":2}'},
    );

    test('chiffre puis déchiffre, sans rien perdre', () async {
      final bytes = await BackupEnvelope.seal(archive, _password, iterations: _iterations);
      final back = await BackupEnvelope.open(bytes, _password);
      expect(back.createdAt, archive.createdAt);
      expect(back.settings, archive.settings);
      expect(back.players, archive.players);
      expect(back.paused, archive.paused);
      expect(back.finished, archive.finished);
    });

    test('le contenu n\'apparaît pas en clair', () async {
      final bytes = await BackupEnvelope.seal(archive, _password, iterations: _iterations);
      expect(latin1.decode(bytes), isNot(contains('settings.theme')));
      expect(latin1.decode(bytes), isNot(contains('game-1.run')));
    });

    test('deux exports du même contenu diffèrent (sel et nonce neufs)', () async {
      final a = await BackupEnvelope.seal(archive, _password, iterations: _iterations);
      final b = await BackupEnvelope.seal(archive, _password, iterations: _iterations);
      expect(a, isNot(equals(b)));
    });

    test('un mauvais mot de passe est refusé', () async {
      final bytes = await BackupEnvelope.seal(archive, _password, iterations: _iterations);
      await expectLater(
        BackupEnvelope.open(bytes, 'un autre mot de passe'),
        throwsA(isA<BackupException>().having((e) => e.failure, 'failure', BackupFailure.wrongPassword)),
      );
    });

    test('un octet modifié, dans le corps comme dans l\'en-tête, est détecté', () async {
      final bytes = await BackupEnvelope.seal(archive, _password, iterations: _iterations);
      for (final index in [bytes.length - 20, 20, 10]) {
        final tampered = Uint8List.fromList(bytes)..[index] ^= 0x01;
        await expectLater(
          BackupEnvelope.open(tampered, _password),
          throwsA(isA<BackupException>()),
          reason: 'octet $index',
        );
      }
    });

    test('un fichier tronqué, ou qui n\'est pas une sauvegarde, est refusé avant tout calcul', () async {
      final bytes = await BackupEnvelope.seal(archive, _password, iterations: _iterations);
      for (final bad in [
        Uint8List(0),
        Uint8List.fromList(utf8.encode('{"json":"quelconque"}' * 5)),
        Uint8List.sublistView(bytes, 0, 20),
      ]) {
        expect(
          () => BackupEnvelope.check(bad),
          throwsA(isA<BackupException>().having((e) => e.failure, 'failure', BackupFailure.notABackup)),
        );
      }
    });

    test('une version plus récente est reconnue comme telle', () async {
      final bytes = Uint8List.fromList(await BackupEnvelope.seal(archive, _password, iterations: _iterations))..[7] = 2;
      expect(
        () => BackupEnvelope.check(bytes),
        throwsA(isA<BackupException>().having((e) => e.failure, 'failure', BackupFailure.unsupportedVersion)),
      );
    });

    test('un nombre d\'itérations démesuré ou nul est refusé (pas de gel de l\'app)', () async {
      final bytes = await BackupEnvelope.seal(archive, _password, iterations: _iterations);
      final huge = Uint8List.fromList(bytes)..setRange(8, 12, [0x7f, 0xff, 0xff, 0xff]);
      final zero = Uint8List.fromList(bytes)..setRange(8, 12, [0, 0, 0, 0]);
      for (final bad in [huge, zero]) {
        expect(() => BackupEnvelope.check(bad), throwsA(isA<BackupException>()));
      }
    });

    test('à la lecture, un nom de fichier hors des formes de l\'app ou une clef hors réglages est écarté', () async {
      final hostile = BackupArchive(
        createdAt: DateTime.utc(2026),
        settings: {'settings.ok': 1, 'online.token': 'secret', 'autre': 'x'},
        players: {'../player-x.json': '{}', 'player-ok.json': '{}', 'player-.json': '{}'},
        paused: {'../../etc/game-1.run': '{}', 'game-1.run': '{}', 'game-x.run': '{}'},
        finished: {'game-2.run.tmp': '{}', 'game-2.run': '{}'},
      );
      final back = await BackupEnvelope.open(
        await BackupEnvelope.seal(hostile, _password, iterations: _iterations),
        _password,
      );
      expect(back.settings.keys, ['settings.ok']);
      expect(back.players.keys, ['player-ok.json']);
      expect(back.paused.keys, ['game-1.run']);
      expect(back.finished.keys, ['game-2.run']);
    });
  });

  group('service', () {
    late Directory root;

    /// Un téléphone : ses trois dossiers, comme l'app les crée.
    ({BackupService service, GameSaveStore paused, GameSaveStore finished, PlayerStore players}) phone(String name) {
      Future<Directory> dir(String sub) async => Directory('${root.path}/$name/$sub');
      final paused = GameSaveStore(rootDirectory: () => dir('in-progress'));
      final finished = GameSaveStore(rootDirectory: () => dir('over'));
      final players = PlayerStore(rootDirectory: () => dir('players'));
      return (
        service: BackupService(paused: paused, finished: finished, players: players),
        paused: paused,
        finished: finished,
        players: players,
      );
    }

    setUp(() async {
      root = await Directory.systemTemp.createTemp('tenk_backup_test_');
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('collecte les réglages « settings. » et rien d\'autre, et ignore un fichier corrompu', () async {
      SharedPreferences.setMockInitialValues({
        'settings.themeChoice': 'dark',
        'settings.autoDelayMs': 2000,
        'online.token': 'jeton-secret',
        'online.code': 'ABCD',
        'update.dismissed': 12,
      });
      final a = phone('a');
      await a.paused.write(game(1));
      await a.finished.write(game(2));
      await a.players.write(PlayerProfile.create(name: 'Anna'));
      File('${(await a.paused.directory()).path}/game-3.run').writeAsStringSync('pas du json');

      final archive = await a.service.collect();
      expect(archive.settings, {'settings.themeChoice': 'dark', 'settings.autoDelayMs': 2000});
      expect(archive.paused.keys, ['game-1.run']);
      expect(archive.finished.keys, ['game-2.run']);
      expect(archive.players, hasLength(1));

      final bytes = await a.service.export(_password, iterations: _iterations);
      expect(latin1.decode(bytes), isNot(contains('jeton-secret')));
      final opened = await a.service.open(bytes, _password);
      expect(opened.settings.keys, isNot(contains('online.token')));
    });

    test('un mot de passe trop court est refusé à l\'export', () async {
      expect(() => phone('a').service.export('court', iterations: _iterations), throwsArgumentError);
    });

    test('remplacer : le téléphone prend exactement l\'état de l\'export', () async {
      SharedPreferences.setMockInitialValues({'settings.themeChoice': 'dark', 'online.token': 'a'});
      final a = phone('a');
      await a.paused.write(game(1, alias: 'En pause'));
      await a.finished.write(game(2, alias: 'Finie'));
      final anna = PlayerProfile.create(name: 'Anna');
      await a.players.write(anna);
      final bytes = await a.service.export(_password, iterations: _iterations);

      // Un autre téléphone, avec ses propres données et ses propres réglages.
      SharedPreferences.setMockInitialValues({
        'settings.themeChoice': 'light',
        'settings.musicEnabled': true,
        'online.token': 'celui-de-b',
      });
      final b = phone('b');
      await b.paused.write(game(10));
      await b.finished.write(game(20));
      await b.players.write(PlayerProfile.create(name: 'Bob'));

      final result = await b.service.restore(await b.service.open(bytes, _password), BackupImportMode.replace);
      expect(result.games, 2);
      expect(result.profiles, 1);
      expect(result.skipped, 0);

      expect((await b.paused.list()).map((g) => g.seed), [1]);
      expect((await b.finished.list()).map((g) => g.seed), [2]);
      expect((await b.players.list()).map((p) => p.id), [anna.id]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.themeChoice'), 'dark');
      expect(prefs.containsKey('settings.musicEnabled'), isFalse, reason: 'un réglage absent du fichier disparaît');
      expect(prefs.getString('online.token'), 'celui-de-b', reason: 'le jeton en ligne n\'est jamais touché');
      final siblings = root.listSync().whereType<Directory>().expand((d) => d.listSync()).map((e) => e.path.split('/').last);
      expect(siblings, everyElement(isNot(anyOf(endsWith('.restore'), endsWith('.previous')))));
    });

    test('remplacer : un échec en route laisse tout l\'ancien état, dossiers comme réglages', () async {
      SharedPreferences.setMockInitialValues({'settings.themeChoice': 'light'});
      final b = phone('b');
      await b.paused.write(game(10));
      await b.finished.write(game(20));
      final bob = PlayerProfile.create(name: 'Bob');
      await b.players.write(bob);
      // Le dossier voisin des parties finies (où l'on prépare le nouveau) est pris par un fichier :
      // l'écriture de ce dossier, le dernier, échoue.
      File('${root.path}/b/over.restore').writeAsStringSync('en travers');
      final anna = PlayerProfile.create(name: 'Anna');
      final archive = BackupArchive(
        createdAt: DateTime.utc(2026),
        settings: {'settings.themeChoice': 'dark'},
        paused: {'game-1.run': gameJson(1)},
        finished: {'game-2.run': gameJson(2)},
        players: {'player-${anna.id}.json': playerJson(anna)},
      );

      await expectLater(b.service.restore(archive, BackupImportMode.replace), throwsA(isA<FileSystemException>()));

      expect((await b.paused.list()).map((g) => g.seed), [10]);
      expect((await b.finished.list()).map((g) => g.seed), [20]);
      expect((await b.players.list()).map((p) => p.id), [bob.id]);
      expect((await SharedPreferences.getInstance()).getString('settings.themeChoice'), 'light');
    });

    test('remplacer : un ancien contenu impossible à supprimer ne fait pas échouer la restauration', () async {
      if (Platform.isWindows || Process.runSync('id', ['-u']).stdout.toString().trim() == '0') {
        return; // les droits de fichier ne bloquent pas la suppression dans ces cas
      }
      SharedPreferences.setMockInitialValues({'settings.themeChoice': 'light'});
      final b = phone('b');
      await b.finished.write(game(20));
      // Un sous-dossier non modifiable dans l'ancien contenu : sa suppression échoue.
      final locked = Directory('${root.path}/b/over/verrou')..createSync(recursive: true);
      File('${locked.path}/x').writeAsStringSync('x');
      Process.runSync('chmod', ['555', locked.path]);
      addTearDown(() => Process.runSync('chmod', ['755', '${root.path}/b/over.previous/verrou']));
      final archive = BackupArchive(
        createdAt: DateTime.utc(2026),
        settings: {'settings.themeChoice': 'dark'},
        finished: {'game-2.run': gameJson(2)},
      );

      final result = await b.service.restore(archive, BackupImportMode.replace);

      expect(result.games, 1);
      expect((await b.finished.list()).map((g) => g.seed), [2]);
      expect((await SharedPreferences.getInstance()).getString('settings.themeChoice'), 'dark',
          reason: 'les réglages suivent la restauration, malgré le reste impossible à nettoyer');
    });

    test('fusionner : ajoute ce qui manque, garde ce qui existe, réglages du fichier par-dessus', () async {
      SharedPreferences.setMockInitialValues({'settings.themeChoice': 'dark', 'settings.rightHanded': false});
      final a = phone('a');
      await a.finished.write(game(1, alias: 'Version du fichier'));
      await a.finished.write(game(2, alias: 'Seulement dans le fichier'));
      await a.players.write(PlayerProfile.create(name: 'Anna'));
      final bytes = await a.service.export(_password, iterations: _iterations);

      SharedPreferences.setMockInitialValues({'settings.themeChoice': 'light', 'settings.musicEnabled': true});
      final b = phone('b');
      await b.finished.write(game(1, alias: 'Version du téléphone'));
      await b.finished.write(game(3, alias: 'Seulement ici'));
      await b.paused.write(game(4));
      await b.players.write(PlayerProfile.create(name: 'Bob'));

      final result = await b.service.restore(await b.service.open(bytes, _password), BackupImportMode.merge);
      expect(result.games, 1, reason: 'seule la partie 2 manquait');
      expect(result.profiles, 1);

      final finished = {for (final g in await b.finished.list()) g.seed: g.alias};
      expect(finished, {1: 'Version du téléphone', 2: 'Seulement dans le fichier', 3: 'Seulement ici'});
      expect((await b.paused.list()).map((g) => g.seed), [4]);
      expect((await b.players.list()).map((p) => p.name), unorderedEquals(['Anna', 'Bob']));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.themeChoice'), 'dark', reason: 'le fichier l\'emporte');
      expect(prefs.getBool('settings.rightHanded'), isFalse);
      expect(prefs.getBool('settings.musicEnabled'), isTrue, reason: 'un réglage que le fichier n\'a pas reste');
    });

    test('une entrée illisible de l\'archive est écartée et comptée, le reste est restauré', () async {
      final b = phone('b');
      final archive = BackupArchive(
        createdAt: DateTime.utc(2026),
        finished: {'game-1.run': gameJson(1), 'game-2.run': '{"seed": "pas un entier"}'},
        players: {'player-x.json': 'n\'importe quoi'},
      );
      final result = await b.service.restore(archive, BackupImportMode.replace);
      expect(result.games, 1);
      expect(result.profiles, 0);
      expect(result.skipped, 2);
      expect((await b.finished.list()).map((g) => g.seed), [1]);
    });

    test('restaurer écarte un nom de fichier hors des formes de l\'app, même d\'une archive non passée par open', () async {
      final b = phone('b');
      final archive = BackupArchive(
        createdAt: DateTime.utc(2026),
        finished: {'../hors-du-dossier.run': gameJson(1), 'game-2.run': gameJson(2)},
      );

      final result = await b.service.restore(archive, BackupImportMode.merge);

      expect(result.games, 1);
      expect(result.skipped, 1);
      expect((await b.finished.list()).map((g) => g.seed), [2]);
      expect(File('${root.path}/b/hors-du-dossier.run').existsSync(), isFalse);
      expect(File('${root.path}/hors-du-dossier.run').existsSync(), isFalse);
    });

    test('un fichier de sauvegarde qui n\'est pas une sauvegarde est refusé sans rien écrire', () async {
      final b = phone('b');
      await b.finished.write(game(1));
      expect(() => b.service.check(Uint8List.fromList(utf8.encode('x' * 100))), throwsA(isA<BackupException>()));
      expect((await b.finished.list()), hasLength(1));
    });

    test('le profil d\'un joueur survit au voyage (nom, surnom, latéralité)', () async {
      final a = phone('a');
      final marie = PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi', rightHanded: false);
      await a.players.write(marie);
      final bytes = await a.service.export(_password, iterations: _iterations);
      final b = phone('b');
      await b.service.restore(await b.service.open(bytes, _password), BackupImportMode.replace);
      final back = (await b.players.list()).single;
      expect(back.id, marie.id);
      expect(back.nickname, 'Mimi');
      expect(back.rightHanded, isFalse);
      expect(playerJson(back), playerJson(marie));
    });
  });
}
