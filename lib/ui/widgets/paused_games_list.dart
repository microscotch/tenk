import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/game_save_store.dart';
import '../../state/settings_providers.dart';
import '../screens/game_screen.dart';
import 'game_run_tile.dart';

/// Liste des parties en pause (voir [pausedGamesProvider]) : chaque ligne
/// affiche l'alias de la partie et les avatars de ses joueurs, se purge par
/// balayage (avec confirmation si activée dans les réglages), et reprend la
/// partie sur simple tap.
class PausedGamesList extends ConsumerStatefulWidget {
  const PausedGamesList({super.key});

  @override
  ConsumerState<PausedGamesList> createState() => _PausedGamesListState();
}

class _PausedGamesListState extends ConsumerState<PausedGamesList> {
  // Un Dismissible doit disparaître de l'arbre dès la fin de son animation,
  // synchroniquement : attendre la suppression/le rechargement réels (async)
  // avant de le retirer déclenche "A dismissed Dismissible widget is still
  // part of the tree". On le masque donc immédiatement ici, pendant que la
  // persistance (voir [_PausedGameRow._delete]) se termine en arrière-plan.
  final Set<int> _hiddenSeeds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncGames = ref.watch(pausedGamesProvider);

    return asyncGames.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _EmptyMessage(text: l10n.noPausedGamesMessage),
      data: (allGames) {
        final games = allGames.where((g) => !_hiddenSeeds.contains(g.seed)).toList();
        if (games.isEmpty) return _EmptyMessage(text: l10n.noPausedGamesMessage);
        return BoundedGameRunsList(
          children: [
            for (final game in games)
              _PausedGameRow(
                game: game,
                onDismissed: () {
                  // Retire la ligne de l'arbre immédiatement (synchrone) ; la
                  // suppression réelle sur disque et le rechargement de la
                  // liste suivent en arrière-plan sans bloquer le retrait
                  // visuel. Passé par le parent (pas la ligne elle-même) :
                  // son `ref` reste valide même une fois la ligne démontée.
                  setState(() => _hiddenSeeds.add(game.seed));
                  unawaited(_deleteFromStore(game.seed));
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFromStore(int seed) async {
    await ref.read(gameSaveStoreProvider).delete(seed);
    ref.invalidate(pausedGamesProvider);
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

class _PausedGameRow extends ConsumerWidget {
  final SavedGame game;
  final VoidCallback onDismissed;

  const _PausedGameRow({required this.game, required this.onDismissed});

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    if (!ref.read(settingsProvider).confirmBeforeDeleteGame) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteGameConfirmTitle),
        content: Text(l10n.deleteGameConfirmMessage(game.alias)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancelButton)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.deleteButton)),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _resume(BuildContext context, WidgetRef ref) {
    ref.read(gameProvider.notifier).resumeFromSave(game);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(game.seed),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context, ref),
      onDismissed: (_) => onDismissed(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _resume(context, ref),
            child: GameRunTile(game: game),
          ),
        ),
      ),
    );
  }
}
