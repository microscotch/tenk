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
      expect(end.y, closeTo(DieRollMotion.restTiltY, 1e-9));
      expect(end.z, closeTo(0, 1e-9));
    }
  });

  test('le signe des tours inverse bien le sens de rotation', () {
    const forward = DieRollMotion(duration: DieWidget.maxRollDuration, turnsX: 3, turnsY: 2, turnsZ: 1);
    const backward = DieRollMotion(duration: DieWidget.maxRollDuration, turnsX: -3, turnsY: -2, turnsZ: -1);
    final f = forward.anglesAt(0.3);
    final b = backward.anglesAt(0.3);
    expect(f.x - DieRollMotion.restTiltX, closeTo(-(b.x - DieRollMotion.restTiltX), 1e-9));
    expect(f.y - DieRollMotion.restTiltY, closeTo(-(b.y - DieRollMotion.restTiltY), 1e-9));
    expect(f.z, closeTo(-b.z, 1e-9));
  });
}
