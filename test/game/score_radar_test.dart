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

    test('le point de départ : mon score + le minimum d\'un tour, jamais sous mon total potentiel', () {
      expect(radarReachFrom(currentTotal: 2200, minimum: 200, potentialTotal: 2200), 2400);
      expect(radarReachFrom(currentTotal: 2200, minimum: 200, potentialTotal: 2400), 2400);
      expect(radarReachFrom(currentTotal: 2200, minimum: 200, potentialTotal: 2700), 2700);
      expect(radarReachFrom(currentTotal: 0, minimum: 500, potentialTotal: 150), 500, reason: 'pas entré : 500');
    });

    test('le cas signalé : à 2200, les lignes 2400, 2600, 2800 restent visibles quand la main mène à 2400', () {
      // Grille 2400, 2600, 2800, 3600 (courante).
      final other = [2400, 200, 200, 800].fold(Player(name: 'Bob'), (p, points) => p.applySuccessfulTurn(points));
      expect(other.totalScore, 3600);
      expect(collisionTargets(other, radarReachFrom(currentTotal: 2200, minimum: 200, potentialTotal: 2200)), [2400, 2600, 2800]);
      expect(collisionTargets(other, radarReachFrom(currentTotal: 2200, minimum: 200, potentialTotal: 2400)), [2400, 2600, 2800]);
      expect(collisionTargets(other, radarReachFrom(currentTotal: 2200, minimum: 200, potentialTotal: 2500)), [2600, 2800],
          reason: '2400 est dépassé : plus atteignable ce tour-ci');
    });

    test('les lignes barrées, la ligne 0 et la ligne courante ne comptent pas, au plus 3', () {
      expect(collisionTargets(alice, 1000), [1500, 2800, 3000], reason: 'sans 3100, son score');
      final barred = alice.applyBust().applyBust(); // 3100 barrée : retour sur 3000
      expect(collisionTargets(barred, 2000), [2800]);
      expect(collisionTargets(Player(name: 'Carl'), 0), isEmpty);
    });

    test('rien d\'atteignable : l\'écart entre son score et mon total potentiel', () {
      final bob = Player(name: 'Bob').applySuccessfulTurn(1800);
      expect(collisionTargets(bob, 2750), isEmpty);
      expect(radarGap(bob, 2750), -950);
    });

    test('s\'arrêter sur une ligne non barrée d\'un autre joueur le barrerait', () {
      final players = [Player(name: 'Moi', totalScore: 2000, hasEntered: true), alice];
      expect(barsAnotherPlayer(players, 0, 2800), isTrue);
      expect(barsAnotherPlayer(players, 0, 2900), isFalse);
      expect(barsAnotherPlayer(players, 0, 2000), isFalse, reason: 'sa propre ligne ne compte pas');
    });
  });
}
