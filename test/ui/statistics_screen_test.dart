import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/player_stats.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_statistics.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/player_stats_screen.dart';
import 'package:le10000/ui/screens/statistics_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';

void main() {
  late FakePlayerStore players;

  setUp(() => players = FakePlayerStore());

  Future<void> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        playerStoreProvider.overrideWithValue(players),
        archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
        // Le recalcul dérive TOUT des parties archivées : le laisser tourner
        // sur une archive vide remettrait à zéro les fiches que ces tests
        // viennent d'écrire. Il a ses propres tests
        // (`player_statistics_test.dart`) ; ici on n'éprouve que le rendu.
        playerStatisticsSyncProvider.overrideWith((ref) async => 0),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatisticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans partie jouée, les records le disent au lieu de mentir', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie'));
    await pump(tester);

    expect(find.text('Aucun record pour l\'instant.'), findsOneWidget);
  });

  testWidgets('un joueur sans partie n\'apparaît pas dans la liste', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie'));
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Marie'), findsNothing,
        reason: 'une fiche vierge n\'a rien à montrer ici ; elle reste dans la gestion des joueurs');
  });

  testWidgets('un joueur ayant joué est listé, avec un chevron vers son détail', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie')
        .copyWith(stats: const PlayerStats(gamesPlayed: 4, gamesWon: 3, brelans: {4: 3})));
    await pump(tester);

    expect(find.text('Marie'), findsOneWidget);
    expect(find.text('4 parties jouées'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.text('Marie'));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerStatsScreen), findsOneWidget);
  });

  testWidgets('un record à égalité nomme tous ses détenteurs', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie')
        .copyWith(stats: const PlayerStats(gamesPlayed: 1, bestBankedTurn: 2000)));
    await players.write(PlayerProfile.create(name: 'Bob')
        .copyWith(stats: const PlayerStats(gamesPlayed: 1, bestBankedTurn: 2000)));
    await pump(tester);

    expect(find.text('2000 — Bob, Marie'), findsOneWidget,
        reason: 'départager arbitrairement serait injuste et instable d\'un recalcul à l\'autre');
  });
}
