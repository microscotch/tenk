import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_providers.dart';
import '../../state/player_providers.dart';
import '../../state/player_store.dart';
import '../../state/settings_providers.dart';
import '../sound_effects.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/dice_off_board.dart';
import 'game_screen.dart';

/// Détermine qui commence la partie et dans quel sens elle tourne : tous les
/// joueurs lancent leur dé en même temps, le plus faible commence, et les
/// ex-aequo au plus bas relancent seuls jusqu'à se départager. Tout se joue
/// sans intervention ; un tap sur l'écran abrège l'attente avant une relance.
class DiceOffScreen extends ConsumerStatefulWidget {
  const DiceOffScreen({super.key});

  /// Pause avant le premier lancer, le temps que l'écran s'installe.
  static const firstRollDelay = Duration(milliseconds: 500);

  /// Pause entre deux rounds : l'animation du dé, puis de quoi lire qui est à
  /// égalité avant que ses dés repartent.
  static const tieRerollDelay = Duration(milliseconds: 1800);

  @override
  ConsumerState<DiceOffScreen> createState() => _DiceOffScreenState();
}

class _DiceOffScreenState extends ConsumerState<DiceOffScreen> {
  Timer? _pendingTimer;
  VoidCallback? _pendingAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(diceOffProvider);
      if (state == null) return;
      if (state.isResolved) {
        _scheduleAutoStartIfNeeded();
      } else {
        _schedule(_rollRound, DiceOffScreen.firstRollDelay);
      }
    });
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  void _schedule(VoidCallback action, Duration delay) {
    _pendingTimer?.cancel();
    _pendingAction = action;
    _pendingTimer = Timer(delay, () {
      if (!mounted) return;
      _pendingAction = null;
      action();
    });
  }

  void _skipPendingAction() {
    final action = _pendingAction;
    if (action == null) return;
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingAction = null;
    action();
  }

  void _rollRound() {
    SoundEffects.instance.playDiceRoll();
    ref.read(diceOffProvider.notifier).rollRound();
    if (ref.read(diceOffProvider)!.isResolved) {
      _scheduleAutoStartIfNeeded();
    } else {
      _schedule(_rollRound, DiceOffScreen.tieRerollDelay);
    }
  }

  /// Quand tous les joueurs sont des IA en mode auto, personne n'est là pour
  /// cliquer sur "Commencer la partie" une fois l'ordre déterminé : la
  /// partie démarre donc seule, après le délai IA réglé dans les préférences.
  void _scheduleAutoStartIfNeeded() {
    final notifier = ref.read(diceOffProvider.notifier);
    if (notifier.humanPlayerCount > 0 || !notifier.allPlayersAreAuto) return;
    final delay = ref.read(settingsProvider).aiMessageDelay;
    if (delay <= Duration.zero) return;
    _schedule(_startGame, delay);
  }

  /// Le nom sous lequel le joueur du siège [seat] est appelé : son surnom quand
  /// sa fiche en porte un (voir `displayNamesFor`). Le tirage au sort se joue
  /// sur la config d'origine, avant que l'ordre de jeu soit fixé.
  String _shownName(int seat) {
    final notifier = ref.read(diceOffProvider.notifier);
    final names = displayNamesFor(notifier.setup, ref.read(playersProvider).value);
    return displayNameOf(names, notifier.nameOf(seat));
  }

  void _startGame() {
    if (!mounted) return;
    _pendingTimer?.cancel();
    _pendingAction = null;
    final diceOffNotifier = ref.read(diceOffProvider.notifier);
    final ordered = diceOffNotifier.buildOrderedSetup();
    ref.read(gameProvider.notifier).startGame(ordered, handoff: diceOffNotifier.handoff());
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(diceOffProvider);
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.diceOffTitle)),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipPendingAction,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: DiceOffBoard(
                  state: state,
                  shownName: _shownName,
                  onStart: state.isResolved ? _startGame : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
