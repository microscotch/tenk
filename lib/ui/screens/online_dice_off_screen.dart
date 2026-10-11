import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/dice_off.dart';
import '../../game/game_recording.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/online_providers.dart';
import '../sound_effects.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/dice_off_board.dart';
import 'game_screen.dart';

/// Le tirage au sort d'une partie en ligne. Le serveur l'a déjà entièrement
/// joué (tous les rounds, avec ses dés) : cet écran le RACONTE, un round après
/// l'autre, à partir du journal reçu, puis mène à la partie.
///
/// Une partie déjà entamée (on y revient après une coupure) saute directement
/// au jeu, comme une revanche (pas de tirage : l'ordre est imposé).
///
/// Face à un serveur qui connaît le signal de départ ([startSignalFeature]),
/// seul le joueur qui commence a le bouton « Jouer » : il lance la partie pour
/// tous ([OnlineSession.begin]). Les autres attendent, bouton inactif, et
/// entrent dans la partie dès que le serveur l'annonce (`begun`) — ou, à
/// défaut, dès que son premier coup arrive.
class OnlineDiceOffScreen extends ConsumerStatefulWidget {
  const OnlineDiceOffScreen({super.key});

  /// Pause avant le premier lancer, puis entre deux rounds.
  static const firstRollDelay = Duration(milliseconds: 500);
  static const roundDelay = Duration(milliseconds: 1800);

  @override
  ConsumerState<OnlineDiceOffScreen> createState() => _OnlineDiceOffScreenState();
}

class _OnlineDiceOffScreenState extends ConsumerState<OnlineDiceOffScreen> {
  List<DiceOffState> _steps = const [];
  var _shown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final game = ref.read(gameProvider.notifier);
    // Le notifier a servi à autre chose depuis (partie locale, rejeu) : il n'y a
    // pas de partie en ligne à raconter.
    if (!game.isOnline || game.originalSetup == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }
    final actions = game.actions;
    final diceOffCount = diceOffActionCount(actions);
    // Un journal qui va déjà bien au-delà du premier tour : la partie est en
    // cours, le tirage n'a plus rien à raconter. Pareil pour un ordre imposé
    // (une revanche) ou une partie déjà lancée par son premier joueur.
    if (actions.length > diceOffCount + 1 ||
        (actions.isNotEmpty && actions.first.type == GameActionType.presetOrder) ||
        ref.read(onlineSessionProvider).begun) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
      return;
    }
    final setup = GameSetup(playerNames: ref.read(gameProvider.notifier).originalSetup!.playerNames);
    _steps = [
      DiceOffState.start(setup.playerNames.length),
      for (var i = 0; i < diceOffCount; i++)
        if (actions[i].type == GameActionType.diceOffResolveRound)
          replayGame(setup, 0, actions.sublist(0, i + 1)).diceOff,
    ];
    _scheduleNext(OnlineDiceOffScreen.firstRollDelay);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNext(Duration delay) {
    _timer?.cancel();
    if (_shown >= _steps.length - 1) return;
    _timer = Timer(delay, () {
      if (!mounted) return;
      // Le round qu'on va montrer : un dé par joueur qui y a lancé.
      SoundEffects.instance.playDiceRoll(_steps[_shown + 1].roundHistory.last.length);
      setState(() => _shown++);
      _scheduleNext(OnlineDiceOffScreen.roundDelay);
    });
  }

  /// Un tap abrège l'attente : on va droit au résultat.
  void _skip() {
    if (_steps.isEmpty) return;
    _timer?.cancel();
    setState(() => _shown = _steps.length - 1);
  }

  var _left = false;

  void _play() {
    if (!mounted || _left) return;
    _left = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  /// Le premier joueur lance la partie, pour lui et pour tous.
  void _begin() {
    ref.read(onlineSessionProvider.notifier).begin();
    _play();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_steps.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final seats = ref.watch(onlineSessionProvider).seats;
    String nameOf(int seat) => seat < seats.length ? seats[seat].name : '${seat + 1}';
    final state = _steps[_shown];

    // Le signal de départ du premier joueur, ou à défaut son premier coup : les
    // autres entrent dans la partie.
    ref.listen<bool>(onlineSessionProvider.select((s) => s.begun), (_, begun) {
      if (begun) _play();
    });
    ref.listen(gameProvider, (_, _) {
      final actions = ref.read(gameProvider.notifier).actions;
      if (actions.length > diceOffActionCount(actions) + 1) _play();
    });
    final session = ref.watch(onlineSessionProvider);
    final link = ref.read(gameProvider.notifier).onlineLink;
    final waits = session.startSignalEnabled && link != null && link.playOrder.first != link.mySeat;

    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.diceOffTitle)),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: DiceOffBoard(
                  state: state,
                  shownName: nameOf,
                  startButton: !state.isResolved
                      ? null
                      : waits
                          ? (label: l10n.onlineDiceOffWaitingStart, onPressed: null)
                          : (label: l10n.onlineDiceOffContinue, onPressed: _begin),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
