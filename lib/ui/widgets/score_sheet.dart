import 'package:flutter/material.dart';

import '../../game/player.dart';

class ScoreSheet extends StatelessWidget {
  final List<Player> players;
  final int currentPlayerIndex;

  const ScoreSheet({super.key, required this.players, required this.currentPlayerIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < players.length; i++)
          _PlayerRow(
            player: players[i],
            isCurrent: i == currentPlayerIndex,
            gaps: _scoreGaps(players, i),
          ),
      ],
    );
  }
}

/// Écart entre le score d'un joueur et ceux de ses adversaires les plus
/// proches, un cran en dessous et un cran au-dessus (null si personne n'est
/// de ce côté-là).
class _ScoreGaps {
  final int? below;
  final int? above;
  const _ScoreGaps({this.below, this.above});
}

_ScoreGaps _scoreGaps(List<Player> players, int index) {
  final score = players[index].totalScore;
  int? nearestBelow;
  int? nearestAbove;
  for (var i = 0; i < players.length; i++) {
    if (i == index) continue;
    final other = players[i].totalScore;
    if (other < score && (nearestBelow == null || other > nearestBelow)) nearestBelow = other;
    if (other > score && (nearestAbove == null || other < nearestAbove)) nearestAbove = other;
  }
  return _ScoreGaps(
    below: nearestBelow != null ? score - nearestBelow : null,
    above: nearestAbove != null ? nearestAbove - score : null,
  );
}

class _PlayerRow extends StatelessWidget {
  final Player player;
  final bool isCurrent;
  final _ScoreGaps gaps;

  const _PlayerRow({required this.player, required this.isCurrent, required this.gaps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Un écart de 200 (le score minimum d'un tour) signale un risque réel de
    // collision au prochain tour de l'adversaire concerné.
    final dangerBelow = gaps.below == 200;
    final opportunityAbove = gaps.above == 200;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isCurrent ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isCurrent) const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.play_arrow, size: 18),
              ),
              Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (!player.hasEntered)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('(pas entré)', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ),
            ],
          ),
          Row(
            children: [
              if (opportunityAbove)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: 'À 200 points de barrer le joueur juste au-dessus !',
                    child: Icon(Icons.gps_fixed, size: 18, color: Colors.lightGreenAccent),
                  ),
                ),
              if (dangerBelow)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: 'Danger : le joueur juste en dessous n\'est qu\'à 200 points, risque de vous barrer',
                    child: Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
                  ),
                ),
              if (player.hasTiret)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: 'Tiret : un second craque barrera le score',
                    child: Icon(Icons.priority_high, size: 18, color: Colors.orange),
                  ),
                ),
              Text('${player.totalScore}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
