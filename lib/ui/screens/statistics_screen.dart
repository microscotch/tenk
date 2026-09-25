import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player_profile.dart';
import '../../game/player_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_statistics.dart';
import '../../state/player_store.dart';
import '../widgets/app_top_bar.dart';
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
      appBar: AppTopBar(title: Text(l10n.statisticsButton)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BorderedSection(
              label: l10n.statsRecordsTitle,
              fillAvailableSpace: false,
              child: played.isEmpty
                  ? Text(l10n.statsNoRecordYet)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _records(context, l10n, played),
                    ),
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
  ///
  /// Les figures reprennent celles de la fiche d'un joueur (voir
  /// `PlayerStatsGroups`), détails compris : le record de chaque valeur de dé
  /// sous les brelans, les carrés et les quintes, celui des petites et des
  /// grandes suites sous les suites.
  List<Widget> _records(BuildContext context, AppLocalizations l10n, List<PlayerProfile> players) {
    /// Le record d'une grandeur, suivi de ses détenteurs. Un record à zéro n'en
    /// a pas : personne ne l'a battu, les nommer tous n'apprendrait rien.
    ({int best, String text}) record(int Function(PlayerStats) value, {String Function(int)? format}) {
      final best = players.map((p) => value(p.stats)).reduce((a, b) => a > b ? a : b);
      final shown = format?.call(best) ?? '$best';
      if (best == 0) return (best: best, text: shown);
      final holders = players.where((p) => value(p.stats) == best).map((p) => p.displayName);
      return (best: best, text: l10n.statsValueWithHolder(shown, holders.join(', ')));
    }

    Widget row(
      String label,
      int Function(PlayerStats) value, {
      String Function(int)? format,
      bool detail = false,
    }) {
      return StatRow(label: label, value: record(value, format: format).text, detail: detail);
    }

    /// Une figure et, dessous, le record de chacune des six valeurs de dé — y
    /// compris celles que personne n'a jamais sorties, comme sur la fiche d'un
    /// joueur.
    Widget faceRow(int face, Map<int, int> Function(PlayerStats) byValue) {
      final r = record((s) => byValue(s)[face] ?? 0);
      return BreakdownRow(value: face, count: r.best, display: r.text);
    }

    /// Une ligne de record dont le détail se déplie (voir [ExpandableStatRow]) :
    /// six lignes par figure, trois figures à la suite, encombraient l'écran.
    Widget expandable(String label, int Function(PlayerStats) value, List<Widget> details) {
      return ExpandableStatRow(label: label, value: record(value).text, children: details);
    }

    Widget figure(
      String label,
      int Function(PlayerStats) total,
      Map<int, int> Function(PlayerStats) byValue,
    ) {
      return expandable(label, total, [
        for (var face = 1; face <= 6; face++) faceRow(face, byValue),
      ]);
    }

    return [
      row(l10n.statsBestTurn, (s) => s.bestBankedTurn),
      row(l10n.statsGamesWon, (s) => s.gamesWon),
      row(l10n.statsHotDiceRun, (s) => s.longestHotDiceRun),
      row(l10n.statsLongestTime, (s) => s.longestActiveSeconds ?? 0, format: formatDuration),
      row(l10n.statsBusts, (s) => s.bustsTotal),
      row(l10n.statsLongestBustStreak, (s) => s.longestBustStreak, detail: true),
      row(l10n.statsBarsInflicted, (s) => s.barsInflictedTotal),
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 2),
        child: Text(l10n.statsSectionFigures, style: Theme.of(context).textTheme.titleSmall),
      ),
      figure(l10n.statsBrelans, (s) => s.brelansTotal, (s) => s.brelans),
      figure(l10n.statsCarres, (s) => s.carresTotal, (s) => s.carres),
      figure(l10n.statsQuintes, (s) => s.quintesTotal, (s) => s.quintes),
      expandable(l10n.statsSuites, (s) => s.suitesTotal, [
        row(l10n.statsSmallSuites, (s) => s.petitesSuites, detail: true),
        row(l10n.statsBigSuites, (s) => s.grandesSuites, detail: true),
      ]),
      row(l10n.statsLoneAces, (s) => s.keptLoneAces),
      row(l10n.statsLoneFives, (s) => s.keptLoneFives),
      expandable(l10n.statsAceQuints, (s) => s.quintesDAsTotal, [
        row(l10n.statsAceQuintsWon, (s) => s.quintesDAsReussies, detail: true),
      ]),
    ];
  }
}
