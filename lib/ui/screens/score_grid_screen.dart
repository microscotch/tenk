import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import '../theme.dart';

import '../../game/avatar_catalog.dart';
import '../../game/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_providers.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/player_avatar.dart';

/// Nombre de grilles par page : chacune occupe la moitié de la largeur.
const int _columnsPerPage = 2;

/// Grille de score complète : une colonne par joueur (sa pastille en entête,
/// couleurs désambiguïsées entre joueurs de la même partie — voir
/// [assignAvatarColors] — au lieu d'un texte d'initiales ; voir l'écran de
/// jeu, qui ouvre cette même grille filtrée sur un joueur en cliquant sur sa
/// ligne), avec tous ses tours validés dans l'ordre, le tiret ou le barré
/// propre à chaque ligne, et la ligne courante mise en évidence.
///
/// Chaque colonne occupe la moitié de la largeur : deux grilles au plus par
/// page, une colonne seule étant centrée. Avec un [reference] et des
/// adversaires à montrer, il y a une page par adversaire : la grille de
/// [reference] à gauche, celle de l'adversaire à droite, **sur une même échelle**
/// (voir [ladderRows]) : une rangée par valeur de score, la plus haute en haut, deux
/// lignes de même valeur face à face, et la vue ouverte sur la ligne courante de
/// [reference], au milieu de l'écran quand la liste le permet. Sans [reference],
/// chaque grille se lit seule, ses tours dans l'ordre, et les colonnes sont
/// réparties par deux sur des pages navigables façon carrousel **circulaire** (glissement +
/// points de page : après la dernière page vient la première, et inversement).
///
/// Les grilles se lisent depuis [reference] — le joueur dont c'est le tour, ou
/// le gagnant d'une partie finie : sur chaque ligne d'un autre joueur, l'écart
/// entre ce score et le total potentiel de [reference] ([potentialTotal]), en
/// valeur absolue suivie de « devant » ou « derrière » (jamais sur une ligne
/// barrée).
///
/// En tête de chaque colonne : la pastille et le nom (le surnom d'abord),
/// tronqué à la largeur de la colonne ; une grille seule le montre en entier,
/// centré sur toute la largeur de l'écran, au-dessus d'elle.
class ScoreGridScreen extends StatefulWidget {
  /// Les joueurs dont la grille est affichée — en général tous ; depuis la ligne d'un
  /// joueur, c'est tout de même le carrousel complet, ouvert sur sa page
  /// ([initialPlayer]).
  final List<Player> players;

  /// Tous les joueurs de la partie, dans l'ordre de jeu : c'est sur eux que
  /// les couleurs de pastille se décident (voir [assignAvatarColors]), même
  /// quand [players] n'en montre qu'un.
  ///
  /// Deux noms de même couleur naturelle sont départagés dans cet ordre. Les
  /// recalculer sur une liste réduite rendait au second la couleur que le
  /// premier lui avait prise : sa grille individuelle portait alors la pastille
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

  /// Apparence des pastilles, par nom en jeu (voir `avatarLooksProvider`) : la lettre
  /// du nom affiché, l'animal et la couleur choisis dans les profils. Un joueur absent
  /// de la table a la lettre de son nom et une couleur attribuée.
  final Map<String, AvatarLook> looks;

  /// Vrai quand la main du joueur de référence peut être encaissée : une ligne
  /// d'un autre joueur égale à son total potentiel passe alors en rouge — s'il
  /// s'arrête, elle est barrée.
  final bool handBankable;

  /// Le joueur sur la page duquel le carrousel s'ouvre : avec un [reference], la page de
  /// cet adversaire (la première si ce joueur est le [reference] lui-même ou n'est pas
  /// montré). Nul : la première page.
  final Player? initialPlayer;

  const ScoreGridScreen({
    super.key,
    required this.players,
    this.roster,
    this.reference,
    this.potentialTotal,
    this.displayNames = const {},
    this.looks = const {},
    this.handBankable = false,
    this.initialPlayer,
  });

  @override
  State<ScoreGridScreen> createState() => _ScoreGridScreenState();
}

class _ScoreGridScreenState extends State<ScoreGridScreen> {
  /// Le carrousel est circulaire : le contrôleur part loin du début de la liste infinie
  /// (la page 0 d'un `PageView` sans fin n'a rien avant elle), sur un multiple du nombre
  /// de pages, pour qu'un balayage vers l'arrière comme vers l'avant ne trouve jamais de
  /// bord. Le numéro de page réellement montré est ce numéro modulo le nombre de pages.
  static const _loops = 1000;

  late final int _firstPage = _initialPageIndex();
  late final PageController _pageController = PageController(initialPage: _loops * _pages().length + _firstPage);
  late int _page = _firstPage;

  /// L'index (dans [_pageList]) de la page de [ScoreGridScreen.initialPlayer].
  int _initialPageIndex() {
    final wanted = widget.initialPlayer;
    if (wanted == null || widget.reference?.name == wanted.name) return 0;
    final index = _pages().indexWhere((page) => page.any((p) => p.name == wanted.name));
    return index < 0 ? 0 : index;
  }

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
    final avatars = AvatarSet.resolve((widget.roster ?? widget.players).map((p) => p.name), widget.looks);
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
                  avatars: avatars,
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
                      // Sans fin : la dernière page est suivie de la première, et inversement.
                      onPageChanged: (p) => setState(() => _page = p % pageCount),
                      itemBuilder: (context, pageIndex) {
                        return _GridPage(
                          players: pages[pageIndex % pageCount],
                          avatars: avatars,
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
  final AvatarSet avatars;
  final Player? reference;
  final int? potentialTotal;
  final Map<String, String> displayNames;
  final bool handBankable;

  const _GridPage({
    required this.players,
    required this.avatars,
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
    // Deux grilles lues depuis le joueur de référence : à l'échelle, voir [_ComparisonPage].
    if (players.length == 2 && reference != null && players.first.name == reference!.name) {
      return _ComparisonPage(
        reference: players.first,
        opponent: players.last,
        avatars: avatars,
        potentialTotal: potentialTotal,
        displayNames: displayNames,
        handBankable: handBankable,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (solo)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlayerHeader(
                  avatar: avatars.of(players.first.name, size: 36),
                  displayName: displayNameOf(displayNames, players.first.name),
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
                        avatars: avatars,
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

/// Les deux grilles sur une même échelle : une ligne par valeur de score, la plus
/// haute en haut, et deux lignes de même valeur (une par joueur) face à face. Une
/// valeur que l'un des joueurs n'a jamais eue laisse un blanc de son côté. Une même
/// valeur présente deux fois chez un joueur (une ligne barrée, puis refaite) prend deux
/// rangées, la plus récente d'abord ; quand les deux joueurs en ont un nombre différent,
/// la plus récente de l'un fait face à la plus récente de l'autre (aucun autre
/// appariement ne serait moins arbitraire).
@visibleForTesting
List<({ScoreEntry? left, ScoreEntry? right, bool leftCurrent, bool rightCurrent})> ladderRows(Player left, Player right) {
  // Par valeur décroissante ; à valeur égale, la plus récente d'abord.
  List<int> order(Player p) => [for (var i = 0; i < p.grid.length; i++) i]
    ..sort((a, b) {
      final byValue = p.grid[b].value.compareTo(p.grid[a].value);
      return byValue != 0 ? byValue : b.compareTo(a);
    });

  final l = order(left);
  final r = order(right);
  final rows = <({ScoreEntry? left, ScoreEntry? right, bool leftCurrent, bool rightCurrent})>[];
  var i = 0;
  var j = 0;
  while (i < l.length || j < r.length) {
    final lv = i < l.length ? left.grid[l[i]].value : null;
    final rv = j < r.length ? right.grid[r[j]].value : null;
    final takeLeft = lv != null && (rv == null || lv >= rv);
    final takeRight = rv != null && (lv == null || rv >= lv);
    rows.add((
      left: takeLeft ? left.grid[l[i]] : null,
      right: takeRight ? right.grid[r[j]] : null,
      leftCurrent: takeLeft && l[i] == left.currentIndex,
      rightCurrent: takeRight && r[j] == right.currentIndex,
    ));
    if (takeLeft) i++;
    if (takeRight) j++;
  }
  return rows;
}

/// La grille en mode comparaison : les noms restent en haut, et dessous, l'échelle
/// des scores ([ladderRows]) défile, ouverte sur la ligne courante du joueur de
/// référence, au milieu de l'écran quand la liste le permet — de quoi garder sa
/// ligne en vue même quand son score est loin de celui de l'adversaire.
class _ComparisonPage extends StatefulWidget {
  final Player reference;
  final Player opponent;
  final AvatarSet avatars;
  final int? potentialTotal;
  final Map<String, String> displayNames;
  final bool handBankable;

  const _ComparisonPage({
    required this.reference,
    required this.opponent,
    required this.avatars,
    required this.potentialTotal,
    required this.displayNames,
    required this.handBankable,
  });

  @override
  State<_ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<_ComparisonPage> {
  final _scroll = ScrollController();
  final _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnCurrent());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Amène la ligne courante du joueur de référence au milieu de l'écran, autant que
  /// la liste le permet : près d'une extrémité, elle reste là où le défilement s'arrête
  /// (aucun espace n'est ajouté pour forcer le centrage). Quand tout tient à l'écran,
  /// il n'y a rien à faire défiler.
  void _centerOnCurrent() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.maxScrollExtent <= 0) return;
    final context = _currentKey.currentContext;
    if (context == null) return;
    final viewport = RenderAbstractViewport.maybeOf(context.findRenderObject());
    if (viewport == null) return;
    final target = viewport.getOffsetToReveal(context.findRenderObject()!, 0.5).offset;
    _scroll.jumpTo(target.clamp(position.minScrollExtent, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final rows = ladderRows(widget.reference, widget.opponent);
    final reference = widget.reference;
    final gapFrom = widget.potentialTotal ?? reference.totalScore;

    Widget cell(ScoreEntry? entry, {required bool current, required int? gap}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: entry == null
            ? const SizedBox.shrink()
            : _ScoreRow(
                entry: entry,
                isCurrent: current,
                avatars: widget.avatars,
                gapFrom: gap,
                handBankable: widget.handBankable,
              ),
      ),
    );

    Widget header(Player p) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _PlayerHeader(
          avatar: widget.avatars.of(p.name, size: 28),
          displayName: displayNameOf(widget.displayNames, p.name),
          size: 28,
          truncate: true,
        ),
      ),
    );

    return Column(
      children: [
        Row(children: [header(reference), header(widget.opponent)]),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: IntrinsicHeight(
                      key: row.leftCurrent ? _currentKey : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // L'écart se lit depuis le joueur de référence : sa grille n'en porte pas.
                          cell(row.left, current: row.leftCurrent, gap: null),
                          cell(row.right, current: row.rightCurrent, gap: gapFrom),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// La pastille d'un joueur suivie de son nom, centrés : tronqué (points de
/// suspension) à la largeur disponible si [truncate], entier sinon.
class _PlayerHeader extends StatelessWidget {
  final Widget avatar;
  final String displayName;
  final double size;
  final bool truncate;

  const _PlayerHeader({
    required this.avatar,
    required this.displayName,
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
        avatar,
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  final Player player;
  final String displayName;
  final AvatarSet avatars;
  final bool showHeader;
  final bool handBankable;

  /// Le total potentiel du joueur de référence, quand cette colonne n'est pas
  /// la sienne : chaque ligne affiche alors son écart avec lui.
  final int? gapFrom;

  const _PlayerColumn({
    required this.player,
    required this.displayName,
    required this.avatars,
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
            avatar: avatars.of(player.name, size: 28),
            displayName: displayName,
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
              avatars: avatars,
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
  final AvatarSet avatars;
  final int? gapFrom;
  final bool handBankable;

  const _ScoreRow({
    required this.entry,
    required this.isCurrent,
    required this.avatars,
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
          // La pastille de l'AUTEUR du barrage (pas forcément le propriétaire
          // de cette colonne) rejoint le libellé du score barré : soi-même en
          // cas de second craque consécutif, ou l'adversaire dont le tour
          // vient de provoquer la collision (voir [ScoreEntry.barredBy] et
          // l'entrée "Score barré" du journal de partie, qui suit la même
          // convention — voir _buildLogWhatCell dans game_screen.dart).
          if (entry.isBarred && entry.barredBy != null) ...[
            const SizedBox(width: 6),
            avatars.of(entry.barredBy!, size: 16),
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
