import 'package:flutter/material.dart';

import '../../game/player.dart';

/// Grille de score complète : pour chaque joueur, tous ses tours validés
/// dans l'ordre (du plus ancien au plus récent), avec le tiret d'avertissement
/// ou le barré propre à chaque ligne, et la ligne courante mise en évidence.
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
            for (var i = 0; i < player.grid.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ScoreRow(entry: player.grid[i], isCurrent: i == player.currentIndex),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final ScoreEntry entry;
  final bool isCurrent;

  const _ScoreRow({required this.entry, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = entry.isBarred
        ? colorScheme.errorContainer
        : isCurrent
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest;
    final borderColor = entry.isBarred
        ? colorScheme.error
        : isCurrent
            ? colorScheme.primary
            : colorScheme.outlineVariant;
    final textColor = entry.isBarred ? colorScheme.onErrorContainer : colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '${entry.value}',
            style: TextStyle(
              decoration: entry.isBarred ? TextDecoration.lineThrough : null,
              decorationThickness: 2,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (entry.hasTiret) ...[
            const SizedBox(width: 6),
            Icon(Icons.remove, size: 14, color: entry.isBarred ? colorScheme.onErrorContainer : Colors.orange),
          ],
          if (isCurrent) ...[
            const Spacer(),
            Icon(Icons.play_arrow, size: 16, color: colorScheme.primary),
          ],
        ],
      ),
    );
  }
}
