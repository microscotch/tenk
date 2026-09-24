import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/dice_off_providers.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/dice_off_screen.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/game_statistics_screen.dart';
import 'package:le10000/ui/screens/players_screen.dart';
import 'package:le10000/ui/screens/score_chart_screen.dart';
import 'package:le10000/ui/widgets/die_widget.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

/// Un joueur se nomme partout par son surnom quand il en a un, par son nom
/// sinon — y compris pour une partie ARCHIVÉE, ouverte quand aucune partie
/// n'est en cours : la règle ne dépend pas de la partie « vivante ».
void main() {
  late FakePlayerStore players;
  late PlayerProfile marie;
  late PlayerProfile bruno;
  late GameSetup setup;
  late SavedGame saved;
  late GameEngine finished;

  setUp(() {
    players = FakePlayerStore();
    marie = PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi');
    bruno = PlayerProfile.create(name: 'Bruno');
    setup = GameSetup(playerNames: const ['Marie Curie', 'Bruno'], playerIds: {0: marie.id, 1: bruno.id});
    saved = SavedGame(
      seed: 21,
      setup: setup,
      alias: 'archive',
      createdAt: DateTime(2026, 1, 1),
      actions: playScriptedGame(setup, 21).actions,
    );
    finished = replayGame(saved.setup, saved.seed, saved.actions).engine!;
  });

  /// Monte [home] SANS aucune partie en cours : c'est le cas d'un run archivé
  /// ouvert depuis la liste des parties terminées.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    Widget home, {
    void Function(ProviderContainer container)? before,
  }) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await players.write(marie);
    await players.write(bruno);
    final container = ProviderContainer(
      overrides: [
        playerStoreProvider.overrideWithValue(players),
        gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
        archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(playersProvider.future);
    before?.call(container);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('partie archivée, aucune partie en cours', () {
    testWidgets('la courbe nomme les joueurs par leur surnom, légende et infobulle', (tester) async {
      await pumpApp(tester, ScoreChartScreen(players: finished.players, record: saved));

      // Une fois dans la légende, une fois dans l'infobulle du curseur.
      expect(find.text('Mimi'), findsNWidgets(2));
      expect(find.text('Bruno'), findsNWidgets(2), reason: 'sans surnom, le nom');
      expect(find.text('Marie Curie'), findsNothing);
    });

    testWidgets('les statistiques de la partie nomment le joueur par son surnom', (tester) async {
      await pumpApp(
        tester,
        GameStatisticsScreen(players: finished.players, winnerIndex: finished.winnerIndex!, record: saved),
      );

      expect(find.text('Mimi'), findsOneWidget);
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Marie Curie'), findsNothing);
    });

    testWidgets('l\'écran de fin nomme le vainqueur et le classement par leur surnom', (tester) async {
      await pumpApp(
        tester,
        GameOverScreen(
          players: finished.players,
          winnerIndex: finished.winnerIndex!,
          record: saved,
          archived: true,
        ),
      );

      expect(find.textContaining('Mimi'), findsWidgets);
      expect(find.textContaining('Marie Curie'), findsNothing);
    });

    testWidgets('une partie en cours étrangère ne prête pas ses surnoms', (tester) async {
      // Une autre partie est à l'écran, avec un joueur du même NOM en jeu mais
      // rattaché à une autre fiche : ses surnoms ne sont pas ceux de l'archive.
      final zoe = PlayerProfile.create(name: 'Marie Curie', nickname: 'Zoé');
      await players.write(zoe);
      await pumpApp(
        tester,
        ScoreChartScreen(players: finished.players, record: saved),
        before: (container) {
          final other = GameSetup(playerNames: const ['Marie Curie', 'Bruno'], playerIds: {0: zoe.id});
          container.read(gameProvider.notifier).debugLoadState(
                GameEngine.newGame(other.playerNames).copyWith(
                  players: [Player(name: 'Marie Curie'), Player(name: 'Bruno')],
                ),
                other,
              );
        },
      );

      expect(find.text('Mimi'), findsNWidgets(2), reason: 'le surnom de LA fiche de cette partie');
      expect(find.text('Zoé'), findsNothing);
    });

    testWidgets('une fiche renommée depuis la partie garde son surnom (le lien est l\'identifiant)',
        (tester) async {
      players = FakePlayerStore();
      marie = marie.copyWith(name: 'Marie Sklodowska');
      await pumpApp(tester, ScoreChartScreen(players: finished.players, record: saved));

      expect(find.text('Mimi'), findsNWidgets(2));
    });

    testWidgets('sans lien vers une fiche, le nom enregistré', (tester) async {
      final unlinked = SavedGame(
        seed: saved.seed,
        setup: GameSetup(playerNames: const ['Marie Curie', 'Bruno']),
        alias: 'ancienne',
        createdAt: saved.createdAt,
        actions: saved.actions,
      );
      await pumpApp(tester, ScoreChartScreen(players: finished.players, record: unlinked));

      expect(find.text('Marie Curie'), findsNWidgets(2));
      expect(find.text('Mimi'), findsNothing);
    });
  });

  testWidgets('le tirage au sort nomme les joueurs par leur surnom', (tester) async {
    late ProviderContainer diceOff;
    await pumpApp(
      tester,
      const DiceOffScreen(),
      before: (container) {
        diceOff = container;
        container.read(diceOffProvider.notifier).start(setup);
      },
    );

    expect(find.text('Mimi'), findsOneWidget, reason: 'le nom sous son dé');

    await tester.pump(DiceOffScreen.firstRollDelay);
    while (!diceOff.read(diceOffProvider)!.isResolved) {
      await tester.pump(DiceOffScreen.tieRerollDelay);
    }
    await tester.pump(DieWidget.maxRollDuration);

    expect(
      find.byWidgetPredicate((w) => w is Text && w.data != null && w.data!.contains('→') && w.data!.contains('Mimi')),
      findsOneWidget,
      reason: "l'ordre de jeu aussi",
    );
    expect(find.textContaining('Marie Curie'), findsNothing);
  });

  testWidgets('la confirmation de suppression nomme la fiche par son surnom', (tester) async {
    await players.write(marie);
    await pumpApp(tester, const PlayersScreen());

    await tester.drag(find.text('Mimi'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('« Mimi »'), findsOneWidget);
    expect(find.textContaining('Marie Curie'), findsNothing);
  });

  group('écran de jeu', () {
    testWidgets('une partie en cours nomme les joueurs par leur surnom', (tester) async {
      await pumpApp(
        tester,
        const GameScreen(),
        before: (container) {
          container.read(gameProvider.notifier).debugLoadState(
                GameEngine.newGame(setup.playerNames).startTurn(),
                setup,
              );
        },
      );

      expect(find.text('Mimi'), findsOneWidget);
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Marie Curie'), findsNothing);
    });

    testWidgets('le rejeu d\'une partie archivée nomme les joueurs par leur surnom', (tester) async {
      await pumpApp(
        tester,
        const GameScreen(replayMode: true),
        before: (container) => container.read(gameProvider.notifier).startReplay(saved),
      );

      expect(find.text('Mimi'), findsOneWidget);
      expect(find.text('Marie Curie'), findsNothing);
    });
  });
}
