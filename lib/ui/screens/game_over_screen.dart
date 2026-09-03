import 'package:flutter/material.dart';

import '../../game/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../navigation.dart';
import 'score_grid_screen.dart';

class GameOverScreen extends StatelessWidget {
  final List<Player> players;
  final int winnerIndex;

  const GameOverScreen({
    super.key,
    required this.players,
    required this.winnerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = [...players]
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameOverTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: l10n.scoreGridLabel,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ScoreGridScreen(players: players),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  l10n.winnerAnnouncement(players[winnerIndex].name),
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                for (final p in sorted)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      l10n.playerScoreLine(p.name, p.totalScore),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScoreGridScreen(players: players),
                    ),
                  ),
                  icon: const Icon(Icons.grid_on),
                  label: Text(l10n.scoreGridLabel),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => popToHome(context),
                  child: Text(l10n.okButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
