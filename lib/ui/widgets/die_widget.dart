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

  /// Couleur de corps du dé ; null pour la couleur ivoire par défaut (mode
  /// "uniforme" des préférences). Voir `dice_colors.dart` pour le mode
  /// "panaché", qui attribue une couleur différente par dé de la rangée.
  final Color? bodyColor;

  /// Taille du dé (côté du cube, en logical pixels). Par défaut la taille
  /// "pleine" historique ; une rangée de plusieurs dés peut la réduire pour
  /// tenir sur une seule ligne (voir `_fittedDiceRow` dans game_screen.dart).
  final double size;

  /// Taille maximale d'un dé : atteinte seulement sur écran large, une
  /// rangée de 5 étant contrainte par la largeur disponible bien avant sur un
  /// téléphone (voir `_fittedDiceRow` dans game_screen.dart).
  static const double defaultSize = 96.0;

  /// Marge propre à chaque dé, appliquée sur ses quatre côtés : deux dés
  /// voisins sont donc séparés du double. Volontairement serrée pour laisser
  /// le maximum de largeur aux dés eux-mêmes, la rangée devant toujours tenir
  /// les 5 dés sur une seule ligne.
  static const double margin = 2.0;

  /// Plage de durée d'un lancer (tumble) : chaque dé tire la sienne à chaque
  /// lancer (voir [DieRollMotion]), pour que les dés ne s'immobilisent pas
  /// tous au même instant.
  static const Duration minRollDuration = Duration(milliseconds: 500);

  /// Borne haute de cette plage : passé ce délai, TOUS les dés d'un lancer
  /// sont immobiles. C'est elle que l'UI attend (voir `game_screen.dart`)
  /// avant, par exemple, d'afficher un score.
  static const Duration maxRollDuration = Duration(milliseconds: 1000);

  const DieWidget({
    super.key,
    required this.value,
    required this.state,
    this.onTap,
    this.rollToken,
    this.bodyColor,
    this.size = defaultSize,
  });

  @override
  Widget build(BuildContext context) {
    if (Scene3DDie.isSupported) {
      return Scene3DDie(value: value, state: state, onTap: onTap, rollToken: rollToken, bodyColor: bodyColor, size: size);
    }
    return _TransformCubeDie(
        value: value, state: state, onTap: onTap, rollToken: rollToken, bodyColor: bodyColor, size: size);
  }
}

/// Le mouvement d'un dé pendant un lancer, tiré au sort pour chaque dé à
/// chaque lancer : sa durée, dans la plage [DieWidget.minRollDuration] –
/// [DieWidget.maxRollDuration], et un nombre de tours signé sur chaque axe,
/// dont le signe donne le sens de rotation. Partagé par les deux rendus
/// ([Scene3DDie] et son repli dessiné), qui tournent donc à l'identique.
@immutable
class DieRollMotion {
  final Duration duration;
  final int turnsX;
  final int turnsY;
  final int turnsZ;

  /// Orientation d'arrêt autour de l'axe vertical, en quarts de tour (0 à 3) :
  /// décide quelles faces latérales se retrouvent visibles une fois le dé
  /// immobile (voir [dieFaceValues]).
  final int quarterTurns;

  /// Rebonds sur la table pendant le lancer : leur nombre (0 pour un dé posé),
  /// la hauteur du premier (fraction de la hauteur maximale, voir [hopAt]) et
  /// le coefficient de restitution, part de la vitesse conservée à chaque
  /// contact.
  final int bounces;
  final double firstHop;
  final double restitution;

  const DieRollMotion({
    required this.duration,
    required this.turnsX,
    required this.turnsY,
    required this.turnsZ,
    this.quarterTurns = 0,
    this.bounces = 0,
    this.firstHop = 0,
    this.restitution = 0.5,
  });

  /// Mouvement d'un dé qui n'a pas (encore) été lancé : seule son inclinaison
  /// de repos compte, [rotationAt] étant appelé avec une progression de 1.
  static const rest = DieRollMotion(duration: DieWidget.maxRollDuration, turnsX: 3, turnsY: 2, turnsZ: 1);

  factory DieRollMotion.random(math.Random random) {
    int signed(int turns) => random.nextBool() ? turns : -turns;
    final spanMs = (DieWidget.maxRollDuration - DieWidget.minRollDuration).inMilliseconds;
    return DieRollMotion(
      duration: DieWidget.minRollDuration + Duration(milliseconds: random.nextInt(spanMs + 1)),
      turnsX: signed(2 + random.nextInt(3)),
      turnsY: signed(2 + random.nextInt(3)),
      turnsZ: signed(1 + random.nextInt(2)),
      quarterTurns: random.nextInt(4),
      bounces: 2 + random.nextInt(3),
      firstHop: 0.7 + random.nextDouble() * 0.3,
      restitution: 0.45 + random.nextDouble() * 0.15,
    );
  }

  /// Inclinaison de repos (dé immobile) : vue plongeante donnant l'impression
  /// de regarder le dé du dessus (la face "top" domine), avec juste assez
  /// d'écart par rapport à la verticale pure pour distinguer les faces
  /// latérales et garder un rendu clairement 3D (pas un carré plat).
  static const restTiltX = -0.95;
  static const restTiltY = 0.785; // pi/4 : deux faces latérales adjacentes visibles à parts égales

  /// Part de la durée du lancer occupée par les rebonds : le dé finit posé,
  /// en achevant sa rotation.
  static const _bouncingPart = 0.85;

  /// Hauteur du dé au-dessus de la table (0 = posé, 1 = hauteur maximale) à la
  /// [progress] du lancer. Chaque rebond est une parabole ; comme en vrai, la
  /// vitesse au contact est multipliée par [restitution], donc la hauteur par
  /// son carré et la durée du rebond par [restitution] elle-même.
  double hopAt(double progress) {
    if (bounces == 0) return 0;
    var t = progress.clamp(0.0, 1.0) / _bouncingPart;
    if (t >= 1) return 0;
    // Durées des arcs : d, d·r, d·r², … dont la somme vaut 1.
    final r = restitution;
    var arc = (1 - r) / (1 - math.pow(r, bounces));
    var height = firstHop;
    for (var k = 0; k < bounces; k++) {
      if (t < arc) {
        final u = t / arc;
        return height * 4 * u * (1 - u);
      }
      t -= arc;
      arc *= r;
      height *= r * r;
    }
    return 0;
  }

  /// Angles (radians) du dé sur chaque axe à la [progress] du lancer
  /// (0 = départ, 1 = immobile) : les tours restants décroissent (easeOut)
  /// jusqu'à l'inclinaison de repos. Des angles plutôt qu'une matrice : le
  /// rendu 3D et le repli n'utilisent pas le même type de `Matrix4`.
  ({double x, double y, double z}) anglesAt(double progress) {
    final remaining = 1 - Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    return (
      x: restTiltX + remaining * turnsX * 2 * math.pi,
      y: restTiltY + remaining * turnsY * 2 * math.pi,
      z: remaining * turnsZ * 2 * math.pi * 0.3,
    );
  }
}

/// Élève le dé de sa table selon [hop] (0 = posé, 1 = au plus haut, voir
/// [DieRollMotion.hopAt]) : il monte et grossit un peu, comme s'il se
/// rapprochait de la caméra, au-dessus d'une ombre qui s'éclaircit et
/// rétrécit avec l'altitude. L'ombre n'apparaît qu'en vol (opacité nulle une
/// fois posé). N'occupe pas plus de place que [child] (le vol déborde sans
/// rien décaler), d'où les dimensions [size] imposées.
class DieBounce extends StatelessWidget {
  final double hop;
  final double size;
  final Widget child;

  const DieBounce({super.key, required this.hop, required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    // Toujours la même structure, même posé (hop = 0) : alterner entre [child]
    // seul et cette pile à chaque contact avec la table ferait remonter le
    // widget du dé, et sa vue 3D avec.
    final shadowWidth = size * 0.8 * (1 - 0.35 * hop);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: (size - shadowWidth) / 2,
          top: size * 0.8,
          width: shadowWidth,
          height: size * 0.18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.elliptical(shadowWidth / 2, size * 0.09)),
              color: Colors.black.withValues(alpha: 0.35 * (hop * 4).clamp(0.0, 1.0) * (1 - 0.5 * hop)),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -hop * size * 0.3),
          child: Transform.scale(scale: 1 + 0.15 * hop, child: child),
        ),
      ],
    );
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
  final Color? bodyColor;
  final double size;

  const _TransformCubeDie({
    required this.value,
    required this.state,
    this.onTap,
    this.rollToken,
    this.bodyColor,
    required this.size,
  });

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

/// Valeurs des 6 faces d'un dé standard (faces opposées = 7) pour un [top]
/// donné. La valeur réelle du dé est sur "top" : c'est la face que la caméra
/// (vue plongeante) montre dominamment au joueur.
///
/// Les 4 faces latérales forment un anneau (avant, droite, arrière, gauche)
/// que [quarterTurns] fait tourner d'autant de quarts de tour autour de l'axe
/// vertical : comme un vrai dé, un même résultat peut ainsi s'arrêter avec
/// quatre paires de faces latérales différentes visibles. Une rotation ne
/// change pas la disposition relative des faces : le dé reste le même dé.
Map<String, int> dieFaceValues(int top, {int quarterTurns = 0}) {
  final bottom = 7 - top;
  final remaining = [1, 2, 3, 4, 5, 6].where((v) => v != top && v != bottom).toList();
  final front = remaining[0];
  final right = remaining.firstWhere((v) => v != front && v != 7 - front);
  final ring = [front, right, 7 - front, 7 - right];
  final shift = quarterTurns % 4;
  int at(int i) => ring[(i + shift) % 4];
  return {'front': at(0), 'right': at(1), 'back': at(2), 'left': at(3), 'top': top, 'bottom': bottom};
}

class _TransformCubeDieState extends State<_TransformCubeDie> with SingleTickerProviderStateMixin {
  double get _size => widget.size;
  double get _half => _size / 2;
  late final AnimationController _controller;
  Object? _lastRollToken;
  final _random = math.Random();
  DieRollMotion _motion = DieRollMotion.rest;

  @override
  void initState() {
    super.initState();
    _lastRollToken = widget.rollToken;
    _controller = AnimationController(vsync: this, duration: _motion.duration)
      ..addListener(() => setState(() {}));
    if (widget.rollToken != null) {
      _startRoll();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _TransformCubeDie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rollToken != null && widget.rollToken != _lastRollToken) {
      _lastRollToken = widget.rollToken;
      _startRoll();
    }
  }

  void _startRoll() {
    _motion = DieRollMotion.random(_random);
    _controller
      ..duration = _motion.duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le dé ne revient jamais complètement à plat : même immobile, il garde
    // une légère inclinaison pour rester visiblement un cube en 3D.
    final angles = _motion.anglesAt(_controller.value);
    final spin = Matrix4.identity()
      ..rotateX(angles.x)
      ..rotateY(angles.y)
      ..rotateZ(angles.z);

    final values = dieFaceValues(widget.value, quarterTurns: _motion.quarterTurns);
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
        margin: const EdgeInsets.all(DieWidget.margin),
        width: _size,
        height: _size,
        child: DieBounce(
          hop: _motion.hopAt(_controller.value),
          size: _size,
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
                    child: _DieFace(value: face.value, state: widget.state, bodyColor: widget.bodyColor, size: _size),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DieFace extends StatelessWidget {
  final int value;
  final DieVisualState state;
  final Color? bodyColor;
  final double size;

  const _DieFace({required this.value, required this.state, this.bodyColor, required this.size});

  @override
  Widget build(BuildContext context) {
    final body = bodyColorFor(state, bodyColor);
    return Container(
      width: size,
      height: size,
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

/// Face de dé plate, vue de face, pour les usages à taille d'icône.
///
/// Le cube 3D de [DieWidget] est dessiné en perspective : en dessous d'une
/// trentaine de pixels, sa face utile et ses pips passent sous le pixel et la
/// valeur devient illisible — mesuré à l'écran, lisible à 34, pas à 22. Cette
/// face-ci reste nette à 14. Mêmes positions de pips et mêmes couleurs d'état
/// que le vrai dé, pour qu'elle se lise comme le même objet.
class DieGlyph extends StatelessWidget {
  final int value;
  final DieVisualState state;
  final double size;

  /// Couleur du liseré et des pips à la place de celles de [state] : pour un
  /// glyphe qui accompagne un texte d'une autre couleur que le dé qu'il
  /// représente (voir la mention « = 100 » de la zone « Main courante »).
  final Color? accent;
  final Color? pipColor;

  const DieGlyph({
    super.key,
    required this.value,
    this.state = DieVisualState.kept,
    this.size = 20,
    this.accent,
    this.pipColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DieGlyphPainter(value: value, state: state, accent: accent, pipColor: pipColor),
      ),
    );
  }
}

class _DieGlyphPainter extends CustomPainter {
  final int value;
  final DieVisualState state;
  final Color? accent;
  final Color? pipColor;

  const _DieGlyphPainter({required this.value, required this.state, this.accent, this.pipColor});

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, side, side).deflate(side * 0.05),
      Radius.circular(side * 0.2),
    );
    canvas.drawRRect(rrect, Paint()..color = bodyColorFor(state));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.07
        ..color = accent ?? accentColorFor(state),
    );
    // Pips un peu plus gros que sur le vrai dé (0,078 du côté) : à taille
    // d'icône, ce rayon-là tomberait sous le pixel.
    final pip = Paint()..color = pipColor ?? pipColorFor(state);
    for (final p in pipPositions[value] ?? const <Offset>[]) {
      canvas.drawCircle(Offset(p.dx * side, p.dy * side), side * 0.1, pip);
    }
  }

  @override
  bool shouldRepaint(_DieGlyphPainter old) =>
      old.value != value ||
      old.state != state ||
      old.accent != accent ||
      old.pipColor != pipColor;
}
