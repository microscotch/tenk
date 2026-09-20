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

/// Sortie vers l'écran d'accueil depuis l'écran de jeu et depuis l'écran de
/// fin de partie. Ni l'un ni l'autre n'offre plus de bouton pour ça : c'est le
/// retour système qui ramène à l'accueil, et il doit le faire depuis n'importe
/// quelle profondeur sans laisser la pile vide (écran gris signalé en jeu
/// réel). D'où la pile de routes réelle reproduite ici — `SetupScreen` en
/// racine (poussée par le splash via `pushReplacement`), puis les écrans de
/// partie par-dessus.
void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Accueil + écran de jeu par-dessus, partie en cours (le tour de B est
  /// banquable, donc l'écran reste stable au lieu d'enchaîner tout seul).
  Future<ProviderContainer> pumpGameScreen(
    WidgetTester tester, {
    TargetPlatform? platform,
  }) async {
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
          theme: platform == null ? null : ThemeData(platform: platform),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

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
    expect(find.byType(GameScreen), findsOneWidget);
    return container;
  }

  /// Même pile, poussée jusqu'à la fin de partie : B banque son tour final,
  /// le moteur passe en `gameOver` et GameScreen pousse lui-même
  /// [GameOverScreen] depuis son `ref.listen`, exactement comme en jeu.
  Future<void> pumpEndOfGame(WidgetTester tester, {TargetPlatform? platform}) async {
    await pumpGameScreen(tester, platform: platform);
    await tester.ensureVisible(find.byIcon(Icons.front_hand));
    await tester.tap(find.byIcon(Icons.front_hand));
    await tester.pumpAndSettle();
    expect(find.byType(GameOverScreen), findsOneWidget);
  }

  testWidgets('écran de jeu : le retour système ramène à l\'accueil', (tester) async {
    await pumpGameScreen(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byType(SetupScreen), findsOneWidget,
        reason: 'on doit revenir sur l\'accueil, pas sur un écran vide');
  });

  testWidgets('écran de jeu : aucun bouton de sortie dans la barre', (tester) async {
    await pumpGameScreen(tester);

    expect(find.byType(BackButton), findsNothing, reason: 'plus de flèche de retour');
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.exit_to_app), findsNothing, reason: 'plus de bouton "quitter"');
    expect(find.byIcon(Icons.grid_on), findsOneWidget,
        reason: 'la grille de score, elle, reste accessible');
  });

  testWidgets('fin de partie : le retour système ramène à l\'accueil, pile nettoyée',
      (tester) async {
    await pumpEndOfGame(tester);

    // Un pop() nu retomberait sur le GameScreen de la partie terminée — un
    // écran mort dès que `engine.gameOver` est vrai (il n'affiche plus jamais
    // qu'un indicateur de chargement). Bug remonté en jeu réel.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(GameOverScreen), findsNothing);
    expect(find.byType(GameScreen), findsNothing,
        reason: 'l\'écran de jeu terminé ne doit pas rester dans la pile');
    expect(find.byType(SetupScreen), findsOneWidget,
        reason: 'on doit revenir sur l\'accueil, pas sur un écran figé avec un spinner');
  });

  testWidgets('fin de partie : aucun bouton de retour à l\'accueil', (tester) async {
    await pumpEndOfGame(tester);

    expect(find.byType(BackButton), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('OK'), findsNothing);
  });

  // iOS n'a pas de bouton retour système, et le glissement bord-écran est
  // neutralisé par le PopScope des deux écrans (`popGestureEnabled` est faux
  // dès que la route refuse de se dépiler) : sans la flèche conditionnelle,
  // les deux écrans seraient sans issue sur cette plateforme.
  testWidgets('iOS, écran de jeu : la flèche est là et ramène à l\'accueil', (tester) async {
    await pumpGameScreen(tester, platform: TargetPlatform.iOS);

    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsNothing);
    expect(find.byType(SetupScreen), findsOneWidget);
  });

  testWidgets('iOS, fin de partie : la flèche est là et ramène à l\'accueil', (tester) async {
    await pumpEndOfGame(tester, platform: TargetPlatform.iOS);

    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(GameOverScreen), findsNothing);
    expect(find.byType(GameScreen), findsNothing,
        reason: 'la flèche ramène à l\'accueil, pas sur le GameScreen mort');
    expect(find.byType(SetupScreen), findsOneWidget);
  });
}
