import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';
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

  testWidgets('affiche le score précédent entre parenthèses, avec son état de sanction', (tester) async {
    var a = Player(name: 'A').applySuccessfulTurn(500); // ligne : 500
    a = a.applyBust(); // tiret sur 500
    a = a.applySuccessfulTurn(300); // nouvelle ligne : 800, sans tiret

    await tester.pumpWidget(MaterialApp(home: ScoreSheet(players: [a], currentPlayerIndex: 0)));

    expect(find.text('800'), findsOneWidget);
    expect(find.text('(500)'), findsOneWidget, reason: 'le score précédent apparaît entre parenthèses');
    expect(
      find.descendant(of: _rowOf('A'), matching: find.byIcon(Icons.remove)),
      findsOneWidget,
      reason: 'la ligne précédente portait un tiret, signalé à côté du score entre parenthèses',
    );
  });

  testWidgets('le score précédent ignore les lignes barrées, et affiche 0 s\'il n\'en reste aucune', (tester) async {
    // Grid final : [0, 500(barré), 300(courante)]. La ligne juste avant
    // (500) est barrée : le score précédent affiché doit remonter jusqu'à
    // 0, pas afficher "500".
    var a = Player(name: 'A').applySuccessfulTurn(500);
    a = a.applyBust(); // tiret sur 500
    a = a.applyBust(); // 500 barré, retombe à 0
    a = a.applySuccessfulTurn(300); // nouvelle ligne 300, courante

    await tester.pumpWidget(MaterialApp(home: ScoreSheet(players: [a], currentPlayerIndex: 0)));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('(0)'), findsOneWidget, reason: 'la ligne 500 est barrée : on remonte jusqu\'à 0');
    expect(find.text('(500)'), findsNothing);
  });

  testWidgets('affiche la probabilité de marquer (fraction irréductible) pour le joueur courant seulement',
      (tester) async {
    final players = [
      Player(name: 'A', totalScore: 500, hasEntered: true),
      Player(name: 'B', totalScore: 500, hasEntered: true),
    ];

    await tester.pumpWidget(MaterialApp(
      home: ScoreSheet(
        players: players,
        currentPlayerIndex: 0,
        activeTurn: const TurnState(diceToRoll: 1, bankedScore: 0), // 1 dé : 2/6 réduit à 1/3
      ),
    ));

    expect(find.text('1/3 (33.33%)'), findsOneWidget,
        reason: '2/6 doit être affiché sous forme réduite, avec le pourcentage à 2 décimales');
    expect(
      find.descendant(of: _rowOf('B'), matching: find.textContaining('/')),
      findsNothing,
      reason: 'seul le joueur courant (avec un tour actif) affiche une probabilité',
    );
  });

  testWidgets('un joueur cliqué déclenche onTapPlayer avec ce joueur', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 100, hasEntered: true),
      Player(name: 'B', totalScore: 200, hasEntered: true),
    ];
    Player? tapped;

    await tester.pumpWidget(MaterialApp(
      home: ScoreSheet(players: players, currentPlayerIndex: 0, onTapPlayer: (p) => tapped = p),
    ));

    await tester.tap(find.text('B'));
    await tester.pump();

    expect(tapped?.name, 'B');
  });
}
