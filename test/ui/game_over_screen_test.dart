import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/setup_screen.dart';

import '../test_helpers/fake_game_save_store.dart';

/// Reproduit la pile de routes réelle d'une fin de partie — `SetupScreen` en
/// racine (poussée par le splash via `pushReplacement`), un écran
/// intermédiaire, puis [GameOverScreen] par-dessus — pour vérifier que le
/// bouton de sortie ramène bien à l'écran d'accueil et ne laisse pas la pile
/// vide (écran gris signalé en jeu réel).
void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> pumpEndOfGame(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
        archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pile fidèle au jeu réel : l'accueil, puis GameScreen — c'est ce dernier
    // qui pousse lui-même l'écran de fin de partie depuis son `ref.listen`
    // quand le moteur passe en `gameOver`.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 10000, hasEntered: true),
        Player(name: 'B', totalScore: 3000, hasEntered: true),
      ],
      currentPlayerIndex: 1,
      triggeringWinnerIndex: 0,
      remainingFinalTurns: 1,
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200, hasRolledThisTurn: true),
    );
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(playerNames: ['A', 'B']),
        );

    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
    await tester.pumpAndSettle();

    // B banque son tour final : le moteur passe en gameOver et GameScreen
    // pousse GameOverScreen, exactement comme en jeu.
    await tester.ensureVisible(find.byIcon(Icons.stop));
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    expect(find.byType(GameOverScreen), findsOneWidget);
  }

  testWidgets('le bouton de sortie ramène à l\'écran d\'accueil, pile nettoyée', (tester) async {
    await pumpEndOfGame(tester);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GameOverScreen), findsNothing);
    expect(find.byType(GameScreen), findsNothing, reason: 'l\'écran de jeu ne doit pas rester dans la pile');
    expect(find.byType(SetupScreen), findsOneWidget, reason: 'on doit revenir sur l\'accueil, pas sur un écran vide');
  });
}
