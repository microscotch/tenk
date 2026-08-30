import 'dart:math' as math;

import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3;

import '../die_widget.dart' show DieVisualState;
import 'dice_face_texture.dart';

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

/// Placement (rotation seule, sans translation) de chaque face d'un cube
/// construit à partir de [PlaneGeometry] (face par défaut orientée +Y).
/// Vérifié numériquement : la normale (0,1,0) tournée par cette matrice
/// pointe dans la direction voulue pour chaque face (la caméra par défaut de
/// flutter_scene est en (0,0,-5) regardant l'origine, donc "front" a besoin
/// d'une normale -Z).
final Map<String, Matrix4> _facePlacements = {
  'top': Matrix4.identity(),
  'bottom': Matrix4.identity()..rotateX(math.pi),
  'front': Matrix4.identity()..rotateX(-math.pi / 2),
  'back': Matrix4.identity()..rotateX(math.pi / 2),
  'right': Matrix4.identity()..rotateZ(-math.pi / 2),
  'left': Matrix4.identity()..rotateZ(math.pi / 2),
};

/// Un dé rendu comme un vrai cube 3D via flutter_scene (Impeller/Flutter
/// GPU), avec une texture par face (fond + pips) générée à la volée et mise
/// en cache par (valeur, état visuel). Utilisé uniquement quand [isSupported]
/// est vrai ; sinon [DieWidget] retombe sur un rendu Matrix4/Transform.
class Scene3DDie extends StatefulWidget {
  final int value;
  final DieVisualState state;
  final VoidCallback? onTap;
  final Object? rollToken;

  const Scene3DDie({super.key, required this.value, required this.state, this.onTap, this.rollToken});

  /// Vrai si Flutter GPU/Impeller est disponible sur ce moteur, calculé une
  /// seule fois par processus (les tests widgets tournent sans backend GPU,
  /// où construire une [Scene] lève systématiquement une exception).
  static bool get isSupported {
    if (_isSupported != null) return _isSupported!;
    try {
      Scene();
      _isSupported = true;
    } catch (_) {
      _isSupported = false;
    }
    return _isSupported!;
  }

  static bool? _isSupported;

  @override
  State<Scene3DDie> createState() => _Scene3DDieState();
}

class _Scene3DDieState extends State<Scene3DDie> {
  static const _size = 76.0;
  static const _half = 0.5;
  // Inclinaison de repos (dé immobile) : assez pour voir le dessus et le
  // côté du cube, pas assez pour gêner la lecture de la face avant.
  static const _restTiltX = -0.32;
  static const _restTiltY = 0.42;
  static const _rollSeconds = 0.65;

  final _random = math.Random();
  final Scene _scene = Scene();
  final Node _dieNode = Node();

  Object? _lastRollToken;
  double? _rollStartSeconds;
  int _turnsX = 3;
  int _turnsY = 2;
  int _turnsZ = 1;
  bool _facesReady = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scene.add(_dieNode);
    _buildFaces();
  }

  @override
  void didUpdateWidget(covariant Scene3DDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value || widget.state != oldWidget.state) {
      _buildFaces();
    }
  }

  Future<void> _buildFaces() async {
    final generation = ++_loadGeneration;
    final values = _faceValues(widget.value);
    final textures = await Future.wait(
      values.entries.map((e) async => MapEntry(e.key, await DiceFaceTextures.get(e.value, widget.state))),
    );
    if (!mounted || generation != _loadGeneration) return;

    _dieNode.removeAll();
    for (final entry in textures) {
      final placement = _facePlacements[entry.key]!;
      // Fini plastique mat (dé physique) plutôt que le défaut métallique
      // brillant de PhysicallyBasedMaterial, qui donnait un aspect artificiel.
      final material = PhysicallyBasedMaterial(baseColorTexture: entry.value)
        ..metallicFactor = 0.0
        ..roughnessFactor = 0.45;
      _dieNode.add(Node(
        localTransform: Matrix4.copy(placement)..translateByDouble(0.0, _half, 0.0, 1.0),
        mesh: Mesh(PlaneGeometry(), material),
      ));
    }
    setState(() => _facesReady = true);
  }

  void _onTick(Duration elapsed, double deltaSeconds) {
    final now = elapsed.inMicroseconds / 1e6;
    if (widget.rollToken != null && widget.rollToken != _lastRollToken) {
      _lastRollToken = widget.rollToken;
      _rollStartSeconds = now;
      _turnsX = 2 + _random.nextInt(3);
      _turnsY = 2 + _random.nextInt(3);
      _turnsZ = 1 + _random.nextInt(2);
    }
    final start = _rollStartSeconds;
    final t = start == null ? 1.0 : ((now - start) / _rollSeconds).clamp(0.0, 1.0);
    final remaining = 1 - Curves.easeOut.transform(t);
    _dieNode.localTransform = Matrix4.identity()
      ..rotateX(_restTiltX + remaining * _turnsX * 2 * math.pi)
      ..rotateY(_restTiltY + remaining * _turnsY * 2 * math.pi)
      ..rotateZ(remaining * _turnsZ * 2 * math.pi * 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        width: _size,
        height: _size,
        child: _facesReady
            ? SceneView(
                _scene,
                camera: PerspectiveCamera(position: Vector3(0, 0, -3.2)),
                onTick: _onTick,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
