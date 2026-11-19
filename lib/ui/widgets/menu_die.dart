import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../theme.dart';
import 'dice3d/dice_face_texture.dart' show pipPositions;
import 'player_avatar.dart' show kEmojiFontFallback;
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
  }) => _MenuDiePicture.obtain(_lookKey(icon, color, ink), _painter(icon, color, ink), size, pixelRatio);

  static String _lookKey(IconData icon, Color color, Color ink) =>
      'menu|${icon.codePoint}|${icon.fontFamily}|${icon.fontPackage}|${color.toARGB32()}|${ink.toARGB32()}';

  static _MenuDiePainter _painter(IconData icon, Color color, Color ink) =>
      _MenuDiePainter(icon: icon, color: color, ink: ink, cameraDistance: _perspectiveDistance, yaw: _menuYaw);

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
      child: _MenuDiePicture(look: _lookKey(icon, color, ink), painter: () => _painter(icon, color, ink), size: size),
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
///
/// Les dés de la barre d'action de l'écran de jeu ([ActionDie]) passent par là
/// aussi : peint directement à l'écran, en perspective, un glyphe gravé
/// ([_engrave]) sortait rogné de ses calques ; rendu dans une image, il est
/// entier, comme à l'accueil.
class _MenuDiePicture extends StatefulWidget {
  /// Ce qui distingue l'apparence de ce dé de celle des autres (couleurs,
  /// décor), hors taille et densité : la clé de son image en mémoire.
  final String look;

  /// Le peintre du dé, appelé seulement si son image n'est pas déjà en mémoire.
  final _MenuDiePainter Function() painter;
  final double size;

  const _MenuDiePicture({required this.look, required this.painter, required this.size});

  /// Marge de l'image autour du dé, en part de son côté.
  static const _margin = 0.15;

  static final Map<String, ui.Image> _ready = {};
  static final Map<String, Future<ui.Image>> _pending = {};

  static String keyFor(String look, double size, double ratio) => '$look|$size|$ratio';

  /// L'image de ce dé : celle déjà en mémoire, ou celle que l'on calcule (un seul
  /// calcul, même demandé deux fois à la fois).
  static Future<ui.Image> obtain(String look, _MenuDiePainter painter, double size, double ratio) {
    final key = keyFor(look, size, ratio);
    return _pending.putIfAbsent(key, () async {
      final image = await _render(painter, size, ratio);
      _ready[key] = image;
      return image;
    });
  }

  static Future<ui.Image> _render(_MenuDiePainter painter, double size, double ratio) async {
    final pad = size * _margin;
    final side = size + 2 * pad;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(ratio)
      ..translate(pad, pad);
    painter.paint(canvas, Size(size, size));
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
    final key = _MenuDiePicture.keyFor(w.look, w.size, ratio);
    if (key == _key) return;
    _key = key;
    final ready = _MenuDiePicture._ready[key];
    if (ready != null) {
      _image = ready;
      return;
    }
    // Entre-temps : la couleur ou la taille a changé, l'ancienne image ne va plus.
    _image = null;
    _MenuDiePicture.obtain(w.look, w.painter(), w.size, ratio).then((image) {
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

/// La distance de l'œil au centre d'un dé, en côtés de dé : la perspective des dés
/// du menu et de l'icône de l'app.
const double _perspectiveDistance = 3.0;

/// La hauteur de la caméra des dés de l'accueil et de l'icône : vue de 30°
/// au-dessus de la table.
const double _menuPitch = 30 * math.pi / 180;

/// La hauteur de la caméra du dé central de la barre d'action de l'écran de jeu
/// (Lancer, ou le dé gris du tour d'un autre — voir [ActionDie]) : vu de 43°
/// au-dessus de la table, pour que le dessus (l'as, la pastille du joueur) soit
/// aussi lisible que les flancs. Il est vu de biais exact ([_cornerYaw]) :
/// flancs égaux, le « 10 » comme le « K ».
const double _actionPitch = 43 * math.pi / 180;

/// L'angle du dé Stop de la barre d'action : celui des dés de l'accueil
/// ([_menuYaw]) en miroir, tourné de 12° vers la droite. Les deux dés latéraux,
/// vus de 30° comme ceux de l'accueil, se font face de part et d'autre du dé
/// central : le recyclage (à gauche, [_menuYaw]) montre surtout son flanc droit,
/// Stop surtout son flanc gauche.
const double _mirroredMenuYaw = _cornerYaw + 12 * math.pi / 180;

/// Le quart de tour de base : un dé vu exactement de biais (45° autour de la
/// verticale), deux flancs égaux.
const double _cornerYaw = math.pi / 4;

/// L'angle des dés de l'accueil : un peu tournés par rapport à [_cornerYaw] (de 12°,
/// vers la gauche), pour qu'ils ne soient pas vus tout à fait de face — les deux
/// flancs ne sont plus égaux, celui de droite est le plus large.
const double _menuYaw = _cornerYaw - 12 * math.pi / 180;

/// L'angle du dé de l'icône de l'app : tourné de 8° vers la droite par rapport à
/// [_cornerYaw], donc dans l'autre sens que [_menuYaw] — le flanc de gauche (le
/// « 10 ») est le plus large, celui de droite (le « K ») le plus étroit.
const double _iconYaw = _cornerYaw + 8 * math.pi / 180;

/// Un dé de plastique coloré, transparent dans toute sa masse : ses six faces
/// sont peintes de la plus lointaine à la plus proche, chacune à moitié
/// transparente, si bien qu'on voit à travers le dé les faces du fond (leurs
/// icônes à l'envers) et que la couleur s'épaissit là où les faces se
/// superposent. Le cube est tourné autour de la verticale (45° par défaut, voir [yaw]), vu de 30°
/// au-dessus de la table par défaut (voir [pitch]), en perspective (voir [cameraDistance]) : ce qui est près
/// de l'œil, le sommet de devant, est plus grand que ce qui est loin.
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
  /// parallèle.
  final double? cameraDistance;

  /// De combien le dé est tourné autour de la verticale ([_cornerYaw] : de biais).
  final double yaw;

  /// La hauteur de la caméra au-dessus de la table ([_menuPitch] : 30°).
  final double pitch;

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
    this.yaw = _cornerYaw,
    this.pitch = _menuPitch,
    this.fillBounds = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final spin = Matrix4.identity()
      ..rotateX(-pitch)
      ..rotateY(yaw);
    // Projection en perspective : l'œil est sur l'axe, à [cameraDistance] du centre
    // du cube (dont le côté vaut 1), et ce qui est plus près est plus grand :
    // `w = 1 - z / distance` divise x et y. Sans [cameraDistance], projection
    // parallèle : les arêtes parallèles du cube restent parallèles à l'écran.
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
    // Les trois faces visibles : le dessus (voir plus bas), et des deux flancs
    // celle qui regarde le plus à gauche est la gauche.
    Vector3 normalOf(Matrix4 placement) => spin.transformed3(placement.transformed3(Vector3(0, 0, 1)));
    // Le dé est toujours vu d'au-dessus de la table : des deux faces horizontales
    // (les deux dernières de [faces]), la visible est le dessus. Le chercher par
    // la normale la plus verticale à l'écran ne marche plus au-delà de 45° de
    // hauteur ([pitch]) : un flanc l'emporte alors sur le dessus.
    final visible = [for (final (placement, _, z) in ordered) if (z > 0) placement];
    final top = visible.firstWhere((p) => identical(p, faces[4].$1) || identical(p, faces[5].$1));
    final left = visible.where((p) => !identical(p, top)).reduce((a, b) => normalOf(a).x < normalOf(b).x ? a : b);

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
    TextPainter glyphStyled({Color? color, Paint? foreground}) => TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: unit * 0.62,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              color: color,
              foreground: foreground,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    TextPainter glyph(Color tint) => glyphStyled(color: tint);
    final frontIcon = glyph(ink);
    final backIcon = glyph(ink.withValues(alpha: 0.4));

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
        // Une face du fond prend le rôle de la face visible qui lui est opposée :
        // le dessous se lit comme le dessus, l'arrière d'un flanc comme ce flanc.
        final seen = facing
            ? placement
            : visible.firstWhere((v) => normalOf(v).dot(normalOf(placement)) < -0.9, orElse: () => placement);
        art!(
          canvas,
          unit,
          identical(seen, top) ? _FaceRole.top : (identical(seen, left) ? _FaceRole.left : _FaceRole.right),
          facing,
        );
      } else if (facing) {
        // L'icône de devant est gravée en creux, de sa couleur.
        _engrave(canvas, unit, ink, (paint) => glyphStyled(foreground: paint).paint(canvas, at));
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
      old.icon != icon || old.color != color || old.ink != ink || old.translucent != translucent || old.art != art || old.yaw != yaw || old.pitch != pitch ||
      old.cameraDistance != cameraDistance || old.fillBounds != fillBounds;
}

/// Les trois faces que l'on voit d'un dé.
enum _FaceRole { top, left, right }

/// Ce qui se grave sur une face de [unit] de côté (le repère de la face, origine
/// en haut à gauche). [facing] faux : une face du fond, vue à travers le dé, dont
/// [role] est celui de la face visible opposée.
typedef _FaceArt = void Function(Canvas canvas, double unit, _FaceRole role, bool facing);

/// Une gravure en creux sur une face de [unit] de côté : le fond de la cavité
/// ([cavity]), une ombre intérieure floue le long des bords du haut et de la
/// gauche (là où la paroi cache la lumière), et un mince liseré clair de l'autre
/// côté, là où la lumière touche le rebord. Pas de copie sombre décalée dehors, qui
/// ferait un halo. [draw] trace la forme gravée avec la peinture qu'on lui donne.
void _engrave(Canvas canvas, double unit, Color cavity, void Function(Paint paint) draw) {
  final bounds = Rect.fromLTWH(-unit * 0.1, -unit * 0.1, unit * 1.2, unit * 1.2);
  Paint blur(double sigma) => Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  canvas
    ..saveLayer(bounds, blur(unit * 0.004))
    ..translate(unit * 0.012, unit * 0.012);
  draw(Paint()..color = Colors.white.withValues(alpha: 0.45));
  canvas.restore();
  draw(Paint()..color = cavity);
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

/// Peint dans [size] le dé de l'icône de l'app : le dé du menu, mais opaque, en
/// perspective, remplissant [size],
/// laiton d'un seul tenant, un as sur le dessus, « 10 » sur la face de gauche et
/// « K » sur celle de droite, gravés comme les icônes du menu. [numerals] est la
/// police des chiffres. L'outil `tool/render_app_icon_test.dart` s'en sert pour
/// produire les PNG de l'icône.
void paintAppIconDie(Canvas canvas, Size size, {required Color color, required Color ink, required TextStyle numerals}) {
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
    cameraDistance: _perspectiveDistance,
    yaw: _iconYaw,
    fillBounds: true,
    art: (canvas, unit, role, _) => _engrave(canvas, unit, Color.lerp(color, Colors.black, 0.72)!, (paint) {
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

/// Ce que porte une face visible d'un [ActionDie] : une icône, des pips, un
/// texte, la pastille d'un joueur, ou un émoji.
@immutable
sealed class DieMark {
  const DieMark();

  /// L'icône [icon], gravée.
  const factory DieMark.icon(IconData icon) = _IconMark;

  /// Les pips de [value] (1 à 6), gravés comme sur les dés du jeu.
  const factory DieMark.pips(int value) = _PipsMark;

  /// La pastille d'un joueur, posée sur la face : un disque de [color] portant
  /// sa lettre [letter], ou son animal [emoji] à la place.
  const factory DieMark.avatar({required Color color, required String letter, String? emoji}) = _AvatarMark;

  /// Le texte [text] gravé, dans le style [style] (sa taille est fixée ici) :
  /// le « 10 » et le « K » du dé de l'icône de l'app.
  const factory DieMark.text(String text, TextStyle style) = _TextMark;

  /// L'émoji [emoji], en couleurs, posé sur la face (💥 : le craque).
  const factory DieMark.emoji(String emoji) = _EmojiMark;

  /// Ce qui distingue cette marque des autres, pour la clé de l'image du dé.
  String get _id;

  /// Dessine la marque sur une face de [unit] de côté, gravée en [ink] si la
  /// face est visible ([facing]), estompée sinon (vue à travers le dé).
  void _paint(Canvas canvas, double unit, Color ink, bool facing);
}

class _IconMark extends DieMark {
  final IconData icon;
  const _IconMark(this.icon);

  @override
  String get _id => 'icon:${icon.codePoint}:${icon.fontFamily}:${icon.fontPackage}';

  @override
  void _paint(Canvas canvas, double unit, Color ink, bool facing) {
    TextPainter glyph({Color? color, Paint? foreground}) => TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: unit * 0.62,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              color: color,
              foreground: foreground,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    final probe = glyph(color: ink);
    final at = Offset((unit - probe.width) / 2, (unit - probe.height) / 2);
    if (facing) {
      _stamp(canvas, unit, ink, (paint) => glyph(foreground: paint).paint(canvas, at));
    } else {
      glyph(color: ink.withValues(alpha: 0.4)).paint(canvas, at);
    }
  }

  @override
  bool operator ==(Object other) => other is _IconMark && other.icon == icon;
  @override
  int get hashCode => icon.hashCode;
}

class _TextMark extends DieMark {
  final String text;
  final TextStyle style;
  const _TextMark(this.text, this.style);

  @override
  String get _id => 'text:$text:${style.fontFamily}:${style.fontVariations}';

  @override
  void _paint(Canvas canvas, double unit, Color ink, bool facing) {
    // La taille de [paintAppIconDie] : le même marquage que l'icône de l'app.
    TextPainter painter(Paint paint) => TextPainter(
          text: TextSpan(text: text, style: style.copyWith(fontSize: unit * 0.56, foreground: paint)),
          textDirection: TextDirection.ltr,
        )..layout();
    void draw(Paint paint) {
      final p = painter(paint);
      p.paint(canvas, Offset((unit - p.width) / 2, (unit - p.height) / 2));
    }

    if (facing) {
      _engrave(canvas, unit, ink, draw);
    } else {
      draw(Paint()..color = ink.withValues(alpha: 0.3));
    }
  }

  @override
  bool operator ==(Object other) => other is _TextMark && other.text == text && other.style == style;
  @override
  int get hashCode => Object.hash(text, style);
}

class _PipsMark extends DieMark {
  final int value;
  const _PipsMark(this.value);

  @override
  String get _id => 'pips:$value';

  @override
  void _paint(Canvas canvas, double unit, Color ink, bool facing) {
    // Vue à travers le dé, c'est la face opposée : sur un vrai dé, la somme de
    // deux faces opposées fait 7.
    final shown = facing ? value : 7 - value;
    void draw(Paint paint) {
      for (final p in pipPositions[shown] ?? const <Offset>[]) {
        canvas.drawCircle(Offset(p.dx * unit, p.dy * unit), unit * 0.095, paint);
      }
    }

    if (facing) {
      _engrave(canvas, unit, ink, draw);
    } else {
      draw(Paint()..color = ink.withValues(alpha: 0.3));
    }
  }

  @override
  bool operator ==(Object other) => other is _PipsMark && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

class _AvatarMark extends DieMark {
  final Color color;
  final String letter;
  final String? emoji;
  const _AvatarMark({required this.color, required this.letter, this.emoji});

  @override
  String get _id => 'avatar:${color.toARGB32()}:$letter:${emoji ?? ''}';

  @override
  void _paint(Canvas canvas, double unit, Color ink, bool facing) {
    final center = Offset(unit / 2, unit / 2);
    final radius = unit * 0.38;
    if (!facing) {
      canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.3));
      return;
    }
    // Une pastille collée sur la face, comme dans la liste des joueurs : pas
    // gravée, pour garder sa couleur.
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.03,
    );
    final animal = emoji;
    final text = animal != null
        ? _emojiPainter(animal, unit * 0.4)
        : (TextPainter(
            text: TextSpan(
              text: letter,
              style: TextStyle(fontSize: unit * 0.4, height: 1, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            textDirection: TextDirection.ltr,
          )..layout());
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool operator ==(Object other) =>
      other is _AvatarMark && other.color == color && other.letter == letter && other.emoji == emoji;
  @override
  int get hashCode => Object.hash(color, letter, emoji);
}

/// Un émoji en couleurs de [fontSize], prêt à peindre : la pastille animale
/// ([_AvatarMark]) et l'émoji d'une face ([_EmojiMark]).
TextPainter _emojiPainter(String emoji, double fontSize) => TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: fontSize, height: 1, fontFamilyFallback: kEmojiFontFallback),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

class _EmojiMark extends DieMark {
  final String emoji;
  const _EmojiMark(this.emoji);

  @override
  String get _id => 'emoji:$emoji';

  @override
  void _paint(Canvas canvas, double unit, Color ink, bool facing) {
    // L'émoji en couleurs, posé sur la face comme la pastille : ni gravé ni
    // teinté. Vu à travers le dé (une face cachée), il n'est qu'un reflet.
    final text = _emojiPainter(emoji, unit * 0.62);
    final at = Offset((unit - text.width) / 2, (unit - text.height) / 2);
    if (facing) {
      text.paint(canvas, at);
    } else {
      canvas.saveLayer(Offset.zero & Size.square(unit), Paint()..color = Colors.white.withValues(alpha: 0.3));
      text.paint(canvas, at);
      canvas.restore();
    }
  }

  @override
  bool operator ==(Object other) => other is _EmojiMark && other.emoji == emoji;
  @override
  int get hashCode => emoji.hashCode;
}

/// Une marque pleine imprimée sur une face de [unit] de côté, en [ink], sur une
/// ombre douce décalée vers le bas à droite. Pas de gravure ([_engrave]) : sur
/// un petit dé vu de biais, son ombre intérieure couvre presque toute une forme
/// pleine (le carré du stop, le triangle de lecture), qui paraît alors trouée.
void _stamp(Canvas canvas, double unit, Color ink, void Function(Paint paint) draw) {
  canvas
    ..save()
    ..translate(unit * 0.025, unit * 0.03);
  draw(
    Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.02),
  );
  canvas.restore();
  draw(Paint()..color = ink);
}

/// Le rôle d'un [ActionDie] dans la barre d'action de l'écran de jeu.
enum ActionDieKind {
  /// Lancer les dés.
  roll,

  /// S'arrêter (encaisser).
  stop,

  /// Choisir combien de 5 garder (le recyclage).
  exchange,

  /// Le tour d'un autre (bot, joueur en ligne) : un dé gris, inerte, qui dit ce
  /// qu'il fait.
  observed,
}

/// Un bouton de la barre d'action de l'écran de jeu, en dé translucide comme
/// ceux de l'accueil ([MenuDie]), plus petit : ses trois faces visibles portent
/// [top], [left] et [right] (voir [DieMark]), et un [caption] facultatif
/// s'écrit dessous.
///
/// Sans [onPressed], le dé est inerte. [dimmed] le délave alors et le grise
/// comme un [MenuDie] désactivé ; un dé [ActionDieKind.observed] est déjà gris
/// et garde ses couleurs (la pastille du joueur doit rester lisible).
class ActionDie extends StatelessWidget {
  final ActionDieKind kind;
  final DieMark top;
  final DieMark left;
  final DieMark right;
  final Color color;
  final Color ink;
  final double size;
  final String? caption;

  /// Ce qui s'affiche à la place du texte de [caption], quand il porte autre
  /// chose que du texte (la pastille d'un joueur à la place de son nom) ;
  /// [caption] reste ce que le lecteur d'écran annonce.
  final InlineSpan? captionSpan;

  /// L'infobulle du bouton. Le lecteur d'écran annonce le texte affiché,
  /// [caption], et n'en fait qu'une précision ; sans [caption], c'est elle qu'il
  /// annonce comme nom du bouton.
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool dimmed;

  const ActionDie({
    super.key,
    required this.kind,
    required this.top,
    required this.left,
    required this.right,
    required this.color,
    required this.ink,
    required this.size,
    this.caption,
    this.captionSpan,
    this.tooltip,
    this.onPressed,
    this.dimmed = true,
  });

  /// Un dé dont les trois faces portent la même [mark].
  const ActionDie.uniform({
    Key? key,
    required ActionDieKind kind,
    required DieMark mark,
    required Color color,
    required Color ink,
    required double size,
    String? caption,
    String? tooltip,
    VoidCallback? onPressed,
    bool dimmed = true,
  }) : this(
          key: key,
          kind: kind,
          top: mark,
          left: mark,
          right: mark,
          color: color,
          ink: ink,
          size: size,
          caption: caption,
          tooltip: tooltip,
          onPressed: onPressed,
          dimmed: dimmed,
        );

  /// L'angle de vue du dé selon son rôle : le dé central (Lancer, ou le dé gris
  /// du tour d'un autre) de biais exact, vu de plus haut ([_actionPitch]) ; les
  /// deux dés latéraux vus comme ceux de l'accueil, en miroir l'un de l'autre.
  (double yaw, double pitch) get _view => switch (kind) {
        ActionDieKind.roll || ActionDieKind.observed => (_cornerYaw, _actionPitch),
        ActionDieKind.exchange => (_menuYaw, _menuPitch),
        ActionDieKind.stop => (_mirroredMenuYaw, _menuPitch),
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (yaw, pitch) = _view;
    // La pastille du dessus est redressée : dessinée dans le losange que forme
    // la face vue de biais, elle serait penchée de l'angle du dé.
    final art = _ActionDieArt(top: top, left: left, right: right, ink: ink, topTurn: yaw);
    Widget die = SizedBox(
      width: size,
      height: size,
      child: _MenuDiePicture(
        look: 'action|${kind.name}|${color.toARGB32()}|${art.id}',
        painter: () => _MenuDiePainter(
          icon: Icons.circle,
          color: color,
          ink: ink,
          cameraDistance: _perspectiveDistance,
          yaw: yaw,
          pitch: pitch,
          art: art.call,
        ),
        size: size,
      ),
    );
    final caption = this.caption;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: TableColors.of(context).plain);
    Widget content = caption == null
        ? die
        : Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              die,
              Text.rich(
                captionSpan ?? TextSpan(text: caption),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ],
          );
    if (!enabled && dimmed) {
      content = Opacity(opacity: 0.38, child: ColorFiltered(colorFilter: MenuDie._grayscale, child: content));
    }
    // Le nom annoncé est le texte affiché sous le dé, celui que l'on voit — et
    // que la commande vocale cherche ; l'infobulle, quand elle dit autre chose,
    // vient en précision.
    final label = caption ?? tooltip ?? '';
    final detail = caption != null && tooltip != caption ? tooltip : null;
    content = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      tooltip: detail,
      // Le détecteur de geste est dans le sous-arbre exclu : sans [onTap] ici,
      // le lecteur d'écran annoncerait un bouton impossible à activer.
      onTap: onPressed,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: size / 2 + 6,
        containedInkWell: false,
        child: content,
      ),
    );
    final message = tooltip;
    return message == null ? content : Tooltip(message: message, excludeFromSemantics: true, child: content);
  }
}

/// Les marques d'un [ActionDie], données à [_MenuDiePainter] comme décor de ses
/// faces ; [id] les résume pour la clé de l'image du dé.
@immutable
class _ActionDieArt {
  final DieMark top;
  final DieMark left;
  final DieMark right;
  final Color ink;

  /// De combien la pastille du dessus est tournée sur sa face pour se lire
  /// droite à l'écran : l'angle du dé autour de la verticale.
  final double topTurn;

  const _ActionDieArt({required this.top, required this.left, required this.right, required this.ink, required this.topTurn});

  String get id => '${top._id}|${left._id}|${right._id}|${ink.toARGB32()}';

  void call(Canvas canvas, double unit, _FaceRole role, bool facing) {
    final mark = switch (role) {
      _FaceRole.top => top,
      _FaceRole.left => left,
      _FaceRole.right => right,
    };
    if (role == _FaceRole.top && mark is _AvatarMark) {
      canvas.save();
      canvas.translate(unit / 2, unit / 2);
      canvas.rotate(topTurn);
      canvas.translate(-unit / 2, -unit / 2);
      mark._paint(canvas, unit, ink, facing);
      canvas.restore();
      return;
    }
    mark._paint(canvas, unit, ink, facing);
  }
}
