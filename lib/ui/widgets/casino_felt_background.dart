import 'package:flutter/material.dart';

/// Fond "table de jeu" façon feutre de casino : dégradé vert profond,
/// vignette et un motif discret de losanges qui évoque le tapis d'une
/// piste de dés, entièrement dessiné (pas d'image embarquée).
class CasinoFeltBackground extends StatelessWidget {
  const CasinoFeltBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(painter: _CasinoFeltPainter()),
      ),
    );
  }
}

class _CasinoFeltPainter extends CustomPainter {
  static const _felt = Color(0xFF0E3B2C);
  static const _feltDark = Color(0xFF071F17);
  static const _line = Color(0x14D9A441); // liseré or, très discret

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.3,
          colors: [_felt, _feltDark],
        ).createShader(rect),
    );

    // Motif de losanges (façon piste de dés) : deux familles de diagonales.
    final linePaint = Paint()
      ..color = _line
      ..strokeWidth = 1;
    const spacing = 46.0;
    final diagonal = size.width + size.height;
    for (var offset = -diagonal; offset < diagonal; offset += spacing) {
      canvas.drawLine(Offset(offset, 0), Offset(offset + size.height, size.height), linePaint);
      canvas.drawLine(Offset(size.width - offset, 0), Offset(size.width - offset - size.height, size.height),
          linePaint);
    }

    // Vignette : assombrit les coins pour donner de la profondeur.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CasinoFeltPainter oldDelegate) => false;
}
