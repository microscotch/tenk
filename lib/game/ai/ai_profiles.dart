import 'dart:math';

import '../combination.dart';
import '../turn_state.dart';
import 'ai_strategy.dart';

/// Vrai si le risque de craquer au prochain lancer reste dans la marge
/// [baseMaxRisk] du profil, une fois ce risque mis à l'échelle de ce qui est
/// réellement en jeu. [baseMaxRisk] est calibré pour un craque "ordinaire"
/// qui ne coûte que le score du tour en cours ; quand la ligne courante de
/// la grille porte déjà un tiret actif, ce même craque la barrerait EN PLUS,
/// faisant retomber le score total à sa valeur précédente ([barLossIfBusted]
/// = ce qui serait perdu en plus du tour) — un enjeu bien plus lourd, que la
/// marge de risque tolérée doit refléter en se réduisant d'autant.
/// [barLossIfBusted] à 0 (pas de tiret actif) laisse le calcul inchangé.
bool _withinRiskBudget(
  TurnState state, {
  required double baseMaxRisk,
  required int barLossIfBusted,
}) {
  final p = bustProbability(state.diceToRoll, state.extendedValues);
  final stakes = state.bankedScore + barLossIfBusted;
  final adjustedMaxRisk = baseMaxRisk * state.bankedScore / stakes;
  return p <= adjustedMaxRisk;
}

/// Ajuste [declineCount] au minimum nécessaire pour que le score de tour qui
/// en résulterait ne finisse pas par 50 (voir [BankFailureReason.endsIn50])
/// — un total pareil interdit de s'arrêter dessus, ce qui forcerait un
/// lancer supplémentaire par ailleurs évitable, et donc un risque de craque
/// gratuit. Cherche d'abord à garder un 5 de plus (aucune perte de points),
/// puis à en décliner un de plus si la première option n'est pas légale (le
/// profil déclinait déjà tout ce qu'il pouvait) ; sans effet si aucun
/// ajustement légal ne règle le problème (par ex. un seul 5 déclinable sans
/// dé "junk" pour l'accompagner au relancer, où garder-tout est la seule
/// option — voir [RollAnalysis.canDeclineFives]).
int _avoidEndingIn50(
  TurnState turn,
  RollAnalysis analysis,
  ScoringGroup fives,
  int declineCount,
) {
  // applyKeepDecision exige que pendingRoll soit déjà posé sur l'état passé :
  // toujours vrai côté appelant réel (analysis vient de turn.pendingRoll!,
  // voir GameNotifier.playAiTurnStep), mais pas garanti par le type de
  // [turn] lui-même — on le pose explicitement plutôt que de dépendre de ce
  // couplage implicite.
  final withRoll = turn.copyWith(pendingRoll: analysis);
  bool endsIn50(int decline) => applyKeepDecision(withRoll, declineFivesCount: decline).bankedScore % 100 == 50;
  if (!endsIn50(declineCount)) return declineCount;
  final maxDecline = _maxDeclinable(analysis, fives);
  if (declineCount > 0 && !endsIn50(declineCount - 1)) return declineCount - 1;
  if (declineCount < maxDecline && !endsIn50(declineCount + 1)) return declineCount + 1;
  return declineCount;
}

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

/// Probabilité de marquer au moins un point sur un lancer de [diceCount] dés
/// (complément exact de [bustProbability]), sous forme de fraction
/// irréductible (numérateur, dénominateur) plutôt qu'un flottant : utile
/// pour un affichage lisible façon "1/2" à l'écran.
(int, int) scoreProbabilityFraction(int diceCount, Set<int> extendedValues) {
  if (diceCount <= 0) return (0, 1);
  final total = pow(6, diceCount).toInt();
  var scoreCount = 0;
  final faces = List<int>.filled(diceCount, 1);
  for (var i = 0; i < total; i++) {
    var rem = i;
    for (var d = 0; d < diceCount; d++) {
      faces[d] = (rem % 6) + 1;
      rem ~/= 6;
    }
    if (analyzeRoll(faces, extendedValues: extendedValues).hasAnyScore) scoreCount++;
  }
  final divisor = _gcd(scoreCount, total);
  return (scoreCount ~/ divisor, total ~/ divisor);
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

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

/// Prudent : ne rejette jamais un 5 de son propre chef (préfère sécuriser
/// les points) — sauf si les garder tous finirait sur un score en 50, où
/// décliner le dernier 5 reste le seul moyen de rester sur une position dont
/// on peut s'arrêter — et s'arrête dès que le risque de craquer au prochain
/// lancer dépasse 25%, une marge resserrée d'autant si un nouveau craque
/// barrerait la ligne courante (voir [_withinRiskBudget]).
class CautiousAi implements AiStrategy {
  const CautiousAi();

  @override
  int decideDeclineFives(RollAnalysis analysis, TurnState state) {
    final fives = analysis.declinableFives;
    if (fives == null || !analysis.canDeclineFives) return 0;
    return _avoidEndingIn50(state, analysis, fives, 0);
  }

  @override
  bool decideContinue({
    required TurnState state,
    required int minimumRequired,
    required int currentTotalScore,
    required int barLossIfBusted,
  }) {
    return _withinRiskBudget(state, baseMaxRisk: 0.25, barLossIfBusted: barLossIfBusted);
  }

  @override
  bool decideAcceptInheritedHand({
    required int diceCount,
    required Set<int> extendedValues,
    required int inheritedScore,
    required int currentTotalScore,
  }) {
    // À 0, aucune perte possible à tenter la reprise : la reprise est
    // toujours acceptée. Sinon, seulement si le risque de craquer sur ce
    // premier lancer reste dans la marge habituelle du profil.
    if (currentTotalScore == 0) return true;
    return bustProbability(diceCount, extendedValues) <= 0.25;
  }
}

/// Équilibré : rejette un 5 isolé seulement si cela laisse un lot d'au moins
/// 3 dés à relancer (bonnes chances de combo), quitte à en garder un de plus
/// si ce choix finirait sur un score en 50, et pousse sa chance jusqu'à un
/// risque de craque de 45%, une marge resserrée d'autant si un nouveau
/// craque barrerait la ligne courante (voir [_withinRiskBudget]).
class BalancedAi implements AiStrategy {
  const BalancedAi();

  @override
  int decideDeclineFives(RollAnalysis analysis, TurnState state) {
    final fives = analysis.declinableFives;
    if (fives == null || !analysis.canDeclineFives) return 0;
    final rerollPoolIfDeclined = analysis.junkDiceCount + fives.diceCount;
    final baseline = rerollPoolIfDeclined >= 3 ? _maxDeclinable(analysis, fives) : 0;
    return _avoidEndingIn50(state, analysis, fives, baseline);
  }

  @override
  bool decideContinue({
    required TurnState state,
    required int minimumRequired,
    required int currentTotalScore,
    required int barLossIfBusted,
  }) {
    return _withinRiskBudget(state, baseMaxRisk: 0.45, barLossIfBusted: barLossIfBusted);
  }

  @override
  bool decideAcceptInheritedHand({
    required int diceCount,
    required Set<int> extendedValues,
    required int inheritedScore,
    required int currentTotalScore,
  }) {
    if (currentTotalScore == 0) return true;
    return bustProbability(diceCount, extendedValues) <= 0.45;
  }
}

/// Agressif : rejette systématiquement les 5 isolés dès que possible pour
/// chercher de plus gros combos (quitte à en garder un de plus si tout
/// décliner finirait quand même sur un score en 50), et pousse sa chance
/// jusqu'à un risque de craque de 65%, une marge resserrée d'autant si un
/// nouveau craque barrerait la ligne courante (voir [_withinRiskBudget]).
class AggressiveAi implements AiStrategy {
  const AggressiveAi();

  @override
  int decideDeclineFives(RollAnalysis analysis, TurnState state) {
    final fives = analysis.declinableFives;
    if (fives == null || !analysis.canDeclineFives) return 0;
    return _avoidEndingIn50(state, analysis, fives, _maxDeclinable(analysis, fives));
  }

  @override
  bool decideContinue({
    required TurnState state,
    required int minimumRequired,
    required int currentTotalScore,
    required int barLossIfBusted,
  }) {
    return _withinRiskBudget(state, baseMaxRisk: 0.65, barLossIfBusted: barLossIfBusted);
  }

  @override
  bool decideAcceptInheritedHand({
    required int diceCount,
    required Set<int> extendedValues,
    required int inheritedScore,
    required int currentTotalScore,
  }) {
    if (currentTotalScore == 0) return true;
    return bustProbability(diceCount, extendedValues) <= 0.65;
  }
}
