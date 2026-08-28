import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';

/// Ces scénarios (craque, victoire) sont difficiles à obtenir de façon
/// fiable via de vrais lancers aléatoires en un temps raisonnable ; on
/// charge donc directement un [GameEngine] pré-construit via
/// [GameNotifier.debugLoadState] pour exercer les mêmes écrans que ceux
/// utilisés en jeu réel.
void main() {
  testWidgets('un craque affiche l\'écran "Craqué !" puis passe la main avec un tiret', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(
        diceToRoll: 3,
        pendingRoll: analyzeRoll([2, 3, 4]), // aucun dé marquant
        busted: true,
      ),
    );
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(playerNames: ['A', 'B']),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Craqué !'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.currentPlayerIndex, 1, reason: 'la main doit passer au joueur B');
    expect(after.players[0].hasTiret, isTrue, reason: 'le craque doit marquer un tiret sur A');
    expect(after.players[0].totalScore, 0, reason: 'le craque ne doit pas changer le score déjà acquis');
  });

  testWidgets('atteindre exactement 10000 lors du tour final affiche l\'écran de victoire', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A a déjà déclenché le tour final en atteignant 10000 ; c'est au tour
    // de B de jouer son unique tour final, qu'il réussit à banquer.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        const Player(name: 'A', totalScore: 10000, hasEntered: true),
        const Player(name: 'B', totalScore: 3000, hasEntered: true),
      ],
      currentPlayerIndex: 1,
      triggeringWinnerIndex: 0,
      remainingFinalTurns: 1,
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200),
    );
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(playerNames: ['A', 'B']),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tour final'), findsOneWidget);

    await tester.tap(find.text('S\'arrêter'));
    await tester.pumpAndSettle();

    expect(find.byType(GameOverScreen), findsOneWidget);
    expect(find.textContaining('A gagne'), findsOneWidget);

    final after = container.read(gameProvider)!;
    expect(after.gameOver, isTrue);
    expect(after.winnerIndex, 0, reason: 'A doit gagner malgré le tour final joué par B');
  });
}
