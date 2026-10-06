import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

/// Le maillon que ni le compilateur ni les tests de l'écran de fin ne
/// surveillent : à la victoire, l'écran de JEU doit passer à l'écran de fin le
/// journal de la partie. `GameOverScreen.record` est optionnel — l'oublier
/// compile, et fait disparaître courbe, statistiques et rejeu en vraie partie.
void main() {
  testWidgets('la victoire ouvre un écran de fin qui porte le journal de la partie', (tester) async {
    const setup = GameSetup(playerNames: ['A', 'B']);
    // Atteindre exactement 10000 relance toujours un tour final complet
    // (voir GameEngine._advance) plutôt que de terminer la partie sur-le-champ
    // — et s'arrêter en-dessous est désormais interdit pendant ce tour final
    // (BankFailureReason.mustContinueFinalRound). La partie ne peut donc plus
    // jamais se terminer par un banquage : toujours par le craque de celui
    // qui, en tour final, échoue à égaler le détenteur. C'est ce craque que
    // ce test rejoue à la main.
    var seed = 1;
    late List<GameAction> complete;
    while (true) {
      complete = playScriptedGame(setup, seed).actions;
      if (complete.last.type == GameActionType.endBustedTurn) break;
      seed++;
      expect(seed, lessThan(300), reason: 'aucune partie de test ne finit par un craque');
    }
    // Le journal s'arrête juste avant le craque final : la partie est
    // reprise à l'instant précis où il ne manque plus que lui.
    final beforeVictory = SavedGame(
      seed: seed,
      setup: setup,
      alias: 'victoire',
      createdAt: DateTime(2026, 1, 1),
      actions: complete.sublist(0, complete.length - 1),
    );

    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      playerStoreProvider.overrideWithValue(FakePlayerStore()),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.resumeFromSave(beforeVictory);
    expect(container.read(gameProvider)!.gameOver, isFalse, reason: 'prémisse : rien n\'est encore gagné');

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
    await tester.pump();

    expect(container.read(gameProvider)!.activeTurn?.busted, isTrue, reason: 'prémisse : c\'est bien le craque final');
    notifier.endBustedTurn();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(GameOverScreen), findsOneWidget);
    final screen = tester.widget<GameOverScreen>(find.byType(GameOverScreen));
    expect(screen.record, isNotNull, reason: 'sans journal, ni courbe, ni statistiques, ni rejeu');
    expect(screen.record!.seed, seed);
    expect(screen.archived, isFalse, reason: 'une partie qu\'on vient de jouer : retour vers l\'accueil');
    expect(find.widgetWithText(OutlinedButton, 'Statistiques de la partie'), findsOneWidget);
  });
}
