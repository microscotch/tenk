import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

/// Le même feutre, mais dessiné comme s'il était fixé à l'écran : posé derrière
/// une page qui glisse (voir `FeltTileSlidePageTransitionsBuilder`), il la rend
/// opaque — la page qui part ne se voit pas à travers celle qui arrive — sans
/// que son éclairage (dégradé, vignette) ni ses losanges ne bougent avec elle.
/// Sans cela, les bords assombris de la vignette balayaient l'écran à chaque
/// transition, et le fond paraissait terne le temps du passage.
///
/// À placer dans un `Stack`, comme [CasinoFeltBackground]. [motion] : ce qui
/// fait bouger la page (les deux animations de sa transition). Le moteur ne
/// redessine pas une page qui glisse, il déplace son image : le feutre se
/// redessine donc lui-même à chaque pas de [motion], à sa nouvelle place.
class ScreenFixedFeltBackground extends StatelessWidget {
  final Listenable motion;

  const ScreenFixedFeltBackground({super.key, required this.motion});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(child: _ScreenFixedFelt(screen: MediaQuery.sizeOf(context), motion: motion)),
    );
  }
}

class _ScreenFixedFelt extends LeafRenderObjectWidget {
  final Size screen;
  final Listenable motion;

  const _ScreenFixedFelt({required this.screen, required this.motion});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderScreenFixedFelt(screen, motion);

  @override
  void updateRenderObject(BuildContext context, _RenderScreenFixedFelt renderObject) {
    renderObject
      ..screen = screen
      ..motion = motion;
  }
}

class _RenderScreenFixedFelt extends RenderBox {
  _RenderScreenFixedFelt(this._screen, this._motion);

  Size _screen;
  set screen(Size value) {
    if (value == _screen) return;
    _screen = value;
    markNeedsPaint();
  }

  Listenable _motion;
  set motion(Listenable value) {
    if (identical(value, _motion)) return;
    if (attached) _motion.removeListener(markNeedsPaint);
    _motion = value;
    if (attached) _motion.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _motion.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _motion.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final origin = localToGlobal(Offset.zero);
    canvas.save();
    canvas.clipRect(offset & size);
    canvas.translate(offset.dx - origin.dx, offset.dy - origin.dy);
    _paintFelt(canvas, _screen);
    canvas.restore();
  }
}

class _CasinoFeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => _paintFelt(canvas, size);

  @override
  bool shouldRepaint(covariant _CasinoFeltPainter oldDelegate) => false;
}

const _felt = Color(0xFF0E3B2C);
const _feltDark = Color(0xFF071F17);
const _line = Color(0x14D9A441); // liseré or, très discret

/// Le feutre sur [size] : dégradé, losanges, vignette.
void _paintFelt(Canvas canvas, Size size) {
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
    canvas.drawLine(Offset(size.width - offset, 0), Offset(size.width - offset - size.height, size.height), linePaint);
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
