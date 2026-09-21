import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/player_stats.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/screens/player_stats_screen.dart';
import 'package:le10000/ui/widgets/die_widget.dart';
import 'package:le10000/ui/widgets/stat_row.dart';

void main() {
  Future<void> pump(WidgetTester tester, PlayerProfile player) async {
    await tester.pumpWidget(
      MaterialApp(
        // Fixé plutôt que laissé au défaut de l'environnement de test : le
        // séparateur décimal d'une moyenne en dépend (« 3,3 » ou « 3.3 »).
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerStatsScreen(player: player),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('les compteurs du joueur sont rendus', (tester) async {
    await pump(
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
    expect(find.text('2500'), findsOneWidget);
  });

  testWidgets('chaque figure liste ses six valeurs, zéros compris', (tester) async {
    await pump(
      tester,
      PlayerProfile.create(name: 'Marie').copyWith(
        stats: const PlayerStats(gamesPlayed: 2, brelans: {4: 3, 1: 1}),
      ),
    );

    // Brelans, carrés et quintes : trois figures ventilées sur six valeurs.
    expect(find.byType(BreakdownRow), findsNWidgets(18));
    expect(find.byType(DieGlyph), findsNWidgets(18),
        reason: 'la valeur est dessinée, pas écrite en chiffres');

    final brelans = tester.widgetList<BreakdownRow>(find.byType(BreakdownRow)).take(6).toList();
    expect(brelans.map((r) => r.value), [1, 2, 3, 4, 5, 6], reason: 'toujours dans l\'ordre');
    expect(brelans.map((r) => r.count), [1, 0, 0, 3, 0, 0],
        reason: 'une valeur jamais sortie s\'affiche à zéro plutôt que de disparaître');
  });

  testWidgets('les tours, les lancers et leur moyenne sont rendus, cumulés sur les parties',
      (tester) async {
    // Deux parties cumulées : 10 lancers en 2 tours puis 30 en 10. La moyenne
    // du cumul est 40 / 12 = 3,3 ; la moyenne des deux moyennes (5 et 3), 4,0,
    // serait fausse — c'est ce que ce test empêche d'écrire.
    final cumul = const PlayerStats(gamesPlayed: 1, rollsTotal: 10, turnsTotal: 2) +
        const PlayerStats(gamesPlayed: 1, rollsTotal: 30, turnsTotal: 10);
    await pump(tester, PlayerProfile.create(name: 'Marie').copyWith(stats: cumul));

    Finder valueOf(String label, String text) => find.descendant(
          of: find.widgetWithText(StatRow, label),
          matching: find.text(text),
        );
    expect(valueOf('Tours joués', '12'), findsOneWidget);
    expect(valueOf('Lancers', '40'), findsOneWidget);
    expect(valueOf('Lancers par tour', '3,3'), findsOneWidget, reason: '40 lancers en 12 tours');
    expect(find.text('4,0'), findsNothing, reason: 'pas une moyenne de moyennes');
  });

  testWidgets('sans aucun tour, la moyenne de lancers s\'affiche en tiret', (tester) async {
    await pump(tester, PlayerProfile.create(name: 'Marie'));

    final moyenne = find.descendant(
      of: find.widgetWithText(StatRow, 'Lancers par tour'),
      matching: find.text('—'),
    );
    expect(moyenne, findsOneWidget, reason: 'zéro tour : une moyenne n\'existe pas, ce n\'est pas 0');
  });

  testWidgets('une fiche vierge ne plante pas et affiche des tirets', (tester) async {
    await pump(tester, PlayerProfile.create(name: 'Marie'));

    expect(tester.takeException(), isNull);
    expect(find.text('—'), findsWidgets,
        reason: 'une durée inexistante s\'affiche en tiret, pas en zéro');
  });

  testWidgets('le surnom titre l\'écran', (tester) async {
    await pump(tester, PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi'));

    expect(find.text('Mimi'), findsWidgets);
    expect(find.text('Marie Curie'), findsNothing);
  });
}
