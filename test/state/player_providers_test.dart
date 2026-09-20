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
}
