import 'package:flutter/material.dart';

import '../../game/player.dart' show winningScore;
import '../../l10n/generated/app_localizations.dart';

/// Une courbe : son nom, sa couleur, et le score après chacun de ses tours.
class ScoreSeries {
  final String name;
  final Color color;
  final List<int> scores;

  /// Ce que l'infobulle écrit pour cette courbe (le surnom du joueur, par
  /// exemple) ; [name] quand il n'y en a pas.
  final String? label;

  const ScoreSeries({required this.name, required this.color, required this.scores, this.label});

  String get shownName => label ?? name;
}

/// Courbe des scores, une polyligne par joueur, avec un curseur vertical que
/// l'on déplace du doigt : une infobulle y donne le score de chacun au tour
/// visé.
///
/// Peinte à la main, comme le blason ([PlayerAvatarWidget]), les pips des dés
/// et le tapis : aucune dépendance de graphiques n'entre dans le projet pour
/// une seule vue.
class ScoreChart extends StatefulWidget {
  final List<ScoreSeries> series;

  const ScoreChart({super.key, required this.series});

  /// Le dernier tour de la courbe : l'abscisse au plus long des joueurs,
  /// minorée à 1 pour ne pas diviser par zéro au tout premier tour.
  static int lastTurnOf(List<ScoreSeries> series) =>
      series.fold<int>(1, (m, s) => s.scores.length - 1 > m ? s.scores.length - 1 : m);

  /// Le tour le plus proche de l'abscisse [dx] (dans le repère du widget), pour
  /// un tracé de [lastTurn] tours dans une zone large de [width]. Le curseur
  /// colle toujours à un tour entier : entre deux, il n'y a aucun score à lire.
  static int turnAt(double dx, double width, int lastTurn) {
    final plot = _plotRectFor(Size(width, 100));
    if (plot.width <= 0) return 0;
    return ((dx - plot.left) / plot.width * lastTurn).round().clamp(0, lastTurn);
  }

  @override
  State<ScoreChart> createState() => _ScoreChartState();
}

/// Place réservée à gauche et en bas pour les graduations.
const _leftGutter = 44.0;
const _bottomGutter = 20.0;

Rect _plotRectFor(Size size) =>
    Rect.fromLTRB(_leftGutter, 8, size.width - 8, size.height - _bottomGutter);

class _ScoreChartState extends State<ScoreChart> {
  /// Le tour visé par le curseur ; nul tant que personne n'y a touché, le
  /// curseur est alors au dernier tour (voir [_cursorTurn]) : c'est à la fois
  /// l'état final de la partie et de quoi montrer que le curseur existe.
  int? _turn;

  int get _lastTurn => ScoreChart.lastTurnOf(widget.series);

  int _cursorTurn() => (_turn ?? _lastTurn).clamp(0, _lastTurn);

  void _moveTo(Offset local, double width) =>
      setState(() => _turn = ScoreChart.turnAt(local.dx, width, _lastTurn));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final plot = _plotRectFor(size);
        final lastTurn = _lastTurn;
        final turn = _cursorTurn();
        final cursorX = plot.left + plot.width * (turn / lastTurn);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _moveTo(d.localPosition, size.width),
          onPanUpdate: (d) => _moveTo(d.localPosition, size.width),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScoreChartPainter(
                    series: widget.series,
                    axisColor: scheme.outlineVariant,
                    cursorColor: scheme.onSurface,
                    cursorTurn: turn,
                    labelStyle: labelStyle,
                  ),
                ),
              ),
              if (plot.width > 0 && plot.height > 0)
                _Tooltip(
                  series: widget.series,
                  turn: turn,
                  cursorX: cursorX,
                  plot: plot,
                  width: size.width,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// L'infobulle du curseur : le tour, puis le score de chaque joueur à ce tour.
///
/// Un joueur qui n'a pas joué autant de tours que le curseur en demande (la
/// partie s'est arrêtée avant son tour) n'a pas de score à ce tour : un tiret,
/// pas son dernier score, qui se lirait comme un score de ce tour-là.
class _Tooltip extends StatelessWidget {
  final List<ScoreSeries> series;
  final int turn;
  final double cursorX;
  final Rect plot;
  final double width;

  const _Tooltip({
    required this.series,
    required this.turn,
    required this.cursorX,
    required this.plot,
    required this.width,
  });

  /// Écart entre le curseur et l'infobulle, posée du côté où il y a de la
  /// place : à droite dans la moitié gauche de la zone, à gauche sinon.
  static const _side = 8.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall;
    final onRight = cursorX < plot.center.dx;
    return Positioned(
      top: plot.top + 4,
      left: onRight ? cursorX + _side : null,
      right: onRight ? null : width - cursorX + _side,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.95),
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scoreChartTurn(turn),
                style: small?.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface),
              ),
              const SizedBox(height: 2),
              for (final one in series)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: one.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(one.shownName, style: small?.copyWith(color: scheme.onSurface)),
                    const SizedBox(width: 12),
                    Text(
                      turn < one.scores.length ? '${one.scores[turn]}' : '—',
                      style: small?.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  final List<ScoreSeries> series;
  final Color axisColor;
  final Color cursorColor;
  final int cursorTurn;
  final TextStyle labelStyle;

  const _ScoreChartPainter({
    required this.series,
    required this.axisColor,
    required this.cursorColor,
    required this.cursorTurn,
    required this.labelStyle,
  });

  /// Une ligne de repère tous les 200 points, sans libellé : les graduations
  /// écrites restent celles de [_labelStep].
  static const _minorStep = 200;
  static const _labelStep = 2000;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = _plotRectFor(size);
    if (plot.width <= 0 || plot.height <= 0) return;

    // Ordonnée fixée à la cible : elle ne doit pas dépendre des scores du
    // moment, sans quoi deux parties ne se compareraient pas et la courbe se
    // remettrait à l'échelle à chaque tour.
    final maxTurns = ScoreChart.lastTurnOf(series);

    _paintGrid(canvas, plot, maxTurns);

    for (final one in series) {
      if (one.scores.length < 2) continue;
      final path = Path();
      for (var turn = 0; turn < one.scores.length; turn++) {
        final point = _pointOf(plot, maxTurns, turn, one.scores[turn]);
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

    _paintCursor(canvas, plot, maxTurns);
  }

  Offset _pointOf(Rect plot, int maxTurns, int turn, int score) => Offset(
        plot.left + plot.width * (turn / maxTurns),
        plot.bottom - plot.height * (score / winningScore),
      );

  /// Le curseur : un trait vertical sur le tour visé, et, sur chaque courbe qui
  /// a un score à ce tour, son point grossi.
  void _paintCursor(Canvas canvas, Rect plot, int maxTurns) {
    final x = plot.left + plot.width * (cursorTurn / maxTurns);
    canvas.drawLine(
      Offset(x, plot.top),
      Offset(x, plot.bottom),
      Paint()
        ..color = cursorColor.withValues(alpha: 0.7)
        ..strokeWidth = 1.5,
    );
    for (final one in series) {
      if (cursorTurn >= one.scores.length) continue;
      final point = _pointOf(plot, maxTurns, cursorTurn, one.scores[cursorTurn]);
      canvas.drawCircle(point, 5.5, Paint()..color = cursorColor);
      canvas.drawCircle(point, 4, Paint()..color = one.color);
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
      old.series != series ||
      old.axisColor != axisColor ||
      old.cursorColor != cursorColor ||
      old.cursorTurn != cursorTurn;
}
