import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/dice_off_providers.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/dice_off_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/pass_device_screen.dart';
import 'package:le10000/ui/widgets/die_widget.dart';

void main() {
  Widget app(ProviderContainer container) => UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          home: DiceOffScreen(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

  /// Laisse les rounds s'enchaîner seuls jusqu'à ce que le départage soit
  /// tranché — le vrai hasard peut produire des égalités, d'où la boucle.
  Future<void> waitUntilResolved(WidgetTester tester, ProviderContainer container) async {
    await tester.pump(DiceOffScreen.firstRollDelay);
    var rounds = 1;
    while (!container.read(diceOffProvider)!.isResolved) {
      await tester.pump(DiceOffScreen.tieRerollDelay);
      rounds++;
      expect(rounds, lessThan(30), reason: 'le départage ne devrait pas s\'éterniser');
    }
    await tester.pump(DieWidget.rollAnimationDuration);
  }

  testWidgets('tous les dés partent ensemble, sans que personne n\'ait à cliquer', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(diceOffProvider.notifier).start(const GameSetup(playerNames: ['A', 'B', 'C', 'D']));

    await tester.pumpWidget(app(container));
    await tester.pump();
    expect(find.byType(DieWidget), findsNothing, reason: 'personne n\'a encore lancé');

    await tester.pump(DiceOffScreen.firstRollDelay);

    expect(find.byType(DieWidget), findsNWidgets(4), reason: 'un dé par joueur, tous lancés d\'un coup');
    expect(container.read(diceOffProvider)!.roundHistory, hasLength(1));

    await waitUntilResolved(tester, container);
  });

  testWidgets('pas d\'écran « passez l\'appareil » entre les joueurs humains', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(diceOffProvider.notifier).start(const GameSetup(playerNames: ['A', 'B', 'C']));

    await tester.pumpWidget(app(container));
    await waitUntilResolved(tester, container);

    expect(find.byType(PassDeviceScreen), findsNothing);
  });

  testWidgets('une égalité fait relancer les seuls ex-aequo, les autres dés restent posés', (tester) async {
    // Le hasard n'est pas injectable ici : on rejoue des départages jusqu'à
    // tomber sur une égalité, ce qui arrive très vite à six joueurs.
    for (var attempt = 0; attempt < 30; attempt++) {
      final container = ProviderContainer();
      container.read(diceOffProvider.notifier).start(
            const GameSetup(playerNames: ['A', 'B', 'C', 'D', 'E', 'F']),
          );
      await tester.pumpWidget(app(container));
      await tester.pump(DiceOffScreen.firstRollDelay);

      final afterFirst = container.read(diceOffProvider)!;
      if (afterFirst.isResolved) {
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        continue;
      }

      expect(find.textContaining('Égalité'), findsOneWidget);
      await tester.pump(DiceOffScreen.tieRerollDelay);
      final second = container.read(diceOffProvider)!.roundHistory[1];
      expect(second.keys.toSet(), afterFirst.activeIndices.toSet(), reason: 'seuls les ex-aequo relancent');
      expect(find.byType(DieWidget), findsNWidgets(6), reason: 'les dés des départagés restent affichés');

      await waitUntilResolved(tester, container);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      return;
    }
    fail('aucune égalité en 30 départages à six joueurs');
  });

  testWidgets('un tap sur l\'écran relance les ex-aequo sans attendre', (tester) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final container = ProviderContainer();
      container.read(diceOffProvider.notifier).start(
            const GameSetup(playerNames: ['A', 'B', 'C', 'D', 'E', 'F']),
          );
      await tester.pumpWidget(app(container));
      await tester.pump(DiceOffScreen.firstRollDelay);

      if (!container.read(diceOffProvider)!.isResolved) {
        await tester.tapAt(const Offset(10, 300));
        await tester.pump();
        expect(container.read(diceOffProvider)!.roundHistory, hasLength(2));

        await waitUntilResolved(tester, container);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        return;
      }
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    }
    fail('aucune égalité en 30 départages à six joueurs');
  });

  testWidgets('le résultat annonce l\'ordre de jeu, et la partie démarre dans cet ordre', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const names = ['A', 'B', 'C', 'D'];
    container.read(diceOffProvider.notifier).start(const GameSetup(playerNames: names));

    await tester.pumpWidget(app(container));
    await waitUntilResolved(tester, container);

    final state = container.read(diceOffProvider)!;
    final expectedOrder = [for (final i in state.playOrder) names[i]];
    expect(find.textContaining('commence la partie !'), findsOneWidget);
    expect(find.text('Ordre de jeu'), findsOneWidget);
    expect(find.text(expectedOrder.join('  →  ')), findsOneWidget);
    expect(find.textContaining('à rebours'), state.reversesOrder ? findsOneWidget : findsNothing);

    await tester.tap(find.text('Commencer la partie'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    final engine = container.read(gameProvider)!;
    expect(engine.players.map((p) => p.name).toList(), expectedOrder);
    expect(engine.currentPlayerIndex, 0);
  });

  testWidgets('une partie 100% IA démarre seule une fois l\'ordre déterminé', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(diceOffProvider.notifier).start(
          const GameSetup(
            playerNames: ['IA 1', 'IA 2'],
            aiPlayers: {0: AiDifficulty.equilibre, 1: AiDifficulty.equilibre},
            autoPlayers: {0, 1},
          ),
        );

    await tester.pumpWidget(app(container));
    await waitUntilResolved(tester, container);

    expect(find.text('Commencer la partie'), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing, reason: 'le délai de transition automatique n\'est pas écoulé');

    await tester.pump(const AppSettings().aiMessageDelay);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(container.read(gameProvider), isNotNull);
  });

  testWidgets('avec un humain à la table, la partie attend son clic', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(diceOffProvider.notifier).start(
          const GameSetup(
            playerNames: ['Joueur', 'IA'],
            aiPlayers: {1: AiDifficulty.equilibre},
            autoPlayers: {1},
          ),
        );

    await tester.pumpWidget(app(container));
    await waitUntilResolved(tester, container);
    await tester.pump(const AppSettings().aiMessageDelay * 3);

    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('Commencer la partie'), findsOneWidget);
  });
}
