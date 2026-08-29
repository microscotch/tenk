import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/combination.dart';
import '../../game/game_engine.dart';
import '../../game/turn_result.dart';
import '../../game/turn_state.dart';
import '../../state/game_providers.dart';
import '../widgets/die_widget.dart';
import '../widgets/score_sheet.dart';
import 'game_over_screen.dart';
import 'pass_device_screen.dart';

/// Détermine l'état visuel de chaque dé d'un lancer, en tenant compte du
/// nombre de 5 que le joueur envisage de rejeter (aperçu avant validation).
List<DieVisualState> _classifyDiceForDisplay(RollAnalysis analysis, int selectedDeclineCount) {
  if (analysis.groups.any((g) => g.isSuite)) {
    return List.filled(analysis.faces.length, DieVisualState.kept);
  }

  final mandatoryRemaining = <int, int>{};
  for (final g in analysis.mandatoryGroups) {
    mandatoryRemaining[g.value] = (mandatoryRemaining[g.value] ?? 0) + g.diceCount;
  }

  final fives = analysis.declinableFives;
  var toDeclineRemaining = selectedDeclineCount;

  return [
    for (final v in analysis.faces)
      if ((mandatoryRemaining[v] ?? 0) > 0)
        _consume(mandatoryRemaining, v, DieVisualState.kept)
      else if (fives != null && v == 5)
        (() {
          if (toDeclineRemaining > 0) {
            toDeclineRemaining--;
            return DieVisualState.declined;
          }
          return DieVisualState.declinable;
        })()
      else
        DieVisualState.junk,
  ];
}

DieVisualState _consume(Map<int, int> remaining, int value, DieVisualState result) {
  remaining[value] = remaining[value]! - 1;
  return result;
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int _selectedDecline = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAiIfNeeded());
  }

  void _scheduleAiIfNeeded() {
    final engine = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (engine == null || engine.gameOver) return;
    if (!notifier.isAiPlayer(engine.currentPlayerIndex)) return;
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      ref.read(gameProvider.notifier).playAiTurnStep();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameEngine?>(gameProvider, (previous, next) {
      if (next == null) return;
      if (next.gameOver) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GameOverScreen(players: next.players, winnerIndex: next.winnerIndex!),
        ));
        return;
      }
      if (previous != null &&
          next.currentPlayerIndex != previous.currentPlayerIndex &&
          ref.read(gameProvider.notifier).isPassAndPlayMode) {
        Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (_) => PassDeviceScreen(nextPlayerName: next.currentPlayer.name),
            ))
            .then((_) => _scheduleAiIfNeeded());
      }
      if (previous?.activeTurn?.pendingRoll != next.activeTurn?.pendingRoll) {
        _selectedDecline = 0;
      }
      _scheduleAiIfNeeded();
    });

    final engine = ref.watch(gameProvider);
    if (engine == null || engine.gameOver) {
      // Partie terminée : l'écran de fin de partie est poussé par le
      // ref.listen ci-dessus, activeTurn est déjà nettoyé côté moteur.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final notifier = ref.read(gameProvider.notifier);
    final isAiTurn = notifier.isAiPlayer(engine.currentPlayerIndex);

    if (engine.activeTurn == null) {
      // Dés hérités d'un tour précédent : le joueur doit choisir de les
      // garder ou de repartir avec une main pleine, avant que le tour ne
      // démarre réellement.
      return Scaffold(
        appBar: AppBar(title: const Text('Le 10000')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ScoreSheet(players: engine.players, currentPlayerIndex: engine.currentPlayerIndex),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: isAiTurn ? const Text('L\'IA réfléchit...') : _buildHandChoiceView(engine),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final turn = engine.activeTurn!;

    return Scaffold(
      appBar: AppBar(title: const Text('Le 10000')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ScoreSheet(players: engine.players, currentPlayerIndex: engine.currentPlayerIndex),
              const SizedBox(height: 16),
              if (engine.isInFinalRound)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Tour final : un joueur a atteint 10000 !',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ),
              Text('Score du tour : ${turn.bankedScore}', style: Theme.of(context).textTheme.titleLarge),
              Text('Minimum requis : ${engine.minimumForCurrentPlayer}'),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: isAiTurn
                      ? _buildAiTurnView(turn)
                      : (turn.busted
                          ? _buildBustedView(turn)
                          : (turn.pendingRoll != null
                              ? _buildPendingRollView(turn)
                              : _buildIdleView(engine, turn))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandChoiceView(GameEngine engine) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${engine.currentPlayer.name} hérite de ${engine.nextTurnDice} dé(s) du tour précédent.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => ref.read(gameProvider.notifier).startTurn(useFullHand: false),
          child: Text('Continuer avec ${engine.nextTurnDice} dé(s)'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => ref.read(gameProvider.notifier).startTurn(useFullHand: true),
          child: const Text('Recommencer avec 5 dés neufs'),
        ),
      ],
    );
  }

  Widget _buildAiTurnView(TurnState turn) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (turn.pendingRoll != null) _diceRow(turn.pendingRoll!, 0),
        const SizedBox(height: 16),
        const Text('L\'IA réfléchit...'),
      ],
    );
  }

  Widget _buildBustedView(TurnState turn) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _diceRow(turn.pendingRoll!, 0),
        const SizedBox(height: 16),
        const Text('Craqué !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => ref.read(gameProvider.notifier).endBustedTurn(),
          child: const Text('Continuer'),
        ),
      ],
    );
  }

  Widget _buildPendingRollView(TurnState turn) {
    final analysis = turn.pendingRoll!;
    final fives = analysis.declinableFives;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _diceRow(analysis, _selectedDecline),
        const SizedBox(height: 16),
        if (fives != null && analysis.canDeclineFives) ...[
          const Text('Rejeter combien de 5 ?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              // Il faut toujours garder au moins un dé marquant sur ce
              // lancer : si aucun groupe obligatoire n'existe, impossible de
              // rejeter le dernier 5.
              for (var i = 0; i <= (analysis.mandatoryGroups.isEmpty ? fives.diceCount - 1 : fives.diceCount); i++)
                ChoiceChip(
                  label: Text('$i'),
                  selected: _selectedDecline == i,
                  onSelected: (_) => setState(() => _selectedDecline = i),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: () =>
              ref.read(gameProvider.notifier).applyKeep(declineFivesCount: _selectedDecline),
          child: const Text('Valider'),
        ),
      ],
    );
  }

  Widget _buildIdleView(GameEngine engine, TurnState turn) {
    final attempt = tryBank(turn, minimumRequired: engine.minimumForCurrentPlayer);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${turn.diceToRoll} dé(s) à lancer', style: Theme.of(context).textTheme.titleMedium),
        if (turn.mustContinue)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Dés chauds : vous devez relancer !',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          )
        else if (!attempt.success)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_failureMessage(attempt), style: const TextStyle(color: Colors.grey)),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => ref.read(gameProvider.notifier).roll(),
              child: const Text('Lancer les dés'),
            ),
            if (!turn.mustContinue) ...[
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: attempt.success ? () => ref.read(gameProvider.notifier).bank() : null,
                child: const Text('S\'arrêter'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _failureMessage(BankAttempt attempt) {
    switch (attempt.reason) {
      case BankFailureReason.belowMinimum:
        return 'Score insuffisant pour s\'arrêter.';
      case BankFailureReason.endsIn50:
        return 'Interdit de s\'arrêter sur un score finissant par 50.';
      case BankFailureReason.mustContinueHotDice:
        return 'Vous devez relancer.';
      case null:
        return '';
    }
  }

  Widget _diceRow(RollAnalysis analysis, int selectedDecline) {
    final states = _classifyDiceForDisplay(analysis, selectedDecline);
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < analysis.faces.length; i++)
          DieWidget(value: analysis.faces[i], state: states[i]),
      ],
    );
  }
}
