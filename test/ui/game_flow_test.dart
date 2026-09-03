import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/pass_device_screen.dart';
import 'package:le10000/ui/widgets/player_avatar.dart';

import '../test_helpers/scripted_game.dart';

/// Ces scénarios (craque, victoire) sont difficiles à obtenir de façon
/// fiable via de vrais lancers aléatoires en un temps raisonnable ; on
/// charge donc directement un [GameEngine] pré-construit via
/// [GameNotifier.debugLoadState] pour exercer les mêmes écrans que ceux
/// utilisés en jeu réel.
///
/// Marge au-dessus du délai par défaut réglé dans les préférences : assez
/// pour laisser UNE étape automatique se déclencher, mais pas assez pour
/// qu'une deuxième s'enchaîne dans le même pump (sinon un test qui vérifie
/// l'état juste après une seule étape deviendrait dépendant du hasard).
final _autoActionPump = const AppSettings().autoActionDelay + const Duration(milliseconds: 100);
final _aiStepPump = const AppSettings().aiMessageDelay + const Duration(milliseconds: 100);

void main() {
  testWidgets('un craque affiche l\'écran "Craqué !" puis passe la main avec un tiret', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      // Score déjà entamé : un craque à 0 ne marque plus jamais de tiret
      // (voir le test dédié plus bas), donc ce scénario générique a besoin
      // d'un score non nul pour exercer le marquage normal.
      players: [Player(name: 'A', totalScore: 700, hasEntered: true), Player(name: 'B')],
      activeTurn: TurnState(
        diceToRoll: 3,
        pendingRoll: analyzeRoll([2, 3, 4]), // aucun dé marquant
        busted: true,
      ),
    );
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
    await tester.pump();

    // Le message ne doit pas gâcher le suspense : il n'apparaît pas tant que
    // l'animation de lancer des dés n'est pas terminée.
    expect(find.textContaining('Craqué'), findsNothing);

    await tester.pumpAndSettle();

    // Le message est désormais visible à deux endroits une fois révélé : le
    // journal de partie ET le bouton lui-même (voir CLAUDE.md, libellés
    // contextuels).
    expect(find.textContaining('Craqué'), findsWidgets);

    await tester.tap(find.text('Craqué !'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.currentPlayerIndex, 1, reason: 'la main doit passer au joueur B');
    expect(after.players[0].hasTiret, isTrue, reason: 'le craque doit marquer un tiret sur A');
    expect(after.players[0].totalScore, 700, reason: 'le craque ne doit pas changer le score déjà acquis');
  });

  testWidgets('un craque à 0 n\'affiche jamais de tiret (rien à sanctionner en dessous du plancher)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(
        diceToRoll: 3,
        pendingRoll: analyzeRoll([2, 3, 4]), // aucun dé marquant
        busted: true,
      ),
    );
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

    await tester.tap(find.text('Craqué !'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.players[0].hasTiret, isFalse, reason: 'un craque à 0 ne marque jamais de tiret');
    expect(after.players[0].totalScore, 0);
  });

  testWidgets(
      'un craque par dépassement de 10000 (sans lancer en attente) ne plante pas et sanctionne le joueur',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A a 9900 points ; la décision de garde qui vient d'être appliquée
    // ajoute 200 points, détectés en trop par GameEngine.applyKeep : le tour
    // est marqué craqué SANS lancer en attente (contrairement à un craque
    // classique où aucun dé ne marque, qui garde le lancer pour l'afficher).
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 9900, hasEntered: true), Player(name: 'B')],
      activeTurn: const TurnState(
        diceToRoll: 3,
        bankedScore: 200,
        busted: true,
        hasRolledThisTurn: true,
        keptDiceThisTurn: [
          KeptDie(value: 1, points: 100, isExtended: false),
          KeptDie(value: 1, points: 100, isExtended: false),
        ],
      ),
    );
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
    // Pas de lancer à animer pour ce type de craque : révélation immédiate.
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'ne doit pas planter faute de lancer en attente');
    expect(find.textContaining('Craqué'), findsWidgets);

    await tester.tap(find.text('Craqué !'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.currentPlayerIndex, 1, reason: 'la main doit passer au joueur B');
    expect(after.players[0].hasTiret, isTrue, reason: 'le craque doit marquer un tiret sur A');
    expect(after.players[0].totalScore, 9900, reason: 'le craque ne doit pas changer le score déjà acquis');
    expect(after.nextTurnDice, 5, reason: 'un craque ne transmet jamais de main héritée au joueur suivant');
    expect(after.inheritedScore, 0);
  });

  testWidgets('main héritée qui dépasserait déjà 10000 : "Continuer" n\'est pas proposé', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A a 9700 points, le tour précédent laisse un score hérité de 700 :
    // 9700 + 700 = 10400 > 10000, reprendre cette main ne pourrait plus
    // jamais aboutir à un banquage réussi.
    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 9700, hasEntered: true), Player(name: 'B')],
      nextTurnDice: 3,
      inheritedScore: 700,
    );
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

    expect(find.widgetWithIcon(FilledButton, Icons.casino), findsNothing,
        reason: 'reprendre cette main garantirait un dépassement de 10000');
    expect(find.text('Refuser'), findsOneWidget);
    expect(find.textContaining('dépasserait déjà 10000'), findsOneWidget);
  });

  testWidgets('un second craque barre le score : le tiret disparaît et le score retombe', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A porte déjà un tiret (posé quand son score était 700) et a depuis
    // validé un tour de 300 points ; il craque une seconde fois.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 1000, previousScore: 700, hasEntered: true, hasTiret: true),
        Player(name: 'B'),
      ],
      currentPlayerIndex: 0,
      activeTurn: TurnState(
        diceToRoll: 4,
        pendingRoll: analyzeRoll([2, 3, 4, 6]), // aucun dé marquant
        busted: true,
      ),
    );
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

    // Avant le second craque : le score affiché est 1000, avec le tiret visible.
    expect(find.text('1000'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high), findsOneWidget);
    expect(find.textContaining('Craqué'), findsWidgets);

    await tester.tap(find.text('Craqué !'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.players[0].totalScore, 700, reason: 'retombe au dernier score non barré');
    expect(after.players[0].hasTiret, isFalse, reason: 'le tiret est consommé par le barrage');
    expect(after.currentPlayerIndex, 1);
  });

  testWidgets('une collision de score barre l\'autre joueur, visible sur la feuille de score', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A est à 2000 (avec un tiret actif). B va banquer un tour qui l'amène
    // aussi à 2000 : la collision doit barrer A (retour à 1800) et effacer
    // son tiret, même si ce n'est pas lui qui vient de jouer.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 2000, previousScore: 1800, hasEntered: true, hasTiret: true),
        Player(name: 'B', totalScore: 1500, hasEntered: true),
      ],
      currentPlayerIndex: 1,
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 500, hasRolledThisTurn: true), // B : 1500 -> 2000
    );
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

    // Avant le banquage de B : A affiche 2000 avec son tiret, B affiche 1500.
    expect(find.text('2000'), findsOneWidget);
    expect(find.text('1500'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high), findsOneWidget);

    await tester.tap(find.text('S\'arrêter'));
    await tester.pumpAndSettle();

    // La main passe à A (pass-and-play) : écran de transition affiché.
    expect(find.byType(PassDeviceScreen), findsOneWidget);
    await tester.tap(find.text('Prêt'));
    await tester.pumpAndSettle();

    // De retour sur la feuille de score : B est à 2000, A est retombé à
    // 1800 (barré par la collision) et n'a plus son tiret.
    expect(find.text('2000'), findsOneWidget); // B
    expect(find.text('1800'), findsOneWidget); // A, barré

    // Le journal de partie mentionne le score barré de A par collision.
    expect(find.textContaining('Score barré'), findsOneWidget,
        reason: 'la collision de score doit apparaître dans le journal de partie');
    expect(find.byIcon(Icons.priority_high), findsNothing);

    // ... précédée par l'annonce de la prise de mise de B elle-même (score
    // pris + nombre de dés restants hérités par A).
    expect(find.textContaining('500 3 dés'), findsOneWidget,
        reason: 'la prise de mise de B doit annoncer le score pris et les dés restants');

    final after = container.read(gameProvider)!;
    expect(after.players[1].totalScore, 2000);
    expect(after.players[0].totalScore, 1800, reason: 'A retombe à son score précédent : collision à 2000');
    expect(after.players[0].hasTiret, isFalse);
  });

  testWidgets('prendre la mise annonce le score pris et les dés restants dans le journal', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Un seul dé restant hérité par le joueur suivant : vérifie l'accord au
    // singulier ("1 dé"), le pluriel étant déjà couvert par le test de
    // collision ci-dessus ("3 dés").
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 0), Player(name: 'B', totalScore: 0)],
      currentPlayerIndex: 0,
      activeTurn: const TurnState(diceToRoll: 1, bankedScore: 500, hasRolledThisTurn: true),
    );
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

    await tester.tap(find.text('S\'arrêter'));
    await tester.pumpAndSettle();

    expect(find.byType(PassDeviceScreen), findsOneWidget);
    await tester.tap(find.text('Prêt'));
    await tester.pumpAndSettle();

    expect(find.textContaining('500 1 dé'), findsOneWidget,
        reason: 'accord au singulier pour un seul dé restant');
    expect(find.textContaining('500 1 dés'), findsNothing);
  });

  testWidgets('atteindre exactement 10000 lors du tour final affiche l\'écran de victoire', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A a déjà déclenché le tour final en atteignant 10000 ; c'est au tour
    // de B de jouer son unique tour final, qu'il réussit à banquer.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [
        Player(name: 'A', totalScore: 10000, hasEntered: true),
        Player(name: 'B', totalScore: 3000, hasEntered: true),
      ],
      currentPlayerIndex: 1,
      triggeringWinnerIndex: 0,
      remainingFinalTurns: 1,
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200, hasRolledThisTurn: true),
    );
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

    expect(find.textContaining('Tour final'), findsOneWidget);

    await tester.ensureVisible(find.text('S\'arrêter'));
    await tester.tap(find.text('S\'arrêter'));
    await tester.pumpAndSettle();

    expect(find.byType(GameOverScreen), findsOneWidget);
    expect(find.textContaining('A gagne'), findsOneWidget);

    final after = container.read(gameProvider)!;
    expect(after.gameOver, isTrue);
    expect(after.winnerIndex, 0, reason: 'A doit gagner malgré le tour final joué par B');
  });

  testWidgets('le choix de main hérité relance directement, sans écran séparé', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(nextTurnDice: 3); // A hérite de 3 dés d'un tour précédent
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(playerNames: ['A', 'B'], autoPlayers: {0}),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    // Pas d'écran dédié : la même ligne de contrôle que le reste du tour,
    // avec le bouton "Lancer" (pourcentage de chance de marquer) qui
    // reprend la main héritée ET lance en un seul geste, et "Refuser" pour
    // repartir à 5 dés neufs à la place.
    expect(find.widgetWithIcon(FilledButton, Icons.casino), findsOneWidget);
    expect(find.text('Refuser'), findsOneWidget);
    expect(container.read(gameProvider)!.activeTurn, isNull, reason: 'rien n\'est encore décidé');

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await tester.pump();

    final after = container.read(gameProvider)!;
    expect(after.activeTurn!.diceToRoll, 3);
    expect(after.activeTurn!.pendingRoll, isNotNull, reason: 'reprendre la main héritée lance directement, sans étape intermédiaire');
  });

  testWidgets(
      'sans le mode auto, la main héritée n\'est reprise/lancée que sur clic manuel, même après un long délai',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(nextTurnDice: 3);
    // Pas de autoPlayers : le mode auto est désactivé par défaut.
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

    // Un délai bien plus long que l'auto-validation habituelle ne doit rien
    // déclencher tout seul.
    await tester.pump(const Duration(seconds: 30));
    expect(container.read(gameProvider)!.activeTurn, isNull,
        reason: 'sans mode auto, rien ne doit se déclencher sans clic, quel que soit le délai écoulé');

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await tester.pump();
    final after = container.read(gameProvider)!;
    expect(after.activeTurn!.diceToRoll, 3);
    expect(after.activeTurn!.pendingRoll, isNotNull, reason: 'le clic manuel reprend la main ET lance en un seul geste');
  });

  testWidgets(
      'continuer une main héritée dont le score dépasse déjà le minimum '
      'lance quand même directement (impossible de s\'arrêter avant d\'avoir relancé)', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A hérite de 3 dés ET d'un score de 500 déjà validé par le joueur
    // précédent : ce score seul dépasserait le minimum requis, mais aucun
    // lancer n'a encore eu lieu ce tour-ci pour A.
    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(nextTurnDice: 3, inheritedScore: 500);
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

    expect(find.text('S\'arrêter'), findsNothing, reason: 'pas encore de tour actif tant que la main n\'est pas reprise');

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await tester.pump();

    final after = container.read(gameProvider)!;
    expect(after.activeTurn!.bankedScore, 500);
    expect(after.activeTurn!.pendingRoll, isNotNull,
        reason: 'le score hérité seul ne suffit pas à s\'arrêter : reprendre relance directement');
  });

  testWidgets('après un lancer avec un choix de 5 à garder, "S\'arrêter" banque directement', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // B a déjà 100 pts banqués ce tour ; le lancer en attente propose deux 5
    // déclinables. Garder les deux amène à 200, le minimum requis (entré).
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A'), Player(name: 'B', hasEntered: true)],
      currentPlayerIndex: 1,
      activeTurn: TurnState(
        diceToRoll: 5,
        bankedScore: 100,
        pendingRoll: analyzeRoll([5, 5, 2, 3, 4]),
        hasRolledThisTurn: true,
      ),
    );
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

    // Aucun écran intermédiaire "Valider" : le choix de garde propose
    // directement de continuer ou de s'arrêter.
    expect(find.text('Valider'), findsNothing);
    expect(find.widgetWithIcon(FilledButton, Icons.casino), findsOneWidget);
    expect(find.text('S\'arrêter'), findsOneWidget);

    await tester.ensureVisible(find.text('S\'arrêter'));
    await tester.tap(find.text('S\'arrêter'));
    await tester.pumpAndSettle();

    expect(find.byType(PassDeviceScreen), findsOneWidget, reason: 'B a banqué, la main passe à A');
    final after = container.read(gameProvider)!;
    expect(after.players[1].totalScore, 200);
  });

  testWidgets('après un lancer avec un choix de 5 à garder, "Lancer les dés" relance directement', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A'), Player(name: 'B', hasEntered: true)],
      currentPlayerIndex: 1,
      activeTurn: TurnState(
        diceToRoll: 5,
        bankedScore: 100,
        pendingRoll: analyzeRoll([5, 5, 2, 3, 4]),
        hasRolledThisTurn: true,
      ),
    );
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

    await tester.ensureVisible(find.widgetWithIcon(FilledButton, Icons.casino));
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await tester.pump();

    final after = container.read(gameProvider)!;
    expect(after.activeTurn!.bankedScore, 200, reason: 'le choix de garde a bien été appliqué avant de relancer');
    expect(after.activeTurn!.pendingRoll, isNotNull, reason: 'un nouveau lancer a été déclenché directement');
  });

  testWidgets('choisir de repartir à 5 dés neufs ignore les dés hérités', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(nextTurnDice: 2);
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

    await tester.tap(find.text('Refuser'));
    await tester.pump();

    expect(container.read(gameProvider)!.activeTurn!.diceToRoll, 5);
  });

  testWidgets('le tour d\'un joueur IA se joue automatiquement à l\'écran, sans interaction', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // De vrais lancers de dés pilotent ce tour (pas d'état pré-construit
    // comme les autres tests) : on vérifie ici le comportement du GameScreen
    // face à un vrai tour IA, dés aléatoires compris.
    var engine = GameEngine.newGame(['Joueur', 'IA']).startTurn();
    engine = engine.copyWith(currentPlayerIndex: 1, activeTurn: TurnState.initial(5));
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(
            playerNames: ['Joueur', 'IA'],
            aiPlayers: {1: AiDifficulty.prudent},
            autoPlayers: {0, 1},
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pump(); // premier frame : le postFrameCallback programme le 1er pas IA

    // Dès le premier frame, c'est visiblement le tour de l'IA (en mode
    // auto) : le bouton affiché est le sien, pas un choix réservé à
    // l'humain ("S'arrêter" n'a de sens que dans le dialogue de banque
    // humain à deux boutons, "Valider" n'existe plus du tout).
    expect(find.text('S\'arrêter'), findsNothing);
    expect(find.text('Valider'), findsNothing);

    // On laisse le temps s'écouler (délai de "réflexion" de l'IA) jusqu'à ce
    // que la main revienne au joueur humain ou que la partie se termine.
    var iterations = 0;
    while (container.read(gameProvider)!.currentPlayerIndex == 1 && !container.read(gameProvider)!.gameOver) {
      await tester.pump(_aiStepPump);
      iterations++;
      expect(iterations, lessThan(60), reason: 'le tour de l\'IA ne devrait pas s\'éterniser');
    }

    final after = container.read(gameProvider)!;
    if (!after.gameOver) {
      expect(after.currentPlayerIndex, 0, reason: 'la main revient bien au joueur humain');
      await tester.pump();

      if (after.activeTurn == null) {
        // L'IA a laissé des dés hérités : le joueur humain doit d'abord
        // choisir sa main avant de pouvoir lancer les dés (pas d'écran
        // séparé : "Refuser" repart à 5 dés neufs dans la même ligne de
        // contrôle).
        await tester.tap(find.text('Refuser'));
        await tester.pump();
      }

      // Score de tour à 0 : insuffisant pour s'arrêter. Le bouton "Lancer"
      // (icône dé + pourcentage) est affiché immédiatement et se valide
      // seul (joueur humain en mode auto).
      expect(find.widgetWithIcon(FilledButton, Icons.casino), findsOneWidget);
      await tester.pump(_autoActionPump);
      expect(container.read(gameProvider)!.activeTurn!.pendingRoll, isNotNull,
          reason: 'le joueur humain reprend la main normalement, avec un lancer automatique');
    }
  });

  testWidgets('reprendre une partie en pause recharge le journal depuis l\'historique déjà persisté',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Journal minimal mais authentique (départage réellement rejoué, voir
    // buildResumableActionLog) : départage + startTurn + un premier roll,
    // sans aucune décision de garde encore appliquée dessus.
    final saved = buildResumableSavedGame(seed: 7, alias: 'Reprise', playerNames: const ['A', 'B']);
    container.read(gameProvider.notifier).resumeFromSave(saved);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pump();

    // Rien n'a encore été joué depuis que l'écran a été monté : cette entrée
    // ne peut venir que du rejeu de l'historique déjà dans le .run (voir
    // GameNotifier.actions/_seedLogFromHistory), pas du suivi en direct.
    expect(find.textContaining('5 dés à lancer'), findsOneWidget);
    expect(find.byType(PlayerAvatarWidget), findsWidgets);
  });
}
