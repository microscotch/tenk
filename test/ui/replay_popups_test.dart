import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/ui/screens/game_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/scripted_game.dart';

/// Les popups du rejeu spectateur (craque, reprise de main) : mêmes que celles
/// de la partie jouée, inertes, refermées par le rejeu lui-même — et jamais
/// ouvertes une seconde fois par l'écran de la partie jouée, resté empilé
/// dessous quand le rejeu est lancé depuis l'écran de fin.
///
/// Les scénarios sont de vraies parties scriptées, tronquées juste après l'état
/// à observer : la popup s'ouvre sur cet état, puis l'action qui suit la
/// referme.
void main() {
  const humans = GameSetup(playerNames: ['A', 'B']);
  const bots = GameSetup(
    playerNames: ['A', 'B'],
    aiPlayers: {0: AiDifficulty.equilibre, 1: AiDifficulty.equilibre},
  );

  bool isDiceOff(GameAction a) =>
      a.type.isDiceOff;

  /// Le premier état d'une partie scriptée pour lequel [wanted] est vrai, et le
  /// journal qui y mène, terminé par l'action qui le quitte — ou par
  /// [closingAction] quand on en impose une autre.
  ({int seed, List<GameAction> diceOff, List<GameAction> game}) scenario(
    GameSetup setup,
    bool Function(GameEngine engine) wanted, {
    GameAction? closingAction,
  }) {
    for (var seed = 1; seed < 400; seed++) {
      final all = playScriptedGame(setup, seed).actions;
      final diceOff = all.takeWhile(isDiceOff).toList();
      final replayed = replayGame(setup, seed, diceOff);
      var engine = GameEngine.newGame(replayed.orderedSetup!.playerNames);
      for (var i = diceOff.length; i < all.length; i++) {
        if (!engine.gameOver && wanted(engine)) {
          return (
            seed: seed,
            diceOff: diceOff,
            game: [...all.sublist(diceOff.length, i), closingAction ?? all[i]],
          );
        }
        engine = applyGameAction(engine, all[i], replayed.random);
      }
    }
    throw StateError('aucune partie scriptée ne mène à l\'état voulu');
  }

  bool humanBust(GameEngine e) => e.activeTurn?.busted == true;
  bool inheritedChoice(GameEngine e) => e.activeTurn == null && e.nextTurnDice < 5;
  bool inheritedChoiceResumable(GameEngine e) => inheritedChoice(e) && !e.inheritedHandCannotBank;

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore())],
    );
  });

  tearDown(() => container.dispose());

  /// Monte l'écran de la partie JOUÉE, puis pousse le rejeu par-dessus, comme
  /// le fait le bouton « Revoir la partie » de l'écran de fin.
  Future<void> pumpReplay(
    WidgetTester tester,
    GameSetup setup,
    ({int seed, List<GameAction> diceOff, List<GameAction> game}) s,
  ) async {
    final notifier = container.read(gameProvider.notifier);
    // La partie jouée dessous est toujours à deux humains, quelle que soit la
    // table du rejeu : des bots y programmeraient des tours automatiques, que
    // rien n'arrête, alors qu'une partie terminée n'en a plus.
    notifier.startGame(humans);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final replayed = replayGame(setup, s.seed, s.diceOff);
    notifier.startGameReplay(
      replayed.orderedSetup!,
      GameRecordingHandoff(
        seed: 0,
        random: replayed.random,
        originalSetup: setup,
        alias: '',
        createdAt: DateTime(2026, 1, 1),
        actions: s.game,
      ),
    );
    tester.state<NavigatorState>(find.byType(Navigator)).push(
          MaterialPageRoute(builder: (_) => const GameScreen(replayMode: true)),
        );
    await tester.pump();
  }

  /// Fait avancer le temps, par petits pas, jusqu'à ce que [done] soit vrai.
  /// Le journal mène à l'état voulu par toute la partie qui le précède, qui a
  /// ses propres popups : le temps à laisser passer se compte en minutes.
  Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 6000 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(done(), isTrue, reason: 'l\'état attendu n\'est jamais survenu');
  }

  final dialog = find.byType(AlertDialog);

  /// La popup portant ce titre, et non n'importe laquelle : celles des états
  /// précédents du journal passent aussi.
  Finder popup(String title) => find.descendant(of: dialog, matching: find.text(title));
  final bustPopup = popup('Craqué !');
  final handPopup = popup('Reprendre ?');

  IconButton iconWithTooltip(WidgetTester tester, String tooltip) => tester.widget<IconButton>(
        find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
      );

  /// L'icône est-elle dessinée pleine (choisie) plutôt qu'en contour ?
  bool isFilled(IconButton button) =>
      button.style!.backgroundColor!.resolve({WidgetState.disabled}) != Colors.transparent;

  group('popup de craque', () {
    testWidgets('elle s\'affiche une seule fois, sans bouton, et le rejeu la referme', (tester) async {
      await pumpReplay(tester, humans, scenario(humans, humanBust));

      await pumpUntil(tester, () => bustPopup.evaluate().isNotEmpty);
      // Deux popups : l'écran de la partie jouée, resté dessous, ouvrait aussi
      // la sienne — et le rejeu ne fermait pas celle-là.
      expect(dialog, findsOneWidget);
      expect(find.text('Craqué !'), findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.byType(FilledButton)),
        findsNothing,
        reason: 'le spectateur n\'a rien à valider',
      );

      final bustedTurn = container.read(gameProvider)!.activeTurn;
      expect(bustedTurn?.busted, isTrue);

      await pumpUntil(tester, () => bustPopup.evaluate().isEmpty);
      expect(container.read(gameProvider)!.activeTurn, isNot(same(bustedTurn)),
          reason: 'elle se ferme parce que le rejeu est passé à la suite');
      expect(find.byType(GameScreen), findsWidgets, reason: 'le rejeu est toujours là');
    });

    testWidgets('le spectateur peut la refermer lui-même, le rejeu continue', (tester) async {
      await pumpReplay(tester, humans, scenario(humans, humanBust));
      await pumpUntil(tester, () => bustPopup.evaluate().isNotEmpty);

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(dialog, findsNothing, reason: 'le retour referme la popup du rejeu');
      expect(find.byType(GameScreen), findsWidgets, reason: 'et rien de plus');

      // L'étape suivante trouve la popup déjà partie : elle ne doit pas
      // dépiler autre chose à sa place.
      final bustedTurn = container.read(gameProvider)!.activeTurn;
      await pumpUntil(tester, () => container.read(gameProvider)!.activeTurn != bustedTurn);
      expect(find.byType(GameScreen), findsWidgets);
    });

    testWidgets('un tour de bot n\'ouvre aucune popup', (tester) async {
      await pumpReplay(tester, bots, scenario(bots, humanBust));

      await pumpUntil(tester, () => container.read(gameProvider)!.activeTurn?.busted == true);
      // Assez pour que la révélation du craque ait eu lieu.
      await tester.pump(const Duration(milliseconds: 900));
      expect(dialog, findsNothing, reason: 'comme en jeu réel, les tours IA n\'ont pas de popup');
    });
  });

  group('popup de reprise de main', () {
    testWidgets('elle s\'affiche dans le rejeu, inerte, et le rejeu la referme', (tester) async {
      await pumpReplay(tester, humans, scenario(humans, inheritedChoice));

      await pumpUntil(tester, () => handPopup.evaluate().isNotEmpty);
      expect(dialog, findsOneWidget);
      expect(find.text('Reprendre ?'), findsOneWidget);

      expect(iconWithTooltip(tester, 'Reprendre la main').onPressed, isNull);
      expect(iconWithTooltip(tester, 'Nouvelle main').onPressed, isNull);
      expect(find.byTooltip('Grille des scores'), findsNothing,
          reason: 'la grille s\'ouvrirait par-dessus une popup qui se referme seule');

      final before = container.read(gameProvider)!;
      await pumpUntil(tester, () => handPopup.evaluate().isEmpty);
      expect(container.read(gameProvider)!.activeTurn, isNotNull,
          reason: 'elle se ferme parce que le tour a démarré');
      expect(identical(container.read(gameProvider), before), isFalse);
    });

    testWidgets('la nouvelle main choisie par le joueur est mise en évidence', (tester) async {
      await pumpReplay(tester, humans, scenario(humans, inheritedChoice));
      await pumpUntil(tester, () => handPopup.evaluate().isNotEmpty);

      expect(isFilled(iconWithTooltip(tester, 'Nouvelle main')), isTrue);
      expect(isFilled(iconWithTooltip(tester, 'Reprendre la main')), isFalse);
    });

    testWidgets('la reprise choisie par le joueur est mise en évidence', (tester) async {
      await pumpReplay(
        tester,
        humans,
        scenario(
          humans,
          inheritedChoiceResumable,
          closingAction: GameAction.startTurn(useFullHand: false),
        ),
      );
      await pumpUntil(tester, () => handPopup.evaluate().isNotEmpty);

      expect(isFilled(iconWithTooltip(tester, 'Reprendre la main')), isTrue);
      expect(isFilled(iconWithTooltip(tester, 'Nouvelle main')), isFalse);
    });

    testWidgets('le début du rejeu n\'ouvre pas de popup : aucune main n\'est encore engagée',
        (tester) async {
      await pumpReplay(tester, humans, scenario(humans, inheritedChoice));

      // L'état initial du rejeu : partie neuve, premier tour pas encore lancé.
      expect(container.read(gameProvider)!.activeTurn, isNull);
      await tester.pump(const Duration(milliseconds: 100));
      expect(dialog, findsNothing);
    });

    testWidgets('un tour de bot n\'ouvre aucune popup', (tester) async {
      await pumpReplay(tester, bots, scenario(bots, inheritedChoice));

      await pumpUntil(tester, () => container.read(gameProvider)!.nextTurnDice < 5);
      await tester.pump(const Duration(milliseconds: 300));
      expect(dialog, findsNothing);
    });
  });
}
