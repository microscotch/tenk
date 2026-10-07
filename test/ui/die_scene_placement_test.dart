import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/dice3d/scene_die.dart';
import 'package:le10000/ui/widgets/die_widget.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3;

/// La scène 3D : l'écran a +X à droite, +Y en haut, et la caméra regarde +Z
/// (voir `dieFacePlacement`). Pour chaque face on vérifie, dans ce repère, que
/// la normale sort du cube, que le bas de l'image est vers le bas de la face
/// et que, une fois la texture dessinée en miroir horizontal, sa droite est
/// bien la droite de la face vue de dehors.
void main() {
  const faces = {
    // face: (normale, bas de la face vu de l'écran, droite de la face vue de dehors)
    'top': ((0.0, 1.0, 0.0), (0.0, 0.0, -1.0), (1.0, 0.0, 0.0)),
    'front': ((0.0, 0.0, -1.0), (0.0, -1.0, 0.0), (1.0, 0.0, 0.0)),
    'right': ((1.0, 0.0, 0.0), (0.0, -1.0, 0.0), (0.0, 0.0, 1.0)),
    'left': ((-1.0, 0.0, 0.0), (0.0, -1.0, 0.0), (0.0, 0.0, -1.0)),
  };

  Vector3 v((double, double, double) t) => Vector3(t.$1, t.$2, t.$3);

  for (final entry in faces.entries) {
    test('face ${entry.key} : normale, bas et droite de l\'image', () {
      final (normal, down, right) = entry.value;
      final m = dieFacePlacement(entry.key);
      // Le plan par défaut : normale +Y, image de haut en bas sur +Z, de gauche
      // à droite sur +X.
      expect((m.transform3(Vector3(0, 1, 0)) - v(normal)).length, lessThan(1e-9));
      expect((m.transform3(Vector3(0, 0, 1)) - v(down)).length, lessThan(1e-9));
      // Dessinée en miroir horizontal, la droite de l'image est l'opposé de +X.
      expect((-m.transform3(Vector3(1, 0, 0)) - v(right)).length, lessThan(1e-9));
      expect(m.determinant(), closeTo(1, 1e-9), reason: 'une vraie rotation, jamais un miroir');
    });
  }

  test('le dessus : le haut du motif reste à moins de 45° de la verticale de l\'écran, quel que soit le lacet', () {
    for (final degrees in DieRollMotion.restYawChoicesDegrees) {
      final yaw = degrees * math.pi / 180;
      final motion = DieRollMotion(
        duration: DieWidget.maxRollDuration,
        turnsX: 0,
        turnsY: 0,
        turnsZ: 0,
        restYaw: yaw,
      );
      final m = dieFacePlacement('top', topQuarterTurns: motion.topQuarterTurns);
      // Haut de l'image = -Z du plan ; haut de l'écran sur le dessus = +Z.
      final up = Matrix4.rotationY(yaw).transform3(m.transform3(Vector3(0, 0, -1)));
      final residual = math.atan2(up.x, up.z) * 180 / math.pi;
      expect(residual.abs(), lessThanOrEqualTo(45), reason: 'lacet $degrees° : ${residual.toStringAsFixed(0)}°');
    }
  });
}
