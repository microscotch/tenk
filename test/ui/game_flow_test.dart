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
import 'package:le10000/ui/widgets/die_widget.dart';
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
/// Fenêtre pendant laquelle les commandes restent inertes après une
/// transition d'écran (voir `_controlLockAfterTransition` dans
/// `game_screen.dart`), plus une marge : un test qui agit tout de suite après
/// une transition doit la laisser s'écouler, comme un vrai joueur.
const _controlLockPump = Duration(milliseconds: 400);

final _autoActionPump = const AppSettings().autoActionDelay + const Duration(milliseconds: 100);
final _aiStepPump = const AppSettings().aiMessageDelay + const Duration(milliseconds: 100);

/// Le bouton Stop est désormais toujours présent dans la ligne de contrôle,
/// et c'est son activation — pas sa présence — qui dit si s'arrêter est
/// possible (voir `_controlRow` dans `game_screen.dart`).
bool _stopEnabled(WidgetTester tester) {
  final button = tester.widget<IconButton>(
    find.ancestor(of: find.byIcon(Icons.front_hand), matching: find.byType(IconButton)).first,
  );
  return button.onPressed != null;
}

void main() {
  testWidgets('le bouton retour ne referme pas la popup de craque', (tester) async {
    // Ces popups portent la seule action qui débloque le tour : les fermer
    // avec le bouton retour laissait la partie dans un état injouable.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 700, hasEntered: true), Player(name: 'B')],
      activeTurn: TurnState(diceToRoll: 3, pendingRoll: analyzeRoll([2, 3, 4]), busted: true),
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
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget,
        reason: 'la popup doit rester : son bouton porte la seule action qui passe la main');
    expect(find.text('Continuer'), findsOneWidget);

    // Le cadre du titre occupe toute la largeur de la popup quel que soit
    // l'alignement : c'est l'alignement du texte lui-même qui compte.
    final title = tester.widget<Text>(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Craqué !')),
    );
    expect(title.textAlign, TextAlign.center, reason: 'le titre doit être centré');

    final dialogRect = tester.getRect(find.byType(AlertDialog));
    final continueRect = tester.getRect(find.widgetWithText(FilledButton, 'Continuer'));
    expect((continueRect.center.dx - dialogRect.center.dx).abs(), lessThan(1.0),
        reason: 'le bouton Continuer doit être centré dans la popup');
  });

  testWidgets('la popup de craque montre la main perdue et le lancer qui l\'emporte', (tester) async {
    // La popup recouvre les deux zones de l'écran au moment précis où le
    // joueur veut voir ce que le craque lui coûte : elle les reprend donc.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 700, hasEntered: true), Player(name: 'B')],
      activeTurn: TurnState(
        diceToRoll: 3,
        bankedScore: 200,
        keptDiceThisTurn: const [
          KeptDie(value: 1, points: 100, isExtended: false),
          KeptDie(value: 1, points: 100, isExtended: false),
        ],
        pendingRoll: analyzeRoll([2, 3, 4]),
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
        child: const MaterialApp(
          home: GameScreen(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(DieWidget),
    );
    final dice = tester.widgetList<DieWidget>(inDialog).toList();

    expect(dice.map((d) => d.value), [1, 1, 2, 3, 4],
        reason: 'la main courante d\'abord, puis les dés du lancer perdu');
    expect(dice.take(2).map((d) => d.state), everyElement(DieVisualState.kept));
    expect(dice.skip(2).map((d) => d.state), everyElement(DieVisualState.junk));

    // Ce que la main valait (200 engrangés + 2+3+4 du lancer fatal), puis ce
    // que le craque fait à la grille : ce premier craque ne pose qu'un tiret
    // sur les 700, qui gardent leur valeur.
    final score = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.textContaining('209 : 700'),
    );
    expect(score, findsOneWidget);
    expect(tester.getRect(score).top, greaterThan(tester.getRect(inDialog.first).bottom),
        reason: 'le score s\'affiche sous les dés');
    expect(
      find.descendant(of: score, matching: find.byIcon(Icons.remove)),
      findsOneWidget,
      reason: 'le tiret que le craque vient de poser accompagne le score',
    );

    // Tout tient sur une seule ligne : les dés gardés portent le liseré de
    // leur lancer, ceux de la piste n'en ont pas, le lancer ayant craqué.
    final framed = find.descendant(
      of: find.byKey(const ValueKey('popup-roll-frame-0')),
      matching: find.byType(DieWidget),
    );
    expect(tester.widgetList<DieWidget>(framed).map((d) => d.value), [1, 1]);
    expect(find.byKey(const ValueKey('popup-roll-frame-1')), findsNothing,
        reason: 'un seul lancer validé, donc un seul liseré');

    final premier = tester.getRect(inDialog.first);
    for (var i = 1; i < dice.length; i++) {
      final suivant = tester.getRect(inDialog.at(i));
      expect(suivant.center.dy, closeTo(premier.center.dy, 1.0),
          reason: 'tous les dés tiennent sur une seule ligne');
      expect(suivant.left, greaterThan(premier.left),
          reason: 'et se suivent de gauche à droite');
    }
  });

  testWidgets('la popup de craque annonce la chute de score quand la ligne est barrée',
      (tester) async {
    // Une ligne déjà tiretée : ce second craque la barre et fait retomber le
    // joueur sur sa ligne précédente — c'est le seul cas où le score de
    // grille annoncé diffère de celui qu'il avait en entrant dans le tour.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final marque = Player(name: 'A').applySuccessfulTurn(700).applyBust();
    expect(marque.hasTiret, isTrue, reason: 'sinon ce craque ne barrerait rien');

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [marque, Player(name: 'B')],
      activeTurn: TurnState(
        diceToRoll: 3,
        bankedScore: 200,
        pendingRoll: analyzeRoll([2, 3, 4]),
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
        child: const MaterialApp(
          home: GameScreen(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Les 700 sont barrés et le joueur retombe sur sa ligne précédente (0) :
    // le score barré, ce que ça lui coûte, et où il atterrit.
    final score = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.textContaining('209 : 700, -700 => 0'),
    );
    expect(score, findsOneWidget);
    expect(
      find.descendant(of: score, matching: find.byIcon(Icons.remove)),
      findsNothing,
      reason: 'une ligne barrée ne porte plus de tiret',
    );

    final barre = tester.widget<Text>(score);
    expect(barre.textSpan!.toPlainText(), '209 : 700, -700 => 0');
    expect(
      (barre.textSpan! as TextSpan).children!.any((s) =>
          s is TextSpan && s.style?.decoration == TextDecoration.lineThrough && s.text == '700'),
      isTrue,
      reason: 'le score perdu doit être barré, comme dans la grille',
    );
  });

  testWidgets('la popup de craque n\'invente pas de marque pour un joueur encore à zéro',
      (tester) async {
    // Un craque à 0 ne pose rien dans la grille (voir Player.applyBust, qui
    // s'arrête là) : la ligne de bilan ne doit donc afficher ni tiret ni barre.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(
        diceToRoll: 3,
        pendingRoll: analyzeRoll([2, 3, 4]),
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
        child: const MaterialApp(
          home: GameScreen(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final score = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.textContaining('9 : 0'),
    );
    expect(score, findsOneWidget);
    expect(tester.widget<Text>(score).textSpan!.toPlainText(), '9 : 0',
        reason: 'rien après le score : ce craque ne change rien à la grille');
    expect(find.descendant(of: score, matching: find.byIcon(Icons.remove)), findsNothing);
  });

  testWidgets('la popup de main héritée montre les dés déjà mis de côté, sur une seule ligne',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Le joueur précédent a mis de côté un as, relancé, puis gardé deux cinq
    // (300 points en tout) et laissé 2 dés : la popup doit montrer ces 3 dés
    // sous le score annoncé, chaque lancer dans son liseré.
    const kept = [
      KeptDie(value: 1, points: 100, isExtended: false),
      KeptDie(value: 5, points: 50, isExtended: false, rollIndex: 1),
      KeptDie(value: 5, points: 50, isExtended: false, rollIndex: 1),
    ];
    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 1000, hasEntered: true), Player(name: 'B')],
      nextTurnDice: 2,
      inheritedScore: 300,
      inheritedKeptDice: kept,
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

    final diceInDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(DieWidget),
    );
    expect(diceInDialog, findsNWidgets(3));

    // Un liseré par lancer, comme dans la zone "Main courante".
    List<int> diceInFrame(int i) => tester
        .widgetList<DieWidget>(
          find.descendant(
            of: find.byKey(ValueKey('popup-roll-frame-$i')),
            matching: find.byType(DieWidget),
          ),
        )
        .map((d) => d.value)
        .toList();
    expect(diceInFrame(0), [1], reason: 'le premier lancer n\'a gardé que l\'as');
    expect(diceInFrame(1), [5, 5], reason: 'le second a gardé les deux cinq');
    expect(find.byKey(const ValueKey('popup-roll-frame-2')), findsNothing);

    // Tous alignés sur une même ligne, et contenus dans la popup.
    final dialogRect = tester.getRect(find.byType(AlertDialog));
    final boxes = tester.widgetList<DieWidget>(diceInDialog).toList();
    final tops = tester.getRect(diceInDialog.at(0)).top;
    for (var i = 0; i < boxes.length; i++) {
      final r = tester.getRect(diceInDialog.at(i));
      expect(r.top, tops, reason: 'les dés doivent être sur la même ligne');
      expect(dialogRect.contains(r.topLeft) && dialogRect.contains(r.bottomRight), isTrue,
          reason: 'chaque dé doit tenir dans la popup');
    }

    // Empilement voulu, de haut en bas : les dés, ce qu'ils valent, puis les
    // deux suites possibles.
    final diceBottom = tester.getRect(diceInDialog.at(0)).bottom;
    final score = tester.getRect(
      find.descendant(of: find.byType(AlertDialog), matching: find.textContaining('300')),
    );
    final resume = tester.getRect(find.byTooltip('Reprendre la main'));
    final newHand = tester.getRect(find.byTooltip('Nouvelle main'));

    expect(diceBottom, lessThanOrEqualTo(score.top), reason: 'les dés au-dessus du score');
    expect(score.bottom, lessThanOrEqualTo(resume.top),
        reason: 'le score au-dessus des deux icônes de décision');
    expect(resume.top, newHand.top,
        reason: 'les deux icônes de décision sont côte à côte, sur une même ligne');
    expect(resume.right, lessThanOrEqualTo(newHand.left),
        reason: 'valider à gauche, refuser à droite');

    // Le titre occupe toute la largeur de la popup : son cadre est centré
    // quel que soit l'alignement, c'est donc l'alignement du texte lui-même
    // qu'il faut vérifier.
    final title = tester.widget<Text>(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Reprendre ?')),
    );
    expect(title.textAlign, TextAlign.center, reason: 'le titre doit être centré');

    // La grille de score se consulte depuis la popup, en coin de titre : elle
    // ne tranche pas le choix, donc elle n'est pas dans la rangée décisive.
    // Celle de la popup, pas celle de l'AppBar (même infobulle, à dessein :
    // c'est la même destination).
    final grid = tester.getRect(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byTooltip('Grille des scores'),
    ));
    expect(grid.bottom, lessThanOrEqualTo(tester.getRect(diceInDialog.at(0)).top),
        reason: 'la grille est en haut, au-dessus des dés, pas avec les deux décisions');

    // Le score est centré, et la paire d'icônes l'est en bloc (l'espace à
    // gauche de la première vaut celui à droite de la seconde).
    expect((score.center.dx - dialogRect.center.dx).abs(), lessThan(1.0),
        reason: 'le score doit être centré dans la popup');
    expect(
      ((resume.left - dialogRect.left) - (dialogRect.right - newHand.right)).abs(),
      lessThan(1.0),
      reason: 'la rangée des deux icônes doit être centrée dans la popup',
    );
  });

  testWidgets('le bouton retour ne referme pas la popup de main héritée', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Main héritée reprenable : le joueur doit choisir, et seule la popup
    // porte ce choix.
    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 1000, hasEntered: true), Player(name: 'B')],
      nextTurnDice: 3,
      inheritedScore: 300,
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
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget,
        reason: 'sans ce choix, activeTurn reste null et plus rien n\'est jouable');
  });

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
    // contextuels). Le journal annonce en plus la sanction encourue — ici un
    // petit trait, le score acquis restant intact.
    expect(find.textContaining('Craqué'), findsWidgets);
    expect(find.textContaining('Craqué ! => 700 petit trait'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.currentPlayerIndex, 1, reason: 'la main doit passer au joueur B');
    expect(after.players[0].hasTiret, isTrue, reason: 'le craque doit marquer un tiret sur A');
    expect(after.players[0].totalScore, 700, reason: 'le craque ne doit pas changer le score déjà acquis');
  });

  testWidgets('pendant le suspense d\'un craque, la ligne montre le bouton Lancer désactivé, sans indicateur d\'attente',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
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

    // Le craque n'est pas encore révélé : rien ne doit l'annoncer.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final rollButton = find.widgetWithIcon(FilledButton, Icons.casino);
    expect(rollButton, findsOneWidget);
    expect(tester.widget<FilledButton>(rollButton).onPressed, isNull,
        reason: 'le bouton reste en place mais inerte pendant le suspense');

    await tester.pumpAndSettle();
  });

  testWidgets('les commandes restent inertes juste après une transition, puis redeviennent actives',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', hasEntered: true), Player(name: 'B')],
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 300, hasRolledThisTurn: true),
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.debugLoadState(engine, const GameSetup(playerNames: ['A', 'B']));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    final rollButton = find.widgetWithIcon(FilledButton, Icons.casino);
    expect(tester.widget<FilledButton>(rollButton).onPressed, isNotNull,
        reason: 'au repos, la commande répond');

    // Transition : le moteur change d'état sous le doigt du joueur.
    notifier.debugLoadState(
      engine.copyWith(activeTurn: const TurnState(diceToRoll: 2, bankedScore: 400, hasRolledThisTurn: true)),
      const GameSetup(playerNames: ['A', 'B']),
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(rollButton).onPressed, isNull,
        reason: 'un tap déjà parti ne doit pas être encaissé par la commande qui vient d\'apparaître');

    await tester.pump(_controlLockPump);
    expect(tester.widget<FilledButton>(rollButton).onPressed, isNotNull,
        reason: 'la fenêtre passée, la commande répond de nouveau');

    await tester.pumpAndSettle();
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

    await tester.tap(find.text('Continuer'));
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

    // La popup vient de surgir : ses commandes restent inertes le temps de la
    // fenêtre anti-clic involontaire (voir _controlLockAfterTransition), comme
    // pour un vrai joueur.
    await tester.pump(_controlLockPump);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.currentPlayerIndex, 1, reason: 'la main doit passer au joueur B');
    expect(after.players[0].hasTiret, isTrue, reason: 'le craque doit marquer un tiret sur A');
    expect(after.players[0].totalScore, 9900, reason: 'le craque ne doit pas changer le score déjà acquis');
    expect(after.nextTurnDice, 5, reason: 'un craque ne transmet jamais de main héritée au joueur suivant');
    expect(after.inheritedScore, 0);
  });

  testWidgets('popup de main héritée sans issue : l\'icône de reprise reste visible mais inerte', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Une partie en cours ne s'arrête plus jamais sur ce choix (voir le test
    // "une main héritée sans issue ne pose aucune question") : la popup n'a
    // plus qu'un chemin, la reprise d'une sauvegarde enregistrée avant ce
    // comportement, qui rejoue jusqu'à un activeTurn null. Le garde-fou doit
    // donc y tenir aussi.
    //
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

    // Popup dédiée (voir _showInheritedHandDialog) : la rangée d'icônes est
    // fixe, l'icône de reprise reste donc à sa place — mais désactivée, pour
    // ne pas recentrer l'autre en disparaissant (même arbitrage que la ligne
    // de contrôle, voir _buildInheritedChoiceRow).
    final resume = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Reprendre la main'),
        matching: find.byType(IconButton),
      ),
    );
    expect(resume.onPressed, isNull,
        reason: 'reprendre cette main garantirait un dépassement de 10000');
    final newHand = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Nouvelle main'),
        matching: find.byType(IconButton),
      ),
    );
    expect(newHand.onPressed, isNotNull, reason: 'repartir à 5 dés neufs reste possible');
    expect(find.textContaining('impossible de banquer'), findsOneWidget);
  });

  testWidgets('une main héritée sans issue ne pose aucune question : le tour suivant démarre à 5 dés neufs',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A (déjà entré) garde une paire d'as et s'arrête : il banque 200 et
    // laisse 3 dés. B est à 9800, donc 9800 + 200 = 10000 pile — reprendre
    // cette main ne pourrait que craquer, et repartir à 5 dés neufs est sa
    // seule suite jouable. Il n'y a donc rien à lui demander.
    final engine = GameEngine(
      players: [
        Player(name: 'A', totalScore: 1500, hasEntered: true),
        Player(name: 'B', totalScore: 9800, hasEntered: true),
      ],
      currentPlayerIndex: 0,
      nextTurnDice: 3,
      activeTurn: const TurnState(diceToRoll: 3, bankedScore: 200, hasRolledThisTurn: true),
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.debugLoadState(engine, const GameSetup(playerNames: ['A', 'B']));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    final attempt = notifier.bank();
    expect(attempt.success, isTrue);
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.currentPlayer.name, 'B');
    expect(after.activeTurn, isNotNull, reason: 'le tour de B doit avoir démarré tout seul');
    expect(after.activeTurn!.diceToRoll, 5, reason: 'une main neuve, pas les 3 dés hérités');
    expect(after.activeTurn!.bankedScore, 0, reason: 'la base héritée de 200 est abandonnée');

    expect(find.text('Reprendre ?'), findsNothing,
        reason: 'aucune popup : il n\'y a pas de choix à faire');
    expect(find.byTooltip('Reprendre la main'), findsNothing);
    expect(find.byTooltip('Nouvelle main'), findsNothing);
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
    // Le journal annonce la sanction : la ligne 1000 est barrée (affichée
    // biffée) et le score retombe à 700.
    expect(find.textContaining('Craqué ! =>'), findsWidgets);
    expect(find.textContaining('retour à 700'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.players[0].totalScore, 700, reason: 'retombe au dernier score non barré');
    expect(after.players[0].hasTiret, isFalse, reason: 'le tiret est consommé par le barrage');
    expect(after.currentPlayerIndex, 1);
  });

  testWidgets('un barrage qui replie sur une ligne déjà tiretée réaffiche le point d\'exclamation',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A : 1600 tiretée, puis 1800 tiretée à son tour. Le craque qui suit
    // barre 1800 et le replie sur 1600 -- qui porte toujours son tiret dans
    // la grille : la feuille de score de l'écran de jeu doit le dire aussi
    // (bug remonté : l'avertissement disparaissait à ce moment-là).
    var player = Player(name: 'A').applySuccessfulTurn(1600);
    player = player.applyBust(); // tiret sur 1600
    player = player.applySuccessfulTurn(200); // 1600 -> 1800
    player = player.applyBust(); // tiret sur 1800
    expect(player.hasTiret, isTrue);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [player, Player(name: 'B')],
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
    expect(find.byIcon(Icons.priority_high), findsOneWidget, reason: '1800 porte un tiret');

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    // La main passe à B : on repasse par l'écran de transition avant de
    // retrouver la feuille de score.
    expect(find.byType(PassDeviceScreen), findsOneWidget);
    await tester.tap(find.text('Prêt'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.players[0].totalScore, 1600, reason: '1800 est barré, repli sur 1600');
    expect(after.players[0].currentEntry.hasTiret, isTrue, reason: '1600 avait déjà son tiret');
    expect(
      find.byIcon(Icons.priority_high),
      findsOneWidget,
      reason: 'la feuille de score doit montrer le tiret que la grille affiche déjà sur 1600',
    );
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

    await tester.tap(find.byIcon(Icons.front_hand));
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
    // encaissé + nouveau total).
    expect(find.textContaining('500 pts sont pris => 2000 pts'), findsOneWidget,
        reason: 'la prise de mise de B doit annoncer le score encaissé et son nouveau total');

    final after = container.read(gameProvider)!;
    expect(after.players[1].totalScore, 2000);
    expect(after.players[0].totalScore, 1800, reason: 'A retombe à son score précédent : collision à 2000');
    expect(after.players[0].hasTiret, isFalse);
  });

  testWidgets(
      'la quinte d\'as gagne la partie sur-le-champ et l\'annonce correctement dans le journal',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Alice à 0 : son lancer (5 as) applique la garde ET banque dans la
    // MÊME transition (exception de la quinte d'as, voir GameEngine.
    // applyKeep) -- contrairement au cas normal où ce sont deux actions
    // séparées. Régression ciblée : le journal doit annoncer les 10000 pts
    // effectivement gagnés, pas 0 (voir le commentaire sur
    // _logEntriesForStep).
    var engine = GameEngine.newGame(['Alice', 'Bob']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'Alice'), Player(name: 'Bob', totalScore: 3000, hasEntered: true)],
      currentPlayerIndex: 0,
      activeTurn: TurnState(
        diceToRoll: 5,
        pendingRoll: analyzeRoll(const [1, 1, 1, 1, 1]),
        hasRolledThisTurn: true,
      ),
    );
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

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await tester.pumpAndSettle();

    expect(find.textContaining('Craqué'), findsNothing, reason: 'la quinte d\'as ne craque jamais');

    // La main est banquée : elle passe directement à Bob (pas de popup de
    // craque à acquitter), donc l'écran de passation s'intercale avant de
    // pouvoir relire le journal.
    expect(find.byType(PassDeviceScreen), findsOneWidget);
    await tester.tap(find.text('Prêt'));
    await tester.pumpAndSettle();

    expect(find.textContaining('10000 pts sont pris => 10000 pts'), findsOneWidget);

    final after = container.read(gameProvider)!;
    expect(after.players[0].totalScore, 10000);
    expect(after.triggeringWinnerIndex, 0);
    expect(after.remainingFinalTurns, 1);
  });

  testWidgets('prendre la mise annonce le score encaissé et le nouveau total dans le journal', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A part de 0 : le score encaissé et le nouveau total se confondent ici,
    // le cas où ils diffèrent étant couvert par le test de collision
    // ci-dessus (500 encaissés sur 1500 déjà acquis).
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

    await tester.tap(find.byIcon(Icons.front_hand));
    await tester.pumpAndSettle();

    expect(find.byType(PassDeviceScreen), findsOneWidget);
    await tester.tap(find.text('Prêt'));
    await tester.pumpAndSettle();

    expect(find.textContaining('500 pts sont pris => 500 pts'), findsOneWidget);
  });

  testWidgets('reprendre la main héritée l\'annonce dans le journal', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A hérite des 2 dés et des 400 points laissés par le tour précédent.
    var engine = GameEngine.newGame(['A', 'B']);
    engine = engine.copyWith(nextTurnDice: 2, inheritedScore: 400);
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

    await tester.tap(find.byTooltip('Reprendre la main'));
    await tester.pump();

    expect(find.textContaining('400 pts sont repris'), findsOneWidget);
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

    await tester.ensureVisible(find.byIcon(Icons.front_hand));
    await tester.tap(find.byIcon(Icons.front_hand));
    await tester.pumpAndSettle();

    expect(find.byType(GameOverScreen), findsOneWidget);
    expect(find.textContaining('A gagne'), findsOneWidget);

    final after = container.read(gameProvider)!;
    expect(after.gameOver, isTrue);
    expect(after.winnerIndex, 0, reason: 'A doit gagner malgré le tour final joué par B');
  });

  testWidgets('le choix de main héritée ouvre une popup dédiée qui relance directement', (tester) async {
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

    // Popup dédiée (voir _showInheritedHandDialog), pas d'écran séparé : le
    // bouton "Reprendre la main" reprend la main héritée ET lance en un seul
    // geste, "Nouvelle main" repart à 5 dés neufs à la place.
    expect(find.byTooltip('Reprendre la main'), findsOneWidget);
    expect(find.byTooltip('Nouvelle main'), findsOneWidget);
    expect(container.read(gameProvider)!.activeTurn, isNull, reason: 'rien n\'est encore décidé');

    await tester.tap(find.byTooltip('Reprendre la main'));
    await tester.pump();

    final after = container.read(gameProvider)!;
    expect(after.activeTurn!.diceToRoll, 3);
    expect(after.activeTurn!.pendingRoll, isNotNull, reason: 'reprendre la main héritée lance directement, sans étape intermédiaire');
  });

  testWidgets('refuser la main héritée lance directement une main neuve de 5 dés, sans étape intermédiaire', (tester) async {
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

    await tester.tap(find.byTooltip('Nouvelle main'));
    await tester.pump();

    final after = container.read(gameProvider)!;
    expect(after.activeTurn!.diceToRoll, 5);
    expect(after.activeTurn!.pendingRoll, isNotNull, reason: 'refuser la main héritée lance directement, sans repasser par le bouton Lancer');
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

    await tester.tap(find.byTooltip('Reprendre la main'));
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

    expect(find.byIcon(Icons.front_hand), findsNothing, reason: 'pas encore de tour actif tant que la main n\'est pas reprise');

    await tester.tap(find.byTooltip('Reprendre la main'));
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
    expect(find.byIcon(Icons.front_hand), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.front_hand));
    await tester.tap(find.byIcon(Icons.front_hand));
    await tester.pumpAndSettle();

    expect(find.byType(PassDeviceScreen), findsOneWidget, reason: 'B a banqué, la main passe à A');
    final after = container.read(gameProvider)!;
    expect(after.players[1].totalScore, 200);
  });

  testWidgets('main pleine pile sur 10000 : pas de Stop trompeur, et lancer mène au craque sans planter',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A est à 9000 et son lancer complète la main avec un brelan d'as
    // (1000) : pile 10000, mais main pleine -- impossible de s'arrêter, et
    // tout relancer dépasserait.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 9000, hasEntered: true), Player(name: 'B')],
      activeTurn: TurnState(
        diceToRoll: 3,
        pendingRoll: analyzeRoll([1, 1, 1]),
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

    // Stop est là mais inerte : ce banquage n'est pas une victoire
    // disponible, une main pleine ne peut pas être banquée.
    expect(_stopEnabled(tester), isFalse,
        reason: 'une main pleine ne peut pas être banquée, même pile sur 10000');

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'relancer un tour déjà craqué ne doit pas lever');
    final after = container.read(gameProvider)!;
    expect(after.activeTurn!.busted, isTrue);
    expect(after.activeTurn!.bustReason, BustReason.fullHandAtTarget);
    expect(find.textContaining('Main pleine à 10000'), findsWidgets,
        reason: 'la raison du craque est expliquée au joueur');
  });

  testWidgets('le journal résume chaque lancer : dés gardés, gain, dés restants et total de la main', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(
        diceToRoll: 5,
        bankedScore: 300,
        pendingRoll: analyzeRoll([1, 3, 6, 3, 3]),
        hasRolledThisTurn: true,
      ),
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.debugLoadState(engine, const GameSetup(playerNames: ['A', 'B']));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    // La décision de garde appliquée sur ce lancer est ce qui produit
    // l'entrée : l'as (100) et le brelan de 3 (300) sont obligatoires, il
    // reste 1 dé, et la main passe de 300 à 700.
    notifier.debugLoadState(engine.applyKeep(), const GameSetup(playerNames: ['A', 'B']));
    await tester.pumpAndSettle();

    expect(find.textContaining("1 as et brelan de 3 : 400, 1 dé => 700 pts"), findsOneWidget);
    expect(find.textContaining('à lancer'), findsNothing, reason: 'plus d\'entrée séparée pour les dés à relancer');
  });

  testWidgets('sans décision à prendre, le résumé du lancer est journalisé dès les dés immobilisés',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A n'est pas entré (minimum 500) : ce lancer ne marque que l'as (100),
    // aucun 5 à décliner, et s'arrêter reste illégal. Relancer est donc le
    // seul geste possible -- rien à attendre pour l'annoncer.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    final notifier = container.read(gameProvider.notifier);
    notifier.debugLoadState(engine, const GameSetup(playerNames: ['A', 'B']));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    // Le lancer arrive écran monté : les dés roulent, rien n'est encore dit.
    engine = engine.copyWith(
      activeTurn: TurnState(
        diceToRoll: 5,
        pendingRoll: analyzeRoll([1, 2, 3, 4, 6]),
        hasRolledThisTurn: true,
      ),
    );
    notifier.debugLoadState(engine, const GameSetup(playerNames: ['A', 'B']));
    await tester.pump();
    expect(find.textContaining('1 as : 100'), findsNothing, reason: 'les dés roulent encore');

    // Dés immobilisés : le résumé est là, sans qu'aucune action n'ait été
    // faite (le tour n'a pas bougé côté moteur).
    await tester.pump(DieWidget.rollAnimationDuration);
    expect(find.textContaining('1 as : 100, 4 dés => 100 pts'), findsOneWidget);
    expect(container.read(gameProvider)!.activeTurn!.pendingRoll, isNotNull,
        reason: 'le résumé est affiché avant l\'action, pas après');

    // ... et la décision de garde, quand elle finit par être appliquée, ne le
    // journalise pas une seconde fois.
    notifier.applyKeep(declineFivesCount: 0);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 as : 100, 4 dés => 100 pts'), findsOneWidget);
  });

  testWidgets('avec une décision à prendre, le résumé du lancer attend l\'action du joueur',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // B est entré et a 100 pts en main : les deux 5 de ce lancer sont
    // déclinables, et s'arrêter deviendrait légal en les gardant -- il y a
    // donc bien un choix à faire, et rien à annoncer tant qu'il n'est pas
    // tranché.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A'), Player(name: 'B', hasEntered: true)],
      currentPlayerIndex: 1,
      activeTurn: const TurnState(diceToRoll: 5, bankedScore: 100, hasRolledThisTurn: true),
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.debugLoadState(engine, const GameSetup(playerNames: ['A', 'B']));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    notifier.debugLoadState(
      engine.copyWith(
        activeTurn: TurnState(
          diceToRoll: 5,
          bankedScore: 100,
          pendingRoll: analyzeRoll([5, 5, 2, 3, 4]),
          hasRolledThisTurn: true,
        ),
      ),
      const GameSetup(playerNames: ['A', 'B']),
    );
    await tester.pump();
    await tester.pump(DieWidget.rollAnimationDuration);

    expect(find.textContaining('2 cinq : 100'), findsNothing,
        reason: 'le joueur peut encore choisir combien de 5 garder, ou s\'arrêter');

    // L'action tranche le choix : le résumé arrive à ce moment-là.
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await tester.pump();
    expect(find.textContaining('2 cinq : 100, 3 dés => 200 pts'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('le journal annonce "main pleine" à la place des dés restants quand tous les dés scorent',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(
        diceToRoll: 3,
        pendingRoll: analyzeRoll([1, 1, 1]), // brelan d'as : les 3 dés scorent
        hasRolledThisTurn: true,
      ),
    );
    final notifier = container.read(gameProvider.notifier);
    notifier.debugLoadState(engine, const GameSetup(playerNames: ['A', 'B']));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pumpAndSettle();

    notifier.debugLoadState(engine.applyKeep(), const GameSetup(playerNames: ['A', 'B']));
    await tester.pumpAndSettle();

    expect(find.textContaining("brelan d'as : 1000, main pleine => 1000 pts"), findsOneWidget);
    // "Main pleine !" reste le libellé du bouton Lancer, mais n'a plus
    // d'entrée de journal à lui tout seul : le résumé du lancer le dit déjà.
    expect(find.widgetWithText(FilledButton, 'Main pleine !'), findsOneWidget);
  });

  testWidgets('le bouton Stop reste caché tant que les dés du lancer n\'ont pas fini de rouler', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // B est entré et a déjà de quoi s'arrêter : Stop est donc légal AVANT et
    // APRÈS le lancer qui suit — seule l'animation en cours doit le cacher,
    // et non un changement de légalité.
    final players = [Player(name: 'A'), Player(name: 'B', hasEntered: true)];
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: players,
      currentPlayerIndex: 1,
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
    expect(_stopEnabled(tester), isTrue, reason: 'au repos, s\'arrêter est déjà légal');

    // Le lancer arrive alors que l'écran est monté : les dés se mettent à
    // rouler (contrairement à un lancer déjà présent au montage, cf.
    // _rollSettled), et leur résultat ne doit pas être trahi par Stop.
    container.read(gameProvider.notifier).debugLoadState(
          engine.copyWith(
            activeTurn: TurnState(
              diceToRoll: 3,
              bankedScore: 200,
              pendingRoll: analyzeRoll([5, 5, 2]),
              hasRolledThisTurn: true,
            ),
          ),
          const GameSetup(playerNames: ['A', 'B']),
        );
    await tester.pump();
    expect(_stopEnabled(tester), isFalse,
        reason: 'les dés roulent encore : un Stop actif révélerait que ce lancer marque');

    await tester.pump(DieWidget.rollAnimationDuration);
    expect(_stopEnabled(tester), isTrue, reason: 'dés immobilisés : Stop peut enfin devenir actif');

    await tester.pumpAndSettle();
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

    await tester.tap(find.byTooltip('Nouvelle main'));
    await tester.pump();

    expect(container.read(gameProvider)!.activeTurn!.diceToRoll, 5);
  });

  testWidgets('la ligne de contrôle d\'un tour IA se superpose exactement à celle d\'un tour humain',
      (tester) async {
    // Même situation de jeu jouée deux fois, une fois par un humain, une
    // fois par une IA : le bouton principal doit occuper le même
    // emplacement, à la même taille, avec le même pictogramme -- rien ne
    // doit sauter à l'écran quand la main passe de l'un à l'autre.
    Future<(Offset, Size)> measure({required bool ai}) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var engine = GameEngine.newGame(['A', 'B']).startTurn();
      engine = engine.copyWith(
        players: [Player(name: 'A', hasEntered: true), Player(name: 'B')],
        activeTurn: const TurnState(diceToRoll: 3, bankedScore: 300, hasRolledThisTurn: true),
      );
      container.read(gameProvider.notifier).debugLoadState(
            engine,
            GameSetup(
              playerNames: const ['A', 'B'],
              aiPlayers: ai ? const {0: AiDifficulty.prudent} : const {},
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
        ),
      );
      await tester.pump();

      final rollButton = find.widgetWithIcon(FilledButton, Icons.casino);
      expect(rollButton, findsOneWidget,
          reason: ai ? 'le tour IA doit montrer le même bouton dé' : null);
      final geometry = (tester.getTopLeft(rollButton), tester.getSize(rollButton));

      // L'IA enchaîne toute seule : on démonte avant que ses temporisations
      // ne fassent diverger l'état mesuré.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      return geometry;
    }

    final human = await measure(ai: false);
    final ai = await measure(ai: true);

    expect(ai.$1, human.$1, reason: 'même position à l\'écran');
    expect(ai.$2, human.$2, reason: 'même taille');
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
    expect(_stopEnabled(tester), isFalse, reason: 'le tour est à l\'IA : rien à arrêter soi-même');
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
      await tester.pumpAndSettle();

      if (after.activeTurn == null) {
        // L'IA a laissé des dés hérités : popup dédiée (voir
        // _showInheritedHandDialog) avant que le joueur humain puisse lancer
        // les dés -- "Nouvelle main" repart à 5 dés neufs ET lance aussitôt.
        // Ce lancer-là est fait de vrais dés aléatoires : la suite dépend de
        // ce qu'ils donnent (garde à appliquer, craque...), donc on s'arrête
        // ici plutôt que de deviner. Le détail de ce chemin est couvert, avec
        // des dés déterministes, par "refuser la main héritée lance
        // directement une main neuve de 5 dés".
        await tester.tap(find.byTooltip('Nouvelle main'));
        await tester.pump();
        expect(container.read(gameProvider)!.activeTurn, isNotNull,
            reason: 'le joueur humain a bien repris la main, sur une main neuve');
        return;
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
    // puis la garde par défaut sur ce lancer — sans cette décision, un tour
    // à peine entamé ne produit aucune entrée de journal du tout, et il n'y
    // aurait rien à vérifier ici.
    final saved = buildResumableSavedGame(
      seed: 7,
      alias: 'Reprise',
      playerNames: const ['A', 'B'],
      applyKeepAfterRoll: true,
    );
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
    // GameNotifier.actions/_seedLogFromHistory), pas du suivi en direct. Le
    // lancer rejoué pour cette seed est 3-4-1-3-5 : le 1 (100) et le 5 (50)
    // sont gardés, 3 dés restent à relancer.
    expect(find.textContaining('1 as et 1 cinq : 150, 3 dés => 150 pts'), findsOneWidget);
    expect(find.byType(PlayerAvatarWidget), findsWidgets);
  });

  testWidgets('un lancer qui ne peut que dépasser 10000 : les dés sont montrés, puis le craque est annoncé',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // État tel que GameEngine.roll le produit désormais : le lancer marque
    // (deux 1 = 200 incompressibles) mais 9900 + 200 dépasserait 10000, donc
    // craque immédiat AVEC le lancer conservé pour l'afficher.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 9900, hasEntered: true), Player(name: 'B')],
      activeTurn: TurnState(
        diceToRoll: 2,
        pendingRoll: analyzeRoll([1, 1]),
        busted: true,
        bustReason: BustReason.exceedsTarget,
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
    await tester.pump();

    expect(find.textContaining('Craqué'), findsNothing,
        reason: 'le lancer doit d\'abord être montré, comme pour un craque classique');

    await tester.pumpAndSettle();

    expect(find.textContaining('Craqué'), findsWidgets);
    // Visible à deux endroits une fois révélé : le journal ET le contenu de
    // la popup dédiée (voir _showBustDialog).
    expect(find.textContaining('dépasser 10000'), findsWidgets,
        reason: 'le motif du craque est explicité, malgré un lancer en attente');

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    final after = container.read(gameProvider)!;
    expect(after.currentPlayerIndex, 1);
    expect(after.players[0].totalScore, 9900, reason: 'le craque ne retire pas le score déjà acquis');
  });

  testWidgets('les gardes de 5 qui feraient dépasser 10000 ne sont pas proposées', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // A est à 9850. Le lancer contient un 1 obligatoire (100) et deux 5
    // déclinables : garder un seul 5 amène pile à 10000, en garder deux
    // dépasserait — cette option ne doit pas apparaître.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', totalScore: 9850, hasEntered: true), Player(name: 'B')],
      activeTurn: TurnState(
        diceToRoll: 4,
        pendingRoll: analyzeRoll([1, 5, 5, 2]),
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

    // On lit les valeurs proposées dans la combobox plutôt que du texte
    // brut : des chiffres isolés apparaissent ailleurs sur l'écran.
    final dropdown = tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>));
    final offered = dropdown.items!.map((item) => item.value).toList();
    expect(offered, [0, 1],
        reason: 'garder 0 ou 1 cinq reste légal, en garder 2 dépasserait 10000');
  });

  testWidgets('les dés d\'un tour d\'IA restent à leur taille d\'avant l\'élargissement', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 900));

    Future<double> dieSize({required bool ai}) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var engine = GameEngine.newGame(['A', 'B']).startTurn();
      engine = engine.copyWith(
        activeTurn: TurnState(
          diceToRoll: 5,
          bankedScore: 0,
          hasRolledThisTurn: true,
          pendingRoll: analyzeRoll(const [1, 5, 2, 3, 6]),
        ),
      );
      container.read(gameProvider.notifier).debugLoadState(
            engine,
            GameSetup(
              playerNames: const ['A', 'B'],
              aiPlayers: ai ? const {0: AiDifficulty.prudent} : const {},
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
        ),
      );
      await tester.pump();

      final size = tester.widgetList<DieWidget>(find.byType(DieWidget)).first.size;

      // L'IA enchaîne toute seule : on démonte avant que ses temporisations
      // ne fassent diverger l'état mesuré.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      return size;
    }

    final human = await dieSize(ai: false);
    final ai = await dieSize(ai: true);

    expect(ai, lessThan(human),
        reason: 'un tour d\'IA garde les dés plus petits qu\'un tour joué à la main');
  });

  testWidgets('le choix de main héritée n\'est pas affiché pour l\'IA', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Main héritée en attente, et c'est à l'IA de jouer : elle tranche seule,
    // le joueur n'a aucune réponse à donner.
    var engine = GameEngine.newGame(['Bot', 'B']);
    engine = engine.copyWith(
      players: [Player(name: 'Bot', totalScore: 1000, hasEntered: true), Player(name: 'B')],
      nextTurnDice: 3,
      inheritedScore: 300,
    );
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(playerNames: ['Bot', 'B'], aiPlayers: {0: AiDifficulty.prudent}),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen(), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales),
      ),
    );
    await tester.pump();

    expect(find.text('Refuser'), findsNothing,
        reason: 'ce choix ne s\'adresse à personne : l\'IA décide seule');
    expect(find.text('Reprendre ?'), findsNothing, reason: 'ni popup pour l\'IA');
    expect(find.widgetWithIcon(FilledButton, Icons.casino), findsOneWidget,
        reason: 'la ligne garde la forme d\'un tour d\'IA ordinaire');

    // L'IA enchaîne toute seule : on démonte avant que ses temporisations ne
    // fassent diverger l'état.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('ligne de contrôle : Lancer centré, les deux latéraux de part et d\'autre selon la main',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(400, 900));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Lancer en attente avec un vrai choix de 5 (deux 5 déclinables) et un
    // score déjà banquable : les deux commandes latérales sont actives.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', hasEntered: true), Player(name: 'B')],
      activeTurn: TurnState(
        diceToRoll: 3,
        bankedScore: 300,
        hasRolledThisTurn: true,
        pendingRoll: analyzeRoll([5, 5, 2]),
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

    final stop = tester.getRect(find.byIcon(Icons.front_hand));
    final roll = tester.getRect(find.widgetWithIcon(FilledButton, Icons.casino));
    final exchange = tester.getRect(find.byIcon(Icons.swap_vert));

    // Réglage par défaut, droitier : l'échange tombe sous le pouce droit...
    expect(exchange.center.dx, lessThan(roll.left), reason: 'droitier : l\'échange est à gauche');
    expect(stop.center.dx, greaterThan(roll.right), reason: 'droitier : Stop est à droite');

    // ...et le mode gaucher les intervertit, sans toucher au bouton central.
    container.read(settingsProvider.notifier).setRightHanded(false);
    await tester.pumpAndSettle();
    final stopG = tester.getRect(find.byIcon(Icons.front_hand));
    final exchangeG = tester.getRect(find.byIcon(Icons.swap_vert));
    final rollG = tester.getRect(find.widgetWithIcon(FilledButton, Icons.casino));
    expect(stopG.center.dx, lessThan(rollG.left), reason: 'gaucher : Stop passe à gauche');
    expect(exchangeG.center.dx, greaterThan(rollG.right), reason: 'gaucher : l\'échange passe à droite');
    expect(rollG.center.dx, roll.center.dx, reason: 'le bouton Lancer ne bouge pas');
    container.read(settingsProvider.notifier).setRightHanded(true);
    await tester.pumpAndSettle();

    // Lancer centré dans la ligne, indépendamment de ce qui l'encadre.
    final row = tester.getRect(find.byType(GameScreen));
    expect((roll.center.dx - row.center.dx).abs(), lessThan(1.0),
        reason: 'le bouton Lancer doit être centré');

    expect(_stopEnabled(tester), isTrue, reason: '300 banqués suffisent pour s\'arrêter');
    expect(
      tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).onChanged,
      isNotNull,
      reason: 'deux 5 déclinables : l\'échange est possible',
    );
  });

  testWidgets('ligne de contrôle : les deux commandes latérales restent visibles mais inertes',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Tour tout juste démarré : rien n'a été lancé, donc ni arrêt ni échange.
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      players: [Player(name: 'A', hasEntered: true), Player(name: 'B')],
      activeTurn: const TurnState(diceToRoll: 5, bankedScore: 0),
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

    expect(find.byIcon(Icons.front_hand), findsOneWidget, reason: 'Stop reste visible');
    expect(find.byIcon(Icons.swap_vert), findsOneWidget, reason: 'l\'échange reste visible');
    expect(_stopEnabled(tester), isFalse, reason: 'rien n\'a encore été lancé');
    expect(
      tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).onChanged,
      isNull,
      reason: 'aucun 5 à échanger',
    );
  });

  testWidgets('le pourcentage de chance de marquer n\'est affiché que si l\'option est activée',
      (tester) async {
    Future<String> rollButtonLabel({required bool showProbabilities}) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      if (showProbabilities) {
        container.read(settingsProvider.notifier).setShowProbabilities(true);
      }

      var engine = GameEngine.newGame(['A', 'B']).startTurn();
      engine = engine.copyWith(
        players: [Player(name: 'A', hasEntered: true), Player(name: 'B')],
        activeTurn: const TurnState(diceToRoll: 3, bankedScore: 300, hasRolledThisTurn: true),
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

      final button = find.widgetWithIcon(FilledButton, Icons.casino);
      expect(button, findsOneWidget);
      final label = tester
          .widget<Text>(find.descendant(of: button, matching: find.byType(Text)))
          .data!;

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      return label;
    }

    expect(await rollButtonLabel(showProbabilities: false), 'Lancer',
        reason: 'option désactivée par défaut : un libellé simple, aucun pourcentage');
    expect(await rollButtonLabel(showProbabilities: true), endsWith('%'),
        reason: 'option activée : le bouton porte la probabilité de marquer');
  });
}
