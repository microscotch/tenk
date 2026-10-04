import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_statistics.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/game_statistics_screen.dart';
import 'package:le10000/ui/screens/settings_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

/// Le bilan d'une partie se consulte aussi PENDANT la partie, depuis la barre de
/// l'écran de jeu : sur le journal du moment, sans vainqueur.
void main() {
  Future<ProviderContainer> pumpResumedGame(WidgetTester tester, {bool replay = false}) async {
    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      playerStoreProvider.overrideWithValue(FakePlayerStore()),
    ]);
    addTearDown(container.dispose);
    final saved = buildResumableSavedGame(
      seed: 3,
      alias: 'En cours',
      playerNames: const ['Anna', 'Bob'],
      applyKeepAfterRoll: true,
    );
    container.read(gameProvider.notifier).resumeFromSave(saved);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(replayMode: replay),
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    return container;
  }

  Finder inAppBar(Finder f) => find.descendant(of: find.byType(AppBar), matching: f);

  /// Ouvre le menu (☰) de la barre de l'écran de jeu.
  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(inAppBar(find.byIcon(Icons.menu)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('le menu de la barre porte la grille, la courbe, le bilan de la partie, puis les paramètres', (tester) async {
    await pumpResumedGame(tester);
    await openMenu(tester);

    double top(String label) => tester.getTopLeft(find.text(label)).dy;
    expect(top('Grille des scores'), lessThan(top('Évolution des scores')));
    expect(top('Évolution des scores'), lessThan(top('Statistiques de la partie')));
    expect(top('Statistiques de la partie'), lessThan(top('Paramètres')));
    expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    expect(inAppBar(find.byIcon(Icons.grid_on)), findsNothing, reason: 'plus d\'icônes alignées dans la barre');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('le menu ouvre les paramètres', (tester) async {
    await pumpResumedGame(tester);
    await openMenu(tester);

    await tester.tap(find.text('Paramètres'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('le bilan ouvert en cours de partie reflète le journal du moment, sans vainqueur', (tester) async {
    final container = await pumpResumedGame(tester);
    final record = container.read(gameProvider.notifier).gameRecord!;
    final expected = collectGameStatistics(
      setup: record.setup,
      seed: record.seed,
      actions: record.actions,
      includeUnfinished: true,
    ).bySeat.fold(0, (sum, s) => sum + s.rollsTotal);
    expect(expected, greaterThan(0), reason: 'prémisse : la partie a déjà des lancers');

    await openMenu(tester);
    await tester.tap(find.text('Statistiques de la partie'));
    await tester.pumpAndSettle();

    expect(find.byType(GameStatisticsScreen), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsNothing, reason: 'pas de vainqueur tant que la partie continue');
    final rollsRow = find.ancestor(of: find.text('Lancers'), matching: find.byType(Row)).first;
    expect(find.descendant(of: rollsRow, matching: find.text('$expected')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('en rejeu, la barre ne porte pas de menu', (tester) async {
    await pumpResumedGame(tester, replay: true);
    expect(inAppBar(find.byIcon(Icons.menu)), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
