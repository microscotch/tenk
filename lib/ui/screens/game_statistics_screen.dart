import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_statistics.dart';
import '../../game/player.dart';
import '../../game/player_stats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_save_store.dart';
import '../../state/player_providers.dart';
import '../widgets/bordered_section.dart';
import '../widgets/player_avatar.dart';
import '../widgets/player_stats_groups.dart';
import '../widgets/stat_row.dart';

/// Le bilan d'UNE partie terminée : ce qui vaut pour toute la table, puis, pour
/// chaque joueur, ses tours, ses figures et ses faits d'armes.
///
/// Rien n'est stocké : tout se dérive du journal de la partie en la rejouant
/// (voir [collectGameStatistics]), comme les statistiques cumulées des fiches
/// dont il partage les lignes (voir [PlayerStatsGroups]).
class GameStatisticsScreen extends ConsumerStatefulWidget {
  /// Les joueurs dans l'ordre du MOTEUR, grilles finales comprises — celui de
  /// `GameEngine.players`.
  final List<Player> players;
  final int winnerIndex;

  /// Le journal de la partie bilanée. Passé explicitement plutôt que lu dans le
  /// notifier de partie : un run archivé ouvert depuis la liste n'y est pas.
  final SavedGame record;

  const GameStatisticsScreen({
    super.key,
    required this.players,
    required this.winnerIndex,
    required this.record,
  });

  @override
  ConsumerState<GameStatisticsScreen> createState() => _GameStatisticsScreenState();
}

class _GameStatisticsScreenState extends ConsumerState<GameStatisticsScreen> {
  /// Statistiques par NOM de joueur, et non par siège : `collectGameStatistics`
  /// rend l'ordre de la config d'origine, `widget.players` celui du moteur, deux
  /// ordres que seul le nom permet de rapprocher sans se tromper.
  late final Map<String, PlayerStats> _statsByName;
  late final int _activeSeconds;

  /// Les compteurs de toute la table, cumulés. Sert aux figures, aux lancers et
  /// aux tours ; les autres champs s'y additionnent ou s'y maximisent sans rien
  /// dire d'une table (voir `PlayerStats.operator +`).
  late final PlayerStats _tableStats;

  @override
  void initState() {
    super.initState();
    // Calculé une fois, ici : c'est un rejeu complet de la partie, qui n'a pas
    // à être refait à chaque reconstruction de l'écran.
    final record = widget.record;
    final stats = collectGameStatistics(setup: record.setup, seed: record.seed, actions: record.actions);

    _activeSeconds = stats.activeSeconds;
    _tableStats = stats.bySeat.fold(PlayerStats.empty, (total, seat) => total + seat);
    _statsByName = {
      for (var i = 0; i < record.setup.playerNames.length; i++) record.setup.playerNames[i]: stats.bySeat[i],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final displayNames = ref.watch(displayNamesProvider);
    final colors = assignAvatarColors(widget.players.map((p) => p.name));
    final winnerName = widget.players[widget.winnerIndex].name;
    final ranking = [...widget.players]..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameStatsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BorderedSection(
              label: l10n.gameStatsGameSection,
              fillAvailableSpace: false,
              child: Column(
                children: [
                  StatRow(label: l10n.gameStatsDuration, value: formatDuration(_activeSeconds)),
                  StatRow(label: l10n.statsTurns, value: '${_tableStats.turnsTotal}'),
                  StatRow(label: l10n.statsRolls, value: '${_tableStats.rollsTotal}'),
                  StatRow(
                    label: l10n.statsRollsPerTurn,
                    value: formatAverage(_tableStats.averageRollsPerTurn, locale),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Les figures sorties pendant la partie, toujours visibles : sans
            // ventilation par valeur de dé, réservée au détail d'un joueur,
            // pour ne pas repousser les joueurs hors de l'écran.
            BorderedSection(
              label: l10n.gameStatsFiguresSection,
              fillAvailableSpace: false,
              child: PlayerStatsGroups(
                stats: _tableStats,
                includeGamesAndTime: false,
                includeMisc: false,
                includeRolls: false,
                showBreakdown: false,
                showTitles: false,
              ),
            ),
            const SizedBox(height: 8),
            // Un panneau par joueur, replié : le détail complet fait une
            // trentaine de lignes, et les empiler à la suite donnait un écran
            // interminable dès quelques joueurs. Le résumé en sous-titre suffit
            // à comparer sans rien déplier.
            for (final player in ranking)
              Builder(builder: (context) {
                final stats = _statsByName[player.name] ?? PlayerStats.empty;
                return ExpansionTile(
                  key: PageStorageKey('game-stats-${player.name}'),
                  leading: PlayerAvatarWidget(name: player.name, size: 40, color: colors[player.name]),
                  title: Row(
                    children: [
                      Flexible(child: Text(displayNameOf(displayNames, player.name), overflow: TextOverflow.ellipsis)),
                      if (player.name == winnerName) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.emoji_events, size: 18, color: Colors.amber),
                      ],
                    ],
                  ),
                  subtitle: Text(l10n.gameStatsPlayerSummary(
                    stats.turnsTotal,
                    stats.bestBankedTurn,
                    stats.bustsTotal,
                  )),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  children: [PlayerStatsGroups(stats: stats, includeGamesAndTime: false)],
                );
              }),
          ],
        ),
      ),
    );
  }
}
