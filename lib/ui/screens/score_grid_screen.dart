import 'package:flutter/material.dart';
import '../theme.dart';

import '../../game/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_providers.dart';
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
/// page, une colonne seule étant centrée. Avec un [reference] et des
/// adversaires à montrer, il y a une page par adversaire : la grille de
/// [reference] à gauche, celle de l'adversaire à droite (une seule page pour
/// la grille individuelle d'un adversaire). Sans [reference], les colonnes
/// sont réparties par deux sur des pages navigables façon carrousel
/// (glissement + points de page).
///
/// Les grilles se lisent depuis [reference] — le joueur dont c'est le tour, ou
/// le gagnant d'une partie finie : sur chaque ligne d'un autre joueur, l'écart
/// entre ce score et le total potentiel de [reference] ([potentialTotal]), en
/// valeur absolue suivie de « devant » ou « derrière » (jamais sur une ligne
/// barrée).
///
/// En tête de chaque colonne : le blason et le nom (le surnom d'abord),
/// tronqué à la largeur de la colonne ; une grille seule le montre en entier,
/// centré sur toute la largeur de l'écran, au-dessus d'elle.
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

  /// Noms à afficher, par nom en jeu (voir `displayNamesProvider`) : le surnom
  /// s'il y en a un. Un joueur absent de la table garde son nom.
  final Map<String, String> displayNames;

  /// Vrai quand la main du joueur de référence peut être encaissée : une ligne
  /// d'un autre joueur égale à son total potentiel passe alors en rouge — s'il
  /// s'arrête, elle est barrée.
  final bool handBankable;

  const ScoreGridScreen({
    super.key,
    required this.players,
    this.roster,
    this.reference,
    this.potentialTotal,
    this.displayNames = const {},
    this.handBankable = false,
  });

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

  /// Le contenu de chaque page. Avec un joueur de référence et au moins un
  /// adversaire à montrer : une page par adversaire, la grille du joueur de
  /// référence à gauche et celle de l'adversaire à droite. Sinon, les joueurs
  /// par paquets de [_columnsPerPage].
  List<List<Player>> _pages() {
    final reference = widget.reference;
    if (reference != null) {
      final opponents = widget.players.where((p) => p.name != reference.name).toList();
      if (opponents.isNotEmpty) {
        return [
          for (final opponent in opponents) [reference, opponent],
        ];
      }
    }
    return [
      for (var i = 0; i < widget.players.length; i += _columnsPerPage)
        widget.players.sublist(i, (i + _columnsPerPage).clamp(0, widget.players.length)),
    ];
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
              final pages = _pages();
              final pageCount = pages.length;

              if (pageCount <= 1) {
                return _GridPage(
                  players: pages.isEmpty ? const [] : pages.first,
                  avatarColors: avatarColors,
                  reference: widget.reference,
                  potentialTotal: widget.potentialTotal,
                  displayNames: widget.displayNames,
                  handBankable: widget.handBankable,
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
                        return _GridPage(
                          players: pages[pageIndex],
                          avatarColors: avatarColors,
                          reference: widget.reference,
                          potentialTotal: widget.potentialTotal,
                          displayNames: widget.displayNames,
                          handBankable: widget.handBankable,
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

/// Une page du carrousel : les colonnes de [players], chacune sur la moitié de
/// la largeur, centrées ensemble (une colonne seule se retrouve donc au
/// milieu).
class _GridPage extends StatelessWidget {
  final List<Player> players;
  final Map<String, Color> avatarColors;
  final Player? reference;
  final int? potentialTotal;
  final Map<String, String> displayNames;
  final bool handBankable;

  const _GridPage({
    required this.players,
    required this.avatarColors,
    required this.reference,
    required this.potentialTotal,
    required this.displayNames,
    required this.handBankable,
  });

  @override
  Widget build(BuildContext context) {
    // Une grille seule (ouverte depuis la ligne d'un joueur) : son nom en
    // entier, centré sur toute la largeur, au-dessus de la grille.
    final solo = players.length == 1;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (solo)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlayerHeader(
                  name: players.first.name,
                  displayName: displayNameOf(displayNames, players.first.name),
                  color: avatarColors[players.first.name],
                  size: 36,
                  truncate: false,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < players.length; i++)
                  SizedBox(
                    width: constraints.maxWidth / _columnsPerPage,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _PlayerColumn(
                        player: players[i],
                        displayName: displayNameOf(displayNames, players[i].name),
                        avatarColors: avatarColors,
                        showHeader: !solo,
                        handBankable: handBankable,
                        // L'écart se lit depuis le joueur de référence : sa
                        // propre grille n'en porte pas.
                        gapFrom: reference != null && reference!.name != players[i].name
                            ? (potentialTotal ?? reference!.totalScore)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Le blason d'un joueur suivi de son nom, centrés : tronqué (points de
/// suspension) à la largeur disponible si [truncate], entier sinon.
class _PlayerHeader extends StatelessWidget {
  final String name;
  final String displayName;
  final Color? color;
  final double size;
  final bool truncate;

  const _PlayerHeader({
    required this.name,
    required this.displayName,
    required this.color,
    required this.size,
    required this.truncate,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      displayName,
      textAlign: TextAlign.center,
      maxLines: truncate ? 1 : null,
      overflow: truncate ? TextOverflow.ellipsis : TextOverflow.visible,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlayerAvatarWidget(name: name, size: size, color: color),
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  final Player player;
  final String displayName;
  final Map<String, Color> avatarColors;
  final bool showHeader;
  final bool handBankable;

  /// Le total potentiel du joueur de référence, quand cette colonne n'est pas
  /// la sienne : chaque ligne affiche alors son écart avec lui.
  final int? gapFrom;

  const _PlayerColumn({
    required this.player,
    required this.displayName,
    required this.avatarColors,
    required this.showHeader,
    required this.handBankable,
    required this.gapFrom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          _PlayerHeader(
            name: player.name,
            displayName: displayName,
            color: avatarColors[player.name],
            size: 28,
            truncate: true,
          ),
          const SizedBox(height: 8),
        ],
        for (var i = player.grid.length - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ScoreRow(
              entry: player.grid[i],
              isCurrent: i == player.currentIndex,
              avatarColors: avatarColors,
              gapFrom: gapFrom,
              handBankable: handBankable,
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
  final bool handBankable;

  const _ScoreRow({
    required this.entry,
    required this.isCurrent,
    required this.avatarColors,
    required this.gapFrom,
    required this.handBankable,
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
    // L'écart avec le total potentiel du joueur de référence (jamais sur une
    // ligne barrée). Nul et main prenable : s'arrêter barrerait cette ligne.
    final gap = (gapFrom == null || entry.isBarred) ? null : entry.value - gapFrom!;
    final strikable = gap == 0 && handBankable;

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
              color: strikable ? TableColors.of(context).negative : textColor,
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
            Icon(Icons.remove, size: 14, color: TableColors.of(context).warning),
          ],
          if (gap != null) ...[
            const Spacer(),
            Text(
              gap == 0
                  ? '0'
                  : gap > 0
                  ? AppLocalizations.of(context).gridGapAhead(gap)
                  : AppLocalizations.of(context).gridGapBehind(-gap),
              style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
