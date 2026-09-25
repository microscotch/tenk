import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/finished_games_screen.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

/// Un tap sur un run terminé ouvre son écran de fin — classement, courbe,
/// statistiques, rejeu — et non plus directement le rejeu.
void main() {
  const setup = GameSetup(playerNames: ['Alice', 'Bruno']);

  late FakeGameSaveStore archive;

  setUp(() => archive = FakeGameSaveStore());

  SavedGame finishedGame(int seed, String alias) => SavedGame(
        seed: seed,
        setup: setup,
        alias: alias,
        createdAt: DateTime(2026, 1, 1),
        actions: playScriptedGame(setup, seed).actions,
      );

  /// Ouvre la liste depuis un écran d'accueil, comme dans l'app : la liste n'y
  /// est pas la première route. Sans cet écran dessous, `popToHome` s'arrêterait
  /// sur la liste elle-même, et un retour « à la liste » ne se distinguerait pas
  /// d'un retour « à l'accueil ».
  Future<void> pumpList(WidgetTester tester, {TargetPlatform? platform}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          archivedGameSaveStoreProvider.overrideWithValue(archive),
          gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
          playerStoreProvider.overrideWithValue(FakePlayerStore()),
        ],
        child: MaterialApp(
          theme: platform == null ? null : ThemeData(platform: platform),
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FinishedGamesScreen()),
                  ),
                  child: const Text('ACCUEIL'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ACCUEIL'));
    await tester.pumpAndSettle();
  }

  testWidgets('un tap ouvre l\'écran de fin de la partie, avec le bon vainqueur', (tester) async {
    final saved = finishedGame(11, 'Vieille partie');
    await archive.write(saved);
    await pumpList(tester);

    await tester.tap(find.text('Vieille partie'));
    await tester.pumpAndSettle();

    expect(find.byType(GameOverScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing, reason: 'l\'écran de fin, pas le rejeu direct');

    // Le vainqueur relu en rejouant le journal, indépendamment de l'écran.
    final engine = replayGame(saved.setup, saved.seed, saved.actions).engine!;
    final winner = engine.players[engine.winnerIndex!].name;
    expect(find.text('$winner gagne !'), findsOneWidget);
    for (final player in engine.players) {
      expect(find.textContaining('${player.name} : ${player.totalScore}'), findsOneWidget);
    }
  });

  testWidgets('l\'écran de fin d\'un run propose courbe, statistiques et rejeu', (tester) async {
    await archive.write(finishedGame(12, 'Partie 12'));
    await pumpList(tester);

    await tester.tap(find.text('Partie 12'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Évolution des scores'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Statistiques de la partie'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Revoir la partie'), findsOneWidget);
  });

  testWidgets('le retour depuis l\'écran de fin d\'un run ramène à la liste, pas à l\'accueil',
      (tester) async {
    await archive.write(finishedGame(13, 'Partie 13'));
    await pumpList(tester);
    await tester.tap(find.text('Partie 13'));
    await tester.pumpAndSettle();
    expect(find.byType(GameOverScreen), findsOneWidget);

    // Le retour système, celui d'Android : à la fin d'une partie jouée il
    // vide toute la pile jusqu'à l'accueil (voir `popToHome`).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(GameOverScreen), findsNothing);
    expect(find.byType(FinishedGamesScreen), findsOneWidget, reason: 'la liste, pas l\'accueil');
    expect(find.text('ACCUEIL'), findsNothing);
    expect(find.text('Partie 13'), findsOneWidget, reason: 'la liste est bien là, intacte');
  });

  testWidgets('sur Android, l\'écran de fin d\'un run n\'a pas de flèche : le retour système suffit',
      (tester) async {
    await archive.write(finishedGame(14, 'Partie 14'));
    await pumpList(tester, platform: TargetPlatform.android);
    await tester.tap(find.text('Partie 14'));
    await tester.pumpAndSettle();

    expect(find.byType(GameOverScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('iOS : la flèche de retour de l\'écran de fin d\'un run ramène aussi à la liste', (tester) async {
    await archive.write(finishedGame(14, 'Partie 14'));
    await pumpList(tester, platform: TargetPlatform.iOS);
    await tester.tap(find.text('Partie 14'));
    await tester.pumpAndSettle();

    // La flèche elle-même : `pageBack()` la cherche par son infobulle anglaise
    // « Back », qui s'appelle « Retour » sous la locale française.
    expect(find.byType(BackButton), findsOneWidget, reason: 'la flèche automatique est là');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(FinishedGamesScreen), findsOneWidget);
    expect(find.byType(GameOverScreen), findsNothing);
  });

  testWidgets('une partie qui ne va pas à son terme est rejouée directement', (tester) async {
    // Pas de classement final à montrer : le journal s'arrête avant la victoire.
    final complete = finishedGame(15, 'Partie 15');
    await archive.write(SavedGame(
      seed: complete.seed,
      setup: complete.setup,
      alias: 'Partie 15',
      createdAt: complete.createdAt,
      actions: complete.actions.sublist(0, complete.actions.length - 1),
    ));
    await pumpList(tester);

    await tester.tap(find.text('Partie 15'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(GameOverScreen), findsNothing);
    expect(tester.widget<GameScreen>(find.byType(GameScreen)).replayMode, isTrue,
        reason: 'rejeu spectateur, droit sur la partie');
  });

  testWidgets('un journal illisible ne fait pas planter la liste, et le dit', (tester) async {
    await archive.write(SavedGame(
      seed: 16,
      setup: setup,
      alias: 'Partie cassée',
      createdAt: DateTime(2026, 1, 1),
      // Une banque sans départage ni tour : aucun moteur ne peut en sortir.
      actions: [GameAction.bank()],
    ));
    await pumpList(tester);

    await tester.tap(find.text('Partie cassée'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.byType(GameOverScreen), findsNothing);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('Cette partie ne peut pas être rejouée : son journal est incomplet.'), findsOneWidget);
  });
}
