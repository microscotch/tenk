import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/game_save_store.dart';
import '../../state/online_providers.dart';
import '../../state/player_providers.dart';
import '../navigation.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/emotes.dart';
import '../widgets/player_avatar.dart';
import '../widgets/score_sheet.dart' show AvatarWithBubble;
import 'game_screen.dart';
import 'game_statistics_screen.dart';
import 'online_game_over_panel.dart';
import 'score_chart_screen.dart';
import 'score_grid_screen.dart';

class GameOverScreen extends ConsumerStatefulWidget {
  final List<Player> players;
  final int winnerIndex;

  /// Le journal de la partie : c'est de lui que se dérivent la courbe des
  /// scores, les statistiques et le rejeu. Sans lui (état chargé par
  /// `debugLoadState`), il n'y aurait rien à montrer, et les trois boutons ne
  /// s'affichent donc pas.
  final SavedGame? record;

  /// Vrai quand l'écran est ouvert depuis la liste des runs terminées, sans
  /// partie jouée dessous : le retour ramène alors à cette liste. Faux à la fin
  /// d'une partie qu'on vient de jouer, où il ramène à l'accueil (voir le
  /// `PopScope` plus bas).
  final bool archived;

  const GameOverScreen({
    super.key,
    required this.players,
    required this.winnerIndex,
    this.record,
    this.archived = false,
  });

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen> {
  /// Les bulles d'émotion en cours, par nom de joueur (partie en ligne).
  final Map<String, String> _bubbles = {};
  final Map<String, Timer> _bubbleTimers = {};

  /// La dernière émotion déjà montrée : celles d'avant l'ouverture de l'écran
  /// ne refont pas de bulle.
  int _lastEmoteId = -1;

  /// Vrai pour l'écran de fin d'une partie en ligne qu'on vient de jouer : il
  /// propose la revanche et les émotions.
  late final bool _online = !widget.archived && ref.read(gameProvider.notifier).isOnline;

  @override
  void initState() {
    super.initState();
    final emotes = ref.read(onlineEmotesProvider);
    if (emotes.isNotEmpty) _lastEmoteId = emotes.last.id;
  }

  @override
  void dispose() {
    for (final timer in _bubbleTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _showEmote(EmoteEvent event) {
    final seats = ref.read(onlineSessionProvider).seats;
    if (event.seat >= seats.length) return;
    final name = seats[event.seat].name;
    final text = emoteText(AppLocalizations.of(context), event.emote, event.phrase);
    setState(() => _bubbles[name] = text);
    _bubbleTimers[name]?.cancel();
    _bubbleTimers[name] = Timer(GameScreen.bubbleDuration, () {
      if (mounted) setState(() => _bubbles.remove(name));
    });
  }

  /// Quitte l'écran de fin : retour à l'accueil. En ligne, c'est aussi quitter
  /// le salon (et donc refuser une revanche en cours).
  void _leave() {
    popToHome(context);
    if (_online) unawaited(ref.read(onlineSessionProvider.notifier).leaveFinishedGame());
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.players;
    final winnerIndex = widget.winnerIndex;
    final record = widget.record;
    final archived = widget.archived;
    final l10n = AppLocalizations.of(context);
    if (_online) {
      ref.listen<List<EmoteEvent>>(onlineEmotesProvider, (previous, next) {
        for (final event in next) {
          if (event.id <= _lastEmoteId) continue;
          _lastEmoteId = event.id;
          _showEmote(event);
        }
      });
    }
    // Le surnom prime sur le nom, ici comme partout où le joueur est nommé.
    // Un siège non rattaché à une fiche — un bot, une partie antérieure à la
    // base — garde le nom sous lequel la partie l'a enregistré.
    final displayNames = watchDisplayNames(ref, record);
    final sorted = [...players]
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final journal = record;
    return PopScope(
      // Cet écran est empilé PAR-DESSUS le GameScreen de la partie qui vient
      // de se terminer (voir le ref.listen dans game_screen.dart) : un pop()
      // nu retomberait sur ce GameScreen — devenu un écran mort, puisqu'une
      // fois `engine.gameOver` vrai il n'affiche plus jamais qu'un indicateur
      // de chargement (voir ce commentaire côté GameScreen). Le retour
      // système ramène donc à l'accueil, seule sortie de cet écran.
      //
      // Ouvert depuis la liste des runs terminées ([archived]), rien de tel
      // dessous : un pop() ordinaire revient à la liste, ce qu'on attend.
      canPop: archived,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: Text(l10n.gameOverTitle),
          // Aucune sortie dans la barre — et surtout pas la flèche de retour
          // automatique de Flutter, qui ferait précisément le pop() nu que le
          // PopScope ci-dessus existe pour éviter.
          //
          // iOS fait exception : pas de bouton retour système, et le
          // glissement depuis le bord est neutralisé par ce même PopScope
          // (`ModalRoute.popGestureEnabled` est faux dès que la route refuse
          // de se dépiler). Sans cette flèche, cet écran serait sans issue.
          // Elle ramène à l'accueil, comme le retour système ailleurs.
          //
          // Archivé, c'est l'inverse : la flèche automatique de Flutter fait
          // exactement le retour voulu, là où [AppTopBar] la garde (hors
          // Android, où le retour système suffit).
          automaticallyImplyLeading: archived,
          leading: !archived && Theme.of(context).platform == TargetPlatform.iOS
              ? BackButton(onPressed: _leave)
              : null,
        ),
        body: SafeArea(
          child: Center(
            // Défilant : avec les boutons de courbe et de statistiques, la
            // colonne dépasse la hauteur d'un petit écran dès quelques joueurs.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    l10n.winnerAnnouncement(displayNameOf(displayNames, players[winnerIndex].name)),
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  for (final p in sorted)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // En ligne, le blason porte la bulle de ce que le
                          // joueur exprime (voir la barre d'émotions plus bas).
                          if (_online) ...[
                            AvatarWithBubble(
                              bubble: _bubbles[p.name],
                              child: PlayerAvatarWidget(name: p.name, size: 24),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              l10n.playerScoreLine(displayNameOf(displayNames, p.name), p.totalScore),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_online) ...[
                    const SizedBox(height: 24),
                    const OnlineGameOverPanel(),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScoreGridScreen(players: players),
                      ),
                    ),
                    icon: const Icon(Icons.grid_on),
                    label: Text(l10n.scoreGridLabel),
                  ),
                  if (journal != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ScoreChartScreen(players: players, record: journal),
                        ),
                      ),
                      icon: const Icon(Icons.show_chart),
                      label: Text(l10n.scoreChartTitle),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameStatisticsScreen(
                            players: players,
                            winnerIndex: winnerIndex,
                            record: journal,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.bar_chart),
                      label: Text(l10n.gameStatsTitle),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => openReplay(context, ref, journal),
                      icon: const Icon(Icons.replay),
                      label: Text(l10n.gameOverReplayButton),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
