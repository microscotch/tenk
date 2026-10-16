import 'package:flutter/material.dart';

import '../../game/player.dart';
import '../../game/score_radar.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/player_avatar.dart';

/// Nombre de grilles par page : chacune occupe la moitié de la largeur.
const int _columnsPerPage = 2;

/// Grille de score complète : une colonne par joueur (son blason en entête,
/// couleurs désambiguïsées entre joueurs de la même partie — voir
/// [assignAvatarColors] — au lieu d'un texte d'initiales ; voir l'écran de
/// jeu, qui ouvre cette même grille filtrée sur un joueur en cliquant sur sa
/// ligne), avec tous ses tours validés dans l'ordre, le tiret ou le barré
/// propre à chaque ligne, et la ligne courante mise en évidence.
///
/// Chaque colonne occupe la moitié de la largeur : deux grilles au plus par
/// page, une colonne seule étant centrée. Au-delà de deux joueurs, les
/// colonnes sont réparties sur plusieurs pages navigables façon carrousel
/// (glissement + points de page).
///
/// Les grilles se lisent depuis [reference] — le joueur dont c'est le tour, ou
/// le gagnant d'une partie finie : sur chaque ligne d'un autre joueur, l'écart
/// signé entre ce score et le total potentiel de [reference] ([potentialTotal]).
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

  /// Le joueur depuis qui se lisent les grilles. Nul : aucun écart affiché.
  final Player? reference;

  /// Son total potentiel (score + main en cours). Nul : son score seul.
  final int? potentialTotal;

  const ScoreGridScreen({super.key, required this.players, this.roster, this.reference, this.potentialTotal});

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              const columnsPerPage = _columnsPerPage;
              final pageCount = (widget.players.length / columnsPerPage).ceil();

              if (pageCount <= 1) {
                return _GridPage(
                  players: widget.players,
                  avatarColors: avatarColors,
                  start: 0,
                  end: widget.players.length,
                  reference: widget.reference,
                  potentialTotal: widget.potentialTotal,
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
                          reference: widget.reference,
                          potentialTotal: widget.potentialTotal,
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
            },
          ),
        ),
      ),
    );
  }
}

/// Une page du carrousel : les colonnes des joueurs [start] (inclus) à [end]
/// (exclus), chacune sur la moitié de la largeur, centrées ensemble (une
/// colonne seule se retrouve donc au milieu).
class _GridPage extends StatelessWidget {
  final List<Player> players;
  final Map<String, Color> avatarColors;
  final int start;
  final int end;
  final Player? reference;
  final int? potentialTotal;

  const _GridPage({
    required this.players,
    required this.avatarColors,
    required this.start,
    required this.end,
    required this.reference,
    required this.potentialTotal,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = start; i < end; i++)
              SizedBox(
                width: constraints.maxWidth / _columnsPerPage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _PlayerColumn(
                    player: players[i],
                    avatarColors: avatarColors,
                    // L'écart se lit depuis le joueur de référence : sa propre
                    // grille n'en porte pas.
                    gapFrom: reference != null && reference!.name != players[i].name
                        ? (potentialTotal ?? reference!.totalScore)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  final Player player;
  final Map<String, Color> avatarColors;

  /// Le total potentiel du joueur de référence, quand cette colonne n'est pas
  /// la sienne : chaque ligne affiche alors son écart avec lui.
  final int? gapFrom;

  const _PlayerColumn({required this.player, required this.avatarColors, required this.gapFrom});

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
              gapFrom: gapFrom,
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
  final int? gapFrom;

  const _ScoreRow({required this.entry, required this.isCurrent, required this.avatarColors, required this.gapFrom});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          // L'écart avec le total potentiel du joueur de référence, à droite.
          if (gapFrom != null) ...[
            const Spacer(),
            Text(
              signedGap(entry.value - gapFrom!),
              style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
