import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/replay_pause_provider.dart';
import 'package:le10000/state/replay_progress_provider.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/widgets/replay_controls.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/scripted_game.dart';

/// Les commandes du rejeu, en bas de l'écran : pause / lecture, curseur de
/// tour, vitesse.
void main() {
  const setup = GameSetup(playerNames: ['A', 'B']);

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore())],
    );
  });

  tearDown(() => container.dispose());

  SavedGame finishedGame(int seed) => SavedGame(
        seed: seed,
        setup: setup,
        alias: 'test',
        createdAt: DateTime(2026, 1, 1),
        actions: playScriptedGame(setup, seed).actions,
      );

  /// Pose l'écran de rejeu sur [saved], sur un écran assez haut pour que les
  /// commandes du bas soient à portée du doigt.
  Future<SavedGame> pumpReplay(WidgetTester tester, {int seed = 21}) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final saved = finishedGame(seed);
    container.read(replayPausedProvider.notifier).set(false);
    container.read(gameProvider.notifier).startReplay(saved);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(replayMode: true),
        ),
      ),
    );
    await tester.pump();
    return saved;
  }

  final slider = find.byType(Slider);
  final pauseButton = find.byTooltip('Pause');
  final playButton = find.byTooltip('Lecture');

  Future<void> tapSliderAt(WidgetTester tester, double fraction) async {
    final rect = tester.getRect(slider);
    // Le rail du curseur est un peu en retrait de son cadre.
    const inset = 24.0;
    final x = rect.left + inset + (rect.width - 2 * inset) * fraction;
    await tester.tapAt(Offset(x, rect.center.dy));
    await tester.pump();
  }

  ReplayProgress progress() => container.read(replayProgressProvider);

  testWidgets('les commandes sont en bas de l\'écran, la vitesse n\'est plus dans la barre', (tester) async {
    await pumpReplay(tester);

    expect(find.byType(ReplayControls), findsOneWidget);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('x2')), findsNothing,
        reason: 'plus de vitesse dans la barre de navigation');
    expect(find.descendant(of: find.byType(ReplayControls), matching: find.text('x2')), findsOneWidget);
    expect(pauseButton, findsOneWidget);
    expect(slider, findsOneWidget);
  });

  testWidgets('le curseur donne le tour à l\'écran, sur le nombre de tours de la partie', (tester) async {
    await pumpReplay(tester);

    expect(find.text('1 / ${progress().count}'), findsOneWidget);
    expect(tester.widget<Slider>(slider).min, 1);
    expect(tester.widget<Slider>(slider).max, progress().count.toDouble());
  });

  testWidgets('la pause arrête le rejeu, la lecture le relance', (tester) async {
    await pumpReplay(tester);
    final debut = container.read(gameProvider);
    await tester.pump(const Duration(seconds: 3));
    expect(identical(container.read(gameProvider), debut), isFalse, reason: 'prémisse : le rejeu avance tout seul');

    await tester.tap(pauseButton);
    await tester.pump();
    // Le pas déjà programmé est annulé : plus rien ne bouge, même longtemps après.
    final enPause = container.read(gameProvider);
    await tester.pump(const Duration(seconds: 20));
    expect(identical(container.read(gameProvider), enPause), isTrue, reason: 'en pause, le rejeu est figé');
    expect(playButton, findsOneWidget, reason: 'le bouton propose maintenant de reprendre');

    await tester.tap(playButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(identical(container.read(gameProvider), enPause), isFalse, reason: 'la lecture a repris');
    expect(pauseButton, findsOneWidget);
  });

  testWidgets('toucher le curseur amène le rejeu au tour visé, et la suite reste fidèle', (tester) async {
    final saved = await pumpReplay(tester);
    await tester.tap(pauseButton);
    await tester.pump();
    final count = progress().count;

    await tapSliderAt(tester, 1);

    expect(progress().turn, count, reason: 'tout au bout : le dernier tour');
    expect(find.text('$count / $count'), findsOneWidget);
    final expected = replayGame(
      saved.setup,
      saved.seed,
      saved.actions.sublist(0, replayTurnStarts(saved.setup, saved.seed, saved.actions).last),
    ).engine!;
    expect(container.read(gameProvider)!.players.map((p) => p.totalScore),
        expected.players.map((p) => p.totalScore));

    // Et en revenant au tout début.
    await tapSliderAt(tester, 0);
    expect(progress().turn, 1);
    expect(container.read(gameProvider)!.players.map((p) => p.totalScore), everyElement(0));
  });

  testWidgets('aller à un tour reconstruit le journal de partie', (tester) async {
    await pumpReplay(tester);
    await tester.tap(pauseButton);
    await tester.pump();
    expect(find.textContaining(' pts'), findsNothing, reason: 'au premier tour, rien n\'est encore arrivé');

    await tapSliderAt(tester, 0.6);

    expect(find.textContaining(' pts'), findsWidgets, reason: 'les tours déjà joués figurent au journal');

    // Aller quelque part ne relance pas la lecture : le rejeu était en pause.
    final apresSaut = container.read(gameProvider);
    await tester.pump(const Duration(seconds: 10));
    expect(identical(container.read(gameProvider), apresSaut), isTrue, reason: 'toujours en pause');

    await tapSliderAt(tester, 0);
    expect(find.textContaining(' pts'), findsNothing, reason: 'et il se vide en revenant au début');
  });

  testWidgets('aller à un tour referme la popup ouverte', (tester) async {
    await pumpReplay(tester);
    final dialog = find.byType(AlertDialog);
    for (var i = 0; i < 6000 && dialog.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(dialog, findsOneWidget, reason: 'prémisse : une popup de rejeu est ouverte');
    // Sous la popup, rien à toucher : on passe par les commandes.
    container.read(replayPausedProvider.notifier).set(true);
    await tester.pump();

    final controls = tester.widget<ReplayControls>(find.byType(ReplayControls, skipOffstage: false));
    controls.onSeek(2);
    await tester.pump(const Duration(milliseconds: 400));

    expect(progress().turn, 2);
    expect(dialog, findsNothing, reason: 'la popup appartenait à l\'état qu\'on vient de quitter');
  });

  testWidgets('aller sur un choix de reprise n\'ouvre pas la popup, dont le fond couvrirait les commandes',
      (tester) async {
    final saved = await pumpReplay(tester);
    container.read(replayPausedProvider.notifier).set(true);
    await tester.pump();

    // Un tour qui commence sur le choix de reprendre une main héritée.
    final starts = replayTurnStarts(saved.setup, saved.seed, saved.actions);
    final turn = 1 +
        starts.indexWhere(
          (start) => replayGame(saved.setup, saved.seed, saved.actions.sublist(0, start)).engine!.activeTurn == null,
        );
    expect(turn, greaterThan(1), reason: 'prémisse : cette partie a un tour qui commence sur un choix');

    tester.widget<ReplayControls>(find.byType(ReplayControls)).onSeek(turn);
    // Assez longtemps pour que la popup, si elle devait s'ouvrir, l'ait fait.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));

    expect(progress().turn, turn);
    expect(container.read(gameProvider)!.activeTurn, isNull, reason: 'on est bien sur le choix');
    expect(find.byType(AlertDialog), findsNothing);
  });
}
