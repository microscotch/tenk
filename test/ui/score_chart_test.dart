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

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(width: 300, height: 200, child: chart)),
    ));

    expect(tester.takeException(), isNull, reason: 'le peintre doit tenir sur une taille réelle');
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('une série d\'un seul point ne trace rien mais ne plante pas', (tester) async {
    const chart = ScoreChart(series: [ScoreSeries(name: 'A', color: Colors.red, scores: [0])]);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: 300, height: 200, child: chart)),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  group('courbe interactive', () {
    // Deux joueurs de longueurs différentes : A a joué 2 tours, B 3.
    const a = ScoreSeries(name: 'A', color: Colors.red, scores: [0, 500, 1200]);
    const b = ScoreSeries(name: 'B', color: Colors.blue, scores: [0, 300, 700, 900], label: 'Bibi');

    Future<void> pumpChart(WidgetTester tester, {List<ScoreSeries> series = const [a, b]}) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: SizedBox(width: 400, height: 300, child: ScoreChart(series: series)))),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Repère du tracé pour 400 x 300 : voir `_plotRectFor` (gouttières 44 et 20).
    const plotLeft = 44.0;
    const plotWidth = 400 - 8 - plotLeft;
    Offset onTurn(WidgetTester tester, int turn, int lastTurn) =>
        tester.getTopLeft(find.byType(ScoreChart)) + Offset(plotLeft + plotWidth * turn / lastTurn, 100);

    testWidgets('le curseur part du dernier tour', (tester) async {
      await pumpChart(tester);

      expect(find.text('Tour 3'), findsOneWidget);
      expect(find.text('900'), findsOneWidget, reason: 'le score de B à son 3e tour');
      expect(find.text('—'), findsOneWidget, reason: 'A n\'a joué que 2 tours : pas de score au 3e');
    });

    testWidgets('toucher le graphique déplace le curseur et l\'infobulle', (tester) async {
      await pumpChart(tester);

      await tester.tapAt(onTurn(tester, 1, 3));
      await tester.pumpAndSettle();

      expect(find.text('Tour 1'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.text('Tour 3'), findsNothing);
    });

    testWidgets('le glisser du doigt fait suivre le curseur, collé aux tours', (tester) async {
      await pumpChart(tester);

      final gesture = await tester.startGesture(onTurn(tester, 0, 3));
      await tester.pump();
      expect(find.text('Tour 0'), findsOneWidget);

      // Un peu avant le tour 2 : le curseur arrondit au tour le plus proche.
      await gesture.moveTo(onTurn(tester, 2, 3) - const Offset(10, 0));
      await tester.pump();
      expect(find.text('Tour 2'), findsOneWidget);
      expect(find.text('1200'), findsOneWidget);
      expect(find.text('700'), findsOneWidget);
      await gesture.up();
    });

    testWidgets('l\'infobulle appelle le joueur par son libellé, à défaut par son nom', (tester) async {
      await pumpChart(tester);

      expect(find.text('Bibi'), findsOneWidget, reason: 'le surnom de B');
      expect(find.text('B'), findsNothing);
      expect(find.text('A'), findsOneWidget, reason: 'sans libellé, le nom');
    });

    test('le curseur se cale sur le tour entier le plus proche', () {
      // Tracé large de 400 : de x = 44 (tour 0) à x = 392 (dernier tour).
      expect(ScoreChart.turnAt(0, 400, 4), 0, reason: 'avant le tracé');
      expect(ScoreChart.turnAt(44, 400, 4), 0);
      expect(ScoreChart.turnAt(44 + 348 / 4 * 1.4, 400, 4), 1);
      expect(ScoreChart.turnAt(44 + 348 / 4 * 1.6, 400, 4), 2);
      expect(ScoreChart.turnAt(392, 400, 4), 4);
      expect(ScoreChart.turnAt(9999, 400, 4), 4, reason: 'après le tracé');
    });

    testWidgets('une ligne de repère tous les 200 points, sans libellé de plus', (tester) async {
      await pumpChart(tester);

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
  });
}
