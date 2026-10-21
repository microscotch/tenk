import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/ui/widgets/score_sheet.dart';

/// La ligne (le [Container]) affichant le nom [playerName], pour vérifier
/// les hints propres à ce joueur plutôt que ceux de toute la feuille de
/// score.
Finder _rowOf(String playerName) => find.ancestor(of: find.text(playerName), matching: find.byType(Container)).first;

void main() {
  testWidgets('signale un écart de 200 : danger pour celui au-dessus, opportunité pour celui en dessous', (
    tester,
  ) async {
    final players = [
      Player(name: 'A', totalScore: 800, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(players: players, currentPlayerIndex: 0),
      ),
    );

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

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(players: players, currentPlayerIndex: 0),
      ),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.gps_fixed), findsNothing);
  });

  testWidgets('un joueur courant encadré par deux écarts de 200 cumule les deux hints', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 800, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
      Player(name: 'C', totalScore: 1200, hasEntered: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(players: players, currentPlayerIndex: 1),
      ),
    );

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

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(players: [a], currentPlayerIndex: 0),
      ),
    );

    expect(find.text('800'), findsOneWidget);
    expect(
      find.textContaining('500'),
      findsOneWidget,
      reason: 'le score précédent apparaît en petit après le séparateur',
    );

    // Le tiret doit être DANS la parenthèse, donc porté par ce même widget de
    // texte, et non posé à côté : sinon il se lit comme qualifiant le score
    // courant affiché juste avant.
    expect(
      find.descendant(of: find.textContaining('500'), matching: find.byIcon(Icons.remove)),
      findsOneWidget,
      reason: 'la ligne précédente portait un tiret, marqué dans le même texte que ce score',
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

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(players: [a], currentPlayerIndex: 0),
      ),
    );

    expect(find.text('300'), findsOneWidget);
    expect(find.text('0'), findsOneWidget, reason: 'la ligne 500 est barrée : on remonte jusqu\'à 0');
    expect(find.text('500'), findsNothing);
  });

  testWidgets('un joueur cliqué déclenche onTapPlayer avec ce joueur', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 100, hasEntered: true),
      Player(name: 'B', totalScore: 200, hasEntered: true),
    ];
    Player? tapped;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(players: players, currentPlayerIndex: 0, onTapPlayer: (p) => tapped = p),
      ),
    );

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

    Color medalColorIn(WidgetTester tester, String playerName) =>
        tester.widget<Icon>(find.descendant(of: _rowOf(playerName), matching: find.byIcon(Icons.military_tech))).color!;

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

      expect(
        find.byIcon(Icons.military_tech),
        findsNothing,
        reason: 'tout le monde à 0 en début de partie : personne n\'est en tête',
      );
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

  group('liste statique et écarts', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      List<Player> players, {
      required int current,
      int? potential,
      bool handRevealed = true,
    }) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScoreSheet(
            players: players,
            currentPlayerIndex: current,
            potentialTotal: potential,
            handRevealed: handRevealed,
          ),
        ),
      ),
    );

    double topOf(WidgetTester tester, String name) => tester.getTopLeft(find.text(name)).dy;

    testWidgets('l\'ordre ne change pas quand le tour passe', (tester) async {
      final players = [Player(name: 'A'), Player(name: 'B'), Player(name: 'C')];
      await pumpSheet(tester, players, current: 1);
      expect(topOf(tester, 'A'), lessThan(topOf(tester, 'B')));
      expect(topOf(tester, 'B'), lessThan(topOf(tester, 'C')));
    });

    testWidgets('seul le nom du joueur courant est en gras', (tester) async {
      await pumpSheet(tester, [Player(name: 'A'), Player(name: 'B')], current: 1);
      expect(tester.widget<Text>(find.text('A')).style?.fontWeight, FontWeight.normal);
      expect(tester.widget<Text>(find.text('B')).style?.fontWeight, FontWeight.bold);
    });

    testWidgets('le joueur courant montre son total potentiel puis son score précédent', (tester) async {
      final me = Player(name: 'Moi').applySuccessfulTurn(1000);
      await pumpSheet(tester, [me], current: 0, potential: 1400);
      expect(find.text('1400'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('un adversaire en rouge et en gras si un arrêt le barrerait, puis l\'écart au premier barrable', (
      tester,
    ) async {
      final me = Player(name: 'Moi', totalScore: 2200, hasEntered: true);
      final bob = [
        2400,
        200,
        200,
        800,
      ].fold(Player(name: 'Bob'), (p, v) => p.applySuccessfulTurn(v)); // 2400 2600 2800 3600
      await pumpSheet(tester, [me, bob], current: 0, potential: 2400);
      // 2400 : ligne barrable, mais pas son score (3600) : pas de rouge ; l'écart
      // nul laisse la place au score barrable, en rouge.
      final barrable = tester.widget<Text>(find.descendant(of: _rowOf('Bob'), matching: find.text(' · 2400')));
      expect(barrable.style?.color, Colors.redAccent);
      expect(tester.widget<Text>(find.descendant(of: _rowOf('Bob'), matching: find.text('3600'))).style?.color, isNull);

      await pumpSheet(tester, [me, bob], current: 0, potential: 3600);
      final score = tester.widget<Text>(find.descendant(of: _rowOf('Bob'), matching: find.text('3600')));
      expect((score.style?.color, score.style?.fontWeight), (Colors.redAccent, FontWeight.bold));
    });

    testWidgets('la couleur attend les dés de la main', (tester) async {
      final me = Player(name: 'Moi', totalScore: 2200, hasEntered: true);
      final bob = Player(name: 'Bob').applySuccessfulTurn(2400);
      await pumpSheet(tester, [me, bob], current: 0, potential: 2400, handRevealed: false);
      expect(tester.widget<Text>(find.descendant(of: _rowOf('Bob'), matching: find.text('2400'))).style?.color, isNull);
    });

    testWidgets('au-dessus du score de l\'adversaire : écart négatif signé', (tester) async {
      final me = Player(name: 'Moi', totalScore: 2300, hasEntered: true);
      final bob = Player(name: 'Bob').applySuccessfulTurn(1800);
      await pumpSheet(tester, [me, bob], current: 0, potential: 2750);
      expect(find.descendant(of: _rowOf('Bob'), matching: find.text(' · \u2212950')), findsOneWidget);
    });

    testWidgets('le nom d\'un adversaire n\'est pas rogné tant qu\'il y a la place : le score ne prend que sa largeur',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // La police des tests est large : ce nom court tient largement, avec la
      // médaille, le score et l'écart, dans cette largeur.
      await tester.binding.setSurfaceSize(const Size(480, 800));
      final me = Player(name: 'Moi', totalScore: 2300, hasEntered: true);
      final other = Player(name: 'Alex').applySuccessfulTurn(7800);
      await pumpSheet(tester, [me, other], current: 0, potential: 2750);
      expect(tester.renderObject<RenderParagraph>(find.text('Alex')).didExceedMaxLines, isFalse);
    });

    testWidgets('les indices d\'écart de 200 ne restent que sur la ligne du joueur courant', (tester) async {
      final players = [
        Player(name: 'A', totalScore: 800, hasEntered: true),
        Player(name: 'B', totalScore: 1000, hasEntered: true),
      ];
      await pumpSheet(tester, players, current: 1);
      expect(find.descendant(of: _rowOf('B'), matching: find.byIcon(Icons.warning_amber_rounded)), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsNothing);
    });
  });
}
