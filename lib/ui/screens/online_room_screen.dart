import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/online/protocol.dart';
import '../../game/online/room_link.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/online_providers.dart';
import '../online_messages.dart';
import '../share.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/emotes.dart';
import '../widgets/player_avatar.dart';
import '../widgets/score_sheet.dart' show AvatarWithBubble;
import 'game_screen.dart' show GameScreen;
import 'online_dice_off_screen.dart';

/// Le salon d'attente d'une partie en ligne : le code à donner, les joueurs
/// présents, et pour l'hôte l'ordre des sièges et le lancement.
class OnlineRoomScreen extends ConsumerStatefulWidget {
  const OnlineRoomScreen({super.key});

  @override
  ConsumerState<OnlineRoomScreen> createState() => _OnlineRoomScreenState();
}

class _OnlineRoomScreenState extends ConsumerState<OnlineRoomScreen> {
  /// La bulle de ce que chaque joueur (par pseudo) vient d'exprimer, et la minuterie qui la retire.
  final Map<String, String> _bubbles = {};
  final Map<String, Timer> _bubbleTimers = {};

  /// La dernière émotion déjà montrée : celles d'avant l'ouverture du salon ne refont pas de bulle.
  int _lastEmoteId = -1;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(onlineSessionProvider);
    final session = ref.read(onlineSessionProvider.notifier);

    ref.listen<List<EmoteEvent>>(onlineEmotesProvider, (previous, next) {
      for (final event in next) {
        if (event.id <= _lastEmoteId) continue;
        _lastEmoteId = event.id;
        _showEmote(event);
      }
    });

    ref.listen<OnlineState>(onlineSessionProvider, (previous, next) {
      if (next.errorSerial != (previous?.errorSerial ?? 0) && next.error != null) {
        final message = onlineErrorMessage(l10n, next.error!, unreachable: next.unreachable);
        if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      if (!(previous?.gameStarted ?? false) && next.gameStarted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnlineDiceOffScreen()));
      }
    });

    // Quitter le salon d'attente : libérer la place d'abord, puis revenir à l'écran d'entrée.
    // Le retour système et la flèche font exactement cela. Un second appui rapide ne dépile pas
    // aussi l'écran d'entrée : une fois le salon quitté, sa route n'est plus la courante.
    Future<void> leaveRoom() async {
      final route = ModalRoute.of(context);
      await session.leave();
      if (context.mounted && (route?.isCurrent ?? true)) Navigator.of(context).pop();
    }

    final everyoneHere = online.seats.length >= minOnlinePlayers && online.seats.every((s) => s.connected);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leaveRoom();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: Text(l10n.onlineTitle),
          leading: BackButton(onPressed: leaveRoom),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connexion tombée (par exemple pendant le partage du code) : la
                // reconnexion se fait seule, ce bandeau le dit — une seule fois, pas
                // un message par tentative.
                if (online.status != OnlineStatus.online)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          l10n.onlineReconnecting,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                      ),
                    ),
                  ),
                Text(l10n.onlineCodeLabel, style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => Clipboard.setData(ClipboardData(text: online.roomCode ?? '')),
                  child: Text(
                    online.roomCode ?? '',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(letterSpacing: 6, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(l10n.onlineShareHint, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Center(child: _shareButton(context, l10n, online.roomCode ?? '')),
                const SizedBox(height: 16),
                Text(
                  l10n.onlinePlayersHeader(online.seats.length, maxOnlinePlayers),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(child: _players(context, l10n, online, session)),
                // De quoi se saluer avant le départ : le « câlin » et ses phrases (hello, bonne chance...).
                if (online.lobbyEmotesEnabled) ...[
                  EmoteBar(
                    emotes: const [Emote.joyful],
                    v2: online.emotes2Enabled,
                    onSend: (emote, phrase) => session.sendEmote(emote, phrase: phrase),
                  ),
                  const SizedBox(height: 12),
                ],
                if (online.isHost) ...[
                  if (!everyoneHere)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(l10n.onlineNeedTwoPlayers, textAlign: TextAlign.center),
                    ),
                  FilledButton(
                    onPressed: everyoneHere ? session.start : null,
                    child: Text(l10n.startGameButton),
                  ),
                ] else
                  Center(child: Text(l10n.onlineWaitingForHost)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Envoie le code par une application du téléphone. Sans feuille de partage
  /// disponible (bureau), le message est copié : le code reste transmissible.
  Widget _shareButton(BuildContext context, AppLocalizations l10n, String code) {
    return Builder(
      builder: (buttonContext) => OutlinedButton.icon(
        icon: const Icon(Icons.share),
        label: Text(l10n.onlineShareButton),
        onPressed: code.isEmpty
            ? null
            : () async {
                final message = l10n.onlineShareMessage(code, roomLinkFor(code).toString());
                final box = buttonContext.findRenderObject() as RenderBox?;
                final origin = box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
                try {
                  await ref.read(shareTextProvider)(message, origin: origin);
                } catch (_) {
                  await Clipboard.setData(ClipboardData(text: message));
                }
              },
      ),
    );
  }

  Widget _players(BuildContext context, AppLocalizations l10n, OnlineState online, OnlineSession session) {
    // Les pastilles des joueurs présents : celles qu'ils ont annoncées, sinon la lettre de leur pseudo.
    final avatars = AvatarSet.resolve(
      [for (final seat in online.seats) seat.name],
      {for (final seat in online.seats) seat.name: ?seat.avatar},
    );
    Widget tile(int index, {Widget? trailing}) {
      final seat = online.seats[index];
      return ListTile(
        key: ValueKey('seat-$index-${seat.name}'),
        leading: Opacity(
          opacity: seat.connected ? 1 : 0.4,
          child: AvatarWithBubble(bubble: _bubbles[seat.name], child: avatars.of(seat.name, size: 40)),
        ),
        title: Text(seat.name + (index == online.mySeat ? '  •' : '')),
        subtitle: index == online.hostSeat
            ? Text(l10n.onlineHostBadge)
            : (seat.connected ? null : Text(l10n.onlineDisconnectedBadge)),
        trailing: trailing,
      );
    }

    if (!online.isHost) {
      return ListView(children: [for (var i = 0; i < online.seats.length; i++) tile(i)]);
    }
    // L'hôte règle l'ordre autour de la table en glissant les lignes, comme sur
    // l'écran de nouvelle partie.
    return ReorderableListView(
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        final order = [for (var i = 0; i < online.seats.length; i++) i];
        order.insert(newIndex, order.removeAt(oldIndex));
        session.reorder(order);
      },
      children: [
        for (var i = 0; i < online.seats.length; i++)
          tile(
            i,
            trailing: ReorderableDragStartListener(
              index: i,
              child: Tooltip(message: l10n.reorderPlayerHandleLabel, child: const Icon(Icons.drag_handle)),
            ),
          ),
      ],
    );
  }
}
