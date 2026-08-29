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
/// nombre de 5 que le joueur envisage de garder (aperçu avant validation).
List<DieVisualState> _classifyDiceForDisplay(RollAnalysis analysis, int selectedKeepCount) {
  if (analysis.groups.any((g) => g.isSuite)) {
    return List.filled(analysis.faces.length, DieVisualState.kept);
  }

  final mandatoryRemaining = <int, int>{};
  for (final g in analysis.mandatoryGroups) {
    mandatoryRemaining[g.value] = (mandatoryRemaining[g.value] ?? 0) + g.diceCount;
  }

  final fives = analysis.declinableFives;
  var keepRemaining = selectedKeepCount;

  return [
    for (final v in analysis.faces)
      if ((mandatoryRemaining[v] ?? 0) > 0)
        _consume(mandatoryRemaining, v, _mandatoryVisualState(analysis, v))
      else if (fives != null && v == 5)
        (() {
          if (keepRemaining > 0) {
            keepRemaining--;
            final perDie = fives.points ~/ fives.diceCount;
            return perDie == 100 ? DieVisualState.extended : DieVisualState.kept;
          }
          return DieVisualState.declined;
        })()
      else
        DieVisualState.junk,
  ];
}

DieVisualState _mandatoryVisualState(RollAnalysis analysis, int value) {
  final g = analysis.mandatoryGroups.firstWhere((g) => g.value == value);
  // Un groupe obligatoire isolé (moins de 3 dés) de valeur non-as ne peut
  // exister que via la règle d'extension : ses points sont "temporaires".
  final isExtended = g.diceCount < 3 && g.value != 1;
  return isExtended ? DieVisualState.extended : DieVisualState.kept;
}

DieVisualState _consume(Map<int, int> remaining, int value, DieVisualState result) {
  remaining[value] = remaining[value]! - 1;
  return result;
}

/// Points que rapporterait ce lancer si le joueur valide sa sélection
/// actuelle (combien de 5 garder).
int _previewPoints(RollAnalysis analysis, int selectedKeepCount) {
  var points = analysis.mandatoryGroups.fold<int>(0, (sum, g) => sum + g.points);
  final fives = analysis.declinableFives;
  if (fives != null) {
    final perDie = fives.points ~/ fives.diceCount;
    points += selectedKeepCount * perDie;
  }
  return points;
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  /// Combien de 5 déclinables le joueur choisit de garder (par défaut, tous).
  int _selectedKeep = 0;

  @override
  void initState() {
    super.initState();
    final initialPendingRoll = ref.read(gameProvider)?.activeTurn?.pendingRoll;
    _selectedKeep = initialPendingRoll?.declinableFives?.diceCount ?? 0;
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
      final newPendingRoll = next.activeTurn?.pendingRoll;
      if (previous?.activeTurn?.pendingRoll != newPendingRoll) {
        // Par défaut, on garde tous les 5 déclinables.
        _selectedKeep = newPendingRoll?.declinableFives?.diceCount ?? 0;
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
              if (turn.keptDiceThisTurn.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Dés gardés ce tour', style: TextStyle(fontSize: 12, color: Colors.grey)),
                _keptDiceRow(turn),
              ],
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
    final canChoose = fives != null && analysis.canDeclineFives;
    final minKeep = analysis.mandatoryGroups.isEmpty ? 1 : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Score de ce lancer : ${_previewPoints(analysis, _selectedKeep)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _diceRow(analysis, _selectedKeep),
        const SizedBox(height: 16),
        if (canChoose) ...[
          const Text('Combien de 5 garder ?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var i = minKeep; i <= fives.diceCount; i++)
                ChoiceChip(
                  label: Text('$i'),
                  selected: _selectedKeep == i,
                  onSelected: (_) => setState(() => _selectedKeep = i),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: () {
            final declineCount = (fives?.diceCount ?? 0) - _selectedKeep;
            ref.read(gameProvider.notifier).applyKeep(declineFivesCount: declineCount);
          },
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

  Widget _diceRow(RollAnalysis analysis, int selectedKeep) {
    final states = _classifyDiceForDisplay(analysis, selectedKeep);
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < analysis.faces.length; i++)
          DieWidget(value: analysis.faces[i], state: states[i]),
      ],
    );
  }

  Widget _keptDiceRow(TurnState turn) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (final d in turn.keptDiceThisTurn)
          DieWidget(value: d.value, state: d.isExtended ? DieVisualState.extended : DieVisualState.kept),
      ],
    );
  }
}
