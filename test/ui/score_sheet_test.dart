import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
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

    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: ScoreSheet(players: players, currentPlayerIndex: 0)));

    // A (joueur courant) est à 200 pts de barrer B. Les indices ne se lisent
    // que sur la ligne du joueur courant : celle de B montre le radar.
    expect(find.descendant(of: _rowOf('A'), matching: find.byIcon(Icons.gps_fixed)), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
  });

  testWidgets('aucun hint si aucun écart ne vaut exactement 200', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 300, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
    ];

    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: ScoreSheet(players: players, currentPlayerIndex: 0)));

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.gps_fixed), findsNothing);
  });

  testWidgets('un joueur courant encadré par deux écarts de 200 cumule les deux hints', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 800, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
      Player(name: 'C', totalScore: 1200, hasEntered: true),
    ];

    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: ScoreSheet(players: players, currentPlayerIndex: 1)));

    // B (courant) est à 200 sous C, qu'il peut barrer, et à 200 au-dessus de
    // A, qui peut le barrer : les deux indices, sur sa ligne seulement.
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    final bIcons = _rowOf('B');
    expect(find.descendant(of: bIcons, matching: find.byIcon(Icons.gps_fixed)), findsOneWidget);
    expect(find.descendant(of: bIcons, matching: find.byIcon(Icons.warning_amber_rounded)), findsOneWidget);
  });

  testWidgets('affiche le score précédent entre parenthèses, avec son état de sanction', (tester) async {
    var a = Player(name: 'A').applySuccessfulTurn(500); // ligne : 500
    a = a.applyBust(); // tiret sur 500
    a = a.applySuccessfulTurn(300); // nouvelle ligne : 800, sans tiret

    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: ScoreSheet(players: [a], currentPlayerIndex: 0)));

    expect(find.text('800'), findsOneWidget);
    expect(find.textContaining('(500'), findsOneWidget, reason: 'le score précédent apparaît entre parenthèses');

    // Le tiret doit être DANS la parenthèse, donc porté par ce même widget de
    // texte, et non posé à côté : sinon il se lit comme qualifiant le score
    // courant affiché juste avant.
    expect(
      find.descendant(of: find.textContaining('(500'), matching: find.byIcon(Icons.remove)),
      findsOneWidget,
      reason: 'la ligne précédente portait un tiret, marqué à l\'intérieur des parenthèses',
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

    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: ScoreSheet(players: [a], currentPlayerIndex: 0)));

    expect(find.text('300'), findsOneWidget);
    expect(find.text('(0)'), findsOneWidget, reason: 'la ligne 500 est barrée : on remonte jusqu\'à 0');
    expect(find.text('(500)'), findsNothing);
  });

  testWidgets('un joueur cliqué déclenche onTapPlayer avec ce joueur', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 100, hasEntered: true),
      Player(name: 'B', totalScore: 200, hasEntered: true),
    ];
    Player? tapped;

    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, 
      home: ScoreSheet(players: players, currentPlayerIndex: 0, onTapPlayer: (p) => tapped = p),
    ));

    await tester.tap(find.text('B'));
    await tester.pump();

    expect(tapped?.name, 'B');
  });

  group('médailles du podium', () {
    Future<void> pumpSheet(WidgetTester tester, List<Player> players) => tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ScoreSheet(players: players, currentPlayerIndex: 0),
          ),
        );

    Color medalColorIn(WidgetTester tester, String playerName) => tester
        .widget<Icon>(find.descendant(of: _rowOf(playerName), matching: find.byIcon(Icons.military_tech)))
        .color!;

    testWidgets('or, argent et bronze vont aux trois meilleurs scores', (tester) async {
      await pumpSheet(tester, [
        Player(name: 'A', totalScore: 1200, hasEntered: true),
        Player(name: 'B', totalScore: 3000, hasEntered: true),
        Player(name: 'C', totalScore: 2000, hasEntered: true),
      ]);

      expect(find.byIcon(Icons.military_tech), findsNWidgets(3));
      expect(medalColorIn(tester, 'B'), const Color(0xFFF2C94C), reason: 'meilleur score : or');
      expect(medalColorIn(tester, 'C'), const Color(0xFFC0C0C0), reason: 'deuxième : argent');
      expect(medalColorIn(tester, 'A'), const Color(0xFFCD7F32), reason: 'troisième : bronze');
    });

    testWidgets('au-delà du podium, plus aucune médaille', (tester) async {
      await pumpSheet(tester, [
        Player(name: 'A', totalScore: 4000, hasEntered: true),
        Player(name: 'B', totalScore: 3000, hasEntered: true),
        Player(name: 'C', totalScore: 2000, hasEntered: true),
        Player(name: 'D', totalScore: 1000, hasEntered: true),
      ]);

      expect(find.byIcon(Icons.military_tech), findsNWidgets(3));
      expect(find.descendant(of: _rowOf('D'), matching: find.byIcon(Icons.military_tech)), findsNothing);
    });

    testWidgets('aucune médaille tant que personne n\'a marqué', (tester) async {
      await pumpSheet(tester, [Player(name: 'A'), Player(name: 'B'), Player(name: 'C')]);

      expect(find.byIcon(Icons.military_tech), findsNothing,
          reason: 'tout le monde à 0 en début de partie : personne n\'est en tête');
    });

    testWidgets('deux joueurs à égalité partagent la même médaille', (tester) async {
      await pumpSheet(tester, [
        Player(name: 'A', totalScore: 3000, hasEntered: true),
        Player(name: 'B', totalScore: 3000, hasEntered: true),
        Player(name: 'C', totalScore: 1000, hasEntered: true),
      ]);

      expect(medalColorIn(tester, 'A'), const Color(0xFFF2C94C));
      expect(medalColorIn(tester, 'B'), const Color(0xFFF2C94C));
      expect(medalColorIn(tester, 'C'), const Color(0xFFC0C0C0), reason: 'le suivant prend l\'argent');
    });
  });

  group('liste rotative et radar', () {
    Future<void> pumpSheet(WidgetTester tester, List<Player> players, {required int current, int? potential}) =>
        tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ScoreSheet(players: players, currentPlayerIndex: current, potentialTotal: potential)),
          ),
        );

    double topOf(WidgetTester tester, String name) => tester.getTopLeft(find.text(name)).dy;

    testWidgets('le joueur dont c\'est le tour est en tête, les suivants dans l\'ordre de jeu', (tester) async {
      final players = [Player(name: 'A'), Player(name: 'B'), Player(name: 'C')];
      await pumpSheet(tester, players, current: 1);
      expect(topOf(tester, 'B'), lessThan(topOf(tester, 'C')));
      expect(topOf(tester, 'C'), lessThan(topOf(tester, 'A')));
    });

    testWidgets('un adversaire montre les 3 lignes barrables au-dessus du potentiel, celle qu\'on barre en évidence',
        (tester) async {
      final me = Player(name: 'Moi', totalScore: 2300, hasEntered: true);
      // Lignes 500, 1500, 2800, 3000, 3100 (courante).
      final alice = [500, 1000, 1300, 200, 100].fold(Player(name: 'Alice'), (p, v) => p.applySuccessfulTurn(v));
      await pumpSheet(tester, [me, alice], current: 0, potential: 2800);

      final radar = find.descendant(of: _rowOf('Alice'), matching: find.textContaining('2800 · 3000 · 3100'));
      expect(radar, findsOneWidget);
      // La ligne 2800 est celle que la main barrerait en s'arrêtant là.
      final span = (tester.widget<Text>(radar).textSpan! as TextSpan).children!.first as TextSpan;
      expect(span.text, '2800');
      expect(span.style?.color, Colors.redAccent);
      // Le score précédent entre parenthèses ne vaut que pour le joueur courant.
      expect(find.descendant(of: _rowOf('Alice'), matching: find.textContaining('(')), findsNothing);
    });

    testWidgets('sans ligne barrable, l\'adversaire montre l\'écart à la main en cours', (tester) async {
      final me = Player(name: 'Moi', totalScore: 2300, hasEntered: true);
      final bob = Player(name: 'Bob').applySuccessfulTurn(1800);
      await pumpSheet(tester, [me, bob], current: 0, potential: 2750);
      expect(find.descendant(of: _rowOf('Bob'), matching: find.text('\u2212950')), findsOneWidget);
    });

    testWidgets('les indices d\'écart de 200 ne restent que sur la ligne du joueur courant', (tester) async {
      final players = [
        Player(name: 'A', totalScore: 800, hasEntered: true),
        Player(name: 'B', totalScore: 1000, hasEntered: true),
      ];
      await pumpSheet(tester, players, current: 1);
      // B (courant) est à 200 au-dessus de A : danger chez lui ; A n'a plus d'indice.
      expect(find.descendant(of: _rowOf('B'), matching: find.byIcon(Icons.warning_amber_rounded)), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsNothing);
    });
  });
}
