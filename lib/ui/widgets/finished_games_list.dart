import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_engine.dart';
import '../../game/game_recording.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_save_store.dart';
import '../navigation.dart';
import '../screens/game_over_screen.dart';
import 'game_run_tile.dart';

/// Liste des runs terminés (archivés, voir [finishedGamesProvider]) : chaque
/// ligne affiche l'alias et les avatars des joueurs, en lecture seule (pas
/// de suppression). Un tap ouvre l'écran de fin de la partie — son classement,
/// sa courbe, ses statistiques — d'où le rejeu se lance à son tour.
class FinishedGamesList extends ConsumerWidget {
  const FinishedGamesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncGames = ref.watch(finishedGamesProvider);

    return asyncGames.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _EmptyMessage(text: l10n.noFinishedRunsMessage),
      data: (games) {
        if (games.isEmpty) return _EmptyMessage(text: l10n.noFinishedRunsMessage);
        return BoundedGameRunsList(
          children: [for (final game in games) _FinishedGameRow(game: game)],
        );
      },
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: TextStyle(color: Colors.grey.shade400)));
  }
}

class _FinishedGameRow extends ConsumerWidget {
  final SavedGame game;
  const _FinishedGameRow({required this.game});

  /// Ouvre l'écran de fin de cette partie. Le classement final n'est pas
  /// stocké : on le relit en rejouant le journal, comme le font les statistiques.
  ///
  /// Un journal incohérent, ou une partie qui ne va pas jusqu'à sa fin, n'a pas
  /// de classement à montrer : on revient alors à l'ancien geste, le rejeu
  /// direct — même tolérance que `syncPlayerStatistics` envers un run illisible.
  void _open(BuildContext context, WidgetRef ref) {
    GameEngine? engine;
    try {
      engine = replayGame(game.setup, game.seed, game.actions).engine;
    } catch (_) {
      engine = null;
    }
    if (engine == null || !engine.gameOver || engine.winnerIndex == null) {
      if (!openReplay(context, ref, game)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).replayUnavailable)),
        );
      }
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(
          players: engine!.players,
          winnerIndex: engine.winnerIndex!,
          record: game,
          archived: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _open(context, ref),
          child: GameRunTile(game: game),
        ),
      ),
    );
  }
}
