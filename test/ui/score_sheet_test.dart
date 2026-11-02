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
  testWidgets('en ligne, chaque écran lit le radar depuis son siège (J1 joue, 200 de main)', (tester) async {
    Player grid(String name, List<int> lines) {
      var player = Player(name: name, totalScore: lines.first, hasEntered: true);
      for (final line in lines.skip(1)) {
        player = player.applySuccessfulTurn(line - player.totalScore);
      }
      return player;
    }

    final players = [
      grid('J1', [800, 1300, 1500]),
      grid('J2', [500, 700, 1000]),
      grid('J3', [900, 1900, 2000]),
    ];

    Future<void> seenFrom(int me, {required int j1Potential}) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ScoreSheet(
            players: players,
            currentPlayerIndex: 0,
            referenceIndex: me,
            potentialTotal: me == 0 ? j1Potential : players[me].totalScore,
            currentPotentialTotal: me == 0 ? null : j1Potential,
          ),
        ),
      );
    }

    bool shows(String name, String text) =>
        find.descendant(of: _rowOf(name), matching: find.text(text)).evaluate().isNotEmpty;

    // J2 : J1 montre son total en direct (1700) et son avance sur moi (+700) ;
    // ma ligne, mon score et le précédent.
    await seenFrom(1, j1Potential: 1700);
    expect(shows('J1', '1700') && shows('J1', '700 devant'), isTrue);
    await seenFrom(1, j1Potential: 1900);
    expect(shows('J1', '1900') && shows('J1', '900 devant'), isTrue, reason: 'l\'écart suit la main à chaque lancer');
    await seenFrom(1, j1Potential: 1700);
    expect(shows('J2', '1000') && shows('J2', '700'), isTrue);
    expect(shows('J3', '2000') && shows('J3', '900 devant'), isTrue);

    // J3 : J1 est à 1700, soit 300 sous mon 2000 ; J2 à 1000 de moins.
    await seenFrom(2, j1Potential: 1700);
    expect(shows('J1', '1700') && shows('J1', '300 derrière'), isTrue);
    expect(shows('J2', '1000') && shows('J2', '1000 derrière'), isTrue);
    expect(shows('J3', '2000') && shows('J3', '1900'), isTrue);

    // J1 : ma ligne, 1700 puis mon dernier score non barré sous lui (1500).
    await seenFrom(0, j1Potential: 1700);
    expect(shows('J1', '1700') && shows('J1', '1500'), isTrue);
  });

  testWidgets('en ligne, la ligne de celui qui joue suit sa main en direct (currentPotentialTotal)', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 800, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
    ];

    // Je suis A ; B joue et a 350 de main : sa ligne montre 1350, la mienne reste à 800.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(
          players: players,
          currentPlayerIndex: 1,
          referenceIndex: 0,
          potentialTotal: 800,
          currentPotentialTotal: 1350,
        ),
      ),
    );

    expect(find.descendant(of: _rowOf('B'), matching: find.text('1350')), findsOneWidget);
    expect(find.descendant(of: _rowOf('A'), matching: find.text('800')), findsOneWidget);
  });

  testWidgets('en ligne, le radar se lit depuis moi (referenceIndex), pas depuis le joueur dont c\'est le tour', (
    tester,
  ) async {
    final players = [
      Player(name: 'A', totalScore: 800, hasEntered: true),
      Player(name: 'B', totalScore: 1000, hasEntered: true),
      Player(name: 'C', totalScore: 2000, hasEntered: true),
    ];

    // C'est à B de jouer, mais je suis A : son potentiel est son score, et les
    // écarts des autres se comptent depuis lui.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(players: players, currentPlayerIndex: 1, referenceIndex: 0, potentialTotal: 800),
      ),
    );

    // Mon écart de 200 avec B est signalé sur MA ligne, pas sur celle de B.
    expect(find.descendant(of: _rowOf('A'), matching: find.byIcon(Icons.gps_fixed)), findsOneWidget);
    expect(find.descendant(of: _rowOf('B'), matching: find.byIcon(Icons.gps_fixed)), findsNothing);
    // Ma ligne montre mon total potentiel ; celle de B, son score et son écart avec moi.
    expect(find.descendant(of: _rowOf('A'), matching: find.text('800')), findsOneWidget);
    expect(find.descendant(of: _rowOf('B'), matching: find.text('1000')), findsOneWidget);
    expect(find.descendant(of: _rowOf('B'), matching: find.text('200 devant')), findsOneWidget);
    expect(find.descendant(of: _rowOf('C'), matching: find.text('1200 devant')), findsOneWidget);
  });

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

  testWidgets('les indices de 200 se lisent sur le total potentiel, pas sur le score', (tester) async {
    final players = [
      Player(name: 'A', totalScore: 800, hasEntered: true),
      Player(name: 'B', totalScore: 1200, hasEntered: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ScoreSheet(players: players, currentPlayerIndex: 0, potentialTotal: 1000),
      ),
    );

    // A est à 800 (400 sous B), mais 1000 avec sa main : B est à 200.
    expect(find.descendant(of: _rowOf('A'), matching: find.byIcon(Icons.gps_fixed)), findsOneWidget);
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

    // Le tiret est dans la case du score précédent, à sa droite : il ne se lit
    // pas comme qualifiant le score courant affiché avant.
    expect(
      find.descendant(of: _rowOf('A'), matching: find.byIcon(Icons.remove)),
      findsOneWidget,
      reason: 'la ligne précédente portait un tiret, à droite de ce score',
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
      Locale? locale,
    }) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
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
      // Deux « 2400 » : le score de Bob (gris) puis, dans l'écart, le score barrable.
      final barrable = tester.widgetList<Text>(find.descendant(of: _rowOf('Bob'), matching: find.text('2400'))).last;
      expect(barrable.style?.color, Colors.redAccent);
      expect(tester.widget<Text>(find.descendant(of: _rowOf('Bob'), matching: find.text('3600'))).style?.color, isNull);

      await pumpSheet(tester, [me, bob], current: 0, potential: 3600);
      final score = tester.widgetList<Text>(find.descendant(of: _rowOf('Bob'), matching: find.text('3600'))).first;
      expect((score.style?.color, score.style?.fontWeight), (Colors.redAccent, FontWeight.bold));
    });

    testWidgets('la couleur attend les dés de la main', (tester) async {
      final me = Player(name: 'Moi', totalScore: 2200, hasEntered: true);
      final bob = Player(name: 'Bob').applySuccessfulTurn(2400);
      await pumpSheet(tester, [me, bob], current: 0, potential: 2400, handRevealed: false);
      expect(tester.widgetList<Text>(find.descendant(of: _rowOf('Bob'), matching: find.text('2400'))).first.style?.color, isNull);
    });

    testWidgets('au-dessus du score de l\'adversaire : écart négatif signé', (tester) async {
      final me = Player(name: 'Moi', totalScore: 2300, hasEntered: true);
      final bob = Player(name: 'Bob').applySuccessfulTurn(1800);
      await pumpSheet(tester, [me, bob], current: 0, potential: 2750);
      expect(find.descendant(of: _rowOf('Bob'), matching: find.text('950 derrière')), findsOneWidget);
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

    testWidgets('la zone chiffrée ne bouge pas, quelles que soient les valeurs affichées', (tester) async {
      Future<(double, double, double)> edges(int bobScore, int potential) async {
        final me = Player(name: 'Moi', totalScore: 2200, hasEntered: true);
        final bob = Player(name: 'Bob', totalScore: bobScore, hasEntered: true);
        await pumpSheet(tester, [me, bob], current: 0, potential: potential);
        final row = _rowOf('Bob');
        final bobRight = tester.getTopRight(find.descendant(of: row, matching: find.text('$bobScore'))).dx;
        // L'écart, écrit « N devant » / « N derrière » (ou « 0 »).
        final gapText = find.descendant(
          of: row,
          matching: find.byWidgetPredicate((w) => w is Text && RegExp(r'devant|derrière').hasMatch(w.data ?? '')),
        );
        final meRow = _rowOf('Moi');
        final potentialRight = tester.getTopRight(find.descendant(of: meRow, matching: find.text('$potential'))).dx;
        return (bobRight, tester.getTopRight(gapText).dx, potentialRight);
      }

      final a = await edges(500, 2300);
      final b = await edges(9950, 2750);
      final c = await edges(1000, 3000);
      // Le bord droit du score (adversaire comme joueur courant) est le même.
      expect(b.$1, a.$1);
      expect(c.$1, a.$1);
      expect(b.$3, a.$3);
      expect(c.$3, a.$3);
      // Celui de l'écart aussi, quand il y en a un.
      expect(b.$2, a.$2);
    });

    testWidgets('le score et l\'écart sont l\'un au-dessus de l\'autre, alignés à droite, sans changer la hauteur des lignes', (
      tester,
    ) async {
      final me = Player(name: 'Moi', totalScore: 2300, hasEntered: true);
      final bob = Player(name: 'Bob').applySuccessfulTurn(1800);
      await pumpSheet(tester, [me, bob], current: 0, potential: 2750);
      final row = _rowOf('Bob');
      final score = find.descendant(of: row, matching: find.text('1800'));
      final gap = find.descendant(of: row, matching: find.text('950 derrière'));
      expect(tester.getTopRight(gap).dx, tester.getTopRight(score).dx);
      expect(tester.getTopLeft(gap).dy, greaterThan(tester.getBottomLeft(score).dy - 1));
      // 47,6 : la hauteur d'une ligne avant que le score et l'écart ne passent
      // l'un sous l'autre (un score seul, 10 de marge dessus et dessous).
      for (final name in ['Moi', 'Bob']) {
        final inkWell = find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first;
        expect(tester.getSize(inkWell).height, closeTo(47.6, 0.01), reason: 'la ligne de $name');
      }
    });

    testWidgets('l\'écart d\'un adversaire s\'écrit « N devant » ou « N derrière », comme dans la grille', (tester) async {
      final me = Player(name: 'Moi', totalScore: 2300, hasEntered: true);
      final ahead = Player(name: 'Devant').applySuccessfulTurn(5000);
      final behind = Player(name: 'Derriere').applySuccessfulTurn(1800);
      await pumpSheet(tester, [me, ahead, behind], current: 0, potential: 2750, locale: const Locale('fr'));
      expect(find.descendant(of: _rowOf('Devant'), matching: find.text('2250 devant')), findsOneWidget);
      expect(find.descendant(of: _rowOf('Derriere'), matching: find.text('950 derrière')), findsOneWidget);
    });
  });
}
