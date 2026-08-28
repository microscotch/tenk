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
}
