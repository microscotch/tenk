import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/score_radar.dart';

void main() {
  // Lignes 500, 1500, 2800, 3000, 3100 (courante), toutes non barrées.
  final alice = [500, 1000, 1300, 200, 100].fold(Player(name: 'Alice'), (p, points) => p.applySuccessfulTurn(points));

  group('score affiché en petit sur la ligne du joueur courant', () {
    test('le premier score de la grille, en remontant, strictement sous le total potentiel', () {
      expect(firstEntryBelow(alice, 3500)?.value, 3100, reason: 'au-dessus de tout : sa ligne courante');
      expect(firstEntryBelow(alice, 3100)?.value, 3000);
      expect(firstEntryBelow(alice, 2900)?.value, 2800);
      expect(firstEntryBelow(alice, 400)?.value, 0);
    });

    test('les lignes barrées sont ignorées', () {
      final barred = alice.applyBust().applyBust(); // 3100 barrée, retour sur 3000
      expect(firstEntryBelow(barred, 3500)?.value, 3000);
    });
  });

  group('ligne d\'un adversaire', () {
    test('le premier score barrable : la plus petite ligne non barrée à partir du total potentiel', () {
      expect(nextBarrableScore(alice, 2000), 2800);
      expect(nextBarrableScore(alice, 2800), 2800);
      expect(nextBarrableScore(alice, 3101), isNull);
      expect(nextBarrableScore(alice.applyBust().applyBust(), 3100), isNull, reason: '3100 est barrée');
    });

    test('au-dessus de son score : son score moins le potentiel, négatif', () {
      final bob = Player(name: 'Bob').applySuccessfulTurn(1800);
      expect(radarDifference(bob, 2750), -950);
    });

    test('sinon : la distance au premier score barrable, positive ou nulle', () {
      expect(radarDifference(alice, 2000), 800);
      expect(radarDifference(alice, 3100), 0);
      expect(radarDifference(Player(name: 'Carl'), 0), isNull);
    });
  });

  test('s\'arrêter sur une ligne non barrée d\'un autre joueur le barrerait', () {
    final players = [Player(name: 'Moi', totalScore: 2000, hasEntered: true), alice];
    expect(barsAnotherPlayer(players, 0, 2800), isTrue);
    expect(barsAnotherPlayer(players, 0, 2900), isFalse);
    expect(barsAnotherPlayer(players, 0, 2000), isFalse, reason: 'sa propre ligne ne compte pas');
  });
}
