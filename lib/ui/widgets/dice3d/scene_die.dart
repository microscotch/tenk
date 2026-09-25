import 'dart:math' as math;

import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3;

import '../die_widget.dart' show DieRollMotion, DieVisualState, DieWidget, dieFaceValues;
import 'dice_face_texture.dart';


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
  final Color? bodyColor;
  final double size;

  const Scene3DDie({
    super.key,
    required this.value,
    required this.state,
    this.onTap,
    this.rollToken,
    this.bodyColor,
    required this.size,
  });

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
  double get _size => widget.size;
  static const _half = 0.5;

  final _random = math.Random();
  final Scene _scene = Scene();
  final Node _dieNode = Node();

  Object? _lastRollToken;
  double? _rollStartSeconds;
  bool _rollPending = false;
  DieRollMotion _motion = DieRollMotion.rest;
  bool _facesReady = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scene.add(_dieNode);
    if (widget.rollToken != null) _startRoll();
    _buildFaces();
  }

  @override
  void didUpdateWidget(covariant Scene3DDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newRoll = widget.rollToken != null && widget.rollToken != _lastRollToken;
    if (newRoll) _startRoll();
    // Un nouveau lancer peut changer l'orientation d'arrêt (quarterTurns),
    // donc la répartition des faces latérales, même à valeur égale.
    if (newRoll ||
        widget.value != oldWidget.value ||
        widget.state != oldWidget.state ||
        widget.bodyColor != oldWidget.bodyColor) {
      _buildFaces();
    }
  }

  /// Tire le mouvement du lancer tout de suite (les faces en dépendent) ; son
  /// horloge ne démarre qu'au prochain tick de la scène.
  void _startRoll() {
    _lastRollToken = widget.rollToken;
    _motion = DieRollMotion.random(_random);
    _rollPending = true;
  }

  Future<void> _buildFaces() async {
    final generation = ++_loadGeneration;
    final values = dieFaceValues(widget.value, quarterTurns: _motion.quarterTurns);
    final textures = await Future.wait(
      values.entries
          .map((e) async => MapEntry(e.key, await DiceFaceTextures.get(e.value, widget.state, widget.bodyColor))),
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
    if (_rollPending) {
      _rollPending = false;
      _rollStartSeconds = now;
    }
    final start = _rollStartSeconds;
    final seconds = _motion.duration.inMicroseconds / 1e6;
    final angles = _motion.anglesAt(start == null ? 1.0 : (now - start) / seconds);
    _dieNode.localTransform = Matrix4.identity()
      ..rotateX(angles.x)
      ..rotateY(angles.y)
      ..rotateZ(angles.z);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        // Doit rester identique à la marge du rendu de repli
        // ([DieWidget.margin]) : la rangée de 5 dés est dimensionnée sur cette
        // valeur, et les deux rendus sont interchangeables à l'exécution.
        margin: const EdgeInsets.all(DieWidget.margin),
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
