import 'package:flutter/material.dart';

import '../../state/game_save_store.dart';
import 'player_avatar.dart';

/// Contenu visuel commun à une ligne de run (alias + avatars des joueurs),
/// partagé entre la liste des runs interrompus (dans un `Dismissible`) et
/// celle des runs terminés (lecture seule).
class GameRunTile extends StatelessWidget {
  final SavedGame game;

  const GameRunTile({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(game.alias, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final name in game.setup.playerNames)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: PlayerAvatarWidget(name: name, size: 22),
            ),
        ],
      ),
    );
  }
}

/// Enveloppe une liste de runs dans une hauteur bornée avec un ascenseur
/// fin, visible seulement quand le contenu dépasse cette hauteur (sinon la
/// liste se contente de sa hauteur naturelle).
class BoundedGameRunsList extends StatefulWidget {
  static const double maxListHeight = 320;

  final List<Widget> children;

  const BoundedGameRunsList({super.key, required this.children});

  @override
  State<BoundedGameRunsList> createState() => _BoundedGameRunsListState();
}

class _BoundedGameRunsListState extends State<BoundedGameRunsList> {
  // Scrollbar(thumbVisibility: true) exige un ScrollController explicite :
  // il ne trouve pas de PrimaryScrollController pour un ListView shrinkWrap
  // niché dans un SingleChildScrollView parent (celui de SetupScreen).
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: BoundedGameRunsList.maxListHeight),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        thickness: 3,
        child: ListView(controller: _controller, shrinkWrap: true, children: widget.children),
      ),
    );
  }
}
