import 'package:flutter/material.dart';

import '../../game/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/player_avatar.dart';

/// Largeur minimale d'une colonne pour que le score (jusqu'à 5 chiffres,
/// icônes tiret/courant comprises) ne soit jamais contraint à passer à la
/// ligne.
const double _minColumnWidth = 108.0;

/// Grille de score complète : une colonne par joueur (son blason en entête,
/// couleurs désambiguïsées entre joueurs de la même partie — voir
/// [assignAvatarColors] — au lieu d'un texte d'initiales ; voir l'écran de
/// jeu, qui ouvre cette même grille filtrée sur un joueur en cliquant sur sa
/// ligne), avec tous ses tours validés dans l'ordre, le tiret ou le barré
/// propre à chaque ligne, et la ligne courante mise en évidence.
///
/// Les colonnes s'étalent pour remplir toute la largeur disponible, sans
/// jamais descendre sous [_minColumnWidth] ; si tous les joueurs ne tiennent
/// pas sur une page à cette largeur minimale, elles sont réparties sur
/// plusieurs pages navigables façon carrousel (glissement + points de page).
class ScoreGridScreen extends StatefulWidget {
  /// Les joueurs dont la grille est affichée — tous, ou un seul quand on
  /// ouvre la grille depuis la ligne d'un joueur.
  final List<Player> players;

  /// Tous les joueurs de la partie, dans l'ordre de jeu : c'est sur eux que
  /// les couleurs de blason se décident (voir [assignAvatarColors]), même
  /// quand [players] n'en montre qu'un.
  ///
  /// Deux noms de même couleur naturelle sont départagés dans cet ordre. Les
  /// recalculer sur une liste réduite rendait au second la couleur que le
  /// premier lui avait prise : sa grille individuelle portait alors le blason
  /// d'une autre couleur que partout ailleurs dans le jeu.
  ///
  /// Par défaut [players], ce qui convient dès que la grille les montre tous.
  final List<Player>? roster;

  const ScoreGridScreen({super.key, required this.players, this.roster});

  @override
  State<ScoreGridScreen> createState() => _ScoreGridScreenState();
}

class _ScoreGridScreenState extends State<ScoreGridScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColors = assignAvatarColors((widget.roster ?? widget.players).map((p) => p.name));
    return Scaffold(
      appBar: AppTopBar(title: Text(AppLocalizations.of(context).scoreGridLabel)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(builder: (context, constraints) {
            final columnsPerPage =
                (constraints.maxWidth / _minColumnWidth).floor().clamp(1, widget.players.length);
            final pageCount = (widget.players.length / columnsPerPage).ceil();

            if (pageCount <= 1) {
              return _GridPage(
                players: widget.players,
                avatarColors: avatarColors,
                start: 0,
                end: widget.players.length,
              );
            }

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pageCount,
                    onPageChanged: (p) => setState(() => _page = p),
                    itemBuilder: (context, pageIndex) {
                      final start = pageIndex * columnsPerPage;
                      final end = (start + columnsPerPage).clamp(0, widget.players.length);
                      return _GridPage(
                        players: widget.players,
                        avatarColors: avatarColors,
                        start: start,
                        end: end,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pageCount; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: i == _page
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Une page du carrousel : les colonnes des joueurs [start] (inclus) à [end]
/// (exclus), étalées pour remplir toute la largeur disponible.
class _GridPage extends StatelessWidget {
  final List<Player> players;
  final Map<String, Color> avatarColors;
  final int start;
  final int end;

  const _GridPage({required this.players, required this.avatarColors, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = start; i < end; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PlayerColumn(player: players[i], avatarColors: avatarColors),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  final Player player;
  final Map<String, Color> avatarColors;

  const _PlayerColumn({required this.player, required this.avatarColors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: PlayerAvatarWidget(name: player.name, size: 36, color: avatarColors[player.name]),
        ),
        const SizedBox(height: 8),
        for (var i = player.grid.length - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ScoreRow(
              entry: player.grid[i],
              isCurrent: i == player.currentIndex,
              avatarColors: avatarColors,
            ),
          ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final ScoreEntry entry;
  final bool isCurrent;
  final Map<String, Color> avatarColors;

  const _ScoreRow({
    required this.entry,
    required this.isCurrent,
    required this.avatarColors,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = entry.isBarred
        ? colorScheme.errorContainer
        : isCurrent
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest;
    final borderColor = entry.isBarred
        ? colorScheme.error
        : isCurrent
            ? colorScheme.primary
            : colorScheme.outlineVariant;
    final textColor = entry.isBarred ? colorScheme.onErrorContainer : colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '${entry.value}',
            style: TextStyle(
              decoration: entry.isBarred ? TextDecoration.lineThrough : null,
              decorationThickness: 2,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          // Le blason de l'AUTEUR du barrage (pas forcément le propriétaire
          // de cette colonne) rejoint le libellé du score barré : soi-même en
          // cas de second craque consécutif, ou l'adversaire dont le tour
          // vient de provoquer la collision (voir [ScoreEntry.barredBy] et
          // l'entrée "Score barré" du journal de partie, qui suit la même
          // convention — voir _buildLogWhatCell dans game_screen.dart).
          if (entry.isBarred && entry.barredBy != null) ...[
            const SizedBox(width: 6),
            PlayerAvatarWidget(name: entry.barredBy!, size: 16, color: avatarColors[entry.barredBy]),
          ],
          // Le tiret est un avertissement : "un craque de plus et cette ligne
          // est barrée". Une fois la ligne barrée il a fait son office et
          // n'annonce plus rien — le barré dit tout.
          if (entry.hasTiret && !entry.isBarred) ...[
            const SizedBox(width: 6),
            const Icon(Icons.remove, size: 14, color: Colors.orange),
          ],
        ],
      ),
    );
  }
}
