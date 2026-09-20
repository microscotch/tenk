import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/player_stats.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_statistics.dart';
import 'package:le10000/state/player_store.dart';
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

  testWidgets('une fiche vierge affiche des zéros, sans planter', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie'));
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Marie'), findsOneWidget);
    expect(find.text('—'), findsWidgets,
        reason: 'une durée inexistante s\'affiche en tiret, pas en zéro');
  });

  testWidgets('les compteurs d\'un joueur sont rendus, ventilation comprise', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie').copyWith(
      stats: const PlayerStats(
        gamesPlayed: 4,
        gamesWon: 3,
        totalActiveSeconds: 3600,
        shortestActiveSeconds: 300,
        longestActiveSeconds: 1800,
        brelans: {4: 3, 1: 1},
        bestBankedTurn: 2500,
      ),
    ));
    await pump(tester);

    expect(find.text('4'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('1'), findsWidgets, reason: 'parties perdues = jouées - gagnées');
    expect(find.text('4 (1×1, 4×3)'), findsOneWidget, reason: 'total puis détail par valeur');
    expect(find.text('1 h 00'), findsOneWidget, reason: 'le temps total, lisible');
    expect(find.text('5 min'), findsOneWidget, reason: 'la partie la plus courte');
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
