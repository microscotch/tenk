import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/score_chart_screen.dart';
import 'package:le10000/ui/widgets/score_chart.dart';

/// L'icône de courbe dans la barre de l'écran de jeu, et l'écran qu'elle ouvre.
void main() {
  Future<ProviderContainer> pumpGame(WidgetTester tester, {bool replayMode = false}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 1200, hasEntered: true),
        Player(name: 'B', totalScore: 800, hasEntered: true),
      ],
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 300, hasRolledThisTurn: true),
    );
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(playerNames: ['A', 'B']),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(replayMode: replayMode),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('l\'icône de courbe est dans la barre pendant une partie', (tester) async {
    await pumpGame(tester);

    expect(find.byIcon(Icons.show_chart), findsOneWidget);
  });

  testWidgets('elle disparaît en mode rejeu, comme la grille', (tester) async {
    await pumpGame(tester, replayMode: true);

    expect(find.byIcon(Icons.show_chart), findsNothing);
    expect(find.byIcon(Icons.grid_on), findsNothing);
  });

  testWidgets('sans journal, l\'écran le dit au lieu de planter', (tester) async {
    // `debugLoadState` ne renseigne ni seed ni actions : c'est le cas de TOUS
    // les tests d'écran de jeu, et celui d'un état reconstruit à la main.
    await pumpGame(tester);

    await tester.tap(find.byIcon(Icons.show_chart));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ScoreChartScreen), findsOneWidget);
    expect(find.textContaining('rien à tracer'), findsOneWidget);
    expect(find.byType(ScoreChart), findsNothing);
  });

  testWidgets('le peintre ne redessine que si les séries changent', (tester) async {
    const a = ScoreSeries(name: 'A', color: Colors.red, scores: [0, 500]);
    const chart = ScoreChart(series: [a]);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 300, height: 200, child: chart))));

    expect(tester.takeException(), isNull, reason: 'le peintre doit tenir sur une taille réelle');
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('une série d\'un seul point ne trace rien mais ne plante pas', (tester) async {
    const chart = ScoreChart(series: [ScoreSeries(name: 'A', color: Colors.red, scores: [0])]);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox(width: 300, height: 200, child: chart))),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('une ligne de repère tous les 200 points, sans libellé de plus', (tester) async {
    const chart = ScoreChart(series: [ScoreSeries(name: 'A', color: Colors.red, scores: [0, 500, 1200, 3000])]);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox(width: 400, height: 300, child: chart))),
    );

    final render = tester.renderObject<RenderCustomPaint>(
      find.descendant(of: find.byType(ScoreChart), matching: find.byType(CustomPaint)).first,
    );
    final canvas = TestRecordingCanvas();
    render.paint(TestRecordingPaintingContext(canvas), Offset.zero);

    // Ordonnées des traits horizontaux (mêmes y au départ et à l'arrivée).
    final ys = <double>{};
    for (final call in canvas.invocations.where((c) => c.invocation.memberName == #drawLine)) {
      final from = call.invocation.positionalArguments[0] as Offset;
      final to = call.invocation.positionalArguments[1] as Offset;
      if (from.dy == to.dy) ys.add(from.dy);
    }
    // Zone tracée : de y = 8 à y = 300 - 20, pour 0 à 10000.
    const top = 8.0, bottom = 280.0;
    for (var score = 0; score <= 10000; score += 200) {
      final y = bottom - (bottom - top) * score / 10000;
      expect(ys.any((v) => (v - y).abs() < 0.01), isTrue, reason: 'un trait à $score');
    }

    final labels = canvas.invocations.where((c) => c.invocation.memberName == #drawParagraph).length;
    expect(labels, 8, reason: '6 graduations (0 à 10000, par 2000) et 2 bornes de tours : rien de plus');
  });
}
