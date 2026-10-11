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
    // Lignes 500, 1500, 2800, 3000, 3100 (courante), toutes non barrées.
    final alice = [500, 1000, 1300, 200, 100]
        .fold(Player(name: 'Alice'), (p, points) => p.applySuccessfulTurn(points));

    test('les lignes atteignables : à 200 au moins au-dessus du potentiel, hors ligne courante, croissantes', () {
      expect(alice.grid.map((e) => e.value), [0, 500, 1500, 2800, 3000, 3100]);
      expect(collisionTargets(alice, 1000), [1500, 2800, 3000], reason: 'au plus 3, sans 3100 (son score)');
      expect(collisionTargets(alice, 2600), [2800, 3000]);
      expect(collisionTargets(alice, 2700), [3000], reason: '2800 n\'est qu\'à 100 : pas atteignable');
    });

    test('les lignes barrées, la ligne 0 et la ligne courante ne comptent pas', () {
      // 3100 tirettée puis barrée : retour sur 3000.
      final barred = alice.applyBust().applyBust();
      expect(barred.totalScore, 3000);
      expect(collisionTargets(barred, 2000), [2800]);
      expect(collisionTargets(Player(name: 'Bob'), 0), isEmpty);
    });

    test('rien d\'atteignable : jusqu\'à 3 écarts avec ses plus hautes lignes', () {
      expect(collisionTargets(alice, 2900), isEmpty);
      expect(radarGaps(alice, 2900), [200, 100, -100]);
      final bob = Player(name: 'Bob').applySuccessfulTurn(1800);
      expect(radarGaps(bob, 2750), [-950]);
      expect(radarGaps(Player(name: 'Carl'), 600), [-600], reason: 'sans ligne marquée : l\'écart de son score');
    });

    test('s\'arrêter sur une ligne non barrée d\'un autre joueur le barrerait', () {
      final players = [Player(name: 'Moi', totalScore: 2000, hasEntered: true), alice];
      expect(barsAnotherPlayer(players, 0, 2800), isTrue);
      expect(barsAnotherPlayer(players, 0, 2900), isFalse);
      expect(barsAnotherPlayer(players, 0, 2000), isFalse, reason: 'sa propre ligne ne compte pas');
    });
  });
}
