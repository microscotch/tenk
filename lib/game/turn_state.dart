import 'dart:math';

import 'combination.dart';
import 'dice_roll.dart';
import 'turn_result.dart';

/// État immuable d'un tour en cours. Un tour s'étend sur un ou plusieurs
/// lancers ; chaque lancer produit une [RollAnalysis] en attente de décision
/// ([pendingRoll]) tant que le joueur n'a pas choisi quels dés garder.
class TurnState {
  /// Nombre de dés à lancer au prochain lancer.
  final int diceToRoll;

  /// Score accumulé et verrouillé ce tour (hors lancer en attente de décision).
  final int bankedScore;

  /// Valeurs pour lesquelles un brelan/carré a déjà été encaissé ce tour
  /// (déclenche la règle d'extension sur les lancers suivants).
  final Set<int> extendedValues;

  /// Analyse du dernier lancer, en attente d'une décision du joueur
  /// (null si aucun lancer n'est en attente, par ex. juste après l'application
  /// d'une décision, ou en tout début de tour).
  final RollAnalysis? pendingRoll;

  /// True juste après un lancer où tous les dés ont scoré ("dés chauds") :
  /// le joueur est obligé de relancer, il ne peut pas s'arrêter.
  final bool mustContinue;

  /// True si le tour est terminé (craque). Un tour se termine aussi
  /// "normalement" par un banquage explicite, géré au niveau du moteur de
  /// partie (GameEngine), pas ici.
  final bool busted;

  const TurnState({
    required this.diceToRoll,
    this.bankedScore = 0,
    this.extendedValues = const {},
    this.pendingRoll,
    this.mustContinue = false,
    this.busted = false,
  });

  factory TurnState.initial(int diceToRoll) => TurnState(diceToRoll: diceToRoll);

  bool get isOver => busted;

  int get turnScoreEndsIn50 => bankedScore % 100;

  TurnState copyWith({
    int? diceToRoll,
    int? bankedScore,
    Set<int>? extendedValues,
    RollAnalysis? pendingRoll,
    bool clearPendingRoll = false,
    bool? mustContinue,
    bool? busted,
  }) {
    return TurnState(
      diceToRoll: diceToRoll ?? this.diceToRoll,
      bankedScore: bankedScore ?? this.bankedScore,
      extendedValues: extendedValues ?? this.extendedValues,
      pendingRoll: clearPendingRoll ? null : (pendingRoll ?? this.pendingRoll),
      mustContinue: mustContinue ?? this.mustContinue,
      busted: busted ?? this.busted,
    );
  }
}

/// Effectue un lancer des dés disponibles de [state] et retourne le nouvel
/// état avec l'analyse en attente de décision. Si le lancer ne rapporte
/// aucun point, le tour se termine immédiatement en craque.
TurnState rollTurn(TurnState state, {Random? random}) {
  if (state.pendingRoll != null) {
    throw StateError('Une décision est en attente sur le lancer précédent');
  }
  if (state.busted) {
    throw StateError('Le tour est terminé');
  }

  final faces = rollDice(state.diceToRoll, random);
  final analysis = analyzeRoll(faces, extendedValues: state.extendedValues);

  if (!analysis.hasAnyScore) {
    return state.copyWith(pendingRoll: analysis, busted: true);
  }
  return state.copyWith(pendingRoll: analysis);
}

/// Applique la décision du joueur sur le lancer en attente : combien de 5
/// isolés (parmi ceux déclinables) il choisit de ne PAS garder pour les
/// relancer avec les dés non-marquants.
TurnState applyKeepDecision(TurnState state, {int declineFivesCount = 0}) {
  final analysis = state.pendingRoll;
  if (analysis == null) {
    throw StateError('Aucun lancer en attente de décision');
  }
  if (declineFivesCount < 0) {
    throw ArgumentError('declineFivesCount ne peut pas être négatif');
  }

  final fivesGroup = analysis.declinableFives;
  if (declineFivesCount > 0) {
    if (fivesGroup == null || declineFivesCount > fivesGroup.diceCount) {
      throw ArgumentError('Rejet de 5 invalide : aucun 5 déclinable disponible en quantité suffisante');
    }
    if (!analysis.canDeclineFives) {
      throw StateError('Impossible de rejeter un 5 : aucun dé non-marquant à relancer avec');
    }
  }

  var diceKept = 0;
  var roundPoints = 0;
  final newExtended = {...state.extendedValues};

  for (final g in analysis.mandatoryGroups) {
    diceKept += g.diceCount;
    roundPoints += g.points;
    if (!g.isSuite) newExtended.add(g.value);
  }

  if (fivesGroup != null) {
    final keptFivesCount = fivesGroup.diceCount - declineFivesCount;
    if (keptFivesCount > 0) {
      final perDie = fivesGroup.points ~/ fivesGroup.diceCount;
      diceKept += keptFivesCount;
      roundPoints += keptFivesCount * perDie;
    }
  }

  final diceRemaining = analysis.totalDiceRolled - diceKept;
  final hotDice = diceRemaining == 0;

  return state.copyWith(
    diceToRoll: hotDice ? 5 : diceRemaining,
    bankedScore: state.bankedScore + roundPoints,
    extendedValues: newExtended,
    clearPendingRoll: true,
    mustContinue: hotDice,
  );
}

/// Tente de banquer (valider) le score du tour en cours.
BankAttempt tryBank(TurnState state, {required int minimumRequired}) {
  if (state.pendingRoll != null) {
    throw StateError('Une décision est en attente sur le lancer précédent');
  }
  if (state.mustContinue) {
    return const BankAttempt.failure(BankFailureReason.mustContinueHotDice);
  }
  if (state.bankedScore < minimumRequired) {
    return const BankAttempt.failure(BankFailureReason.belowMinimum);
  }
  if (state.turnScoreEndsIn50 == 50) {
    return const BankAttempt.failure(BankFailureReason.endsIn50);
  }
  return BankAttempt.success(state.bankedScore);
}
