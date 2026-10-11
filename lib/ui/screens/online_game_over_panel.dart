import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/online/protocol.dart' show minOnlinePlayers;
import '../../l10n/generated/app_localizations.dart';
import '../../state/online_providers.dart';
import '../navigation.dart';
import '../widgets/emotes.dart';
import 'game_screen.dart';
import 'setup_screen.dart';

/// Ce que l'écran de fin d'une partie en ligne ajoute : la revanche (voir
/// [rematchFeature]) — la proposer, ou répondre à celle d'un autre joueur
/// avant la fin du délai — et la barre d'émotions.
///
/// Suit aussi la session : la revanche lancée, il ouvre la nouvelle partie (un
/// [GameScreen] neuf, posé sur l'accueil) ; exclu de la revanche ou revanche
/// abandonnée, il ramène à l'accueil en le disant.
class OnlineGameOverPanel extends ConsumerStatefulWidget {
  const OnlineGameOverPanel({super.key});

  @override
  ConsumerState<OnlineGameOverPanel> createState() => _OnlineGameOverPanelState();
}

class _OnlineGameOverPanelState extends ConsumerState<OnlineGameOverPanel> {
  /// Fait avancer le compte à rebours affiché tant qu'un vote est en cours.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(onlineSessionProvider).rematch != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// La revanche est lancée : la nouvelle partie s'ouvre sur l'accueil, à la
  /// place de tout ce qui était empilé (l'écran de jeu de la partie finie, ses
  /// consultations).
  void _openRematch() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
      (route) => route.isFirst || route.settings.name == SetupScreen.routeName,
    );
  }

  void _goHome(String message) {
    final messenger = ScaffoldMessenger.of(context);
    popToHome(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refuse() async {
    final session = ref.read(onlineSessionProvider.notifier);
    popToHome(context);
    await session.answerRematch(accept: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen<int>(onlineSessionProvider.select((s) => s.gameSerial), (previous, next) {
      if (previous != null && next != previous) _openRematch();
    });
    ref.listen(onlineNoticeProvider, (previous, next) {
      if (next == null || next.serial == previous?.serial) return;
      _goHome(switch (next.notice) {
        OnlineNotice.rematchExcluded => l10n.rematchExcludedNotice,
        OnlineNotice.rematchCancelled => l10n.rematchCancelledNotice,
      });
    });

    final session = ref.watch(onlineSessionProvider);
    final mySeat = session.mySeat;
    final vote = session.rematch;
    final humans = session.seats.where((s) => !s.bot && s.connected).length;
    final children = <Widget>[];

    if (session.rematchEnabled && session.phase == RoomPhase.over && mySeat != null) {
      if (vote == null) {
        if (humans >= minOnlinePlayers) {
          children.add(FilledButton.icon(
            key: const ValueKey('rematch-propose'),
            onPressed: () => ref.read(onlineSessionProvider.notifier).proposeRematch(),
            icon: const Icon(Icons.replay_circle_filled),
            label: Text(l10n.rematchButton),
          ));
        }
      } else {
        final left = vote.deadline.difference(DateTime.now());
        final seconds = left.isNegative ? 0 : (left.inMilliseconds / 1000).ceil();
        final answered = vote.answers[mySeat] == true;
        final proposer = vote.proposerSeat < session.seats.length ? session.seats[vote.proposerSeat].name : '?';
        children.add(Card(
          key: const ValueKey('rematch-vote'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  answered ? l10n.rematchWaiting : l10n.rematchProposal(proposer),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(l10n.rematchSecondsLeft(seconds), style: TextStyle(color: Colors.grey.shade400)),
                if (!answered) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(onPressed: _refuse, child: Text(l10n.rematchRefuse)),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => ref.read(onlineSessionProvider.notifier).answerRematch(accept: true),
                        child: Text(l10n.rematchAccept),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ));
      }
    }
    if (session.emotesEnabled) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 16));
      children.add(EmoteBar(
        v2: session.emotes2Enabled,
        onSend: (emote, phrase) => ref.read(onlineSessionProvider.notifier).sendEmote(emote, phrase: phrase),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
