import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player_profile.dart';
import '../../game/player_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_statistics.dart';
import '../../state/player_store.dart';
import '../widgets/bordered_section.dart';
import '../widgets/player_avatar.dart';
import '../widgets/stat_row.dart';
import 'player_stats_screen.dart';

/// Consultation des statistiques : les records tous joueurs confondus, puis
/// le détail de chaque fiche.
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
            for (final player in played) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: PlayerAvatarWidget(name: player.name, size: 40),
                title: Text(player.displayName),
                subtitle: Text(l10n.playerGamesSummary(player.stats.gamesPlayed)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PlayerStatsScreen(player: player)),
                ),
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
