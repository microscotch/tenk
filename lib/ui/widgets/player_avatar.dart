import 'package:flutter/material.dart';

import '../../game/avatar_initials.dart';

/// Palette de fonds de blason : des teintes assez saturées/sombres pour que
/// les initiales blanches en police gothique restent lisibles sur toutes.
const List<Color> kAvatarColorPalette = [
  Color(0xFFB5443B), // brique
  Color(0xFF3B6EA5), // bleu profond
  Color(0xFF4A8B5C), // vert forêt
  Color(0xFFB08A2E), // ambre
  Color(0xFF7A4FA0), // violet
  Color(0xFF4E5D6C), // ardoise
];

/// Couleur de fond du blason d'un joueur : déterministe à partir de son nom
/// (même joueur = même couleur d'un affichage à l'autre, sans état à gérer).
Color avatarColorFor(String name) {
  final hash = name.codeUnits.fold<int>(0, (acc, c) => acc + c);
  return kAvatarColorPalette[hash % kAvatarColorPalette.length];
}

/// Avatar d'un joueur : un blason (écusson) portant ses 2 initiales en
/// police gothique, sur un fond de couleur déterministe propre à son nom.
class PlayerAvatarWidget extends StatelessWidget {
  final String name;
  final double size;

  const PlayerAvatarWidget({super.key, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final initials = avatarInitialsFor(name);
    final color = avatarColorFor(name);
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: CustomPaint(
        painter: _ShieldPainter(color),
        child: Padding(
          padding: EdgeInsets.only(bottom: size * 0.12),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'UnifrakturMaguntia',
                fontSize: size * 0.52,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color fill;
  const _ShieldPainter(this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shieldPath(size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035,
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) => oldDelegate.fill != fill;
}

/// Silhouette d'écusson héraldique : sommet plat à coins arrondis, côtés qui
/// se resserrent en une pointe basse centrée.
Path _shieldPath(Size size) {
  final w = size.width;
  final h = size.height;
  final inset = w * 0.04;
  final r = w * 0.14;

  return Path()
    ..moveTo(inset + r, 0)
    ..lineTo(w - inset - r, 0)
    ..quadraticBezierTo(w - inset, 0, w - inset, r)
    ..cubicTo(w - inset, h * 0.55, w * 0.82, h * 0.85, w * 0.5, h)
    ..cubicTo(w * 0.18, h * 0.85, inset, h * 0.55, inset, r)
    ..quadraticBezierTo(inset, 0, inset + r, 0)
    ..close();
}
