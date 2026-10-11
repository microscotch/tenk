import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/score_radar.dart';

void main() {
  test('la liste tourne pour garder le joueur courant en tête, puis l\'ordre de jeu', () {
    expect(rotatedOrder(4, 0), [0, 1, 2, 3]);
    expect(rotatedOrder(4, 2), [2, 3, 0, 1]);
    expect(rotatedOrder(1, 0), [0]);
  });

  group('radar', () {
    // Lignes 0, 500, 1500, 2800, 3000, 3100 (courante), toutes non barrées.
    final alice = [500, 1000, 1300, 200, 100]
        .fold(Player(name: 'Alice'), (p, points) => p.applySuccessfulTurn(points));

    test('les 3 lignes non barrées les plus proches au-dessus du potentiel, croissantes', () {
      expect(alice.grid.map((e) => e.value), [0, 500, 1500, 2800, 3000, 3100]);
      expect(collisionTargets(alice, 2750), [2800, 3000, 3100]);
      expect(collisionTargets(alice, 1000), [1500, 2800, 3000]);
    });

    test('une ligne égale au potentiel en fait partie : c\'est une collision immédiate', () {
      expect(collisionTargets(alice, 2800), [2800, 3000, 3100]);
    });

    test('les lignes barrées et la ligne 0 ne comptent pas', () {
      // 3100 tirettée puis barrée : retour sur 3000.
      final barred = alice.applyBust().applyBust();
      expect(barred.totalScore, 3000);
      expect(collisionTargets(barred, 2900), [3000]);
      expect(collisionTargets(Player(name: 'Bob'), 0), isEmpty);
    });

    test('au-delà du score du joueur, plus rien à barrer : l\'écart, négatif', () {
      final bob = Player(name: 'Bob').applySuccessfulTurn(1800);
      expect(collisionTargets(bob, 2750), isEmpty);
      expect(radarGap(bob, 2750), -950);
    });
  });
}
