import 'package:flutter/material.dart';

import '../../game/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_providers.dart';
import 'emotes.dart';
import 'player_avatar.dart';

class ScoreSheet extends StatelessWidget {
  final List<Player> players;
  final int currentPlayerIndex;

  /// Appelé avec le joueur concerné quand on clique sur sa ligne (ouvre sa
  /// grille de score complète). Aucune ligne n'est cliquable si null.
  final ValueChanged<Player>? onTapPlayer;

  /// Noms à afficher, par nom en jeu (voir `displayNamesProvider`). Un joueur
  /// absent de la table garde son nom. Le blason, lui, reste dessiné à partir
  /// du nom quoi qu'il arrive.
  final Map<String, String> displayNames;

  /// Les bulles à montrer, par index de joueur : ce qu'il vient d'exprimer en
  /// ligne (voir `EmoteBar`). Une bulle part du blason du joueur et s'étend à
  /// sa droite, sur plusieurs lignes s'il le faut (voir [_AvatarWithBubble]).
  final Map<int, String> bubbles;

  const ScoreSheet({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    this.onTapPlayer,
    this.displayNames = const {},
    this.bubbles = const {},
  });

  @override
  Widget build(BuildContext context) {
    final avatarColors = assignAvatarColors(players.map((p) => p.name));
    final ranks = podiumRanks(players);
    return Column(
      children: [
        for (var i = 0; i < players.length; i++)
          _PlayerRow(
            displayName: displayNameOf(displayNames, players[i].name),
            player: players[i],
            isCurrent: i == currentPlayerIndex,
            gaps: _scoreGaps(players, i),
            onTap: onTapPlayer == null ? null : () => onTapPlayer!(players[i]),
            avatarColor: avatarColors[players[i].name],
            podiumRank: ranks[i],
            bubble: bubbles[i],
          ),
      ],
    );
  }
}

/// Teintes des trois médailles, assez saturées pour rester lisibles sur le
/// fond sombre des lignes de joueur.
Color _medalColor(int podiumRank) => switch (podiumRank) {
      // Or volontairement clair : la ligne du joueur courant a un fond ambré,
      // sur lequel un or plus sombre passait à ~2,9:1 de contraste. Cette
      // teinte tient au-dessus de 5:1 sur les deux fonds de ligne.
      1 => const Color(0xFFF2C94C), // or
      2 => const Color(0xFFC0C0C0), // argent
      _ => const Color(0xFFCD7F32), // bronze
    };

/// Rang sur le podium (1 = or, 2 = argent, 3 = bronze, null = pas de
/// médaille) de chaque joueur, dans l'ordre de [players].
///
/// Deux règles volontaires :
/// - un score de 0 ne vaut jamais de médaille, sinon toute la table en
///   arborerait une au premier tour, avant que quiconque ait marqué ;
/// - à égalité, les joueurs concernés partagent la même médaille sans
///   consommer le rang suivant (deux premiers ex æquo, puis un argent). La
///   règle de collision de score empêche de toute façon deux joueurs de
///   partager durablement un total non nul.
List<int?> podiumRanks(List<Player> players) {
  final scoresDescending = players.map((p) => p.totalScore).where((s) => s > 0).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  return [for (final player in players) _podiumRankOf(player.totalScore, scoresDescending)];
}

int? _podiumRankOf(int score, List<int> scoresDescending) {
  if (score <= 0) return null;
  final index = scoresDescending.indexOf(score);
  return index >= 0 && index < 3 ? index + 1 : null;
}

/// Écart entre le score d'un joueur et ceux de ses adversaires les plus
/// proches, un cran en dessous et un cran au-dessus (null si personne n'est
/// de ce côté-là).
class _ScoreGaps {
  final int? below;
  final int? above;
  const _ScoreGaps({this.below, this.above});
}

_ScoreGaps _scoreGaps(List<Player> players, int index) {
  final score = players[index].totalScore;
  int? nearestBelow;
  int? nearestAbove;
  for (var i = 0; i < players.length; i++) {
    if (i == index) continue;
    final other = players[i].totalScore;
    if (other < score && (nearestBelow == null || other > nearestBelow)) nearestBelow = other;
    if (other > score && (nearestAbove == null || other < nearestAbove)) nearestAbove = other;
  }
  return _ScoreGaps(
    below: nearestBelow != null ? score - nearestBelow : null,
    above: nearestAbove != null ? nearestAbove - score : null,
  );
}

class _PlayerRow extends StatelessWidget {
  final Player player;
  final bool isCurrent;
  final _ScoreGaps gaps;
  final VoidCallback? onTap;
  final Color? avatarColor;

  /// 1/2/3 pour or/argent/bronze, null si le joueur n'est pas sur le podium
  /// (voir [podiumRanks]).
  final int? podiumRank;

  /// Nom déjà résolu par [ScoreSheet] : la ligne n'a pas à connaître la table
  /// de correspondance, juste ce qu'elle doit écrire.
  final String displayName;
  final String? bubble;

  const _PlayerRow({
    required this.player,
    required this.displayName,
    this.bubble,
    required this.isCurrent,
    required this.gaps,
    required this.onTap,
    required this.avatarColor,
    required this.podiumRank,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // Un écart de 200 (le score minimum d'un tour) signale un risque réel de
    // collision au prochain tour de l'adversaire concerné.
    final dangerBelow = gaps.below == 200;
    final opportunityAbove = gaps.above == 200;
    final previousEntry = player.lastUnbarredEntry;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _AvatarWithBubble(
                        bubble: bubble,
                        child: PlayerAvatarWidget(name: player.name, size: 24, color: avatarColor),
                      ),
                    ),
                    Text(displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (podiumRank != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Tooltip(
                          message: switch (podiumRank!) {
                            1 => l10n.rankFirstTooltip,
                            2 => l10n.rankSecondTooltip,
                            _ => l10n.rankThirdTooltip,
                          },
                          child: Icon(Icons.military_tech, size: 18, color: _medalColor(podiumRank!)),
                        ),
                      ),
                    if (!player.hasEntered)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(l10n.notEnteredLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (opportunityAbove)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: l10n.opportunityTooltip,
                          child: const Icon(Icons.gps_fixed, size: 18, color: Colors.lightGreenAccent),
                        ),
                      ),
                    if (dangerBelow)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: l10n.dangerTooltip,
                          child: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
                        ),
                      ),
                    if (player.hasTiret)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: l10n.tiretTooltip,
                          child: const Icon(Icons.priority_high, size: 18, color: Colors.orange),
                        ),
                      ),
                    Text('${player.totalScore}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    // Le tiret est DANS la parenthèse : il qualifie ce score
                    // précédent, pas le total courant qui le précède à
                    // l'écran. D'où le WidgetSpan plutôt qu'une icône posée
                    // après la parenthèse fermante.
                    Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        children: [
                          TextSpan(text: '(${previousEntry?.value ?? 0}'),
                          if (previousEntry?.hasTiret ?? false)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Tooltip(
                                  message: l10n.previousScoreHadTiretTooltip,
                                  child: Icon(Icons.remove, size: 12, color: Colors.orange.shade300),
                                ),
                              ),
                            ),
                          const TextSpan(text: ')'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return row;
  }
}

/// Le blason d'un joueur, et la bulle de ce qu'il vient d'exprimer, quand il y
/// en a une : pointe sur le bord droit du blason, centrée sur lui.
///
/// La bulle est dessinée dans l'overlay de la page, accrochée au blason (un
/// [CompositedTransformFollower] suit son [CompositedTransformTarget]) : elle
/// peut ainsi dépasser la hauteur de la ligne, sans être rognée par la zone qui
/// défile, tout en suivant la ligne quand elle défile.
class _AvatarWithBubble extends StatefulWidget {
  final String? bubble;
  final Widget child;

  const _AvatarWithBubble({required this.bubble, required this.child});

  @override
  State<_AvatarWithBubble> createState() => _AvatarWithBubbleState();
}

class _AvatarWithBubbleState extends State<_AvatarWithBubble> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  /// La dernière bulle montrée, gardée le temps qu'elle s'efface.
  String? _shown;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_AvatarWithBubble old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.bubble == null) return;
    _shown = widget.bubble;
    if (_portal.isShowing) return;
    // Pas pendant la construction de l'arbre, que `show` refuse : juste après.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.bubble != null && !_portal.isShowing) _portal.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.bubble != null;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        // Un `Positioned` sans taille : le suiveur prend celle de la bulle, que
        // `followerAnchor` peut alors centrer sur le blason (sans lui, il
        // prendrait tout l'overlay).
        overlayChildBuilder: (_) => Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.centerRight,
            followerAnchor: Alignment.centerLeft,
            offset: const Offset(2, 0),
            child: IgnorePointer(
              child: AnimatedScale(
                scale: visible ? 1 : 0.6,
                alignment: Alignment.centerLeft,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  onEnd: () {
                    if (!visible && mounted) _portal.hide();
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: SpeechBubble(text: _shown ?? ''),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
