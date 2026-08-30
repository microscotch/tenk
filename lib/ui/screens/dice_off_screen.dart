import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/dice_off.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_providers.dart';
import '../../state/settings_providers.dart';
import '../dice_colors.dart';
import '../sound_effects.dart';
import '../widgets/die_widget.dart';
import 'game_screen.dart';
import 'pass_device_screen.dart';

/// Détermine qui commence la partie : chaque joueur lance un dé, le score le
/// plus faible commence (égalité = relance entre les ex-aequo uniquement).
class DiceOffScreen extends ConsumerStatefulWidget {
  const DiceOffScreen({super.key});

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
      _scheduleAiIfNeeded();
      _scheduleAutoStartIfNeeded();
    });
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  /// Programme [action] pour s'exécuter seule après le délai IA réglé dans
  /// les préférences, sauf si l'utilisateur clique entre-temps n'importe où
  /// sur l'écran (voir [_skipPendingAction]), auquel cas elle s'exécute
  /// immédiatement.
  void _scheduleAutoAction(VoidCallback action) {
    _pendingTimer?.cancel();
    _pendingAction = action;
    _pendingTimer = Timer(ref.read(settingsProvider).aiMessageDelay, () {
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
    _scheduleAutoAction(_rollDie);
  }

  void _rollDie() {
    SoundEffects.instance.playDiceRoll();
    ref.read(diceOffProvider.notifier).rollForCurrent();
  }

  /// Quand tous les joueurs sont des IA, personne n'est là pour cliquer sur
  /// "Commencer la partie" une fois l'ordre déterminé : la partie démarre
  /// donc seule, comme les autres transitions automatiques.
  void _scheduleAutoStartIfNeeded() {
    final state = ref.read(diceOffProvider);
    final notifier = ref.read(diceOffProvider.notifier);
    if (state == null || !state.isResolved) return;
    if (notifier.humanPlayerCount > 0) return;
    _scheduleAutoAction(_startGame);
  }

  void _startGame() {
    if (!mounted) return;
    final rotated = ref.read(diceOffProvider.notifier).buildRotatedSetup();
    ref.read(gameProvider.notifier).startGame(rotated);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(diceOffProvider, (previous, next) {
      if (next == null) return;
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
      appBar: AppBar(title: const Text('Qui commence ?')),
      body: GestureDetector(
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
    );
  }

  Widget _buildRollView(DiceOffState state, DiceOffNotifier notifier) {
    final next = state.nextToRoll!;
    final isAi = notifier.isAiPlayer(next);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Chacun lance un dé : le score le plus faible commence la partie.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (state.roundHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Égalité : ${state.activeIndices.map(notifier.nameOf).join(', ')} relancent.',
              style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        if (state.rollsThisRound.isNotEmpty) ...[
          _diceOffRow(state.rollsThisRound, notifier, roundIndex: state.roundHistory.length),
          const SizedBox(height: 16),
        ],
        Text('${notifier.nameOf(next)} lance le dé', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        if (isAi)
          const Text('L\'IA réfléchit...')
        else
          FilledButton(
            onPressed: _rollDie,
            child: const Text('Lancer le dé'),
          ),
      ],
    );
  }

  Widget _buildResult(DiceOffState state, DiceOffNotifier notifier) {
    final lastRound = state.roundHistory.last;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${notifier.nameOf(state.winnerIndex!)} commence la partie !',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _diceOffRow(lastRound, notifier, roundIndex: state.roundHistory.length - 1),
        const SizedBox(height: 32),
        if (notifier.humanPlayerCount > 0)
          FilledButton(onPressed: _startGame, child: const Text('Commencer la partie'))
        else
          const Text('La partie démarre automatiquement...'),
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
