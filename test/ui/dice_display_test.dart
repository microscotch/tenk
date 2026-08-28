import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/widgets/die_widget.dart';

void main() {
  testWidgets('1-3-4-5-6 : seul le 1 est vert, seul le 5 est orange, le reste est junk', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var engine = GameEngine.newGame(['A', 'B']).startTurn();
    engine = engine.copyWith(
      activeTurn: TurnState(diceToRoll: 5, pendingRoll: analyzeRoll([1, 3, 4, 5, 6])),
    );
    container.read(gameProvider.notifier).debugLoadState(
          engine,
          const GameSetup(playerNames: ['A', 'B']),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final dice = tester.widgetList<DieWidget>(find.byType(DieWidget)).toList();
    expect(dice.length, 5);
    for (final d in dice) {
      switch (d.value) {
        case 1:
          expect(d.state, DieVisualState.kept, reason: 'le 1 doit être gardé (obligatoire)');
        case 5:
          expect(d.state, DieVisualState.declinable, reason: 'le 5 isolé doit être déclinable');
        case 3:
        case 4:
        case 6:
          expect(d.state, DieVisualState.junk, reason: 'le ${d.value} seul ne vaut rien');
      }
    }
  });
}
