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
import 'package:le10000/ui/widgets/bordered_section.dart';
import 'package:le10000/ui/widgets/die_widget.dart';
import 'package:le10000/ui/widgets/stat_row.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';

void main() {
  late FakePlayerStore players;

  setUp(() => players = FakePlayerStore());

  Future<void> pump(WidgetTester tester) async {
    // Haute : un `ListView` ne construit pas ce qui est sous le pli, et un
    // panneau déplié fait une quarantaine de lignes.
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
          // Fixé plutôt que laissé au défaut de l'environnement de test : le
          // séparateur décimal d'une moyenne en dépend (« 3,3 » ou « 3.3 »).
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatisticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Écrit un joueur ayant joué, puis affiche l'écran avec son panneau déplié.
  Future<void> pumpExpanded(WidgetTester tester, PlayerProfile player) async {
    await players.write(player);
    await pump(tester);
    await tester.tap(find.text(player.displayName));
    await tester.pumpAndSettle();
  }

  /// Déplie la ligne [label] (une figure) : son détail est replié par défaut.
  Future<void> unfold(WidgetTester tester, String label, {Finder? within}) async {
    final target = within == null ? find.text(label) : find.descendant(of: within, matching: find.text(label));
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Finder valueOf(String label, String text) => find.descendant(
        of: find.widgetWithText(StatRow, label),
        matching: find.text(text),
      );

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

  testWidgets('un joueur ayant joué est listé avec son résumé, panneau replié', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie').copyWith(
        stats: const PlayerStats(gamesPlayed: 4, gamesWon: 3, bestBankedTurn: 2500, brelans: {4: 3})));
    await pump(tester);

    expect(find.text('Marie'), findsOneWidget);
    final panneau = find.ancestor(of: find.text('Marie'), matching: find.byType(ExpansionTile));
    expect(
      find.descendant(of: panneau, matching: find.text('4 parties · 3 gagnées · meilleur 2500')),
      findsOneWidget,
      reason: 'le résumé se lit sans rien déplier',
    );
    expect(find.text('Temps de jeu'), findsNothing, reason: 'le détail est replié par défaut');
  });

  testWidgets('chaque joueur a son propre résumé', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie')
        .copyWith(stats: const PlayerStats(gamesPlayed: 4, gamesWon: 3, bestBankedTurn: 2500)));
    await players.write(PlayerProfile.create(name: 'Bob')
        .copyWith(stats: const PlayerStats(gamesPlayed: 1, gamesWon: 0, bestBankedTurn: 900)));
    await pump(tester);

    String summaryOf(String name) {
      final panneau = find.ancestor(of: find.text(name), matching: find.byType(ExpansionTile));
      final tile = tester.widget<ExpansionTile>(panneau);
      return (tile.subtitle! as Text).data!;
    }

    expect(summaryOf('Marie'), '4 parties · 3 gagnées · meilleur 2500');
    expect(summaryOf('Bob'), '1 partie · 0 gagnée · meilleur 900');
  });

  testWidgets('toucher un joueur déplie son détail sur place, sans changer d\'écran',
      (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie')
        .copyWith(stats: const PlayerStats(gamesPlayed: 4, gamesWon: 3, brelans: {4: 3})));
    await pump(tester);
    expect(find.text('Temps de jeu'), findsNothing);

    await tester.tap(find.text('Marie'));
    await tester.pumpAndSettle();

    expect(find.text('Temps de jeu'), findsOneWidget, reason: 'le détail est apparu');
    expect(find.byType(StatisticsScreen), findsOneWidget, reason: 'toujours sur l\'écran général');
    expect(find.byType(BackButton), findsNothing, reason: 'aucun écran n\'a été empilé');
    expect(find.text('Records'), findsOneWidget, reason: 'les records restent visibles en tête');

    await tester.tap(find.text('Marie'));
    await tester.pumpAndSettle();
    expect(find.text('Temps de jeu'), findsNothing, reason: 'un second toucher le replie');
  });

  testWidgets('les compteurs du joueur sont rendus', (tester) async {
    await pumpExpanded(
      tester,
      PlayerProfile.create(name: 'Marie').copyWith(
        stats: const PlayerStats(
          gamesPlayed: 4,
          gamesWon: 3,
          totalActiveSeconds: 3600,
          shortestActiveSeconds: 300,
          longestActiveSeconds: 1800,
          bestBankedTurn: 2500,
        ),
      ),
    );

    expect(find.text('1 h 00'), findsOneWidget, reason: 'le temps total, lisible');
    expect(find.text('5 min'), findsOneWidget, reason: 'la partie la plus courte');
    expect(valueOf('Meilleur tour', '2500'), findsWidgets);
  });

  testWidgets('chaque figure liste ses six valeurs, zéros compris', (tester) async {
    await pumpExpanded(
      tester,
      PlayerProfile.create(name: 'Marie').copyWith(
        stats: const PlayerStats(gamesPlayed: 2, brelans: {4: 3, 1: 1}),
      ),
    );

    // Brelans, carrés et quintes : trois figures ventilées sur six valeurs, dont
    // le détail est replié tant qu'on ne l'a pas demandé.
    final panneau = find.byType(ExpansionTile);
    Finder inPanel(Finder f) => find.descendant(of: panneau, matching: f);
    expect(inPanel(find.byType(BreakdownRow)), findsNothing, reason: 'replié par défaut');
    for (final figure in ['Brelans', 'Carrés', 'Quintes']) {
      await unfold(tester, figure, within: panneau);
    }
    expect(inPanel(find.byType(BreakdownRow)), findsNWidgets(18));
    expect(inPanel(find.byType(DieGlyph)), findsNWidgets(18),
        reason: 'la valeur est dessinée, pas écrite en chiffres');

    final brelans = tester.widgetList<BreakdownRow>(inPanel(find.byType(BreakdownRow))).take(6).toList();
    expect(brelans.map((r) => r.value), [1, 2, 3, 4, 5, 6], reason: 'toujours dans l\'ordre');
    expect(brelans.map((r) => r.count), [1, 0, 0, 3, 0, 0],
        reason: 'une valeur jamais sortie s\'affiche à zéro plutôt que de disparaître');
  });

  testWidgets('déplier une figure montre son détail, la replier le cache', (tester) async {
    await pumpExpanded(
      tester,
      PlayerProfile.create(name: 'Marie').copyWith(stats: const PlayerStats(gamesPlayed: 1, brelans: {4: 3})),
    );
    final panneau = find.byType(ExpansionTile);
    Finder inPanel(Finder f) => find.descendant(of: panneau, matching: f);

    await unfold(tester, 'Brelans', within: panneau);
    expect(inPanel(find.byType(BreakdownRow)), findsNWidgets(6), reason: 'les six valeurs, pas les autres figures');

    await unfold(tester, 'Brelans', within: panneau);
    expect(inPanel(find.byType(BreakdownRow)), findsNothing);
  });

  testWidgets('chaque valeur du détail est suivie de sa part du total, à deux décimales', (tester) async {
    // 8 brelans : 5 de 4, 2 de 1 et 1 de 6 — 62,50 %, 25,00 % et 12,50 %.
    await pumpExpanded(
      tester,
      PlayerProfile.create(name: 'Marie').copyWith(
        stats: const PlayerStats(gamesPlayed: 3, brelans: {4: 5, 1: 2, 6: 1}, petitesSuites: 1, grandesSuites: 2),
      ),
    );
    final panneau = find.byType(ExpansionTile);
    await unfold(tester, 'Brelans', within: panneau);

    final rows = tester.widgetList<BreakdownRow>(find.descendant(of: panneau, matching: find.byType(BreakdownRow))).toList();
    expect(rows.map((r) => r.total), everyElement(8), reason: 'la part est celle du total de la figure');
    for (final texte in ['2 (25,00 %)', '0 (0,00 %)', '5 (62,50 %)', '1 (12,50 %)']) {
      expect(find.descendant(of: panneau, matching: find.text(texte)), findsWidgets, reason: texte);
    }

    // Les suites et les quintes d'as ont leur part aussi : 1 petite sur 3 suites.
    await unfold(tester, 'Suites', within: panneau);
    expect(find.descendant(of: panneau, matching: find.text('1 (33,33 %)')), findsOneWidget);
    expect(find.descendant(of: panneau, matching: find.text('2 (66,67 %)')), findsOneWidget);
  });

  testWidgets('sans rien à répartir, la valeur du détail n\'a pas de pourcentage', (tester) async {
    await pumpExpanded(
      tester,
      PlayerProfile.create(name: 'Marie').copyWith(stats: const PlayerStats(gamesPlayed: 1)),
    );
    final panneau = find.byType(ExpansionTile);
    await unfold(tester, 'Brelans', within: panneau);

    expect(find.descendant(of: panneau, matching: find.textContaining('%')), findsNothing,
        reason: 'une part de rien n\'existe : ce n\'est pas 0 %');
    expect(find.descendant(of: panneau, matching: find.text('0')), findsWidgets);
  });

  testWidgets('les tours, les lancers et leur moyenne sont rendus, cumulés sur les parties',
      (tester) async {
    // Deux parties cumulées : 10 lancers en 2 tours puis 30 en 10. La moyenne
    // du cumul est 40 / 12 = 3,3 ; la moyenne des deux moyennes (5 et 3), 4,0,
    // serait fausse — c'est ce que ce test empêche d'écrire.
    final cumul = const PlayerStats(gamesPlayed: 1, rollsTotal: 10, turnsTotal: 2) +
        const PlayerStats(gamesPlayed: 1, rollsTotal: 30, turnsTotal: 10);
    await pumpExpanded(tester, PlayerProfile.create(name: 'Marie').copyWith(stats: cumul));

    expect(valueOf('Tours joués', '12'), findsOneWidget);
    expect(valueOf('Lancers', '40'), findsOneWidget);
    expect(valueOf('Lancers par tour', '3,3'), findsOneWidget, reason: '40 lancers en 12 tours');
    expect(find.text('4,0'), findsNothing, reason: 'pas une moyenne de moyennes');
  });

  testWidgets('sans aucun tour, la moyenne de lancers s\'affiche en tiret', (tester) async {
    // Une partie jouée mais aucun tour comptabilisé : une fiche à zéro partie
    // n'est pas listée, il faut donc au moins une partie pour la voir.
    await pumpExpanded(
      tester,
      PlayerProfile.create(name: 'Marie').copyWith(stats: const PlayerStats(gamesPlayed: 1)),
    );

    expect(valueOf('Lancers par tour', '—'), findsOneWidget,
        reason: 'zéro tour : une moyenne n\'existe pas, ce n\'est pas 0');
  });

  testWidgets('le surnom titre le panneau à la place du nom', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi')
        .copyWith(stats: const PlayerStats(gamesPlayed: 1)));
    await pump(tester);

    final panneau = find.byType(ExpansionTile);
    expect(find.descendant(of: panneau, matching: find.text('Mimi')), findsOneWidget);
    expect(find.text('Marie Curie'), findsNothing);
  });

  group('records des figures', () {
    final records = find.widgetWithText(BorderedSection, 'Records');

    List<BreakdownRow> facesOf(WidgetTester tester) => tester
        .widgetList<BreakdownRow>(find.descendant(of: records, matching: find.byType(BreakdownRow)))
        .toList();

    /// La valeur de record [value] sur la ligne [label], qu'elle soit simple ou
    /// dépliable (le libellé d'un détail s'écrit avec son tiret). Pour une ligne
    /// dépliable, c'est la valeur de son en-tête, pas celles de son détail.
    Finder recordOf(String label, String value) {
      final simple = find.byWidgetPredicate(
          (w) => w is StatRow && (w.label == label || (w.detail && '– ${w.label}' == label)));
      final expandable = find.byWidgetPredicate((w) => w is ExpandableStatRow && w.label == label);
      final header = find.descendant(of: find.descendant(of: records, matching: expandable), matching: find.byType(InkWell));
      final onSimple = find.descendant(of: find.descendant(of: records, matching: simple), matching: find.text(value));
      final onHeader = find.descendant(of: header, matching: find.text(value));
      return onHeader.evaluate().isNotEmpty ? onHeader : onSimple;
    }

    Future<void> twoPlayers() async {
      await players.write(PlayerProfile.create(name: 'Marie').copyWith(
          stats: const PlayerStats(
              gamesPlayed: 2, brelans: {4: 3}, carres: {2: 1}, grandesSuites: 1)));
      await players.write(PlayerProfile.create(name: 'Bob').copyWith(
          stats: const PlayerStats(
              gamesPlayed: 2, brelans: {4: 1, 1: 2}, petitesSuites: 2)));
    }

    testWidgets('chaque figure est ventilée par valeur de dé, avec le détenteur de chaque record',
        (tester) async {
      await twoPlayers();
      await pump(tester);

      expect(facesOf(tester), isEmpty, reason: 'le détail est replié par défaut');
      for (final figure in ['Brelans', 'Carrés', 'Quintes']) {
        await unfold(tester, figure, within: records);
      }
      final rows = facesOf(tester);
      expect(rows, hasLength(18), reason: 'brelans, carrés et quintes, six valeurs chacun');
      expect(rows.map((r) => r.total), everyElement(isNull),
          reason: 'un record par valeur n\'est pas une part : pas de pourcentage');
      expect(rows.take(6).map((r) => r.value), [1, 2, 3, 4, 5, 6]);

      // Brelans : Bob a le plus de brelans de 1, Marie le plus de brelans de 4.
      expect(rows.take(6).map((r) => r.display), [
        '2 — Bob',
        '0',
        '0',
        '3 — Marie',
        '0',
        '0',
      ]);
      // Carrés : seule Marie en a sorti, de 2.
      expect(rows.skip(6).take(6).map((r) => r.display), [
        '0',
        '1 — Marie',
        '0',
        '0',
        '0',
        '0',
      ]);
      expect(rows.skip(12).map((r) => r.display), everyElement('0'), reason: 'aucune quinte');
    });

    testWidgets('le total de la figure donne tous ses détenteurs, ou rien si personne n\'en a',
        (tester) async {
      await twoPlayers();
      await pump(tester);

      expect(recordOf('Brelans', '3 — Bob, Marie'), findsOneWidget,
          reason: 'à égalité, les deux sont nommés');
      expect(recordOf('Carrés', '1 — Marie'), findsOneWidget);
      expect(recordOf('Quintes', '0'), findsOneWidget,
          reason: 'un record à zéro n\'a pas de détenteur à nommer');
    });

    testWidgets('les suites sont détaillées en petites et grandes', (tester) async {
      await twoPlayers();
      await pump(tester);
      await unfold(tester, 'Suites', within: records);

      expect(recordOf('Suites', '2 — Bob'), findsOneWidget);
      expect(recordOf('– dont petites', '2 — Bob'), findsOneWidget);
      expect(recordOf('– dont grandes', '1 — Marie'), findsOneWidget);
    });

    testWidgets('le record de série de craquages suit celui des craquages qu\'il détaille',
        (tester) async {
      await players.write(PlayerProfile.create(name: 'Marie')
          .copyWith(stats: const PlayerStats(gamesPlayed: 1, bustsTotal: 5, longestBustStreak: 3)));
      await pump(tester);

      expect(recordOf('Craquages', '5 — Marie'), findsOneWidget);
      final labels = tester
          .widgetList<StatRow>(find.descendant(of: records, matching: find.byType(StatRow)))
          .map((r) => r.label)
          .toList();
      expect(labels[labels.indexOf('Craquages') + 1], 'dont série la plus longue',
          reason: 'sans son parent, « dont » se lirait comme le détail de la ligne précédente');
    });

    testWidgets('les figures ont leur titre, comme sur la fiche d\'un joueur', (tester) async {
      await twoPlayers();
      await pump(tester);

      expect(find.descendant(of: records, matching: find.text('Figures')), findsOneWidget);
    });
  });

  testWidgets('tous les détails « dont » portent le tiret, sur la fiche d\'un joueur comme ailleurs',
      (tester) async {
    await pumpExpanded(
      tester,
      PlayerProfile.create(name: 'Marie').copyWith(
        stats: const PlayerStats(
          gamesPlayed: 1,
          petitesSuites: 1,
          grandesSuites: 1,
          quintesDAsReussies: 1,
          bustsTotal: 2,
          longestBustStreak: 2,
        ),
      ),
    );

    final panneau = find.byType(ExpansionTile);
    await unfold(tester, 'Suites', within: panneau);
    await unfold(tester, 'Quintes d\'as', within: panneau);
    for (final label in [
      '– dont petites',
      '– dont grandes',
      '– dont gagnantes',
      '– dont série la plus longue',
    ]) {
      expect(find.descendant(of: panneau, matching: find.text(label)), findsOneWidget, reason: label);
    }
    expect(find.text('dont petites'), findsNothing, reason: 'jamais sans son tiret');
    expect(find.text('dont grandes'), findsNothing);
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
