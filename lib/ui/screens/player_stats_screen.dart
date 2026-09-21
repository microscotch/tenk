import 'package:flutter/material.dart';

import '../../game/player_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/bordered_section.dart';
import '../widgets/player_avatar.dart';
import '../widgets/player_stats_groups.dart';

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
        PlayerStatsGroups(stats: s),
      ],
    );
  }
}
