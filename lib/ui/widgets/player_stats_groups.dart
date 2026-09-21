import 'package:flutter/material.dart';

import '../../game/player_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import 'stat_row.dart';

/// Les statistiques d'un joueur, en groupes de lignes : parties, temps,
/// figures, divers.
///
/// Partagé entre la fiche d'un joueur (toutes ses parties cumulées) et le
/// bilan d'une seule partie, qui n'en garde que les figures et le divers : sur
/// une partie unique, « parties jouées » vaut toujours 1 et le temps est le
/// même pour tous, ces groupes n'y diraient rien et se lisent une seule fois
/// en tête de l'écran (voir `GameStatisticsScreen`). Les figures y sont
/// détaillées par valeur de dé dans les deux cas.
class PlayerStatsGroups extends StatelessWidget {
  final PlayerStats stats;

  /// Les groupes « parties » et « temps », qui n'ont de sens qu'à l'échelle de
  /// plusieurs parties.
  final bool includeGamesAndTime;

  /// Le groupe des faits d'armes (meilleur tour, craquages, barrés) : propre à
  /// un joueur, il ne s'additionne pas à l'échelle d'une table.
  final bool includeMisc;

  /// Le groupe « tours et lancers ». À écarter quand ces lignes vivent déjà
  /// ailleurs sur l'écran, comme dans le cadre « Partie » des statistiques
  /// d'une partie.
  final bool includeRolls;

  /// Le titre de chaque groupe. À retirer quand le widget est déjà logé dans un
  /// cadre qui le porte, sous peine de le dire deux fois.
  final bool showTitles;

  const PlayerStatsGroups({
    super.key,
    required this.stats,
    this.includeGamesAndTime = true,
    this.includeMisc = true,
    this.includeRolls = true,
    this.showTitles = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = stats;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeGamesAndTime) ...[
          _group(context, l10n.statsSectionGames, [
            StatRow(label: l10n.statsGamesPlayed, value: '${s.gamesPlayed}'),
            StatRow(label: l10n.statsGamesWon, value: '${s.gamesWon}'),
            StatRow(label: l10n.statsGamesLost, value: '${s.gamesLost}'),
          ]),
          _group(context, l10n.statsSectionTime, [
            StatRow(label: l10n.statsTotalTime, value: formatDuration(s.totalActiveSeconds)),
            StatRow(
              label: l10n.statsAverageTime,
              value: formatDuration(s.averageActiveSeconds?.round()),
            ),
            StatRow(label: l10n.statsShortestTime, value: formatDuration(s.shortestActiveSeconds)),
            StatRow(label: l10n.statsLongestTime, value: formatDuration(s.longestActiveSeconds)),
          ]),
        ],
        if (includeRolls)
          _group(context, l10n.statsSectionRolls, [
            StatRow(label: l10n.statsTurns, value: '${s.turnsTotal}'),
            StatRow(label: l10n.statsRolls, value: '${s.rollsTotal}'),
            StatRow(
              label: l10n.statsRollsPerTurn,
              value: formatAverage(s.averageRollsPerTurn, Localizations.localeOf(context).toString()),
            ),
          ]),
        _group(context, l10n.statsSectionFigures, [
          _figureRow(context, l10n.statsBrelans, s.brelansTotal, s.brelans),
          _figureRow(context, l10n.statsCarres, s.carresTotal, s.carres),
          _figureRow(context, l10n.statsQuintes, s.quintesTotal, s.quintes),
          // Le détail de chaque figure se déplie : replié, les figures tiennent
          // sur une ligne chacune. Chaque part est suivie de son pourcentage du
          // total de la figure.
          ExpandableStatRow(
            label: l10n.statsSuites,
            value: '${s.suitesTotal}',
            children: [
              StatRow(
                label: l10n.statsSmallSuites,
                value: withShare(s.petitesSuites, s.suitesTotal, locale),
                detail: true,
              ),
              StatRow(
                label: l10n.statsBigSuites,
                value: withShare(s.grandesSuites, s.suitesTotal, locale),
                detail: true,
              ),
            ],
          ),
          StatRow(label: l10n.statsLoneAces, value: '${s.keptLoneAces}'),
          StatRow(label: l10n.statsLoneFives, value: '${s.keptLoneFives}'),
          ExpandableStatRow(
            label: l10n.statsAceQuints,
            value: '${s.quintesDAsTotal}',
            children: [
              StatRow(
                label: l10n.statsAceQuintsWon,
                value: withShare(s.quintesDAsReussies, s.quintesDAsTotal, locale),
                detail: true,
              ),
            ],
          ),
        ]),
        if (includeMisc)
          _group(context, l10n.statsSectionMisc, [
            StatRow(label: l10n.statsBestTurn, value: '${s.bestBankedTurn}'),
            StatRow(label: l10n.statsHotDiceRun, value: '${s.longestHotDiceRun}'),
            StatRow(label: l10n.statsBusts, value: '${s.bustsTotal}'),
            StatRow(label: l10n.statsLongestBustStreak, value: '${s.longestBustStreak}', detail: true),
            StatRow(label: l10n.statsSelfBars, value: '${s.selfBarsTotal}'),
            StatRow(label: l10n.statsBarsInflicted, value: '${s.barsInflictedTotal}'),
          ]),
      ],
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitles) Text(title, style: Theme.of(context).textTheme.titleSmall),
          ...rows,
        ],
      ),
    );
  }

  /// Le total, qui se déplie sur une ligne par valeur de dé — les SIX, y compris
  /// celles jamais sorties : un tableau à trous se lit plus mal qu'un tableau
  /// complet, où l'œil retrouve toujours la même ligne au même endroit. Chaque
  /// compte est suivi de sa part du total de la figure.
  Widget _figureRow(BuildContext context, String label, int total, Map<int, int> byValue) {
    return ExpandableStatRow(
      label: label,
      value: '$total',
      children: [
        for (var value = 1; value <= 6; value++)
          BreakdownRow(value: value, count: byValue[value] ?? 0, total: total),
      ],
    );
  }
}
