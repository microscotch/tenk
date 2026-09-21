import 'package:flutter/material.dart';

import '../../game/player_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/bordered_section.dart';
import '../widgets/player_avatar.dart';
import '../widgets/stat_row.dart';

/// Le détail des statistiques d'un joueur.
///
/// Sorti de l'écran Statistiques, qui déroulait le détail de chacun à la
/// suite : à quelques joueurs, l'écran devenait interminable et les records,
/// pourtant en tête, se perdaient dans le défilement.
class PlayerStatsScreen extends StatelessWidget {
  final PlayerProfile player;

  const PlayerStatsScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(player.displayName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BorderedSection(
              label: player.displayName,
              fillAvailableSpace: false,
              child: _PlayerStatsBody(player: player),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatsBody extends StatelessWidget {
  final PlayerProfile player;

  const _PlayerStatsBody({required this.player});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = player.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PlayerAvatarWidget(name: player.name, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.playerGamesSummary(s.gamesPlayed))),
          ],
        ),
        const SizedBox(height: 12),
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
        _group(context, l10n.statsSectionFigures, [
          ..._figureRows(l10n, l10n.statsBrelans, s.brelansTotal, s.brelans),
          ..._figureRows(l10n, l10n.statsCarres, s.carresTotal, s.carres),
          ..._figureRows(l10n, l10n.statsQuintes, s.quintesTotal, s.quintes),
          StatRow(label: l10n.statsSuites, value: '${s.suitesTotal}'),
          StatRow(label: l10n.statsSmallSuites, value: '${s.petitesSuites}'),
          StatRow(label: l10n.statsBigSuites, value: '${s.grandesSuites}'),
          StatRow(label: l10n.statsLoneAces, value: '${s.keptLoneAces}'),
          StatRow(label: l10n.statsLoneFives, value: '${s.keptLoneFives}'),
          StatRow(label: l10n.statsAceQuints, value: '${s.quintesDAsTotal}'),
          StatRow(label: l10n.statsAceQuintsWon, value: '${s.quintesDAsReussies}'),
        ]),
        _group(context, l10n.statsSectionMisc, [
          StatRow(label: l10n.statsBestTurn, value: '${s.bestBankedTurn}'),
          StatRow(label: l10n.statsHotDiceRun, value: '${s.longestHotDiceRun}'),
          StatRow(label: l10n.statsBusts, value: '${s.bustsTotal}'),
          StatRow(label: l10n.statsLongestBustStreak, value: '${s.longestBustStreak}'),
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
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          ...rows,
        ],
      ),
    );
  }

  /// Le total, puis une ligne par valeur de dé — les SIX, y compris celles
  /// jamais sorties : un tableau à trous se lit plus mal qu'un tableau complet,
  /// où l'œil retrouve toujours la même ligne au même endroit.
  List<Widget> _figureRows(AppLocalizations l10n, String label, int total, Map<int, int> byValue) {
    return [
      StatRow(label: label, value: '$total'),
      for (var value = 1; value <= 6; value++)
        BreakdownRow(value: value, count: byValue[value] ?? 0),
    ];
  }
}
