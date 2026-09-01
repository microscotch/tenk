import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/dice_off.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_providers.dart';
import '../../state/replay_speed_provider.dart';
import '../../state/settings_providers.dart';
import '../dice_colors.dart';
import '../sound_effects.dart';
import '../widgets/die_widget.dart';
import '../widgets/replay_speed_control.dart';
import 'game_screen.dart';
import 'pass_device_screen.dart';

/// Détermine qui commence la partie : chaque joueur lance un dé, le score le
/// plus faible commence (égalité = relance entre les ex-aequo uniquement).
///
/// [replayMode] : rejeu spectateur d'un run archivé (voir
/// `DiceOffNotifier.startReplay`) — écran entièrement inerte (AbsorbPointer),
/// avance seul (vitesse x1/x2/x4, [ReplaySpeedControl]) sans jamais afficher
/// [PassDeviceScreen], jusqu'à enchaîner automatiquement sur `GameScreen` en
/// mode rejeu une fois le départage résolu.
class DiceOffScreen extends ConsumerStatefulWidget {
  final bool replayMode;

  const DiceOffScreen({super.key, this.replayMode = false});

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
      if (widget.replayMode) {
        _scheduleReplayStep();
        return;
      }
      _scheduleAiIfNeeded();
      _scheduleAutoStartIfNeeded();
    });
  }

  /// Programme puis applique le pas suivant du rejeu spectateur (départage),
  /// et se reprogramme lui-même jusqu'à ce que le départage soit résolu, où
  /// il enchaîne directement sur le rejeu de la partie principale. Délai =
  /// `aiMessageDelay` (réglages) divisé par [replaySpeedProvider] (x1/x2/x4).
  void _scheduleReplayStep() {
    final s = ref.read(diceOffProvider);
    if (s == null) return;
    if (s.isResolved) {
      _startGameReplay();
      return;
    }
    final baseDelay = ref.read(settingsProvider).aiMessageDelay;
    final speed = ref.read(replaySpeedProvider);
    final delay = Duration(microseconds: baseDelay.inMicroseconds ~/ speed);
    _pendingTimer?.cancel();
    _pendingTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(diceOffProvider.notifier).applyNextDiceOffReplayAction();
      _scheduleReplayStep();
    });
  }

  void _startGameReplay() {
    if (!mounted) return;
    final diceOffNotifier = ref.read(diceOffProvider.notifier);
    final rotated = diceOffNotifier.buildRotatedSetup();
    ref.read(gameProvider.notifier).startGameReplay(rotated, diceOffNotifier.replayHandoff());
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen(replayMode: true)));
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  /// Programme (ou annule) l'auto-validation d'[action] après le délai IA
  /// réglé dans les préférences, si [autoEnabled] (mode auto du/des joueur(s)
  /// concerné(s) et délai > 0). Un bouton explicite reste dans tous les cas
  /// affiché et cliquable (voir les méthodes `_build*`) ; l'utilisateur peut
  /// aussi cliquer n'importe où sur l'écran pour sauter l'attente restante
  /// (voir [_skipPendingAction]).
  void _scheduleAutoAction(VoidCallback action, {required bool autoEnabled}) {
    _pendingTimer?.cancel();
    if (!autoEnabled) {
      _pendingAction = null;
      return;
    }
    final delay = ref.read(settingsProvider).aiMessageDelay;
    if (delay <= Duration.zero) {
      _pendingAction = null;
      return;
    }
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

  void _scheduleAiIfNeeded() {
    final state = ref.read(diceOffProvider);
    final notifier = ref.read(diceOffProvider.notifier);
    if (state == null || state.isResolved) return;
    final next = state.nextToRoll;
    if (next == null || !notifier.isAiPlayer(next)) return;
    _scheduleAutoAction(_rollDie, autoEnabled: notifier.isAutoPlayer(next));
  }

  void _rollDie() {
    SoundEffects.instance.playDiceRoll();
    ref.read(diceOffProvider.notifier).rollForCurrent();
  }

  /// Quand tous les joueurs sont des IA en mode auto, personne n'est là pour
  /// cliquer sur "Commencer la partie" une fois l'ordre déterminé : la
  /// partie démarre donc seule, comme les autres transitions automatiques.
  void _scheduleAutoStartIfNeeded() {
    final state = ref.read(diceOffProvider);
    final notifier = ref.read(diceOffProvider.notifier);
    if (state == null || !state.isResolved) return;
    if (notifier.humanPlayerCount > 0) return;
    _scheduleAutoAction(_startGame, autoEnabled: notifier.allPlayersAreAuto);
  }

  void _startGame() {
    if (!mounted) return;
    final diceOffNotifier = ref.read(diceOffProvider.notifier);
    final rotated = diceOffNotifier.buildRotatedSetup();
    ref.read(gameProvider.notifier).startGame(rotated, handoff: diceOffNotifier.handoff());
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(diceOffProvider, (previous, next) {
      if (next == null || widget.replayMode) return; // le rejeu s'auto-pilote via _scheduleReplayStep
      if (!next.isResolved) {
        if (previous != null &&
            previous.nextToRoll != next.nextToRoll &&
            next.nextToRoll != null &&
            ref.read(diceOffProvider.notifier).shouldShowPassDevice(next.nextToRoll!)) {
          Navigator.of(context)
              .push(MaterialPageRoute(
                builder: (_) => PassDeviceScreen(
                  nextPlayerName: ref.read(diceOffProvider.notifier).nameOf(next.nextToRoll!),
                ),
              ))
              .then((_) => _scheduleAiIfNeeded());
        }
        _scheduleAiIfNeeded();
        return;
      }
      _scheduleAutoStartIfNeeded();
    });

    final state = ref.watch(diceOffProvider);
    final notifier = ref.read(diceOffProvider.notifier);
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).diceOffTitle),
        actions: widget.replayMode ? [const ReplaySpeedControl()] : null,
      ),
      body: AbsorbPointer(
        absorbing: widget.replayMode,
        child: GestureDetector(
          onTap: _skipPendingAction,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: state.isResolved ? _buildResult(state, notifier) : _buildRollView(state, notifier),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRollView(DiceOffState state, DiceOffNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    final next = state.nextToRoll!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.diceOffInstructions,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (state.roundHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              l10n.diceOffTieBreak(state.activeIndices.map(notifier.nameOf).join(', ')),
              style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        if (state.rollsThisRound.isNotEmpty) ...[
          _diceOffRow(state.rollsThisRound, notifier, roundIndex: state.roundHistory.length),
          const SizedBox(height: 16),
        ],
        Text(l10n.diceOffPlayerTurn(notifier.nameOf(next)), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _rollDie,
          child: Text(l10n.diceOffRollButton),
        ),
      ],
    );
  }

  Widget _buildResult(DiceOffState state, DiceOffNotifier notifier) {
    final l10n = AppLocalizations.of(context);
    final lastRound = state.roundHistory.last;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.diceOffWinnerAnnouncement(notifier.nameOf(state.winnerIndex!)),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _diceOffRow(lastRound, notifier, roundIndex: state.roundHistory.length - 1),
        const SizedBox(height: 32),
        FilledButton(onPressed: _startGame, child: Text(l10n.startGameButton)),
      ],
    );
  }

  Widget _diceOffRow(Map<int, int> rolls, DiceOffNotifier notifier, {required int roundIndex}) {
    final colorMode = ref.watch(settingsProvider).diceColorMode;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final i in rolls.keys)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notifier.nameOf(i), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              const SizedBox(height: 4),
              DieWidget(
                value: rolls[i]!,
                state: DieVisualState.kept,
                rollToken: '$roundIndex-$i',
                bodyColor: diceBodyColorFor(colorMode, i),
              ),
            ],
          ),
      ],
    );
  }
}
