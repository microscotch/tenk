import 'package:flutter/material.dart';

import '../../game/player.dart';

/// Grille de score complète : pour chaque joueur, tous ses tours validés
/// dans l'ordre, avec le tiret d'avertissement ou le barré propre à chaque
/// ligne (et non plus seulement le score courant).
class ScoreGridScreen extends StatelessWidget {
  final List<Player> players;

  const ScoreGridScreen({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grille des scores')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [for (final p in players) _PlayerGrid(player: p)],
        ),
      ),
    );
  }
}

class _PlayerGrid extends StatelessWidget {
  final Player player;

  const _PlayerGrid({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final entry in player.grid) _ScoreChip(entry: entry)],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final ScoreEntry entry;

  const _ScoreChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: entry.isBarred ? Colors.red.shade50 : Colors.grey.shade100,
        border: Border.all(color: entry.isBarred ? Colors.red.shade300 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${entry.value}',
            style: TextStyle(
              decoration: entry.isBarred ? TextDecoration.lineThrough : null,
              decorationThickness: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (entry.hasTiret) ...[
            const SizedBox(width: 4),
            Icon(Icons.remove, size: 14, color: entry.isBarred ? Colors.red.shade300 : Colors.orange),
          ],
        ],
      ),
    );
  }
}
