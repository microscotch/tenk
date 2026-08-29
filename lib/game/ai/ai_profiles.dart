import 'dart:math';

import '../combination.dart';
import '../turn_state.dart';
import 'ai_strategy.dart';

/// Calcule par énumération exhaustive la probabilité de craquer (aucun dé
/// marquant) sur un lancer de [diceCount] dés, compte tenu des valeurs déjà
/// étendues ce tour.
double bustProbability(int diceCount, Set<int> extendedValues) {
  if (diceCount <= 0) return 0;
  final total = pow(6, diceCount).toInt();
  var bustCount = 0;
  final faces = List<int>.filled(diceCount, 1);
  for (var i = 0; i < total; i++) {
    var rem = i;
    for (var d = 0; d < diceCount; d++) {
      faces[d] = (rem % 6) + 1;
      rem ~/= 6;
    }
    if (!analyzeRoll(faces, extendedValues: extendedValues).hasAnyScore) {
      bustCount++;
    }
  }
  return bustCount / total;
}

/// Nombre maximal de 5 déclinables qu'il est possible de rejeter : il faut
/// toujours garder au moins un dé marquant sur le lancer, donc si aucun
/// groupe obligatoire n'existe, un des 5 doit rester (le dernier ne peut pas
/// être rejeté).
int _maxDeclinable(RollAnalysis analysis, ScoringGroup fives) {
  return analysis.mandatoryGroups.isEmpty ? fives.diceCount - 1 : fives.diceCount;
}

enum AiDifficulty { prudent, equilibre, agressif }

AiStrategy aiStrategyFor(AiDifficulty difficulty) {
  switch (difficulty) {
    case AiDifficulty.prudent:
      return const CautiousAi();
    case AiDifficulty.equilibre:
      return const BalancedAi();
    case AiDifficulty.agressif:
      return const AggressiveAi();
  }
}

/// Prudent : ne rejette jamais un 5 (préfère sécuriser les points), et
/// s'arrête dès que le risque de craquer au prochain lancer dépasse 25%.
class CautiousAi implements AiStrategy {
  const CautiousAi();

  @override
  int decideDeclineFives(RollAnalysis analysis, TurnState state) => 0;

  @override
  bool decideContinue({
    required TurnState state,
    required int minimumRequired,
    required int currentTotalScore,
  }) {
    return bustProbability(state.diceToRoll, state.extendedValues) <= 0.25;
  }
}

/// Équilibré : rejette un 5 isolé seulement si cela laisse un lot d'au moins
/// 3 dés à relancer (bonnes chances de combo), et pousse sa chance jusqu'à
/// un risque de craque de 45%.
class BalancedAi implements AiStrategy {
  const BalancedAi();

  @override
  int decideDeclineFives(RollAnalysis analysis, TurnState state) {
    final fives = analysis.declinableFives;
    if (fives == null || !analysis.canDeclineFives) return 0;
    final rerollPoolIfDeclined = analysis.junkDiceCount + fives.diceCount;
    return rerollPoolIfDeclined >= 3 ? _maxDeclinable(analysis, fives) : 0;
  }

  @override
  bool decideContinue({
    required TurnState state,
    required int minimumRequired,
    required int currentTotalScore,
  }) {
    return bustProbability(state.diceToRoll, state.extendedValues) <= 0.45;
  }
}

/// Agressif : rejette systématiquement les 5 isolés dès que possible pour
/// chercher de plus gros combos, et pousse sa chance jusqu'à un risque de
/// craque de 65%.
class AggressiveAi implements AiStrategy {
  const AggressiveAi();

  @override
  int decideDeclineFives(RollAnalysis analysis, TurnState state) {
    final fives = analysis.declinableFives;
    if (fives == null || !analysis.canDeclineFives) return 0;
    return _maxDeclinable(analysis, fives);
  }

  @override
  bool decideContinue({
    required TurnState state,
    required int minimumRequired,
    required int currentTotalScore,
  }) {
    return bustProbability(state.diceToRoll, state.extendedValues) <= 0.65;
  }
}
