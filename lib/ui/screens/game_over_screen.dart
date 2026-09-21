import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/player_providers.dart';
import '../navigation.dart';
import 'game_statistics_screen.dart';
import 'score_chart_screen.dart';
import 'score_grid_screen.dart';

class GameOverScreen extends ConsumerWidget {
  final List<Player> players;
  final int winnerIndex;

  const GameOverScreen({
    super.key,
    required this.players,
    required this.winnerIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Le surnom prime sur le nom, ici comme partout où le joueur est nommé.
    // Un siège non rattaché à une fiche — un bot, une partie antérieure à la
    // base — garde le nom sous lequel la partie l'a enregistré.
    final displayNames = ref.watch(displayNamesProvider);
    final sorted = [...players]
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    // La courbe et les statistiques se dérivent du journal de la partie : sans
    // lui (état chargé par `debugLoadState`), il n'y aurait rien à montrer, et
    // les deux boutons ne s'affichent donc pas.
    final hasRecord = ref.read(gameProvider.notifier).gameRecord != null;
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
            // Défilant : avec les boutons de courbe et de statistiques, la
            // colonne dépasse la hauteur d'un petit écran dès quelques joueurs.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    l10n.winnerAnnouncement(displayNameOf(displayNames, players[winnerIndex].name)),
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  for (final p in sorted)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        l10n.playerScoreLine(displayNameOf(displayNames, p.name), p.totalScore),
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
                  if (hasRecord) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ScoreChartScreen()),
                      ),
                      icon: const Icon(Icons.show_chart),
                      label: Text(l10n.scoreChartTitle),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameStatisticsScreen(players: players, winnerIndex: winnerIndex),
                        ),
                      ),
                      icon: const Icon(Icons.bar_chart),
                      label: Text(l10n.gameStatsTitle),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
