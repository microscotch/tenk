import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_save_store.dart';
import 'game_run_tile.dart';
import '../screens/dice_off_screen.dart';

/// Liste des runs terminés (archivés, voir [finishedGamesProvider]) : chaque
/// ligne affiche l'alias et les avatars des joueurs, en lecture seule (pas
/// de suppression). Un tap relance le rejeu spectateur temporisé du run,
/// départage inclus (voir `DiceOffNotifier.startReplay`).
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

  void _replay(BuildContext context, WidgetRef ref) {
    ref.read(diceOffProvider.notifier).startReplay(game);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiceOffScreen(replayMode: true)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _replay(context, ref),
          child: GameRunTile(game: game),
        ),
      ),
    );
  }
}
