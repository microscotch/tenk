import 'package:flutter/material.dart';

import '../../game/player.dart' show winningScore;

/// Une courbe : son nom, sa couleur, et le score après chacun de ses tours.
class ScoreSeries {
  final String name;
  final Color color;
  final List<int> scores;

  const ScoreSeries({required this.name, required this.color, required this.scores});
}

/// Courbe des scores, une polyligne par joueur.
///
/// Peinte à la main, comme le blason ([PlayerAvatarWidget]), les pips des dés
/// et le tapis : aucune dépendance de graphiques n'entre dans le projet pour
/// une seule vue.
class ScoreChart extends StatelessWidget {
  final List<ScoreSeries> series;

  const ScoreChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _ScoreChartPainter(
        series: series,
        axisColor: scheme.outlineVariant,
        labelStyle: Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  final List<ScoreSeries> series;
  final Color axisColor;
  final TextStyle labelStyle;

  const _ScoreChartPainter({
    required this.series,
    required this.axisColor,
    required this.labelStyle,
  });

  /// Place réservée à gauche et en bas pour les graduations.
  static const _leftGutter = 44.0;
  static const _bottomGutter = 20.0;

  /// Une ligne de repère tous les 200 points, sans libellé : les graduations
  /// écrites restent celles de [_labelStep].
  static const _minorStep = 200;
  static const _labelStep = 2000;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_leftGutter, 8, size.width - 8, size.height - _bottomGutter);
    if (plot.width <= 0 || plot.height <= 0) return;

    // Abscisse au plus long des joueurs, minorée à 1 pour ne pas diviser par
    // zéro au tout premier tour. Ordonnée fixée à la cible : elle ne doit pas
    // dépendre des scores du moment, sans quoi deux parties ne se compareraient
    // pas et la courbe se remettrait à l'échelle à chaque tour.
    final maxTurns = series.fold<int>(1, (m, s) => s.scores.length - 1 > m ? s.scores.length - 1 : m);

    _paintGrid(canvas, plot, maxTurns);

    for (final one in series) {
      if (one.scores.length < 2) continue;
      final path = Path();
      for (var turn = 0; turn < one.scores.length; turn++) {
        final point = Offset(
          plot.left + plot.width * (turn / maxTurns),
          plot.bottom - plot.height * (one.scores[turn] / winningScore),
        );
        turn == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
        canvas.drawCircle(point, 2.5, Paint()..color = one.color);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = one.color,
      );
    }
  }

  /// Axes, une graduation écrite tous les 2000 points et, entre elles, un trait
  /// discret tous les 200.
  void _paintGrid(Canvas canvas, Rect plot, int maxTurns) {
    final minor = Paint()
      ..color = axisColor.withValues(alpha: 0.55)
      ..strokeWidth = 0.7;
    final line = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    for (var score = 0; score <= winningScore; score += _minorStep) {
      if (score % _labelStep == 0) continue;
      final y = plot.bottom - plot.height * (score / winningScore);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), minor);
    }
    for (var score = 0; score <= winningScore; score += _labelStep) {
      final y = plot.bottom - plot.height * (score / winningScore);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), line);
      _label(canvas, '$score', Offset(plot.left - 6, y), alignRight: true);
    }

    canvas.drawLine(plot.bottomLeft, plot.bottomRight, line);
    _label(canvas, '0', Offset(plot.left, plot.bottom + 4), alignRight: false, below: true);
    _label(canvas, '$maxTurns', Offset(plot.right, plot.bottom + 4),
        alignRight: true, below: true);
  }

  void _label(Canvas canvas, String text, Offset anchor,
      {required bool alignRight, bool below = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        alignRight ? anchor.dx - painter.width : anchor.dx,
        below ? anchor.dy : anchor.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_ScoreChartPainter old) =>
      old.series != series || old.axisColor != axisColor;
}
