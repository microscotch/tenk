import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player_profile.dart';
import '../../game/player_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_statistics.dart';
import '../../state/player_store.dart';
import '../widgets/bordered_section.dart';
import '../widgets/player_avatar.dart';

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
    final players = ref.watch(playersProvider).value ?? const <PlayerProfile>[];
    final played = players.where((p) => p.stats.gamesPlayed > 0).toList();

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
            for (final player in players) ...[
              const SizedBox(height: 24),
              BorderedSection(
                label: player.displayName,
                fillAvailableSpace: false,
                child: _PlayerStatsBody(player: player),
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
      return _StatRow(
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
          _StatRow(label: l10n.statsGamesPlayed, value: '${s.gamesPlayed}'),
          _StatRow(label: l10n.statsGamesWon, value: '${s.gamesWon}'),
          _StatRow(label: l10n.statsGamesLost, value: '${s.gamesLost}'),
        ]),
        _group(context, l10n.statsSectionTime, [
          _StatRow(label: l10n.statsTotalTime, value: formatDuration(s.totalActiveSeconds)),
          _StatRow(
            label: l10n.statsAverageTime,
            value: formatDuration(s.averageActiveSeconds?.round()),
          ),
          _StatRow(label: l10n.statsShortestTime, value: formatDuration(s.shortestActiveSeconds)),
          _StatRow(label: l10n.statsLongestTime, value: formatDuration(s.longestActiveSeconds)),
        ]),
        _group(context, l10n.statsSectionFigures, [
          _StatRow(label: l10n.statsBrelans, value: _withBreakdown(s.brelansTotal, s.brelans)),
          _StatRow(label: l10n.statsCarres, value: _withBreakdown(s.carresTotal, s.carres)),
          _StatRow(label: l10n.statsQuintes, value: _withBreakdown(s.quintesTotal, s.quintes)),
          _StatRow(label: l10n.statsSuites, value: '${s.suitesTotal}'),
          _StatRow(label: l10n.statsSmallSuites, value: '${s.petitesSuites}'),
          _StatRow(label: l10n.statsBigSuites, value: '${s.grandesSuites}'),
          _StatRow(label: l10n.statsLoneAces, value: '${s.keptLoneAces}'),
          _StatRow(label: l10n.statsLoneFives, value: '${s.keptLoneFives}'),
          _StatRow(label: l10n.statsAceQuints, value: '${s.quintesDAsTotal}'),
          _StatRow(label: l10n.statsAceQuintsWon, value: '${s.quintesDAsReussies}'),
        ]),
        _group(context, l10n.statsSectionMisc, [
          _StatRow(label: l10n.statsBestTurn, value: '${s.bestBankedTurn}'),
          _StatRow(label: l10n.statsHotDiceRun, value: '${s.longestHotDiceRun}'),
          _StatRow(label: l10n.statsBusts, value: '${s.bustsTotal}'),
          _StatRow(label: l10n.statsLongestBustStreak, value: '${s.longestBustStreak}'),
          _StatRow(label: l10n.statsSelfBars, value: '${s.selfBarsTotal}'),
          _StatRow(label: l10n.statsBarsInflicted, value: '${s.barsInflictedTotal}'),
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

  /// « 7 (4×3, 2×1) » : le total, puis le détail par valeur de dé, les valeurs
  /// jamais sorties étant omises plutôt qu'affichées à zéro.
  String _withBreakdown(int total, Map<int, int> byValue) {
    if (byValue.isEmpty) return '$total';
    final parts = byValue.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return '$total (${parts.map((e) => '${e.key}×${e.value}').join(', ')})';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text(value),
        ],
      ),
    );
  }
}

/// Durée lisible : « 1 h 05 », « 12 min », « 45 s ». `null` (aucune partie)
/// s'affiche en tiret plutôt qu'en zéro, qui se lirait « instantané ».
String formatDuration(int? seconds) {
  if (seconds == null) return '—';
  if (seconds < 60) return '$seconds s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
}
