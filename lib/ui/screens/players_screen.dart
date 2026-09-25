import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_statistics.dart';
import '../../state/player_store.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/game_run_tile.dart' show BoundedGameRunsList;
import '../widgets/player_avatar.dart';
import 'player_edit_screen.dart';

/// La base des joueurs humains : lister, créer, modifier, supprimer.
class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  /// Un Dismissible doit quitter l'arbre dès la fin de son animation, de façon
  /// synchrone : attendre la suppression réelle déclencherait « A dismissed
  /// Dismissible widget is still part of the tree ». Même parade que dans
  /// [PausedGamesList].
  final Set<String> _hidden = {};

  Future<void> _openEditor([PlayerProfile? existing]) async {
    await Navigator.of(context).push<PlayerProfile>(
      MaterialPageRoute(builder: (_) => PlayerEditScreen(existing: existing)),
    );
    if (mounted) ref.invalidate(playersProvider);
  }

  Future<bool> _confirmDelete(PlayerProfile player) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deletePlayerConfirmTitle),
        content: Text(l10n.deletePlayerConfirmMessage(player.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(PlayerProfile player) async {
    setState(() => _hidden.add(player.id));
    await ref.read(playerStoreProvider).delete(player.id);
    if (mounted) ref.invalidate(playersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Amorce la base depuis les parties archivées et remet les statistiques à
    // jour, une fois par session (Riverpod garde le résultat). C'est ici que
    // ça se déclenche parce que c'est le premier écran qui montre des fiches.
    ref.watch(playerStatisticsSyncProvider);
    final players =
        (ref.watch(playersProvider).value ?? const <PlayerProfile>[])
            .where((p) => !_hidden.contains(p.id))
            .toList();

    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.playersScreenTitle(players.length))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: l10n.addPlayerTooltip,
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: players.isEmpty
              ? Center(child: Text(l10n.noPlayersMessage, textAlign: TextAlign.center))
              : BoundedGameRunsList(
                  children: [
                    for (final player in players)
                      Dismissible(
                        key: ValueKey(player.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: Theme.of(context).colorScheme.error,
                          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                        ),
                        confirmDismiss: (_) => _confirmDelete(player),
                        onDismissed: (_) => _delete(player),
                        child: ListTile(
                          leading: PlayerAvatarWidget(name: player.name, size: 40),
                          title: Text(player.displayName),
                          subtitle: Text(l10n.playerGamesSummary(player.stats.gamesPlayed)),
                          onTap: () => _openEditor(player),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
