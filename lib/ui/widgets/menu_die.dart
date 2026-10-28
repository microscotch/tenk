import 'dart:math' as math;

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
      child: CustomPaint(painter: _MenuDiePainter(icon: icon, color: color, ink: ink)),
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

/// Un dé de plastique coloré, transparent dans toute sa masse : ses six faces
/// sont peintes de la plus lointaine à la plus proche, chacune à moitié
/// transparente, si bien qu'on voit à travers le dé les faces du fond (leurs
/// icônes à l'envers) et que la couleur s'épaissit là où les faces se
/// superposent. La vue est une projection dimétrique : le cube tourné de 45°
/// autour de la verticale, vu de 30° au-dessus de la table, sans perspective
/// (les flancs gauche et droit sont raccourcis pareillement, le dessus autrement).
class _MenuDiePainter extends CustomPainter {
  final IconData icon;
  final Color color;
  final Color ink;

  const _MenuDiePainter({required this.icon, required this.color, required this.ink});

  static const _yaw = math.pi / 4;
  static const _tilt = -30 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final spin = Matrix4.identity()
      ..rotateX(_tilt)
      ..rotateY(_yaw);
    // Projection parallèle, sans aucune perspective : les arêtes parallèles du
    // cube restent parallèles à l'écran.
    final camera = spin;

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

    // Les huit sommets du cube unité, vus par la caméra (projection parallèle :
    // on ne garde que x et y).
    final corners = [
      for (final x in const [-0.5, 0.5])
        for (final y in const [-0.5, 0.5])
          for (final z in const [-0.5, 0.5]) Vector3(x, y, z),
    ];
    final projected = [for (final v in corners) camera.transformed3(v)];
    final bounds = projected
        .map((p) => Rect.fromPoints(Offset(p.x, p.y), Offset(p.x, p.y)))
        .reduce((a, b) => a.expandToInclude(b));
    final scale = math.min(size.width / bounds.width, size.height / bounds.height);
    final shift = Offset(size.width, size.height) / 2 - bounds.center * scale;
    Offset onScreen(int i) => Offset(projected[i].x, projected[i].y) * scale + shift;

    // L'ombre portée sur le feutre.
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
    // Le contour du dé : l'enveloppe convexe des huit sommets, dont on arrondit
    // chaque coin. Faces et arêtes sont rognées à ce contour, qui donne au dé ses
    // coins arrondis tout en laissant les faces jointives.
    final width = size.width / 36;
    final hull = _convexHull([for (var i = 0; i < 8; i++) onScreen(i)]);
    final silhouette = _roundedPolygon(hull, width * 2.4);
    canvas.save();
    canvas.clipPath(silhouette);

    // Les faces sont des carrés vifs : ce sont les arêtes, dessinées ensuite, qui
    // font les jointures.
    const faceRect = Rect.fromLTWH(0, 0, unit, unit);
    for (final (placement, tint, z) in ordered) {
      final facing = z > 0;
      final onFace = fitted.multiplied(camera)
        ..multiply(placement)
        ..translateByDouble(0.0, 0.0, 0.5, 1.0)
        ..scaleByDouble(1 / unit, 1 / unit, 1.0, 1.0)
        ..translateByDouble(-unit / 2, -unit / 2, 0.0, 1.0);
      canvas.save();
      canvas.transform(onFace.storage);
      // La matière : la couleur, à moitié transparente.
      canvas.drawRect(faceRect, Paint()..color = tint.withValues(alpha: facing ? 0.42 : 0.3));
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
      if (facing) {
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
    for (final (a, b) in hidden) {
      canvas.drawLine(a, b, soft(0.14, 1.6));
    }
    for (final (a, b) in shown) {
      canvas.drawLine(a, b, soft(0.3, 2.4));
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
        ..color = Colors.white.withValues(alpha: 0.3)
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
  bool shouldRepaint(_MenuDiePainter old) => old.icon != icon || old.color != color || old.ink != ink;
}
