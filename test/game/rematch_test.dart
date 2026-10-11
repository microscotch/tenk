import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/online/rematch.dart';

void main() {
  test('les restants, dans l\'ancien ordre de jeu, à partir du meilleur score', () {
    // Ordre de la 1re partie : sièges 2, 0, 3, 1. Le siège 3 avait 8000.
    expect(
      rematchSeatOrder(
        previousPlayOrder: [2, 0, 3, 1],
        finalScoreBySeat: {0: 10000, 1: 4000, 2: 6000, 3: 8000},
        remaining: {1, 2, 3},
      ),
      [3, 1, 2],
    );
  });

  test('le vainqueur reste en tête s\'il rejoue', () {
    expect(
      rematchSeatOrder(previousPlayOrder: [1, 0], finalScoreBySeat: {0: 10000, 1: 3000}, remaining: {0, 1}),
      [0, 1],
    );
  });

  test('à égalité (à 0), le premier dans l\'ancien ordre de jeu commence', () {
    expect(
      rematchSeatOrder(previousPlayOrder: [3, 1, 0], finalScoreBySeat: {0: 0, 1: 0, 3: 0}, remaining: {0, 1}),
      [1, 0],
    );
  });
}
