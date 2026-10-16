import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/score_grid_screen.dart';
import 'package:le10000/ui/widgets/player_avatar.dart';

/// Trouve le blason affiché pour le joueur [name] (voir [PlayerAvatarWidget]) :
/// remplace les anciennes recherches par texte d'initiales dans ces tests.
Finder _avatarFor(String name) =>
    find.byWidgetPredicate((w) => w is PlayerAvatarWidget && w.name == name);

void main() {
  testWidgets('affiche chaque ligne de la grille avec son tiret ou son barré propre, sans doublon', (tester) async {
    var a = Player(name: 'A').applySuccessfulTurn(500); // ligne : 500
    a = a.applyBust(); // tiret sur 500
    a = a.applySuccessfulTurn(300); // nouvelle ligne : 800, sans tiret
    a = a.applyBust(); // tiret sur 800
    a = a.applyBust(); // 800 barré, retombe sur la ligne 500 déjà existante

    await tester.pumpWidget(MaterialApp(home: ScoreGridScreen(players: [a]), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales));
    await tester.pumpAndSettle();

    // Grille attendue : [0, 500(tiret, courante), 800(tiret, barré)] — pas de
    // ligne dupliquée pour le retour à 500.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('800'), findsOneWidget);

    // Seule la ligne 500 montre son tiret : celui de 800 a disparu avec le
    // barrage, l'avertissement n'ayant plus lieu d'être une fois la sanction
    // tombée.
    expect(find.byIcon(Icons.remove), findsOneWidget);

    final texts = tester.widgetList<Text>(find.text('800'));
    expect(texts.single.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('la grille d\'un seul joueur garde la couleur de blason de la partie', (tester) async {
    // 'Random Dent' et 'Lolo' réclament la même couleur naturelle : dans une
    // partie, le premier la garde et le second est décalé. Affichée seule, la
    // grille du second lui rendait cette couleur — celle du premier joueur.
    final ia = Player(name: 'Random Dent');
    final moi = Player(name: 'Lolo');
    final couleurDeLaPartie = assignAvatarColors([ia.name, moi.name])[moi.name];

    expect(couleurDeLaPartie, isNot(avatarColorFor(moi.name)),
        reason: 'ces deux noms doivent bien entrer en collision, sinon le test ne prouve rien');

    await tester.pumpWidget(MaterialApp(
      home: ScoreGridScreen(players: [moi], roster: [ia, moi]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();

    final blason = tester.widget<PlayerAvatarWidget>(_avatarFor(moi.name));
    expect(blason.color, couleurDeLaPartie,
        reason: 'le blason doit être le même ici que partout ailleurs dans le jeu');
  });

  testWidgets('une ligne barrée n\'affiche plus son tiret', (tester) async {
    // 700 tiretée puis barrée par un second craque : le barré remplace
    // l'avertissement, il ne s'y ajoute pas.
    var a = Player(name: 'A').applySuccessfulTurn(700);
    a = a.applyBust(); // tiret sur 700
    a = a.applyBust(); // 700 barré

    await tester.pumpWidget(MaterialApp(
      home: ScoreGridScreen(players: [a]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();

    final barred = a.grid.firstWhere((e) => e.value == 700);
    expect(barred.isBarred, isTrue);
    expect(barred.hasTiret, isTrue, reason: 'le tiret reste dans le modèle, seul l\'affichage le masque');
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets(
      'un score barré par collision affiche le blason de l\'auteur du barrage, pas celui du propriétaire de la colonne',
      (tester) async {
    // Alice a 700 ; Bob vient de banquer exactement 700 lui aussi, ce qui
    // barre la ligne d'Alice. Le blason à côté de ce score barré doit être
    // celui de BOB (l'auteur de la collision), pas celui d'Alice.
    final alice = Player(name: 'Alice').applySuccessfulTurn(700).applyScoreCollisionBarAt(
          700,
          barredByName: 'Bob',
        );
    final bob = Player(name: 'Bob').applySuccessfulTurn(700);

    await tester.pumpWidget(
      MaterialApp(
        home: ScoreGridScreen(players: [alice, bob]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    expect(alice.grid.last.isBarred, isTrue);
    expect(alice.grid.last.barredBy, 'Bob');

    // Le blason de Bob apparaît deux fois : son entête de colonne, et
    // l'auteur du barrage dans la colonne d'Alice. Celui d'Alice n'apparaît
    // qu'une fois : son propre entête -- jamais comme auteur de son propre
    // barrage, puisque ce n'est pas elle qui l'a causé.
    expect(_avatarFor('Bob'), findsNWidgets(2), reason: 'entête de colonne + auteur du barrage chez Alice');
    expect(_avatarFor('Alice'), findsOneWidget, reason: 'seulement son entête : elle n\'a pas causé son propre barrage');
  });

  testWidgets(
      'un score barré par un second craque affiche le blason du joueur lui-même',
      (tester) async {
    // Cas symétrique : un craque sur une ligne déjà tiretée se barre
    // lui-même (voir Player.applyBust) -- le blason affiché doit alors être
    // le sien, pas celui d'un autre joueur.
    var alice = Player(name: 'Alice').applySuccessfulTurn(700);
    alice = alice.applyBust(); // tiret sur 700
    alice = alice.applySuccessfulTurn(300); // 700 -> 1000, nouvelle ligne
    alice = alice.applyBust(); // tiret sur 1000
    alice = alice.applyBust(); // 1000 barré -> retombe sur 700

    await tester.pumpWidget(
      MaterialApp(
        home: ScoreGridScreen(players: [alice]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    final barredEntry = alice.grid.firstWhere((e) => e.value == 1000);
    expect(barredEntry.isBarred, isTrue);
    expect(barredEntry.barredBy, 'Alice');

    // Un seul joueur dans cette partie : le blason d'Alice apparaît deux
    // fois -- son entête de colonne, et l'auteur de son propre barrage.
    expect(_avatarFor('Alice'), findsNWidgets(2));
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
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grille des scores'));
    await tester.pumpAndSettle();

    expect(find.byType(ScoreGridScreen), findsOneWidget);
  });

  testWidgets('affiche une colonne par joueur, avec son blason comme entête', (tester) async {
    final players = [Player(name: 'Alice'), Player(name: 'Bob')];

    await tester.pumpWidget(MaterialApp(home: ScoreGridScreen(players: players), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales));
    await tester.pumpAndSettle();

    expect(_avatarFor('Alice'), findsOneWidget);
    expect(_avatarFor('Bob'), findsOneWidget);
  });

  testWidgets('un clic sur la ligne d\'un joueur ouvre sa grille seule, avec son blason en entête',
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
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.byType(ScoreGridScreen), findsOneWidget);
    expect(_avatarFor('Bob'), findsOneWidget);
    expect(_avatarFor('Alice'), findsNothing, reason: 'la grille est filtrée sur ce seul joueur');
  });

  testWidgets('bascule en carrousel paginé quand toutes les colonnes ne tiennent pas sur une page',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 800));

    // Chaque grille occupe la moitié de la largeur : 2 par page, donc 3 pages
    // pour 6 joueurs.
    final players = [for (var i = 0; i < 6; i++) Player(name: 'J$i')];

    await tester.pumpWidget(MaterialApp(home: ScoreGridScreen(players: players), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales));
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    expect(_avatarFor('J0'), findsOneWidget);
    expect(_avatarFor('J1'), findsOneWidget);
    expect(_avatarFor('J2'), findsNothing, reason: 'pas encore visible : sur la deuxième page');

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(_avatarFor('J2'), findsOneWidget);
    expect(_avatarFor('J0'), findsNothing, reason: 'la première page a défilé hors champ');
  });

  testWidgets('pas de carrousel quand toutes les colonnes tiennent sur une seule page', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 800));

    final players = [Player(name: 'Alice'), Player(name: 'Bob')];

    await tester.pumpWidget(MaterialApp(home: ScoreGridScreen(players: players), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales));
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsNothing);
    expect(_avatarFor('Alice'), findsOneWidget);
    expect(_avatarFor('Bob'), findsOneWidget);
  });

  group('largeur, centrage et écarts', () {
    Future<void> pump(WidgetTester tester, Widget screen) => tester.pumpWidget(MaterialApp(
          home: screen,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ));

    Finder rowOf(String score) => find.ancestor(of: find.text(score), matching: find.byType(Container)).first;

    testWidgets('une grille seule occupe la moitié de la largeur et se centre', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await pump(tester, ScoreGridScreen(players: [Player(name: 'Alice').applySuccessfulTurn(500)]));

      final row = tester.getRect(rowOf('500'));
      expect(row.center.dx, closeTo(200, 1), reason: 'centrée horizontalement');
      expect(row.width, closeTo(184 - 8, 1), reason: 'la moitié de la largeur utile');
      expect(tester.getTopLeft(find.text('500')).dx - row.left, lessThan(20), reason: 'score aligné à gauche');
    });

    testWidgets('deux grilles se partagent chacune la moitié de la largeur', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await pump(
        tester,
        ScoreGridScreen(players: [Player(name: 'Alice').applySuccessfulTurn(500), Player(name: 'Bob').applySuccessfulTurn(700)]),
      );

      expect(tester.getRect(rowOf('500')).center.dx, closeTo(108, 1));
      expect(tester.getRect(rowOf('700')).center.dx, closeTo(292, 1));
    });

    testWidgets('chaque colonne porte le blason et le surnom, le nom à défaut', (tester) async {
      await pump(
        tester,
        ScoreGridScreen(players: [Player(name: 'Alice'), Player(name: 'Bob')], displayNames: const {'Alice': 'Lili'}),
      );
      expect(find.text('Lili'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('un nom trop long est tronqué dans la grille complète, entier et centré dans une grille seule',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(400, 800));
      const long = 'Un pseudo vraiment très très long';
      await pump(
        tester,
        ScoreGridScreen(players: [Player(name: 'Alice'), Player(name: 'Bob')], displayNames: const {'Alice': long}),
      );
      expect(tester.widget<Text>(find.text(long)).overflow, TextOverflow.ellipsis);

      await pump(tester, ScoreGridScreen(players: [Player(name: 'Alice')], displayNames: const {'Alice': long}));
      expect(tester.widget<Text>(find.text(long)).overflow, TextOverflow.visible);
      final header = tester.getRect(find.text(long));
      final avatar = tester.getRect(find.byType(PlayerAvatarWidget));
      expect((avatar.left + header.right) / 2, closeTo(200, 2), reason: 'blason + nom centrés sur tout l\'écran');
    });

    testWidgets('l\'écart avec le total potentiel : valeur absolue, devant ou derrière', (tester) async {
      final alice = Player(name: 'Alice').applySuccessfulTurn(1000);
      final bob = Player(name: 'Bob').applySuccessfulTurn(500).applySuccessfulTurn(700); // 0, 500, 1200
      await pump(tester, ScoreGridScreen(players: [alice, bob], reference: alice, potentialTotal: 1000));

      expect(find.text('200 devant'), findsOneWidget, reason: '1200 - 1000');
      expect(find.text('500 derrière'), findsOneWidget, reason: '500 - 1000');
      expect(find.text('1000 derrière'), findsOneWidget, reason: 'la ligne 0 de Bob');
    });

    testWidgets('pas d\'écart sur une ligne barrée', (tester) async {
      final alice = Player(name: 'Alice').applySuccessfulTurn(1000);
      final bob = Player(name: 'Bob').applySuccessfulTurn(500).applyBust().applyBust(); // 500 barrée
      await pump(tester, ScoreGridScreen(players: [alice, bob], reference: alice, potentialTotal: 1000));

      expect(find.text('500 derrière'), findsNothing);
      expect(find.text('1000 derrière'), findsOneWidget, reason: 'seule la ligne 0, non barrée, garde son écart');
    });

    testWidgets('écart nul : le score passe en rouge seulement si la main est prenable', (tester) async {
      final alice = Player(name: 'Alice').applySuccessfulTurn(1000);
      final bob = Player(name: 'Bob').applySuccessfulTurn(1200);
      Color? colorOf() => tester.widget<Text>(find.text('1200')).style?.color;

      await pump(tester, ScoreGridScreen(players: [alice, bob], reference: alice, potentialTotal: 1200));
      expect(find.text('0'), findsWidgets);
      expect(colorOf(), isNot(Colors.redAccent), reason: 'main non prenable : pas d\'alerte');

      await pump(tester, ScoreGridScreen(players: [alice, bob], reference: alice, potentialTotal: 1200, handBankable: true));
      expect(colorOf(), Colors.redAccent);
    });

    testWidgets('sans joueur de référence, aucun écart', (tester) async {
      await pump(tester, ScoreGridScreen(players: [Player(name: 'Alice').applySuccessfulTurn(1000)]));
      expect(find.textContaining('devant'), findsNothing);
      expect(find.textContaining('derrière'), findsNothing);
    });
  });
}
