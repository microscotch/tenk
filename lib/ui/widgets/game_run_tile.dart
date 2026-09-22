import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_save_store.dart';
import '../../state/player_providers.dart';

/// Contenu visuel commun à une ligne de run, sur deux lignes — partagé entre
/// la liste des runs interrompus (dans un `Dismissible`) et celle des runs
/// terminés (lecture seule) :
/// - 1re ligne : nom de la partie (alias) à gauche, date à droite ;
/// - 2e ligne, dans une police plus petite : les participants au format
///   « surnom1 vs surnom2 » à gauche, heure à droite.
///
/// Les surnoms viennent de la config de CETTE partie (voir
/// [watchDisplayNames]) : une fiche renommée depuis, ou un joueur du même nom
/// dans une autre partie, ne changent rien à ce qui s'affiche ici.
class GameRunTile extends ConsumerWidget {
  final SavedGame game;

  const GameRunTile({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final displayNames = watchDisplayNames(ref, game);
    final participants = [
      for (final name in game.setup.playerNames) displayNameOf(displayNames, name),
    ];
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale).format(game.createdAt);
    final time = DateFormat.Hm(locale).format(game.createdAt);
    const muted = Colors.grey;

    Widget row(Widget left, String right, TextStyle? rightStyle) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          Text(right, style: rightStyle),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            Text(
              game.alias,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            date,
            theme.textTheme.bodySmall?.copyWith(color: muted.shade400),
          ),
          const SizedBox(height: 2),
          row(
            Text(
              participants.join(l10n.gameRunParticipantsSeparator),
              style: theme.textTheme.labelSmall?.copyWith(color: muted.shade400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            time,
            theme.textTheme.labelSmall?.copyWith(color: muted.shade400),
          ),
        ],
      ),
    );
  }
}

/// Enveloppe une liste de runs pour qu'elle occupe toute la hauteur allouée
/// par son parent (typiquement l'`Expanded` d'une [BorderedSection] sur
/// l'écran d'accueil), avec un ascenseur fin visible seulement quand le
/// contenu dépasse cette hauteur.
class BoundedGameRunsList extends StatefulWidget {
  final List<Widget> children;

  const BoundedGameRunsList({super.key, required this.children});

  @override
  State<BoundedGameRunsList> createState() => _BoundedGameRunsListState();
}

class _BoundedGameRunsListState extends State<BoundedGameRunsList> {
  // Scrollbar(thumbVisibility: true) exige un ScrollController explicite :
  // il ne trouve pas de PrimaryScrollController pour ce ListView.
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      thickness: 3,
      child: ListView(controller: _controller, children: widget.children),
    );
  }
}
