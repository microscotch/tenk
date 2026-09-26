import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/online/protocol.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/online_providers.dart';
import '../online_messages.dart';
import '../widgets/app_top_bar.dart';
import 'online_dice_off_screen.dart';

/// Le salon d'attente d'une partie en ligne : le code à donner, les joueurs
/// présents, et pour l'hôte l'ordre des sièges et le lancement.
class OnlineRoomScreen extends ConsumerWidget {
  const OnlineRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(onlineSessionProvider);
    final session = ref.read(onlineSessionProvider.notifier);

    ref.listen<OnlineState>(onlineSessionProvider, (previous, next) {
      if (next.errorSerial != (previous?.errorSerial ?? 0) && next.error != null) {
        final message = onlineErrorMessage(l10n, next.error!, unreachable: next.unreachable);
        if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      if (!(previous?.gameStarted ?? false) && next.gameStarted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnlineDiceOffScreen()));
      }
    });

    final everyoneHere = online.seats.length >= minOnlinePlayers && online.seats.every((s) => s.connected);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await session.leave();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: Text(l10n.onlineTitle),
          leading: Theme.of(context).platform == TargetPlatform.android
              ? null
              : BackButton(onPressed: () async {
                  await session.leave();
                  if (context.mounted) Navigator.of(context).pop();
                }),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 16),
                Text(
                  l10n.onlinePlayersHeader(online.seats.length, maxOnlinePlayers),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Expanded(child: _players(context, l10n, online, session)),
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

  Widget _players(BuildContext context, AppLocalizations l10n, OnlineState online, OnlineSession session) {
    Widget tile(int index, {Widget? trailing}) {
      final seat = online.seats[index];
      return ListTile(
        key: ValueKey('seat-$index-${seat.name}'),
        leading: Icon(index == online.hostSeat ? Icons.star : Icons.person, color: seat.connected ? null : Colors.grey),
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
