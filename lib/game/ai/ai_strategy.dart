import '../combination.dart';
import '../turn_state.dart';

/// Stratégie de décision pour un joueur contrôlé par l'IA.
abstract class AiStrategy {
  /// Décide combien de 5 isolés déclinables rejeter (0 = aucun rejet) à
  /// partir de l'analyse du lancer en attente de décision.
  int decideDeclineFives(RollAnalysis analysis, TurnState state);

  /// Décide si l'IA continue volontairement à lancer les dés alors qu'elle
  /// pourrait légalement s'arrêter (l'appelant ne pose la question que
  /// lorsque banquer est effectivement une option légale).
  bool decideContinue({
    required TurnState state,
    required int minimumRequired,
    required int currentTotalScore,
  });

  /// Décide si l'IA accepte de reprendre la main héritée du tour précédent
  /// ([diceCount] dés à relancer, score de base [inheritedScore]) plutôt que
  /// de repartir avec 5 dés neufs. L'appelant garantit que continuer reste
  /// une option légale (ne dépasserait pas 10000 même sans marquer un seul
  /// point de plus).
  bool decideAcceptInheritedHand({
    required int diceCount,
    required Set<int> extendedValues,
    required int inheritedScore,
    required int currentTotalScore,
  });
}
