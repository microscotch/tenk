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
  testWidgets('affiche chaque ligne de la grille avec son tiret ou son barré propre, sans doublon', (tester) async {
    var a = Player(name: 'A').applySuccessfulTurn(500); // ligne : 500
    a = a.applyBust(); // tiret sur 500
    a = a.applySuccessfulTurn(300); // nouvelle ligne : 800, sans tiret
    a = a.applyBust(); // tiret sur 800
    a = a.applyBust(); // 800 barré, retombe sur la ligne 500 déjà existante

    await tester.pumpWidget(MaterialApp(home: ScoreGridScreen(players: [a])));
    await tester.pumpAndSettle();

    // Grille attendue : [0, 500(tiret, courante), 800(tiret, barré)] — pas de
    // ligne dupliquée pour le retour à 500.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('800'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsNWidgets(2)); // les deux lignes ayant porté un tiret
    expect(find.byIcon(Icons.play_arrow), findsOneWidget, reason: 'une seule ligne courante mise en évidence');

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

  testWidgets('affiche une colonne par joueur, avec ses initiales comme libellé', (tester) async {
    final players = [Player(name: 'Alice'), Player(name: 'Bob')];

    await tester.pumpWidget(MaterialApp(home: ScoreGridScreen(players: players)));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('un clic sur la ligne d\'un joueur ouvre sa grille seule, avec son nom complet en libellé',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['Alice', 'Bob']).startTurn();
    engine = engine.copyWith(activeTurn: const TurnState(diceToRoll: 5, bankedScore: 0));
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(playerNames: ['Alice', 'Bob']),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.byType(ScoreGridScreen), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget, reason: 'le nom complet sert de libellé, pas juste "B"');
    expect(find.text('Alice'), findsNothing, reason: 'la grille est filtrée sur ce seul joueur');
  });

  group('shortLabelsFor', () {
    test('une seule lettre par joueur quand ça suffit à les distinguer', () {
      final players = [Player(name: 'Alice'), Player(name: 'Bob'), Player(name: 'Chloé')];
      expect(shortLabelsFor(players), ['A', 'B', 'C']);
    });

    test('rallonge seulement les joueurs en collision, chacun jusqu\'à distinction', () {
      // Bob est unique dès la première lettre ; Alice et Alex collisionnent
      // sur "A" puis encore sur "AL", et ne se distinguent qu'à "ALI"/"ALE".
      final players = [Player(name: 'Alice'), Player(name: 'Bob'), Player(name: 'Alex')];
      expect(shortLabelsFor(players), ['ALI', 'B', 'ALE']);
    });

    test('accepte une collision résiduelle si plus aucune lettre ne distingue', () {
      final players = [Player(name: 'Ana'), Player(name: 'Ana')];
      expect(shortLabelsFor(players), ['ANA', 'ANA']);
    });
  });
}
