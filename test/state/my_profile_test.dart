import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/state/player_providers.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/fake_player_store.dart';
import '../test_helpers/my_profile.dart';

/// Une base de joueurs illisible.
class _BrokenPlayerStore extends FakePlayerStore {
  @override
  Future<List<PlayerProfile>> list() async => throw const FileSystemException('illisible');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePlayerStore players;

  setUp(() {
    players = FakePlayerStore();
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer newContainer([PlayerStore? store]) {
    final container = ProviderContainer(overrides: [playerStoreProvider.overrideWithValue(store ?? players)]);
    addTearDown(container.dispose);
    return container;
  }

  group('faut-il demander le profil au lancement ?', () {
    test('oui au premier lancement : aucun profil choisi', () async {
      expect(await isMyProfileMissing(newContainer()), isTrue);
    });

    test('non quand le profil existe, même demandé avant la relecture des réglages', () async {
      final me = PlayerProfile.create(name: 'Anna');
      await seedMyProfile(players, me);
      final container = newContainer();
      expect(container.read(settingsProvider).loaded, isFalse, reason: 'les réglages ne sont pas encore relus');

      expect(await isMyProfileMissing(container), isFalse);
      await container.read(playersProvider.future);
      expect(container.read(myProfileProvider)?.id, me.id);
    });

    test('oui quand la fiche du profil a disparu', () async {
      SharedPreferences.setMockInitialValues({'settings.myProfileId': 'fiche-effacee'});
      await players.write(PlayerProfile.create(name: 'Anna'));
      expect(await isMyProfileMissing(newContainer()), isTrue);
    });

    test('non si la base des joueurs est illisible : on ne bloque pas l\'entrée dans le jeu', () async {
      expect(await isMyProfileMissing(newContainer(_BrokenPlayerStore())), isFalse);
    });
  });

  group('ancien « joueur principal » des réglages', () {
    test('retrouve sa fiche par son nom, ou par un ancien nom, sans tenir compte de la casse', () {
      final anna = PlayerProfile.create(name: 'Anna');
      final bob = PlayerProfile.create(name: 'Robert').renamedTo('Bob');
      expect(profileMatchingLegacyName([anna, bob], ' anna ')?.id, anna.id);
      expect(profileMatchingLegacyName([anna, bob], 'Robert')?.id, bob.id);
    });

    test('rien sans nom, ou sans fiche de ce nom', () {
      final anna = PlayerProfile.create(name: 'Anna');
      expect(profileMatchingLegacyName([anna], ''), isNull);
      expect(profileMatchingLegacyName([anna], 'Chloé'), isNull);
    });
  });

  test('la latéralité par défaut est celle du profil, plus celle de l\'ancien réglage', () async {
    SharedPreferences.setMockInitialValues({});
    final me = PlayerProfile.create(name: 'Anna', rightHanded: false);
    await seedMyProfile(players, me);
    final container = newContainer();
    await isMyProfileMissing(container);
    await container.read(playersProvider.future);

    expect(container.read(settingsProvider).rightHanded, isTrue, reason: 'ancien réglage : droitier');
    expect(container.read(currentSeatRightHandedProvider), isFalse, reason: 'le profil : gaucher');
  });
}
