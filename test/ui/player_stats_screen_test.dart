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
