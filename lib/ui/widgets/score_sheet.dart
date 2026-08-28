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
          _PlayerRow(player: players[i], isCurrent: i == currentPlayerIndex),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Player player;
  final bool isCurrent;

  const _PlayerRow({required this.player, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('(pas entré)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
            ],
          ),
          Row(
            children: [
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
