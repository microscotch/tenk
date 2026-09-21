import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/player_providers.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/state/settings_providers.dart';

import '../test_helpers/fake_player_store.dart';

/// La latéralité suit le joueur du siège courant ; le réglage d'appareil n'est
/// plus qu'un repli.
void main() {
  late FakePlayerStore players;

  setUp(() {
    // `SettingsNotifier` charge ses préférences de façon asynchrone : sans
    // valeurs simulées ni attente, le chargement se termine après la
    // destruction du conteneur et lève « Cannot use the Ref ... after it has
    // been disposed » dans le test SUIVANT.
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    players = FakePlayerStore();
  });

  /// Laisse le chargement asynchrone des préférences se terminer.
  Future<void> settleSettings(ProviderContainer container) async {
    container.read(settingsProvider);
    await Future<void>.delayed(Duration.zero);
  }

  Future<ProviderContainer> containerWith({
    required GameSetup setup,
    required int currentSeat,
  }) async {
    final container = ProviderContainer(
      overrides: [playerStoreProvider.overrideWithValue(players)],
    );
    addTearDown(container.dispose);

    final engine = GameEngine.newGame(setup.playerNames).copyWith(
      players: [for (final n in setup.playerNames) Player(name: n)],
      currentPlayerIndex: currentSeat,
      activeTurn: const TurnState(diceToRoll: 5),
    );
    container.read(gameProvider.notifier).debugLoadState(engine, setup);
    await container.read(playersProvider.future);
    await settleSettings(container);
    return container;
  }

  test('un gaucher retourne la disposition pendant son tour', () async {
    final leftHanded = PlayerProfile.create(name: 'Gaucher', rightHanded: false);
    await players.write(leftHanded);
    final container = await containerWith(
      setup: GameSetup(playerNames: const ['Gaucher', 'Bot'], playerIds: {0: leftHanded.id}),
      currentSeat: 0,
    );

    expect(container.read(currentSeatRightHandedProvider), isFalse);
  });

  test('un siège IA retombe sur le réglage d\'appareil', () async {
    final leftHanded = PlayerProfile.create(name: 'Gaucher', rightHanded: false);
    await players.write(leftHanded);
    final container = await containerWith(
      setup: GameSetup(playerNames: const ['Gaucher', 'Bot'], playerIds: {0: leftHanded.id}),
      currentSeat: 1,
    );

    expect(container.read(currentSeatRightHandedProvider), isTrue,
        reason: 'un bot n\'a pas de latéralité');
  });

  test('une partie sans lien vers les fiches retombe sur le réglage d\'appareil', () async {
    final container = await containerWith(
      setup: const GameSetup(playerNames: ['A', 'B']),
      currentSeat: 0,
    );
    container.read(settingsProvider.notifier).setRightHanded(false);

    expect(container.read(currentSeatRightHandedProvider), isFalse,
        reason: 'les parties antérieures à la base gardent le comportement d\'avant');
  });

  test('sans partie en cours, le réglage d\'appareil s\'applique', () async {
    final container = ProviderContainer(
      overrides: [playerStoreProvider.overrideWithValue(players)],
    );
    addTearDown(container.dispose);
    await settleSettings(container);

    expect(container.read(currentSeatRightHandedProvider), isTrue);
  });

  group('noms affichés', () {
    test('un siège rattaché à une fiche à surnom affiche le surnom', () async {
      final marie = PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi');
      await players.write(marie);
      final container = await containerWith(
        setup: GameSetup(playerNames: const ['Marie Curie', 'Bot'], playerIds: {0: marie.id}),
        currentSeat: 0,
      );

      final names = container.read(displayNamesProvider);

      expect(displayNameOf(names, 'Marie Curie'), 'Mimi');
      expect(displayNameOf(names, 'Bot'), 'Bot', reason: 'un bot n\'a pas de fiche');
    });

    test('une fiche sans surnom n\'entre même pas dans la table', () async {
      final bob = PlayerProfile.create(name: 'Bob');
      await players.write(bob);
      final container = await containerWith(
        setup: GameSetup(playerNames: const ['Bob', 'Bot'], playerIds: {0: bob.id}),
        currentSeat: 0,
      );

      final names = container.read(displayNamesProvider);

      expect(names, isEmpty, reason: 'rien à substituer : l\'appelant garde le nom');
      expect(displayNameOf(names, 'Bob'), 'Bob');
    });

    test('une partie sans lien vers les fiches garde les noms enregistrés', () async {
      await players.write(PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi'));
      final container = await containerWith(
        setup: const GameSetup(playerNames: ['Marie Curie', 'B']),
        currentSeat: 0,
      );

      final names = container.read(displayNamesProvider);

      expect(displayNameOf(names, 'Marie Curie'), 'Marie Curie',
          reason: 'une partie antérieure à la base s\'affiche telle qu\'elle a été jouée');
    });

    test('sans partie en cours, la table est vide', () {
      final container = ProviderContainer(
        overrides: [playerStoreProvider.overrideWithValue(players)],
      );
      addTearDown(container.dispose);

      expect(container.read(displayNamesProvider), isEmpty);
    });
  });
}
