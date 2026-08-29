import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/dice_off.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_providers.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAiIfNeeded());
  }

  void _scheduleAiIfNeeded() {
    final state = ref.read(diceOffProvider);
    final notifier = ref.read(diceOffProvider.notifier);
    if (state == null || state.isResolved) return;
    final next = state.nextToRoll;
    if (next == null || !notifier.isAiPlayer(next)) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(diceOffProvider.notifier).rollForCurrent();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(diceOffProvider, (previous, next) {
      if (next == null || next.isResolved) return;
      if (previous != null &&
          previous.nextToRoll != next.nextToRoll &&
          next.nextToRoll != null &&
          ref.read(diceOffProvider.notifier).isPassAndPlayMode) {
        Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (_) => PassDeviceScreen(
                nextPlayerName: ref.read(diceOffProvider.notifier).nameOf(next.nextToRoll!),
              ),
            ))
            .then((_) => _scheduleAiIfNeeded());
      }
      _scheduleAiIfNeeded();
    });

    final state = ref.watch(diceOffProvider);
    final notifier = ref.read(diceOffProvider.notifier);
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Qui commence ?')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: state.isResolved ? _buildResult(state, notifier) : _buildRollView(state, notifier),
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
        Text('${notifier.nameOf(next)} lance le dé', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        if (isAi)
          const Text('L\'IA réfléchit...')
        else
          FilledButton(
            onPressed: () => ref.read(diceOffProvider.notifier).rollForCurrent(),
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
        for (final i in lastRound.keys)
          Text('${notifier.nameOf(i)} : ${lastRound[i]}', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            final rotated = ref.read(diceOffProvider.notifier).buildRotatedSetup();
            ref.read(gameProvider.notifier).startGame(rotated);
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
          },
          child: const Text('Commencer la partie'),
        ),
      ],
    );
  }
}
