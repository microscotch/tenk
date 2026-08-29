import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/state/dice_off_providers.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/ui/screens/dice_off_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/pass_device_screen.dart';

void main() {
  testWidgets('le départage se joue à l\'écran et lance la partie avec le vainqueur en premier', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(diceOffProvider.notifier).start(const GameSetup(playerNames: ['A', 'B']));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiceOffScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Le vrai hasard peut produire une égalité (les ex-aequo relancent) :
    // on boucle jusqu'à résolution plutôt que de supposer exactement 2 lancers.
    var iterations = 0;
    while (!container.read(diceOffProvider)!.isResolved) {
      if (find.byType(PassDeviceScreen).evaluate().isNotEmpty) {
        await tester.tap(find.text('Prêt'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Lancer le dé'), findsOneWidget);
      await tester.tap(find.text('Lancer le dé'));
      await tester.pumpAndSettle();
      iterations++;
      expect(iterations, lessThan(20), reason: 'le départage ne devrait pas s\'éterniser');
    }

    expect(find.textContaining('commence la partie !'), findsOneWidget);

    await tester.tap(find.text('Commencer la partie'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    final engine = container.read(gameProvider)!;
    expect(engine.players.map((p) => p.name).toSet(), {'A', 'B'});
    expect(engine.currentPlayerIndex, 0);
  });

  testWidgets('le départage IA se résout automatiquement sans interaction humaine', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(diceOffProvider.notifier).start(
          const GameSetup(playerNames: ['Joueur', 'IA'], aiPlayers: {1: AiDifficulty.equilibre}),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiceOffScreen()),
      ),
    );
    await tester.pump();

    // Le joueur humain (index 0) lance en premier ; s'il n'y a pas égalité,
    // l'IA (index 1) enchaîne toute seule après son délai de "réflexion".
    if (find.text('Joueur lance le dé').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lancer le dé'));
    }

    var iterations = 0;
    while (!container.read(diceOffProvider)!.isResolved) {
      await tester.pump(const Duration(milliseconds: 700));
      iterations++;
      expect(iterations, lessThan(30), reason: 'le départage ne devrait pas s\'éterniser');
      if (find.text('Lancer le dé').evaluate().isNotEmpty) {
        await tester.tap(find.text('Lancer le dé'));
        await tester.pump();
      }
    }

    expect(container.read(diceOffProvider)!.isResolved, isTrue);
  });
}
