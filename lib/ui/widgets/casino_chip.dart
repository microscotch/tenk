import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Un jeton de casino qui sert de bouton : une couleur, un liseré, une icône,
/// et rien d'écrit dessus. Son nom ([label]) s'affiche dans une infobulle à
/// l'appui long (au survol sur ordinateur) et c'est lui que lit un lecteur
/// d'écran.
///
/// Sans [onPressed], le jeton est inerte : délavé et grisé, comme un bouton
/// désactivé.
class CasinoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Le corps du jeton, ses inserts de bord et le liseré pointillé.
  final Color color;
  final Color edge;

  /// La couleur de l'icône.
  final Color ink;

  /// Le diamètre du jeton ; il occupe en plus son épaisseur sous lui.
  final double size;
  final VoidCallback? onPressed;

  const CasinoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.edge,
    required this.ink,
    this.size = 96,
    this.onPressed,
  });

  static const _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final thickness = math.max(3.0, size / 26);
    Widget chip = SizedBox(
      width: size,
      height: size + thickness,
      child: CustomPaint(
        painter: _CasinoChipPainter(color: color, edge: edge, thickness: thickness),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: Icon(icon, size: size * 0.34, color: ink)),
        ),
      ),
    );
    if (!enabled) {
      chip = Opacity(opacity: 0.38, child: ColorFiltered(colorFilter: _grayscale, child: chip));
    }
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: size / 2,
          containedInkWell: true,
          customBorder: const CircleBorder(),
          child: chip,
        ),
      ),
    );
  }
}

class _CasinoChipPainter extends CustomPainter {
  final Color color;
  final Color edge;
  final double thickness;

  const _CasinoChipPainter({required this.color, required this.edge, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    // L'ombre portée, puis la tranche : le jeton est posé sur le feutre.
    canvas.drawCircle(
      c + Offset(0, thickness * 2),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r / 7),
    );
    canvas.drawCircle(c + Offset(0, thickness), r, Paint()..color = Color.lerp(color, Colors.black, 0.45)!);

    // Le corps, et les inserts de bord : huit rectangles clairs sur la tranche.
    canvas.drawCircle(c, r, Paint()..color = color);
    final rim = Rect.fromCircle(center: c, radius: r);
    final insert = Paint()..color = edge;
    for (var i = 0; i < 8; i++) {
      canvas.drawArc(rim, (i * 45 - 7.5) * math.pi / 180, 15 * math.pi / 180, true, insert);
    }
    canvas.drawCircle(c, r * 0.82, Paint()..color = color);
    canvas.drawCircle(
      c,
      r * 0.82,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, r / 30),
    );

    // Le liseré pointillé, puis le cœur, un peu bombé.
    final dash = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r / 36);
    final ring = Rect.fromCircle(center: c, radius: r * 0.71);
    const dashes = 24;
    for (var i = 0; i < dashes; i++) {
      final start = i * 2 * math.pi / dashes;
      canvas.drawArc(ring, start, math.pi / dashes, false, dash);
    }
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [Color.lerp(color, Colors.white, 0.28)!, color],
          stops: const [0, 0.85],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.62)),
    );
  }

  @override
  bool shouldRepaint(_CasinoChipPainter old) => old.color != color || old.edge != edge || old.thickness != thickness;
}
