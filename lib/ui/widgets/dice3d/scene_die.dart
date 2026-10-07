import 'dart:math' as math;

import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../die_widget.dart' show DieBounce, DieRollMotion, DieVisualState, DieWidget, dieFaceValues;
import 'dice_face_texture.dart';


/// Placement (rotation seule, sans translation) de chaque face d'un cube
/// construit à partir de [PlaneGeometry] : face par défaut orientée +Y, image
/// de gauche à droite sur +X et de haut en bas sur +Z.
///
/// La caméra de flutter_scene est à gauche (droite = haut × avant) : elle est
/// en (0,0,-3.2) et regarde +Z, l'écran a donc +X à droite et +Y en haut, et
/// la face "avant" a besoin d'une normale -Z. Une rotation ne peut pas, avec
/// cette géométrie, à la fois mettre l'image « de haut en bas » sur le bas de
/// la face et « de gauche à droite » sur sa droite : elle tourne toujours le
/// plan en image miroir. On choisit donc, pour chaque face, la rotation qui
/// pose le bas de l'image vers le bas de la face, et les textures sont
/// dessinées en miroir horizontal (voir `DiceFaceTextures`) pour que la
/// double inversion les remette à l'endroit. Sans quoi, selon la face,
/// un 2 ou un 3 se retrouvait en miroir, un 6 couché sur le flanc, ou la
/// face à l'envers — le motif d'un même dé n'avait aucune orientation fixe.
///
/// [topQuarterTurns] fait en plus tourner la texture du dessus (voir
/// [DieRollMotion.topQuarterTurns]).
Matrix4 dieFacePlacement(String face, {int topQuarterTurns = 0}) {
  final (normal, down) = switch (face) {
    'top' => (Vector3(0, 1, 0), Vector3(0, 0, -1)),
    'bottom' => (Vector3(0, -1, 0), Vector3(0, 0, 1)),
    'front' => (Vector3(0, 0, -1), Vector3(0, -1, 0)),
    'back' => (Vector3(0, 0, 1), Vector3(0, -1, 0)),
    'right' => (Vector3(1, 0, 0), Vector3(0, -1, 0)),
    'left' => (Vector3(-1, 0, 0), Vector3(0, -1, 0)),
    _ => throw ArgumentError('face inconnue : $face'),
  };
  final across = normal.cross(down);
  final basis = Matrix4.columns(
    Vector4(across.x, across.y, across.z, 0),
    Vector4(normal.x, normal.y, normal.z, 0),
    Vector4(down.x, down.y, down.z, 0),
    Vector4(0, 0, 0, 1),
  );
  if (face == 'top' && topQuarterTurns != 0) basis.rotateY(-topQuarterTurns * math.pi / 2);
  return basis;
}

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
  final int? restSeed;

  const Scene3DDie({
    super.key,
    required this.value,
    required this.state,
    this.onTap,
    this.rollToken,
    this.bodyColor,
    required this.size,
    this.restSeed,
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

class _Scene3DDieState extends State<Scene3DDie> with SingleTickerProviderStateMixin {
  double get _size => widget.size;
  static const _half = 0.5;

  final _random = math.Random();
  final Scene _scene = Scene();
  final Node _dieNode = Node();

  Object? _lastRollToken;
  late DieRollMotion _motion = DieRollMotion.resting(_random, restSeed: widget.restSeed);

  /// Progression du lancer (0 → 1), qui pilote la rotation (lue à chaque tick
  /// de la scène) et le rebond (qui redessine le widget).
  late final AnimationController _controller = AnimationController(vsync: this, value: 1);
  bool _facesReady = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scene.add(_dieNode);
    if (widget.rollToken != null) _startRoll();
    // Un dé neuf dont les textures sont déjà en cache (c'est le cas d'un dé qui
    // passe de la piste à la main courante) se construit tout de suite : sinon
    // il restait invisible le temps d'un tour de boucle, d'où un « flick » à
    // chaque lancer sur les dés déjà gardés.
    if (!_buildFacesNow()) _buildFaces();
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

  /// Tire le mouvement du lancer (les faces en dépendent) et le lance.
  void _startRoll() {
    _lastRollToken = widget.rollToken;
    _motion = DieRollMotion.random(_random, restSeed: widget.restSeed);
    _controller
      ..duration = _motion.duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Construit le dé sans attendre, si les six textures sont déjà prêtes.
  bool _buildFacesNow() {
    final values = dieFaceValues(widget.value, quarterTurns: _motion.quarterTurns);
    final textures = <MapEntry<String, Texture2D>>[];
    for (final e in values.entries) {
      final texture = DiceFaceTextures.peek(e.value, widget.state, widget.bodyColor);
      if (texture == null) return false;
      textures.add(MapEntry(e.key, texture));
    }
    _loadGeneration++;
    _applyFaces(textures);
    _facesReady = true;
    return true;
  }

  Future<void> _buildFaces() async {
    final generation = ++_loadGeneration;
    final values = dieFaceValues(widget.value, quarterTurns: _motion.quarterTurns);
    final textures = await Future.wait(
      values.entries
          .map((e) async => MapEntry(e.key, await DiceFaceTextures.get(e.value, widget.state, widget.bodyColor))),
    );
    if (!mounted || generation != _loadGeneration) return;
    _applyFaces(textures);
    setState(() => _facesReady = true);
  }

  void _applyFaces(List<MapEntry<String, Texture2D>> textures) {
    _dieNode.removeAll();
    // Orientation déjà posée avant le premier tick de la scène : sans elle, le
    // dé apparaîtrait un instant droit, avant de prendre son orientation.
    _onTick(Duration.zero, 0);
    for (final entry in textures) {
      final placement = dieFacePlacement(entry.key, topQuarterTurns: _motion.topQuarterTurns);
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
  }

  void _onTick(Duration elapsed, double deltaSeconds) {
    final angles = _motion.anglesAt(_controller.value);
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
            ? AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => DieBounce(hop: _motion.hopAt(_controller.value), size: _size, child: child!),
                child: SceneView(
                  _scene,
                  camera: PerspectiveCamera(position: Vector3(0, 0, -3.2)),
                  onTick: _onTick,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
