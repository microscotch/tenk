import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_statistics.dart';
import 'package:le10000/game/player_stats.dart';
import 'package:le10000/game/score_series.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/replay_pause_provider.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/dice_off_screen.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/game_statistics_screen.dart';
import 'package:le10000/ui/screens/score_chart_screen.dart';
import 'package:le10000/ui/widgets/bordered_section.dart';
import 'package:le10000/ui/widgets/score_chart.dart';
import 'package:le10000/ui/widgets/stat_row.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

/// Les boutons « courbe » et « statistiques » de l'écran de fin, et ce qu'ils
/// ouvrent — sur de vraies parties terminées, journal entier compris.
void main() {
  const setup = GameSetup(playerNames: ['A', 'B']);

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      playerStoreProvider.overrideWithValue(FakePlayerStore()),
    ]);
  });

  tearDown(() => container.dispose());

  SavedGame finishedGame(int seed) => SavedGame(
        seed: seed,
        setup: setup,
        alias: 'test',
        createdAt: DateTime(2026, 1, 1),
        actions: playScriptedGame(setup, seed).actions,
      );

  /// Pose l'écran de fin comme l'écran de jeu le fait : avec le journal que le
  /// notifier expose pour la partie à l'écran (voir le `ref.listen` de
  /// `game_screen.dart`, que `GameScreen passe le journal` plus bas vérifie).
  Future<void> pumpGameOver(WidgetTester tester) async {
    final engine = container.read(gameProvider)!;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          // Le français, langue de l'app : sans quoi le locale de test est `en`,
          // et une moyenne s'y écrirait « 2.4 » au lieu de « 2,4 ».
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameOverScreen(
            players: engine.players,
            winnerIndex: engine.winnerIndex!,
            record: container.read(gameProvider.notifier).gameRecord,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final chartButton = find.widgetWithText(OutlinedButton, 'Évolution des scores');
  final statsButton = find.widgetWithText(OutlinedButton, 'Statistiques de la partie');
  final replayButton = find.widgetWithText(OutlinedButton, 'Revoir la partie');

  testWidgets('sans journal de partie, ni courbe, ni statistiques, ni rejeu ne sont proposés',
      (tester) async {
    container.read(gameProvider.notifier).debugLoadState(
          GameEngine.newGame(['A', 'B']).copyWith(gameOver: true, winnerIndex: 0),
          setup,
        );

    await pumpGameOver(tester);

    expect(chartButton, findsNothing);
    expect(statsButton, findsNothing);
    expect(replayButton, findsNothing);
  });

  testWidgets('le bouton de rejeu relance le rejeu de CETTE partie', (tester) async {
    final saved = finishedGame(51);
    container.read(gameProvider.notifier).resumeFromSave(saved);
    await pumpGameOver(tester);
    expect(replayButton, findsOneWidget);

    // Dernier de la colonne : sous le pli d'un écran de test, le tap le
    // manquerait sans le faire défiler d'abord.
    await tester.ensureVisible(replayButton);
    // Un rejeu précédent quitté en pause : le nouveau démarre quand même en lecture.
    container.read(replayPausedProvider.notifier).set(true);
    await tester.tap(replayButton);
    // Deux pas plutôt que `pumpAndSettle` : le rejeu s'enchaîne de lui-même à
    // coups de minuteries, dont celui-ci attendrait indéfiniment la fin. Le
    // second laisse passer la transition de route, sans quoi l'écran n'est pas
    // encore là.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Droit sur la partie : le tirage au sort qui a fixé l'ordre de jeu n'est
    // pas remis en scène.
    expect(find.byType(DiceOffScreen), findsNothing);
    expect(tester.widget<GameScreen>(find.byType(GameScreen)).replayMode, isTrue);
    final game = container.read(gameProvider.notifier);
    expect(game.isReplay, isTrue);
    expect(game.gameRecord?.seed, 51, reason: 'le rejeu est celui de la partie qu\'on vient de finir');
    expect(container.read(replayPausedProvider), isFalse, reason: 'un rejeu démarre toujours en lecture');
  });

  testWidgets('la courbe ouverte est celle de la partie terminée', (tester) async {
    final saved = finishedGame(21);
    container.read(gameProvider.notifier).resumeFromSave(saved);
    await pumpGameOver(tester);

    await tester.tap(chartButton);
    await tester.pumpAndSettle();

    expect(find.byType(ScoreChartScreen), findsOneWidget);
    final chart = tester.widget<ScoreChart>(find.byType(ScoreChart));
    // Chaque joueur est tracé sur toute la partie : autant de points que de
    // tours joués, plus le départ à 0, et la courbe finit sur son score final.
    final expected = scoreSeriesByPlayer(saved.setup, saved.seed, saved.actions);
    expect(chart.series.map((s) => s.scores).toList(), expected);
    final engine = container.read(gameProvider)!;
    for (var i = 0; i < engine.players.length; i++) {
      expect(chart.series[i].scores.last, engine.players[i].totalScore);
    }
  });

  testWidgets('après un rejeu, la courbe est celle de la partie rejouée et non de la précédente',
      (tester) async {
    // Une partie X est jouée d'abord : ses seed/actions restent en mémoire.
    // On rejoue ensuite Y jusqu'à sa fin, comme le fait « Runs terminés ».
    final notifier = container.read(gameProvider.notifier);
    notifier.resumeFromSave(finishedGame(31));

    final replayed = finishedGame(32);
    bool isDiceOff(GameAction a) =>
        a.type == GameActionType.diceOffRoll || a.type == GameActionType.diceOffResolveRound;
    final diceOff = replayed.actions.takeWhile(isDiceOff).toList();
    final afterDiceOff = replayGame(replayed.setup, replayed.seed, diceOff);
    notifier.startGameReplay(
      afterDiceOff.rotatedSetup!,
      GameRecordingHandoff(
        seed: 0,
        random: afterDiceOff.random,
        originalSetup: replayed.setup,
        alias: '',
        createdAt: DateTime(2026, 1, 1),
        actions: replayed.actions.skip(diceOff.length).toList(),
      ),
      source: replayed,
    );
    while (notifier.hasNextReplayAction) {
      notifier.applyNextReplayAction();
    }
    expect(container.read(gameProvider)!.gameOver, isTrue, reason: 'prémisse : le rejeu est allé au bout');

    await pumpGameOver(tester);
    await tester.tap(chartButton);
    await tester.pumpAndSettle();

    final chart = tester.widget<ScoreChart>(find.byType(ScoreChart));
    expect(chart.series.map((s) => s.scores).toList(),
        scoreSeriesByPlayer(replayed.setup, replayed.seed, replayed.actions));
  });

  testWidgets('les statistiques se rattachent au bon joueur, même quand les deux ordres de sièges diffèrent',
      (tester) async {
    // `collectGameStatistics` rend l'ordre de la config d'origine, le moteur
    // celui du départage : pour que le test prouve quelque chose, il faut une
    // partie où le vainqueur du départage n'est PAS le premier joueur saisi, et
    // où les deux joueurs n'ont pas les mêmes chiffres.
    late SavedGame saved;
    late GameStatistics stats;
    var found = false;
    for (var seed = 1; seed < 300 && !found; seed++) {
      final candidate = finishedGame(seed);
      final replay = replayGame(candidate.setup, candidate.seed, candidate.actions);
      final order = replay.rotatedSetup!.playerNames;
      final s = collectGameStatistics(setup: candidate.setup, seed: candidate.seed, actions: candidate.actions);
      if (order.first != candidate.setup.playerNames.first &&
          (s.bySeat[0].turnsTotal != s.bySeat[1].turnsTotal ||
              s.bySeat[0].bestBankedTurn != s.bySeat[1].bestBankedTurn)) {
        saved = candidate;
        stats = s;
        found = true;
      }
    }
    expect(found, isTrue, reason: 'aucune partie de test ne réunit les conditions du scénario');

    // Assez haute pour que les DEUX tuiles soient construites : `ListView` ne
    // construit pas ce qui est sous le pli, et les cadres du haut (partie,
    // figures) occupent la moitié d'un écran de test par défaut.
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 1400));

    container.read(gameProvider.notifier).resumeFromSave(saved);
    await pumpGameOver(tester);
    await tester.tap(statsButton);
    await tester.pumpAndSettle();

    expect(find.byType(GameStatisticsScreen), findsOneWidget);
    String summary(int turns, int best, int busts) =>
        '$turns ${turns <= 1 ? 'tour' : 'tours'} · meilleur $best · $busts ${busts <= 1 ? 'craque' : 'craques'}';

    for (final name in saved.setup.playerNames) {
      final original = saved.setup.playerNames.indexOf(name);
      final s = stats.bySeat[original];
      // Dans SA tuile : chercher le résumé n'importe où à l'écran ne prouverait
      // rien, deux joueurs aux chiffres permutés le trouvant chacun dans la
      // tuile de l'autre.
      expect(
        find.descendant(
          of: find.widgetWithText(ExpansionTile, name),
          matching: find.text(summary(s.turnsTotal, s.bestBankedTurn, s.bustsTotal)),
        ),
        findsOneWidget,
        reason: 'le résumé de $name doit venir de SES chiffres, pas de ceux de l\'autre siège',
      );
    }

    expect(find.text('Durée de jeu'), findsOneWidget);
    expect(find.text('Tours joués'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget, reason: 'un seul vainqueur est couronné');
  });

  testWidgets('les figures de la partie sont totalisées sur toute la table, sans rien déplier',
      (tester) async {
    // Il faut des figures chez PLUSIEURS joueurs : si un seul en avait, le
    // total de la table et le compte de ce joueur seraient indiscernables, et
    // le test ne prouverait pas qu'on additionne.
    late SavedGame saved;
    late GameStatistics stats;
    var found = false;
    for (var seed = 1; seed < 300 && !found; seed++) {
      final candidate = finishedGame(seed);
      final s = collectGameStatistics(setup: candidate.setup, seed: candidate.seed, actions: candidate.actions);
      if (s.bySeat.every((p) => p.brelansTotal > 0) && s.bySeat.every((p) => p.suitesTotal >= 0)) {
        saved = candidate;
        stats = s;
        found = true;
      }
    }
    expect(found, isTrue, reason: 'aucune partie de test ne réunit les conditions du scénario');

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    container.read(gameProvider.notifier).resumeFromSave(saved);
    await pumpGameOver(tester);
    await tester.tap(statsButton);
    await tester.pumpAndSettle();

    final section = find.widgetWithText(BorderedSection, 'Figures de la partie');
    expect(section, findsOneWidget);

    final brelans = stats.bySeat.fold<int>(0, (sum, p) => sum + p.brelansTotal);
    expect(stats.bySeat.every((p) => p.brelansTotal < brelans), isTrue,
        reason: 'prémisse : le total est strictement plus grand que celui de chaque joueur');
    expect(
      find.descendant(
        of: find.descendant(of: section, matching: find.widgetWithText(StatRow, 'Brelans')),
        matching: find.text('$brelans'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.descendant(of: section, matching: find.widgetWithText(StatRow, 'Suites')),
        matching: find.text('${stats.bySeat.fold<int>(0, (sum, p) => sum + p.suitesTotal)}'),
      ),
      findsOneWidget,
    );
    // La même ventilation que la fiche d'un joueur, sommée sur la table : six
    // valeurs sous les brelans, puis sous les carrés, puis sous les quintes.
    final rows = tester
        .widgetList<BreakdownRow>(find.descendant(of: section, matching: find.byType(BreakdownRow)))
        .toList();
    expect(rows, hasLength(18));
    // Les détails « dont » portent le tiret, ici comme sur la fiche d'un joueur.
    expect(find.descendant(of: section, matching: find.text('– dont petites')), findsOneWidget);
    expect(find.descendant(of: section, matching: find.text('– dont grandes')), findsOneWidget);
    int onTable(Map<int, int> Function(PlayerStats) byValue, int face) =>
        stats.bySeat.fold<int>(0, (sum, p) => sum + (byValue(p)[face] ?? 0));
    for (var face = 1; face <= 6; face++) {
      expect(rows[face - 1].value, face);
      expect(rows[face - 1].count, onTable((p) => p.brelans, face), reason: 'brelans de valeur $face');
      expect(rows[6 + face - 1].count, onTable((p) => p.carres, face), reason: 'carrés de valeur $face');
      expect(rows[12 + face - 1].count, onTable((p) => p.quintes, face), reason: 'quintes de valeur $face');
    }
    expect(find.descendant(of: section, matching: find.text('Meilleur tour')), findsNothing,
        reason: 'un record personnel ne se totalise pas à l\'échelle d\'une table');
  });

  testWidgets('les lancers et les lancers par tour figurent pour la table et pour chaque joueur',
      (tester) async {
    final saved = finishedGame(61);
    final stats = collectGameStatistics(setup: saved.setup, seed: saved.seed, actions: saved.actions);
    final table = stats.bySeat.fold(PlayerStats.empty, (total, seat) => total + seat);
    String average(PlayerStats s) => formatAverage(s.averageRollsPerTurn, 'fr');
    // Prémisse : la moyenne de la table n'est celle d'aucun joueur, sans quoi
    // on ne saurait pas si l'écran totalise ou recopie un joueur.
    expect(stats.bySeat.map(average), isNot(contains(average(table))),
        reason: 'ce test doit pouvoir distinguer la table d\'un joueur');

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    container.read(gameProvider.notifier).resumeFromSave(saved);
    await pumpGameOver(tester);
    await tester.tap(statsButton);
    await tester.pumpAndSettle();

    Finder value(Finder within, String label, String text) => find.descendant(
          of: find.descendant(of: within, matching: find.widgetWithText(StatRow, label)),
          matching: find.text(text),
        );

    final tableSection = find.widgetWithText(BorderedSection, 'Partie');
    expect(value(tableSection, 'Tours joués', '${table.turnsTotal}'), findsOneWidget);
    expect(value(tableSection, 'Lancers', '${table.rollsTotal}'), findsOneWidget);
    expect(value(tableSection, 'Lancers par tour', average(table)), findsOneWidget);

    for (final name in saved.setup.playerNames) {
      final own = stats.bySeat[saved.setup.playerNames.indexOf(name)];
      final tile = find.widgetWithText(ExpansionTile, name);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(value(tile, 'Tours joués', '${own.turnsTotal}'), findsOneWidget, reason: 'tours de $name');
      expect(value(tile, 'Lancers', '${own.rollsTotal}'), findsOneWidget, reason: 'lancers de $name');
      expect(value(tile, 'Lancers par tour', average(own)), findsOneWidget, reason: 'moyenne de $name');
    }
  });

  testWidgets('le détail d\'un joueur se déplie', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    container.read(gameProvider.notifier).resumeFromSave(finishedGame(41));
    await pumpGameOver(tester);
    await tester.tap(statsButton);
    await tester.pumpAndSettle();
    expect(find.text('Figures'), findsNothing, reason: 'replié par défaut');

    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Figures'), findsOneWidget);
    expect(find.text('Meilleur tour'), findsOneWidget);
    expect(find.text('Parties jouées'), findsNothing,
        reason: 'sur une seule partie, ce groupe ne dit rien');
  });
}
