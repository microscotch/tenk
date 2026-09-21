import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player_profile.dart';
import '../../game/player_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_statistics.dart';
import '../../state/player_store.dart';
import '../widgets/bordered_section.dart';
import '../widgets/player_avatar.dart';
import '../widgets/player_stats_groups.dart';
import '../widgets/stat_row.dart';

/// Consultation des statistiques : les records tous joueurs confondus, puis
/// chaque fiche, dont le détail se déplie sur place.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Remet les statistiques à jour avant de les montrer : c'est le même
    // recalcul complet que celui de l'écran des joueurs, idempotent.
    ref.watch(playerStatisticsSyncProvider);
    final played = (ref.watch(playersProvider).value ?? const <PlayerProfile>[])
        .where((p) => p.stats.gamesPlayed > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsButton)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BorderedSection(
              label: l10n.statsRecordsTitle,
              fillAvailableSpace: false,
              child: played.isEmpty
                  ? Text(l10n.statsNoRecordYet)
                  : Column(children: _records(l10n, played)),
            ),
            // Seuls les joueurs ayant joué : une fiche vierge n'a rien à
            // montrer ici, et la gestion des joueurs reste l'endroit où voir
            // toute la base.
            //
            // Un panneau par joueur, replié, dont le détail se déplie sur
            // place plutôt que dans un écran à part. Replié, il ne prend que
            // sa ligne : le détail complet fait une trentaine de lignes, et
            // les dérouler toutes à la suite noyait les records en tête.
            // Le résumé en sous-titre suffit à comparer sans rien déplier.
            for (final player in played) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                key: PageStorageKey('stats-${player.id}'),
                leading: PlayerAvatarWidget(name: player.name, size: 40),
                title: Text(player.displayName),
                subtitle: Text(l10n.statsPlayerSummary(
                  player.stats.gamesPlayed,
                  player.stats.gamesWon,
                  player.stats.bestBankedTurn,
                )),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                // Tous les groupes : ces chiffres sont cumulés sur toutes les
                // parties du joueur, parties et temps y disent quelque chose.
                children: [PlayerStatsGroups(stats: player.stats)],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Un record par grandeur, avec TOUS ses détenteurs : en cas d'égalité, en
  /// désigner un arbitrairement serait injuste et, surtout, instable d'un
  /// recalcul à l'autre.
  List<Widget> _records(AppLocalizations l10n, List<PlayerProfile> players) {
    Widget row(String label, int Function(PlayerStats) value, {String Function(int)? format}) {
      final best = players.map((p) => value(p.stats)).reduce((a, b) => a > b ? a : b);
      final holders = players.where((p) => value(p.stats) == best).map((p) => p.displayName);
      return StatRow(
        label: label,
        value: l10n.statsValueWithHolder(
          format?.call(best) ?? '$best',
          holders.join(', '),
        ),
      );
    }

    return [
      row(l10n.statsBestTurn, (s) => s.bestBankedTurn),
      row(l10n.statsGamesWon, (s) => s.gamesWon),
      row(l10n.statsHotDiceRun, (s) => s.longestHotDiceRun),
      row(l10n.statsAceQuints, (s) => s.quintesDAsTotal),
      row(l10n.statsSuites, (s) => s.suitesTotal),
      row(l10n.statsLongestTime, (s) => s.longestActiveSeconds ?? 0, format: formatDuration),
      row(l10n.statsLongestBustStreak, (s) => s.longestBustStreak),
      row(l10n.statsBarsInflicted, (s) => s.barsInflictedTotal),
    ];
  }
}
