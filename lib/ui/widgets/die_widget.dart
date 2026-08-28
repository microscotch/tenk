import 'package:flutter/material.dart';

enum DieVisualState { junk, kept, declinable, declined }

class DieWidget extends StatelessWidget {
  final int value;
  final DieVisualState state;
  final VoidCallback? onTap;

  const DieWidget({super.key, required this.value, required this.state, this.onTap});

  Color get _borderColor => switch (state) {
        DieVisualState.kept => Colors.green.shade600,
        DieVisualState.junk => Colors.blueGrey.shade200,
        DieVisualState.declinable => Colors.amber.shade700,
        DieVisualState.declined => Colors.orange.shade800,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: state == DieVisualState.declined ? Colors.orange.shade50 : Colors.white,
          border: Border.all(color: _borderColor, width: 3),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
        ),
        child: CustomPaint(painter: _PipsPainter(value, _borderColor), size: Size.infinite),
      ),
    );
  }
}

const Map<int, List<Offset>> _pipPositions = {
  1: [Offset(0.5, 0.5)],
  2: [Offset(0.25, 0.25), Offset(0.75, 0.75)],
  3: [Offset(0.25, 0.25), Offset(0.5, 0.5), Offset(0.75, 0.75)],
  4: [Offset(0.25, 0.25), Offset(0.75, 0.25), Offset(0.25, 0.75), Offset(0.75, 0.75)],
  5: [
    Offset(0.25, 0.25),
    Offset(0.75, 0.25),
    Offset(0.5, 0.5),
    Offset(0.25, 0.75),
    Offset(0.75, 0.75),
  ],
  6: [
    Offset(0.25, 0.2),
    Offset(0.75, 0.2),
    Offset(0.25, 0.5),
    Offset(0.75, 0.5),
    Offset(0.25, 0.8),
    Offset(0.75, 0.8),
  ],
};

class _PipsPainter extends CustomPainter {
  final int value;
  final Color color;
  const _PipsPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final p in _pipPositions[value] ?? const []) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), size.width * 0.09, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PipsPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
