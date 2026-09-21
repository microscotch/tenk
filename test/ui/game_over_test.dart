import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';

import '../test_helpers/fake_player_store.dart';

/// L'écran de fin nomme les joueurs par leur surnom quand leur siège est
/// rattaché à une fiche qui en porte un.
void main() {
  late FakePlayerStore players;

  setUp(() => players = FakePlayerStore());

  Future<void> pump(WidgetTester tester, GameSetup setup) async {
    final container = ProviderContainer(
      overrides: [playerStoreProvider.overrideWithValue(players)],
    );
    addTearDown(container.dispose);

    final engine = GameEngine.newGame(setup.playerNames).copyWith(
      players: [
        Player(name: setup.playerNames[0], totalScore: 10000, hasEntered: true),
        Player(name: setup.playerNames[1], totalScore: 6150, hasEntered: true),
      ],
      gameOver: true,
      winnerIndex: 0,
    );
    container.read(gameProvider.notifier).debugLoadState(engine, setup);
    await container.read(playersProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameOverScreen(players: engine.players, winnerIndex: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('le vainqueur est annoncé sous son surnom', (tester) async {
    final marie = PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi');
    await players.write(marie);

    await pump(tester, GameSetup(playerNames: const ['Marie Curie', 'Bruno'], playerIds: {0: marie.id}));

    expect(find.text('Mimi gagne !'), findsOneWidget);
    expect(find.textContaining('Mimi : 10000'), findsOneWidget,
        reason: 'le classement final le nomme pareil');
    expect(find.textContaining('Marie Curie'), findsNothing);
  });

  testWidgets('une fiche sans surnom garde son nom', (tester) async {
    final bob = PlayerProfile.create(name: 'Bob');
    await players.write(bob);

    await pump(tester, GameSetup(playerNames: const ['Bob', 'Bruno'], playerIds: {0: bob.id}));

    expect(find.text('Bob gagne !'), findsOneWidget);
  });

  testWidgets('une partie sans lien vers les fiches garde les noms enregistrés', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi'));

    await pump(tester, const GameSetup(playerNames: ['Marie Curie', 'Bruno']));

    expect(find.text('Marie Curie gagne !'), findsOneWidget,
        reason: 'une partie antérieure à la base s\'affiche telle qu\'elle a été jouée');
  });

  testWidgets('un bot garde son nom', (tester) async {
    final marie = PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi');
    await players.write(marie);

    await pump(tester, GameSetup(playerNames: const ['Marie Curie', 'HAL'], playerIds: {0: marie.id}));

    expect(find.textContaining('HAL : 6150'), findsOneWidget);
  });
}
