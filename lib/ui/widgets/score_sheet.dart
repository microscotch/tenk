import 'package:flutter/material.dart';

import '../../game/ai/ai_profiles.dart';
import '../../game/player.dart';
import '../../game/turn_state.dart';
import '../../l10n/generated/app_localizations.dart';
import 'player_avatar.dart';

class ScoreSheet extends StatelessWidget {
  final List<Player> players;
  final int currentPlayerIndex;

  /// Tour en cours du joueur courant : sert à calculer sa probabilité de
  /// marquer sur les dés qu'il lui reste en main (null si aucun tour actif,
  /// par ex. écran de choix de main).
  final TurnState? activeTurn;

  /// Appelé avec le joueur concerné quand on clique sur sa ligne (ouvre sa
  /// grille de score complète). Aucune ligne n'est cliquable si null.
  final ValueChanged<Player>? onTapPlayer;

  const ScoreSheet({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    this.activeTurn,
    this.onTapPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < players.length; i++)
          _PlayerRow(
            player: players[i],
            isCurrent: i == currentPlayerIndex,
            gaps: _scoreGaps(players, i),
            turnForProbability: i == currentPlayerIndex ? activeTurn : null,
            onTap: onTapPlayer == null ? null : () => onTapPlayer!(players[i]),
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

/// Couleur de la fraction de probabilité de marquer, du rouge (risqué) au
/// vert (favorable) : 1/5 (20%) sert d'ancrage rouge, 1/2 (50%) d'ancrage
/// vert, la valeur est interpolée (et bornée) entre les deux.
Color _probabilityColor(double p) {
  final t = ((p - 0.2) / (0.5 - 0.2)).clamp(0.0, 1.0);
  return Color.lerp(Colors.redAccent, Colors.lightGreenAccent, t)!;
}

class _PlayerRow extends StatelessWidget {
  final Player player;
  final bool isCurrent;
  final _ScoreGaps gaps;
  final TurnState? turnForProbability;
  final VoidCallback? onTap;

  const _PlayerRow({
    required this.player,
    required this.isCurrent,
    required this.gaps,
    required this.turnForProbability,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // Un écart de 200 (le score minimum d'un tour) signale un risque réel de
    // collision au prochain tour de l'adversaire concerné.
    final dangerBelow = gaps.below == 200;
    final opportunityAbove = gaps.above == 200;
    final previousEntry = player.lastUnbarredEntry;
    final turn = turnForProbability;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isCurrent)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.play_arrow, size: 18),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PlayerAvatarWidget(name: player.name, size: 24),
                    ),
                    Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (!player.hasEntered)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(l10n.notEnteredLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (opportunityAbove)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: l10n.opportunityTooltip,
                          child: const Icon(Icons.gps_fixed, size: 18, color: Colors.lightGreenAccent),
                        ),
                      ),
                    if (dangerBelow)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: l10n.dangerTooltip,
                          child: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
                        ),
                      ),
                    if (player.hasTiret)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: l10n.tiretTooltip,
                          child: const Icon(Icons.priority_high, size: 18, color: Colors.orange),
                        ),
                      ),
                    Text('${player.totalScore}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text(
                      '(${previousEntry?.value ?? 0})',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    ),
                    if (previousEntry?.hasTiret ?? false)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Tooltip(
                          message: l10n.previousScoreHadTiretTooltip,
                          child: Icon(Icons.remove, size: 12, color: Colors.orange.shade300),
                        ),
                      ),
                    if (turn != null) ...[
                      const SizedBox(width: 8),
                      Builder(builder: (context) {
                        final (num, den) = scoreProbabilityFraction(turn.diceToRoll, turn.extendedValues);
                        final p = num / den;
                        return Tooltip(
                          message: l10n.scoreProbabilityTooltip(turn.diceToRoll),
                          child: Text(
                            '$num/$den (${(p * 100).toStringAsFixed(2)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _probabilityColor(p),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
