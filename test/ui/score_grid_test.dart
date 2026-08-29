import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/score_grid_screen.dart';

void main() {
  testWidgets('affiche chaque ligne de la grille avec son tiret ou son barré propre', (tester) async {
    var a = Player(name: 'A').applySuccessfulTurn(500); // ligne 0 : 500
    a = a.applyBust(); // tiret sur 500
    a = a.applySuccessfulTurn(300); // ligne 1 : 800, sans tiret
    a = a.applyBust(); // tiret sur 800
    a = a.applyBust(); // 800 barré, retour à 500 (nouvelle ligne propre)

    await tester.pumpWidget(MaterialApp(home: ScoreGridScreen(players: [a])));
    await tester.pumpAndSettle();

    // Grille attendue : [500(tiret), 800(tiret, barré), 500(propre)]
    expect(find.text('500'), findsNWidgets(2));
    expect(find.text('800'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsNWidgets(2)); // les deux lignes ayant porté un tiret

    final texts = tester.widgetList<Text>(find.text('800'));
    expect(texts.single.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('le bouton grille de la partie en cours ouvre bien l\'écran', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(activeTurn: const TurnState(diceToRoll: 5, bankedScore: 0));
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

    await tester.tap(find.byIcon(Icons.grid_on));
    await tester.pumpAndSettle();

    expect(find.byType(ScoreGridScreen), findsOneWidget);
  });
}
