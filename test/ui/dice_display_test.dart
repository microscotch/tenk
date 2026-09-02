import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/widgets/die_widget.dart';

void main() {
  testWidgets('1-3-4-5-6 : le 1 est gardé (obligatoire), le 5 décliné par défaut pour éviter un total finissant par 50',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(diceToRoll: 5, pendingRoll: analyzeRoll([1, 3, 4, 5, 6])),
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

    // Garder le 5 donnerait 100 (le 1) + 50 (le 5) = 150, un total qui finit
    // par 50 : interdit de s'arrêter dessus. Le décliner donne 100, un total
    // valide et bancable tout de suite. Le score optimal par défaut préfère
    // donc le décliner, même si 150 > 100 en valeur brute (voir
    // _defaultKeepCount dans game_screen.dart).
    // 5 dans "Piste" + 1 dans "Main courante" : le 1 (obligatoire, retenu par
    // défaut) y est déjà prévisualisé en fondu — un lancer déjà en attente au
    // montage de l'écran (comme ici, via debugLoadState) saute l'animation
    // d'apparition et affiche l'état "immobilisé" direct (voir _rollSettled/
    // _previewMoveRevealed dans game_screen.dart) : les deux copies du dé "1"
    // existent donc dans l'arbre dès le premier frame (celle de "Piste" à
    // opacité 0, celle de "Main courante" à opacité 1).
    final dice = tester.widgetList<DieWidget>(find.byType(DieWidget)).toList();
    expect(dice.length, 6);
    for (final d in dice) {
      switch (d.value) {
        case 1:
          expect(d.state, DieVisualState.kept, reason: 'le 1 doit être gardé (obligatoire)');
        case 5:
          expect(d.state, DieVisualState.declined,
              reason: 'le garder finirait sur un total de 150 (interdit de s\'arrêter sur un 50)');
        case 3:
        case 4:
        case 6:
          expect(d.state, DieVisualState.junk, reason: 'le ${d.value} seul ne vaut rien');
      }
    }
  });

  testWidgets('changer le nombre de 5 à garder met à jour l\'aperçu du score et les dés', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(diceToRoll: 5, pendingRoll: analyzeRoll([1, 1, 5, 5, 3])),
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

    // Par défaut, les deux 5 sont gardés : 200 (deux 1) + 100 (deux 5) = 300.
    // Le score de ce lancer est affiché dans le libellé de la zone "Piste".
    expect(find.text('Piste (300)'), findsOneWidget);
    expect(tester.widgetList<DieWidget>(find.byType(DieWidget)).where((d) => d.value == 5).map((d) => d.state),
        everyElement(DieVisualState.kept));

    await tester.tap(find.text('1'));
    await tester.pump();

    // Un seul 5 gardé : 200 + 50 = 250, l'aperçu doit se mettre à jour.
    expect(find.text('Piste (250)'), findsOneWidget);
    final fiveStates =
        tester.widgetList<DieWidget>(find.byType(DieWidget)).where((d) => d.value == 5).map((d) => d.state).toList();
    expect(fiveStates, containsAll([DieVisualState.kept, DieVisualState.declined]));
  });

  testWidgets('un dé étendu affiche une bordure rouge, dans le lancer comme dans les dés gardés', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(
        diceToRoll: 4,
        extendedValues: const {2},
        pendingRoll: analyzeRoll([2, 3, 6, 1], extendedValues: const {2}),
        keptDiceThisTurn: const [KeptDie(value: 4, points: 100, isExtended: true)],
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
    // Un seul pump (pas pumpAndSettle) : ce lancer n'a aucun 5 à garder, donc
    // aucun choix réel — l'avancement automatique programme un lancer réel
    // 500ms plus tard, qui remplacerait ce lancer scripté avant l'assertion.
    await tester.pump();

    final dice = tester.widgetList<DieWidget>(find.byType(DieWidget)).toList();
    expect(dice.firstWhere((d) => d.value == 2).state, DieVisualState.extended,
        reason: 'le 2 étendu du lancer en cours doit ressortir en rouge');
    expect(dice.firstWhere((d) => d.value == 4).state, DieVisualState.extended,
        reason: 'le 4 étendu déjà gardé (persistant) doit aussi ressortir en rouge');
  });

  testWidgets(
      'régression : deux 5 sans aucun autre dé, un total tout gardé finissant par 50, ne plante pas',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Aucun dé "junk" dans ce lancer (2 dés, tous les deux des 5) : décliner
    // un 5 est physiquement impossible (RollAnalysis.canDeclineFives est
    // faux), même si tout garder (100 pts) amène le score du tour à 450 —
    // un total qui finit par 50, sur lequel _defaultKeepCount cherchait
    // auparavant une meilleure option en tentant de décliner un 5 quand même,
    // ce qui faisait planter applyKeepDecision (StateError).
    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn:
          TurnState(diceToRoll: 2, bankedScore: 350, pendingRoll: analyzeRoll([5, 5]), hasRolledThisTurn: true),
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

    expect(tester.takeException(), isNull, reason: 'calculer le défaut ne doit jamais planter');
    expect(find.text('Combien de 5 garder ?'), findsNothing,
        reason: 'aucun vrai choix : pas de dé junk pour relancer avec un 5 décliné');
    final fives = tester.widgetList<DieWidget>(find.byType(DieWidget)).where((d) => d.value == 5);
    expect(fives, isNotEmpty);
    expect(fives.every((d) => d.state != DieVisualState.declined), isTrue,
        reason: 'les deux 5 sont forcément gardés, seule option légale');
  });
}
