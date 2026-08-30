import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'dice3d/dice_face_texture.dart' show accentColorFor, bodyColorFor, pipColorFor, pipPositions;
import 'dice3d/scene_die.dart';

enum DieVisualState { junk, kept, declined, extended }

/// Un dé, avec ses pips peints et un état visuel (couleur de bordure).
///
/// Rendu comme un vrai cube 3D via flutter_scene (Impeller/Flutter GPU)
/// quand ce backend est disponible ([Scene3DDie]) ; sinon (par ex. dans les
/// tests widgets, qui tournent sans backend GPU) retombe sur un cube 3D
/// dessiné à la main via Matrix4/Transform ([_TransformCubeDie]), qui donne
/// un rendu très proche sans dépendre du GPU.
///
/// Si [rollToken] est fourni et change d'un build à l'autre (par exemple la
/// référence du `RollAnalysis` d'un nouveau lancer), le dé joue une courte
/// animation de "lancer" (rotation multi-axes qui ralentit puis se fixe sur
/// [value]). Un simple changement de sélection (ex: combien de 5 garder)
/// sans nouveau lancer ne rejoue pas l'animation, tant que [rollToken] reste
/// le même objet.
class DieWidget extends StatelessWidget {
  final int value;
  final DieVisualState state;
  final VoidCallback? onTap;
  final Object? rollToken;

  const DieWidget({super.key, required this.value, required this.state, this.onTap, this.rollToken});

  @override
  Widget build(BuildContext context) {
    if (Scene3DDie.isSupported) {
      return Scene3DDie(value: value, state: state, onTap: onTap, rollToken: rollToken);
    }
    return _TransformCubeDie(value: value, state: state, onTap: onTap, rollToken: rollToken);
  }
}

/// Repli sans GPU : le même cube 6-faces, animé et incliné au repos comme
/// [Scene3DDie], mais dessiné à la main via Matrix4/Transform (algorithme du
/// peintre pour l'ordre de rendu) plutôt que par un vrai moteur de rendu 3D.
class _TransformCubeDie extends StatefulWidget {
  final int value;
  final DieVisualState state;
  final VoidCallback? onTap;
  final Object? rollToken;

  const _TransformCubeDie({required this.value, required this.state, this.onTap, this.rollToken});

  @override
  State<_TransformCubeDie> createState() => _TransformCubeDieState();
}

/// Une face du cube : sa valeur, et la rotation (sans translation) qui la
/// place à sa position canonique (avant l'application du lancer en cours).
class _Face {
  final int value;
  final Matrix4 placement;
  double depth = 0;
  _Face(this.value, this.placement);
}

/// Valeurs des 6 faces d'un dé standard (faces opposées = 7) pour un [front]
/// donné ; les 4 autres faces sont réparties arbitrairement entre les deux
/// paires restantes (uniquement pour l'aspect visuel pendant la rotation).
Map<String, int> _faceValues(int front) {
  final back = 7 - front;
  final remaining = [1, 2, 3, 4, 5, 6].where((v) => v != front && v != back).toList();
  final top = remaining[0];
  final bottom = 7 - top;
  final right = remaining.firstWhere((v) => v != top && v != bottom);
  final left = 7 - right;
  return {'front': front, 'back': back, 'top': top, 'bottom': bottom, 'left': left, 'right': right};
}

class _TransformCubeDieState extends State<_TransformCubeDie> with SingleTickerProviderStateMixin {
  static const _size = 76.0;
  static const _half = _size / 2;
  // Inclinaison de repos (dé immobile) : assez pour voir le dessus et le
  // côté du cube, pas assez pour gêner la lecture de la face avant.
  static const _restTiltX = -0.32;
  static const _restTiltY = 0.42;

  late final AnimationController _controller;
  Object? _lastRollToken;
  final _random = math.Random();
  int _turnsX = 3;
  int _turnsY = 2;
  int _turnsZ = 1;

  @override
  void initState() {
    super.initState();
    _lastRollToken = widget.rollToken;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
      ..addListener(() => setState(() {}));
    if (widget.rollToken != null) {
      _rollRandomTurns();
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _TransformCubeDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rollToken != null && widget.rollToken != _lastRollToken) {
      _lastRollToken = widget.rollToken;
      _rollRandomTurns();
      _controller.forward(from: 0);
    }
  }

  void _rollRandomTurns() {
    _turnsX = 2 + _random.nextInt(3);
    _turnsY = 2 + _random.nextInt(3);
    _turnsZ = 1 + _random.nextInt(2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = 1 - Curves.easeOut.transform(_controller.value);
    // Le dé ne revient jamais complètement à plat : même immobile, il garde
    // une légère inclinaison pour rester visiblement un cube en 3D.
    final spin = Matrix4.identity()
      ..rotateX(_restTiltX + remaining * _turnsX * 2 * math.pi)
      ..rotateY(_restTiltY + remaining * _turnsY * 2 * math.pi)
      ..rotateZ(remaining * _turnsZ * 2 * math.pi * 0.3);

    final values = _faceValues(widget.value);
    final faces = [
      _Face(values['front']!, Matrix4.identity()),
      _Face(values['back']!, Matrix4.identity()..rotateY(math.pi)),
      _Face(values['right']!, Matrix4.identity()..rotateY(math.pi / 2)),
      _Face(values['left']!, Matrix4.identity()..rotateY(-math.pi / 2)),
      _Face(values['top']!, Matrix4.identity()..rotateX(math.pi / 2)),
      _Face(values['bottom']!, Matrix4.identity()..rotateX(-math.pi / 2)),
    ];

    // Algorithme du peintre : on peint les faces de la plus éloignée à la
    // plus proche de la caméra pour un rendu correct pendant la rotation.
    for (final face in faces) {
      final normal = face.placement.transform3(Vector3(0, 0, 1));
      face.depth = spin.transform3(normal).z;
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        width: _size,
        height: _size,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0022)
            ..multiply(spin),
          child: Stack(
            children: [
              for (final face in faces)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.copy(face.placement)..translateByDouble(0.0, 0.0, _half, 1.0),
                  child: _DieFace(value: face.value, state: widget.state),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DieFace extends StatelessWidget {
  final int value;
  final DieVisualState state;

  const _DieFace({required this.value, required this.state});

  @override
  Widget build(BuildContext context) {
    final body = bodyColorFor(state);
    return Container(
      width: _TransformCubeDieState._size,
      height: _TransformCubeDieState._size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [body, Color.lerp(body, Colors.black, 0.05)!],
        ),
        border: Border.all(color: accentColorFor(state), width: 2.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
      ),
      child: CustomPaint(painter: _PipsPainter(value, pipColorFor(state)), size: Size.infinite),
    );
  }
}

class _PipsPainter extends CustomPainter {
  final int value;
  final Color color;
  const _PipsPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pipPositions[value] ?? const []) {
      final center = Offset(p.dx * size.width, p.dy * size.height);
      final radius = size.width * 0.078;
      canvas.drawCircle(center + Offset(size.width * 0.006, size.width * 0.01), radius,
          Paint()..color = Colors.black.withValues(alpha: 0.2));
      canvas.drawCircle(center, radius, Paint()..color = color);
      canvas.drawCircle(center - Offset(radius * 0.3, radius * 0.3), radius * 0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _PipsPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
