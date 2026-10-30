import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// Une entrée du menu d'accueil, en dé vu de trois quarts : chacune de ses
/// trois faces visibles porte l'[icon], le dé a la couleur du bouton, et son
/// [label] est écrit dessous. C'est aussi ce que lit un lecteur d'écran.
///
/// Sans [onPressed], le dé est inerte : délavé et grisé, comme un bouton
/// désactivé.
class MenuDie extends StatelessWidget {
  final IconData icon;
  final String label;

  /// La couleur du dé (la face de gauche ; le dessus est plus clair, la face de
  /// droite plus sombre).
  final Color color;

  /// La couleur de l'icône sur les faces.
  final Color ink;

  /// La largeur du dé ; le libellé s'écrit dessous, sur la même largeur.
  final double size;
  final VoidCallback? onPressed;

  const MenuDie({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.ink,
    this.size = 96,
    this.onPressed,
  });

  /// Ce que le libellé a de plus que le dé en largeur : un nom long passe sur
  /// deux lignes plutôt que d'être coupé.
  static const captionMargin = 16.0;

  /// Calcule d'avance l'image d'un dé (voir [_MenuDiePicture]), pour que l'accueil
  /// la trouve prête. Les paramètres doivent être exactement ceux de l'accueil
  /// (icône, couleurs, taille, densité de l'écran), faute de quoi l'image n'est
  /// pas retrouvée et l'accueil la recalcule.
  static Future<void> precache({
    required IconData icon,
    required Color color,
    required Color ink,
    required double size,
    required double pixelRatio,
  }) => _MenuDiePicture.obtain(icon, color, ink, size, pixelRatio);

  static const _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    Widget die = SizedBox(
      width: size,
      height: size,
      child: _MenuDiePicture(icon: icon, color: color, ink: ink, size: size),
    );
    Widget caption = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TableColors.of(context).plain, height: 1.15),
    );
    Widget content = SizedBox(
      width: size + captionMargin,
      child: Column(mainAxisSize: MainAxisSize.min, spacing: 6, children: [die, caption]),
    );
    if (!enabled) {
      content = Opacity(opacity: 0.38, child: ColorFiltered(colorFilter: _grayscale, child: content));
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: size / 2 + 8,
        containedInkWell: false,
        child: content,
      ),
    );
  }
}

/// Le dé du menu, dessiné une seule fois : [_MenuDiePainter] (une dizaine de
/// flous par dé, neuf dés à l'écran) est rendu dans une image, gardée en mémoire
/// pour toute la session, et l'écran ne fait plus que la poser. Redessiner les
/// dés à chaque repeinture de l'accueil (transitions de page, retour d'un écran)
/// faisait ramer le menu.
///
/// L'image est calculée à la densité de l'écran, avec une marge tout autour pour
/// que l'ombre portée floue ne soit pas rognée. Tant qu'elle n'est pas prête
/// (le premier affichage seulement), la place du dé reste vide.
class _MenuDiePicture extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color ink;
  final double size;

  const _MenuDiePicture({required this.icon, required this.color, required this.ink, required this.size});

  /// Marge de l'image autour du dé, en part de son côté.
  static const _margin = 0.15;

  static final Map<String, ui.Image> _ready = {};
  static final Map<String, Future<ui.Image>> _pending = {};

  static String keyFor(IconData icon, Color color, Color ink, double size, double ratio) =>
      '${icon.codePoint}|${icon.fontFamily}|${icon.fontPackage}|${color.toARGB32()}|${ink.toARGB32()}|$size|$ratio';

  /// L'image de ce dé : celle déjà en mémoire, ou celle que l'on calcule (un seul
  /// calcul, même demandé deux fois à la fois).
  static Future<ui.Image> obtain(IconData icon, Color color, Color ink, double size, double ratio) {
    final key = keyFor(icon, color, ink, size, ratio);
    return _pending.putIfAbsent(key, () async {
      final image = await _render(icon, color, ink, size, ratio);
      _ready[key] = image;
      return image;
    });
  }

  static Future<ui.Image> _render(IconData icon, Color color, Color ink, double size, double ratio) async {
    final pad = size * _margin;
    final side = size + 2 * pad;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(ratio)
      ..translate(pad, pad);
    _MenuDiePainter(icon: icon, color: color, ink: ink).paint(canvas, Size(size, size));
    final picture = recorder.endRecording();
    try {
      return await picture.toImage((side * ratio).ceil(), (side * ratio).ceil());
    } finally {
      picture.dispose();
    }
  }

  @override
  State<_MenuDiePicture> createState() => _MenuDiePictureState();
}

class _MenuDiePictureState extends State<_MenuDiePicture> {
  ui.Image? _image;
  String? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(covariant _MenuDiePicture old) {
    super.didUpdateWidget(old);
    _load();
  }

  void _load() {
    final w = widget;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final key = _MenuDiePicture.keyFor(w.icon, w.color, w.ink, w.size, ratio);
    if (key == _key) return;
    _key = key;
    final ready = _MenuDiePicture._ready[key];
    if (ready != null) {
      _image = ready;
      return;
    }
    // Entre-temps : la couleur ou la taille a changé, l'ancienne image ne va plus.
    _image = null;
    _MenuDiePicture.obtain(w.icon, w.color, w.ink, w.size, ratio).then((image) {
      if (mounted && _key == key) setState(() => _image = image);
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.expand();
    final side = widget.size * (1 + 2 * _MenuDiePicture._margin);
    return OverflowBox(
      minWidth: side,
      maxWidth: side,
      minHeight: side,
      maxHeight: side,
      child: RawImage(image: image, width: side, height: side, filterQuality: FilterQuality.medium),
    );
  }
}

/// Un dé de plastique coloré, transparent dans toute sa masse : ses six faces
/// sont peintes de la plus lointaine à la plus proche, chacune à moitié
/// transparente, si bien qu'on voit à travers le dé les faces du fond (leurs
/// icônes à l'envers) et que la couleur s'épaissit là où les faces se
/// superposent. La vue est une projection dimétrique : le cube tourné de 45°
/// autour de la verticale, vu de 30° au-dessus de la table, sans perspective
/// (les flancs gauche et droit sont raccourcis pareillement, le dessus autrement).
///
/// Avec [translucent] faux, le dé est opaque : plus de faces vues à travers les
/// autres, plus d'arêtes ni d'icônes du fond. C'est le dé de l'icône de l'app
/// (voir [paintAppIconDie]), dont [art] grave un décor propre à chaque face au
/// lieu de l'[icon] commune.
class _MenuDiePainter extends CustomPainter {
  final IconData icon;
  final Color color;
  final Color ink;
  final bool translucent;
  final _FaceArt? art;

  /// La distance de l'œil au centre du dé, en côtés de dé ; nulle : projection
  /// parallèle (celle du menu).
  final double? cameraDistance;

  /// Le dé remplit tout son cadre (contour arrondi compris) au lieu de laisser la
  /// place d'une ombre.
  final bool fillBounds;

  const _MenuDiePainter({
    required this.icon,
    required this.color,
    required this.ink,
    this.translucent = true,
    this.art,
    this.cameraDistance,
    this.fillBounds = false,
  });

  static const _yaw = math.pi / 4;
  static const _tilt = -30 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final spin = Matrix4.identity()
      ..rotateX(_tilt)
      ..rotateY(_yaw);
    // Projection parallèle, sans aucune perspective : les arêtes parallèles du
    // cube restent parallèles à l'écran. Avec [cameraDistance], l'œil est sur l'axe
    // à cette distance du centre du cube (le côté du cube vaut 1) et ce qui est plus
    // près est plus grand : `w = 1 - z / distance` divise x et y.
    final distance = cameraDistance;
    final camera = distance == null
        ? spin
        : (Matrix4.identity()
            ..setEntry(3, 2, -1 / distance)
            ..multiply(spin));

    // Les six faces : leur placement sur le cube, et leur teinte (le dessus
    // attrape la lumière, les flancs sont dans l'ombre).
    final faces = [
      (Matrix4.identity(), color),
      (Matrix4.identity()..rotateY(math.pi), color),
      (Matrix4.identity()..rotateY(math.pi / 2), Color.lerp(color, Colors.black, 0.3)!),
      (Matrix4.identity()..rotateY(-math.pi / 2), Color.lerp(color, Colors.black, 0.3)!),
      (Matrix4.identity()..rotateX(math.pi / 2), Color.lerp(color, Colors.white, 0.3)!),
      (Matrix4.identity()..rotateX(-math.pi / 2), Color.lerp(color, Colors.white, 0.1)!),
    ];
    // La profondeur de chaque face (sa normale tournée, comme dans DieWidget) :
    // on peint le fond d'abord.
    final ordered = [
      for (final (placement, tint) in faces)
        (placement, tint, spin.transformed3(placement.transformed3(Vector3(0, 0, 1))).z),
    ]..sort((a, b) => a.$3.compareTo(b.$3));
    // Les trois faces visibles : le dessus est celle dont la normale est la plus
    // verticale, des deux flancs celle qui regarde le plus à gauche est la gauche.
    Vector3 normalOf(Matrix4 placement) => spin.transformed3(placement.transformed3(Vector3(0, 0, 1)));
    final visible = [for (final (placement, _, z) in ordered) if (z > 0) placement]
      ..sort((a, b) => normalOf(b).y.abs().compareTo(normalOf(a).y.abs()));
    final top = visible.first;
    final left = visible.skip(1).reduce((a, b) => normalOf(a).x < normalOf(b).x ? a : b);

    // Les huit sommets du cube unité, vus par la caméra (projection parallèle :
    // on ne garde que x et y).
    final corners = [
      for (final x in const [-0.5, 0.5])
        for (final y in const [-0.5, 0.5])
          for (final z in const [-0.5, 0.5]) Vector3(x, y, z),
    ];
    final projected = [
      for (final v in corners)
        () {
          final p = spin.transformed3(v);
          final w = distance == null ? 1.0 : 1 - p.z / distance;
          return Offset(p.x / w, p.y / w);
        }(),
    ];
    final bounds = projected.map((p) => Rect.fromPoints(p, p)).reduce((a, b) => a.expandToInclude(b));
    var scale = math.min(size.width / bounds.width, size.height / bounds.height);
    var shift = Offset(size.width, size.height) / 2 - bounds.center * scale;
    Offset onScreen(int i) => projected[i] * scale + shift;

    // Le contour du dé : l'enveloppe convexe des huit sommets, dont on arrondit
    // chaque coin. Faces et arêtes sont rognées à ce contour, qui donne au dé ses
    // coins arrondis tout en laissant les faces jointives.
    final width = size.width / 36;
    Path outline() => _roundedPolygon(_convexHull([for (var i = 0; i < 8; i++) onScreen(i)]), width * 2.4);
    if (fillBounds) {
      // Arrondir les coins rogne le contour : on agrandit le dé pour que ce soit le
      // contour arrondi, et non l'enveloppe des sommets, qui touche les bords de
      // [size] (quelques passes suffisent, l'arrondi variant peu avec l'échelle).
      for (var pass = 0; pass < 3; pass++) {
        final rounded = _tightBounds(outline());
        final grow = math.min(size.width / rounded.width, size.height / rounded.height);
        final center = (rounded.center - shift) / scale;
        scale *= grow;
        shift = Offset(size.width, size.height) / 2 - center * scale;
      }
    }

    // L'ombre portée sur le feutre. Un dé qui remplit son cadre n'en a pas : elle
    // en sortirait, rognée.
    if (!fillBounds) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.97),
          width: size.width * 0.8,
          height: size.height * 0.16,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width / 16),
      );
    }

    const unit = 100.0;
    TextPainter glyph(Color tint) => TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: unit * 0.62,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              color: tint,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    final frontIcon = glyph(ink);
    final backIcon = glyph(ink.withValues(alpha: 0.4));
    // L'incrustation de l'icône de devant : un bord d'ombre en haut à gauche et
    // un reflet en bas à droite.
    final cutShadow = glyph(Colors.black.withValues(alpha: 0.55));
    final cutLight = glyph(Colors.white.withValues(alpha: 0.4));
    const depth = unit * 0.022;

    final fitted = Matrix4(
      scale, 0, 0, 0, //
      0, scale, 0, 0, //
      0, 0, 1, 0, //
      shift.dx, shift.dy, 0, 1,
    );
    final silhouette = outline();
    canvas.save();
    canvas.clipPath(silhouette);

    // Les faces sont des carrés vifs : ce sont les arêtes, dessinées ensuite, qui
    // font les jointures.
    const faceRect = Rect.fromLTWH(0, 0, unit, unit);
    for (final (placement, tint, z) in ordered) {
      final facing = z > 0;
      if (!translucent && !facing) continue;
      final onFace = fitted.multiplied(camera)
        ..multiply(placement)
        ..translateByDouble(0.0, 0.0, 0.5, 1.0)
        ..scaleByDouble(1 / unit, 1 / unit, 1.0, 1.0)
        ..translateByDouble(-unit / 2, -unit / 2, 0.0, 1.0);
      canvas.save();
      canvas.transform(onFace.storage);
      // La matière : la couleur, à moitié transparente.
      canvas.drawRect(faceRect, Paint()..color = translucent ? tint.withValues(alpha: facing ? 0.42 : 0.3) : tint);
      if (facing) {
        // Le reflet du plastique.
        canvas.drawRect(
          faceRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0)],
              stops: const [0, 0.65],
            ).createShader(faceRect),
        );
      }
      final at = Offset((unit - frontIcon.width) / 2, (unit - frontIcon.height) / 2);
      if (art != null) {
        art!(canvas, unit, identical(placement, top) ? _FaceRole.top : (identical(placement, left) ? _FaceRole.left : _FaceRole.right));
      } else if (facing) {
        cutLight.paint(canvas, at + const Offset(depth, depth));
        cutShadow.paint(canvas, at - const Offset(depth, depth));
        frontIcon.paint(canvas, at);
      } else {
        backIcon.paint(canvas, at);
      }
      canvas.restore();
    }

    canvas.restore();

    // Les douze arêtes : deux sommets qui ne diffèrent que d'une coordonnée. Une
    // arête entre deux faces tournées vers le fond est celle qu'on voit à
    // travers le dé : plus fine et plus pâle.
    canvas.save();
    canvas.clipPath(silhouette);
    bool facingNormal(Vector3 normal) => spin.transformed3(normal).z > 0;
    final hidden = <(Offset, Offset)>[];
    final shown = <(Offset, Offset)>[];
    // Les arêtes entre deux faces visibles d'un dé opaque, avec la teinte à mi-chemin
    // de leurs deux faces : le lissage de l'arrondi (voir plus bas).
    final creases = <(Offset, Offset, Color)>[];
    Color tintOf(Vector3 normal) =>
        faces.firstWhere((f) => f.$1.transformed3(Vector3(0, 0, 1)).dot(normal) > 0.9).$2;
    for (var i = 0; i < 8; i++) {
      for (var j = i + 1; j < 8; j++) {
        final d = corners[j] - corners[i];
        if ((d.x != 0 ? 1 : 0) + (d.y != 0 ? 1 : 0) + (d.z != 0 ? 1 : 0) != 1) continue;
        final mid = (corners[i] + corners[j]) / 2;
        // Les deux faces qui se rejoignent là : celles dont la normale est portée
        // par les deux coordonnées non nulles du milieu de l'arête.
        final normals = [
          if (mid.x != 0) Vector3(mid.x.sign, 0, 0),
          if (mid.y != 0) Vector3(0, mid.y.sign, 0),
          if (mid.z != 0) Vector3(0, 0, mid.z.sign),
        ];
        (normals.any(facingNormal) ? shown : hidden).add((onScreen(i), onScreen(j)));
        if (!translucent && normals.every(facingNormal)) {
          creases.add((onScreen(i), onScreen(j), Color.lerp(tintOf(normals[0]), tintOf(normals[1]), 0.5)!));
        }
      }
    }
    // Pas de jointure visible : une arête arrondie n'a pas de trait, seulement un
    // reflet doux là où la lumière glisse d'une face à l'autre.
    Paint soft(double alpha, double factor) => Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * factor
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.9);
    // Une arête arrondie fond une face dans l'autre : une bande floue de la teinte
    // intermédiaire, aux bouts ronds (donc aussi au sommet où les trois faces se
    // rejoignent, qui sans elle resterait une pointe vive).
    for (final (a, b, tint) in creases) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = tint
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 1.4),
      );
    }
    if (translucent) {
      for (final (a, b) in hidden) {
        canvas.drawLine(a, b, soft(0.14, 1.6));
      }
    }
    // Opaque, le dé garde des reflets plus discrets : un halo clair aussi large
    // donnerait un aspect givré.
    final glow = translucent ? 1.0 : 0.5;
    for (final (a, b) in shown) {
      canvas.drawLine(a, b, soft(0.3 * glow, 2.4));
    }
    // Les arêtes du contour sont traitées comme les autres : pas de trait, le même
    // reflet doux, rogné au dé (donc rentrant), avec un léger assombrissement
    // dessous pour que le bord se détache du feutre.
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = Color.lerp(color, Colors.black, 0.6)!.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 3
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.9),
    );
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3 * glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.4
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.9),
    );
    canvas.restore();
  }

  /// L'enveloppe convexe de [points], dans l'ordre du contour.
  static List<Offset> _convexHull(List<Offset> points) {
    final sorted = [...points]..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
    double cross(Offset o, Offset a, Offset b) => (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    final lower = <Offset>[];
    for (final p in sorted) {
      while (lower.length >= 2 && cross(lower[lower.length - 2], lower.last, p) <= 1e-6) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final upper = <Offset>[];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 && cross(upper[upper.length - 2], upper.last, p) <= 1e-6) {
        upper.removeLast();
      }
      upper.add(p);
    }
    return [...lower..removeLast(), ...upper..removeLast()];
  }

  /// L'emprise réelle de [path] : `Path.getBounds` compte les points de contrôle
  /// des courbes (ici ceux des coins arrondis, donc les sommets du polygone), on
  /// échantillonne donc le tracé.
  static Rect _tightBounds(Path path) {
    Rect? bounds;
    for (final metric in path.computeMetrics()) {
      const steps = 400;
      for (var i = 0; i <= steps; i++) {
        final p = metric.getTangentForOffset(metric.length * i / steps)!.position;
        bounds = bounds == null ? Rect.fromPoints(p, p) : bounds.expandToInclude(Rect.fromPoints(p, p));
      }
    }
    return bounds!;
  }

  /// Le polygone [points] dont chaque coin est arrondi sur [radius] de chaque côté.
  static Path _roundedPolygon(List<Offset> points, double radius) {
    final path = Path();
    final n = points.length;
    for (var i = 0; i < n; i++) {
      final prev = points[(i + n - 1) % n];
      final p = points[i];
      final next = points[(i + 1) % n];
      final enter = p + (prev - p) / (prev - p).distance * radius;
      final leave = p + (next - p) / (next - p).distance * radius;
      if (i == 0) {
        path.moveTo(enter.dx, enter.dy);
      } else {
        path.lineTo(enter.dx, enter.dy);
      }
      path.quadraticBezierTo(p.dx, p.dy, leave.dx, leave.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_MenuDiePainter old) =>
      old.icon != icon || old.color != color || old.ink != ink || old.translucent != translucent || old.art != art ||
      old.cameraDistance != cameraDistance || old.fillBounds != fillBounds;
}

/// Les trois faces que l'on voit d'un dé.
enum _FaceRole { top, left, right }

/// Ce qui se grave sur une face de [unit] de côté (le repère de la face, origine
/// en haut à gauche).
typedef _FaceArt = void Function(Canvas canvas, double unit, _FaceRole role);

/// Peint dans [size] le dé de l'icône de l'app : le dé du menu, mais opaque, en
/// perspective, remplissant [size],
/// laiton d'un seul tenant, un as sur le dessus, « 10 » sur la face de gauche et
/// « K » sur celle de droite, gravés comme les icônes du menu. [numerals] est la
/// police des chiffres. L'outil `tool/render_app_icon_test.dart` s'en sert pour
/// produire les PNG de l'icône.
void paintAppIconDie(Canvas canvas, Size size, {required Color color, required Color ink, required TextStyle numerals}) {
  // Une gravure en creux : le fond de la cavité, une ombre intérieure floue le long
  // des bords du haut et de la gauche (là où la paroi cache la lumière), et un mince
  // liseré clair de l'autre côté, là où la lumière touche le rebord. Pas de copie
  // sombre décalée dehors, qui ferait un halo.
  void engrave(Canvas canvas, double unit, void Function(Paint paint) draw) {
    final bounds = Rect.fromLTWH(-unit * 0.1, -unit * 0.1, unit * 1.2, unit * 1.2);
    Paint blur(double sigma) => Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    canvas
      ..saveLayer(bounds, blur(unit * 0.004))
      ..translate(unit * 0.012, unit * 0.012);
    draw(Paint()..color = Colors.white.withValues(alpha: 0.45));
    canvas.restore();
    draw(Paint()..color = Color.lerp(color, Colors.black, 0.72)!);
    canvas.saveLayer(bounds, blur(unit * 0.011));
    draw(Paint()..color = Colors.black.withValues(alpha: 0.95));
    canvas
      ..save()
      ..translate(unit * 0.03, unit * 0.034);
    draw(Paint()..blendMode = BlendMode.dstOut);
    canvas
      ..restore()
      ..restore();
  }

  void text(Canvas canvas, double unit, String text, Paint paint) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: numerals.copyWith(fontSize: unit * 0.56, foreground: paint)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((unit - painter.width) / 2, (unit - painter.height) / 2));
  }

  _MenuDiePainter(
    icon: Icons.circle,
    color: color,
    ink: ink,
    translucent: false,
    cameraDistance: 3.0,
    fillBounds: true,
    art: (canvas, unit, role) => engrave(canvas, unit, (paint) {
      switch (role) {
        case _FaceRole.top:
          canvas.drawCircle(Offset(unit / 2, unit / 2), unit * 0.13, paint);
        case _FaceRole.left:
          text(canvas, unit, '10', paint);
        case _FaceRole.right:
          text(canvas, unit, 'K', paint);
      }
    }),
  ).paint(canvas, size);
}
