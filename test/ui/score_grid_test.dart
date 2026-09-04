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
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_on));
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

    // Largeur utile ~368 (400 - marges) / largeur mini de colonne 108 -> 3
    // colonnes par page, donc 2 pages pour 6 joueurs.
    final players = [for (var i = 0; i < 6; i++) Player(name: 'J$i')];

    await tester.pumpWidget(MaterialApp(home: ScoreGridScreen(players: players), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales));
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    expect(_avatarFor('J0'), findsOneWidget);
    expect(_avatarFor('J3'), findsNothing, reason: 'pas encore visible : sur la deuxième page');

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(_avatarFor('J3'), findsOneWidget);
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
}
