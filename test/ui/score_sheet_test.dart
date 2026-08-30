import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/ui/widgets/score_sheet.dart';

/// La ligne (le [Container]) affichant le nom [playerName], pour vérifier
/// les hints propres à ce joueur plutôt que ceux de toute la feuille de
/// score.
Finder _rowOf(String playerName) => find.ancestor(of: find.text(playerName), matching: find.byType(Container)).first;

void main() {
  testWidgets('signale un écart de 200 : danger pour celui au-dessus, opportunité pour celui en dessous',
      (tester) async {
    final players = [
      Player(name: 'A', totalScore: 800, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
    ];

    await tester.pumpWidget(MaterialApp(home: ScoreSheet(players: players, currentPlayerIndex: 0)));

    // B n'est qu'à 200 pts au-dessus de A : B risque d'être barré si A
    // valide un tour minimal. A, lui, est à 200 pts de barrer B.
    expect(find.descendant(of: _rowOf('B'), matching: find.byIcon(Icons.warning_amber_rounded)),
        findsOneWidget);
    expect(find.descendant(of: _rowOf('A'), matching: find.byIcon(Icons.gps_fixed)), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
  });

  testWidgets('aucun hint si aucun écart ne vaut exactement 200', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 300, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
    ];

    await tester.pumpWidget(MaterialApp(home: ScoreSheet(players: players, currentPlayerIndex: 0)));

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.gps_fixed), findsNothing);
  });

  testWidgets('un joueur encadré par deux écarts de 200 cumule les deux hints', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 800, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
      Player(name: 'C', totalScore: 1200, hasEntered: true),
    ];

    await tester.pumpWidget(MaterialApp(home: ScoreSheet(players: players, currentPlayerIndex: 0)));

    // A (200 sous B) et B (200 sous C) peuvent chacun barrer leur voisin du
    // dessus ; B (200 au-dessus de A) et C (200 au-dessus de B) risquent
    // chacun d'être barrés par leur voisin du dessous.
    expect(find.byIcon(Icons.gps_fixed), findsNWidgets(2), reason: 'A et B peuvent chacun barrer leur voisin');
    expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2), reason: 'B et C risquent chacun le barrage');

    final bIcons = _rowOf('B');
    expect(find.descendant(of: bIcons, matching: find.byIcon(Icons.gps_fixed)), findsOneWidget);
    expect(find.descendant(of: bIcons, matching: find.byIcon(Icons.warning_amber_rounded)), findsOneWidget);
  });
}
