import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/player_stats.dart';
import 'package:le10000/state/player_store.dart';

/// Le magasin sur de vrais fichiers. Les tests de widgets passent par
/// [FakePlayerStore] : les cycles de pump ne résolvent pas fiablement `dart:io`.
void main() {
  late Directory tempDir;
  late PlayerStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tenk_player_store_test_');
    store = PlayerStore(rootDirectory: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('aller-retour d\'une fiche complète', () async {
    final player = PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi', rightHanded: false)
        .copyWith(stats: const PlayerStats(gamesPlayed: 4, gamesWon: 2, brelans: {4: 3}));

    await store.write(player);
    final read = await store.read(player.id);

    expect(read, isNotNull);
    expect(read!.name, 'Marie Curie');
    expect(read.nickname, 'Mimi');
    expect(read.rightHanded, isFalse);
    expect(read.stats.gamesPlayed, 4);
    expect(read.stats.brelans, {4: 3});
  });

  test('une identité inconnue se lit comme absente', () async {
    expect(await store.read('inconnue'), isNull);
    expect(await store.exists('inconnue'), isFalse);
  });

  test('la liste est triée par nom, accents et casse neutralisés', () async {
    for (final name in ['Zoé', 'élodie', 'Bob']) {
      await store.write(PlayerProfile.create(name: name));
    }

    final names = (await store.list()).map((p) => p.name).toList();

    expect(names, ['Bob', 'élodie', 'Zoé'],
        reason: 'une liste de personnes se lit dans l\'ordre alphabétique');
  });

  test('supprimer efface la fiche et ses statistiques', () async {
    final player = PlayerProfile.create(name: 'Bob')
        .copyWith(stats: const PlayerStats(gamesPlayed: 9));
    await store.write(player);

    await store.delete(player.id);

    expect(await store.read(player.id), isNull);
    expect(await store.list(), isEmpty);
  });

  test('une fiche illisible est ignorée sans faire échouer la liste', () async {
    await store.write(PlayerProfile.create(name: 'Bob'));
    await File('${tempDir.path}/player-corrompue.json').writeAsString('{ ceci n\'est pas du JSON');

    final players = await store.list();

    expect(players, hasLength(1), reason: 'une fiche invalide ne doit pas vider l\'écran');
    expect(players.single.name, 'Bob');
  });

  test('l\'écriture ne laisse aucun fichier temporaire derrière elle', () async {
    await store.write(PlayerProfile.create(name: 'Bob'));

    final leftovers = tempDir.listSync().where((e) => e.path.endsWith('.tmp'));

    expect(leftovers, isEmpty, reason: 'écriture atomique : tmp puis renommage');
  });

  group('unicité des noms', () {
    test('détecte un doublon aux accents et à la casse près', () async {
      await store.write(PlayerProfile.create(name: 'Rémi'));

      expect(await store.nameTaken('remi'), isTrue);
      expect(await store.nameTaken('  RÉMI '), isTrue);
      expect(await store.nameTaken('Rémy'), isFalse);
    });

    test('une fiche ne se heurte pas à elle-même lors d\'un renommage', () async {
      final player = PlayerProfile.create(name: 'Rémi');
      await store.write(player);

      expect(await store.nameTaken('Rémi', exceptId: player.id), isFalse);
      expect(await store.nameTaken('Rémi'), isTrue, reason: 'sans exception, c\'est bien pris');
    });
  });
}
