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
    return PopScope(
      // Cet écran est empilé PAR-DESSUS le GameScreen de la partie qui vient
      // de se terminer (voir le ref.listen dans game_screen.dart) : un pop()
      // nu retomberait sur ce GameScreen — devenu un écran mort, puisqu'une
      // fois `engine.gameOver` vrai il n'affiche plus jamais qu'un indicateur
      // de chargement (voir ce commentaire côté GameScreen). Le retour
      // système ramène donc à l'accueil, seule sortie de cet écran.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        popToHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.gameOverTitle),
          // Aucune sortie dans la barre — et surtout pas la flèche de retour
          // automatique de Flutter, qui ferait précisément le pop() nu que le
          // PopScope ci-dessus existe pour éviter.
          //
          // iOS fait exception : pas de bouton retour système, et le
          // glissement depuis le bord est neutralisé par ce même PopScope
          // (`ModalRoute.popGestureEnabled` est faux dès que la route refuse
          // de se dépiler). Sans cette flèche, cet écran serait sans issue.
          // Elle ramène à l'accueil, comme le retour système ailleurs.
          automaticallyImplyLeading: false,
          leading: Theme.of(context).platform == TargetPlatform.iOS
              ? BackButton(onPressed: () => popToHome(context))
              : null,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
