import '../game_engine.dart';
import '../game_recording.dart';
import '../player.dart' show winningScore;
import '../turn_state.dart';
import 'ai_strategy.dart';

/// Le prochain coup d'un joueur joué par [strategy], quand c'est à lui de
/// jouer dans [engine] : une seule action à la fois (démarrer son tour,
/// acquitter un craque, trancher un lancer, s'arrêter ou relancer). Pure : le
/// même calcul sert au bot local (`GameNotifier.playAiTurnStep`) et au bot de
/// siège du serveur, qui joue pour un joueur parti d'une partie en ligne.
///
/// L'action rendue est datée de maintenant, sans faces : à l'appelant de la
/// jouer (et de tirer les dés d'un lancer).
GameAction nextAiMove(GameEngine engine, AiStrategy strategy) {
  final turn = engine.activeTurn;
  if (turn == null) {
    return GameAction.startTurn(useFullHand: !aiAcceptsInheritedHand(engine, strategy));
  }
  if (turn.busted) return GameAction.endBustedTurn();
  if (turn.pendingRoll != null) {
    return GameAction.applyKeep(declineFivesCount: aiDeclineFives(engine, turn, strategy));
  }
  if (!turn.mustContinue) {
    final attempt = tryBank(
      turn,
      minimumRequired: engine.minimumForCurrentPlayer,
      currentTotal: engine.currentPlayer.totalScore,
      isFinalRound: engine.isInFinalRound,
    );
    // Pile sur 10000 : la seule prise sensée, jamais une question de
    // stratégie — on ne consulte pas [aiContinues] dans ce cas (voir
    // winningDeclineFivesCount, déjà appliqué par [aiDeclineFives] pour en
    // arriver là).
    final reachedTarget = engine.currentPlayer.totalScore + turn.bankedScore == winningScore;
    if (attempt.success && (reachedTarget || !aiContinues(engine, turn, strategy))) {
      return GameAction.bank();
    }
  }
  return GameAction.roll();
}

/// Si [strategy] accepterait la main héritée en attente dans [engine] : jamais
/// quand elle ne peut plus être encaissée (voir
/// [GameEngine.inheritedHandCannotBank]), sinon selon le profil.
bool aiAcceptsInheritedHand(GameEngine engine, AiStrategy strategy) {
  if (engine.inheritedHandCannotBank) return false;
  return strategy.decideAcceptInheritedHand(
    diceCount: engine.nextTurnDice,
    extendedValues: engine.inheritedExtendedValues,
    inheritedScore: engine.inheritedScore,
    currentTotalScore: engine.currentPlayer.totalScore,
  );
}

/// Nombre de 5 que [strategy] déclinerait sur le lancer en attente de [turn].
///
/// La stratégie raisonne sur le seul tour en cours : elle ignore le score déjà
/// acquis par le joueur, et donc le plafond de 10000. Sa réponse est donc
/// bornée ici, au seul endroit qui connaît les deux — exactement les mêmes
/// bornes que celles proposées à un joueur humain, pour que les deux jouent la
/// même règle. Atteindre exactement 10000 est imposé avant même de consulter
/// le profil (voir [winningDeclineFivesCount]).
int aiDeclineFives(GameEngine engine, TurnState turn, AiStrategy strategy) {
  final analysis = turn.pendingRoll!;
  final currentTotal = engine.currentPlayer.totalScore;
  final winningDecline = winningDeclineFivesCount(turn, analysis, currentTotal: currentTotal);
  if (winningDecline != null) return winningDecline;
  final fives = analysis.declinableFives?.diceCount ?? 0;
  final minKeep = minKeepableFives(analysis);
  final maxKeep = maxKeepableFives(turn, analysis, currentTotal: currentTotal);
  final wantedKeep = fives - strategy.decideDeclineFives(analysis, turn);
  final keep = wantedKeep.clamp(minKeep, maxKeep < minKeep ? minKeep : maxKeep);
  return fives - keep;
}

/// Si [strategy] continuerait à lancer plutôt que de s'arrêter sur [turn]
/// (l'appelant garantit que s'arrêter y est légal).
bool aiContinues(GameEngine engine, TurnState turn, AiStrategy strategy) {
  final player = engine.currentPlayer;
  return strategy.decideContinue(
    state: turn,
    minimumRequired: engine.minimumForCurrentPlayer,
    currentTotalScore: player.totalScore,
    // Ligne courante déjà tiretée : un nouveau craque la barrerait, retombant
    // sur le score précédent plutôt que de juste marquer un second tiret (voir
    // Player.applyBust).
    barLossIfBusted: player.hasTiret ? player.totalScore - player.previousScore : 0,
  );
}
