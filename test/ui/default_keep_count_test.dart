import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/ui/screens/game_screen.dart';

void main() {
  test('près de 10000, la sélection par défaut compte les 5 écartés sur tous ceux du lancer', () {
    // Un 1 (100) et deux 5 (50 chacun) à 9850 : on ne peut garder qu'un seul 5 (10000 pile ; deux
    // dépasseraient). Garder ce 5 donne 150, un tour qui finit par 50 : interdit de s'arrêter
    // dessus. La bonne sélection par défaut est donc de n'en garder aucun (100).
    final turn = TurnState(diceToRoll: 5, pendingRoll: analyzeRoll([1, 5, 5, 2, 3]), hasRolledThisTurn: true);

    final keep = defaultKeepCount(turn, turn.pendingRoll!, currentTotal: 9850);

    expect(keep, 0);
  });
}
