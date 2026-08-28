import 'package:flutter/material.dart';

import '../../game/player.dart';

class GameOverScreen extends StatelessWidget {
  final List<Player> players;
  final int winnerIndex;

  const GameOverScreen({super.key, required this.players, required this.winnerIndex});

  @override
  Widget build(BuildContext context) {
    final sorted = [...players]..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return Scaffold(
      appBar: AppBar(title: const Text('Fin de la partie')),
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
                  '${players[winnerIndex].name} gagne !',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                for (final p in sorted)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${p.name} : ${p.totalScore}', style: Theme.of(context).textTheme.titleMedium),
                  ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Nouvelle partie'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
