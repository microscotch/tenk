import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/die_widget.dart';

void main() {
  final motions = [for (var i = 0; i < 200; i++) DieRollMotion.random(Random(i))];

  test('chaque lancer dure un temps tiré dans la plage', () {
    for (final m in motions) {
      expect(m.duration, greaterThanOrEqualTo(DieWidget.minRollDuration));
      expect(m.duration, lessThanOrEqualTo(DieWidget.maxRollDuration));
    }
    expect(motions.map((m) => m.duration).toSet().length, greaterThan(50),
        reason: 'les dés ne s\'immobilisent pas tous au même instant');
  });

  test('chaque axe tourne tantôt dans un sens, tantôt dans l\'autre', () {
    for (final turns in [
      motions.map((m) => m.turnsX),
      motions.map((m) => m.turnsY),
      motions.map((m) => m.turnsZ),
    ]) {
      expect(turns.any((t) => t > 0), isTrue);
      expect(turns.any((t) => t < 0), isTrue);
      expect(turns.every((t) => t != 0), isTrue, reason: 'un dé lancé tourne toujours');
    }
  });

  test('en fin de lancer, le dé retrouve son inclinaison de repos, quel que soit le sens', () {
    for (final m in motions.take(20)) {
      final end = m.anglesAt(1);
      expect(end.x, closeTo(DieRollMotion.restTiltX, 1e-9));
      expect(end.y, closeTo(m.restYaw, 1e-9));
      expect(end.z, closeTo(0, 1e-9));
    }
  });

  test('le signe des tours inverse bien le sens de rotation', () {
    const forward = DieRollMotion(duration: DieWidget.maxRollDuration, turnsX: 3, turnsY: 2, turnsZ: 1);
    const backward = DieRollMotion(duration: DieWidget.maxRollDuration, turnsX: -3, turnsY: -2, turnsZ: -1);
    final f = forward.anglesAt(0.3);
    final b = backward.anglesAt(0.3);
    expect(f.x - DieRollMotion.restTiltX, closeTo(-(b.x - DieRollMotion.restTiltX), 1e-9));
    expect(f.y - forward.restYaw, closeTo(-(b.y - backward.restYaw), 1e-9));
    expect(f.z, closeTo(-b.z, 1e-9));
  });

  group('faces latérales à l\'arrêt', () {
    test('chaque quart de tour garde la face du dessus et les faces opposées à 7', () {
      for (var top = 1; top <= 6; top++) {
        for (var q = 0; q < 4; q++) {
          final f = dieFaceValues(top, quarterTurns: q);
          expect(f['top'], top);
          expect(f['top']! + f['bottom']!, 7);
          expect(f['front']! + f['back']!, 7);
          expect(f['left']! + f['right']!, 7);
          expect(f.values.toSet(), {1, 2, 3, 4, 5, 6});
        }
      }
    });

    test('les quatre quarts de tour montrent quatre paires de faces latérales différentes', () {
      for (var top = 1; top <= 6; top++) {
        final pairs = {
          for (var q = 0; q < 4; q++)
            () {
              final f = dieFaceValues(top, quarterTurns: q);
              return '${f['front']}-${f['right']}';
            }(),
        };
        expect(pairs, hasLength(4), reason: 'top = $top');
      }
    });

    test('l\'orientation d\'arrêt est tirée au sort parmi les quatre', () {
      expect(motions.map((m) => m.quarterTurns).toSet(), {0, 1, 2, 3});
    });
  });

  group('rebonds', () {
    /// Les sommets successifs de la trajectoire, échantillonnée finement.
    List<double> peaks(DieRollMotion m) {
      const steps = 4000;
      final h = [for (var i = 0; i <= steps; i++) m.hopAt(i / steps)];
      return [
        for (var i = 1; i < steps; i++)
          if (h[i] > h[i - 1] && h[i] >= h[i + 1] && h[i] > 1e-6) h[i],
      ];
    }

    test('le dé part de la table et y finit posé, sans jamais dépasser son premier rebond', () {
      for (final m in motions.take(50)) {
        expect(m.hopAt(0), 0);
        expect(m.hopAt(0.9), 0, reason: 'les rebonds sont finis avant la fin du lancer');
        expect(m.hopAt(1), 0);
        for (var i = 0; i <= 200; i++) {
          final h = m.hopAt(i / 200);
          expect(h, inInclusiveRange(0, m.firstHop + 1e-9));
        }
      }
    });

    test('autant de sommets que de rebonds, chacun plus bas que le précédent', () {
      for (final m in motions.take(50)) {
        final p = peaks(m);
        expect(p, hasLength(m.bounces));
        expect(p.first, closeTo(m.firstHop, 1e-3));
        for (var k = 1; k < p.length; k++) {
          expect(p[k], closeTo(p[k - 1] * m.restitution * m.restitution, 1e-3));
        }
      }
    });

    test('un dé posé ne rebondit pas', () {
      for (var i = 0; i <= 10; i++) {
        expect(DieRollMotion.resting(Random(i)).hopAt(i / 10), 0);
      }
    });

    test('le nombre de rebonds est tiré entre 2 et 4', () {
      expect(motions.map((m) => m.bounces).toSet(), {2, 3, 4});
    });
  });

  group('orientation au repos', () {
    const allowed = {15, 25, 35, 55, 65, 75};
    int degrees(double radians) => (radians * 180 / pi).round();

    test('la rotation verticale d\'un dé lancé est tirée parmi les valeurs retenues', () {
      final seen = motions.map((m) => degrees(m.restYaw)).toSet();
      expect(seen, allowed, reason: 'toutes les valeurs sortent, et aucune autre (pas 45°)');
    });

    test('un dé non lancé est lui aussi orienté au hasard, sans bouger', () {
      final resting = [for (var i = 0; i < 200; i++) DieRollMotion.resting(Random(i))];
      expect(resting.map((m) => degrees(m.restYaw)).toSet(), allowed);
      expect(resting.map((m) => m.quarterTurns).toSet(), {0, 1, 2, 3});
      for (final m in resting.take(20)) {
        final a = m.anglesAt(1);
        expect(a.y, closeTo(m.restYaw, 1e-9));
        expect(m.anglesAt(0).y, closeTo(m.restYaw, 1e-9), reason: 'aucun tour à faire');
      }
    });

    test('l\'angle de vue au repos est de 37°', () {
      expect(-DieRollMotion.restTiltX * 180 / pi, closeTo(37, 1e-9));
    });
  });
}
