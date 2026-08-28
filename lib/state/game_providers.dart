import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/ai/ai_profiles.dart';
import '../game/ai/ai_strategy.dart';
import '../game/game_engine.dart';
import '../game/turn_result.dart';
import '../game/turn_state.dart';

/// Configuration d'une partie : les noms des joueurs, et pour chacun
/// éventuellement une difficulté d'IA (absent d'index = joueur humain).
class GameSetup {
  final List<String> playerNames;
  final Map<int, AiDifficulty> aiPlayers;

  const GameSetup({required this.playerNames, this.aiPlayers = const {}});

  bool isAi(int index) => aiPlayers.containsKey(index);
}

final gameProvider = NotifierProvider<GameNotifier, GameEngine?>(GameNotifier.new);

class GameNotifier extends Notifier<GameEngine?> {
  GameSetup? _setup;

  @override
  GameEngine? build() => null;

  bool isAiPlayer(int index) => _setup?.isAi(index) ?? false;

  /// Vrai s'il s'agit d'une partie pass-and-play pure (aucun joueur IA),
  /// auquel cas les transitions entre joueurs doivent afficher l'écran
  /// "passez l'appareil".
  bool get isPassAndPlayMode => _setup?.aiPlayers.isEmpty ?? true;

  void startGame(GameSetup setup) {
    _setup = setup;
    state = GameEngine.newGame(setup.playerNames).startTurn();
  }

  void roll() {
    state = state!.roll();
  }

  void applyKeep({int declineFivesCount = 0}) {
    state = state!.applyKeep(declineFivesCount: declineFivesCount);
  }

  void endBustedTurn() {
    final ended = state!.endBustedTurn();
    state = ended.gameOver ? ended : ended.startTurn();
  }

  BankAttempt bank() {
    final (engine, attempt) = state!.bank();
    if (attempt.success) {
      state = engine.gameOver ? engine : engine.startTurn();
    }
    return attempt;
  }

  /// Joue une unique action du tour du joueur IA courant (un lancer, une
  /// décision de garde, ou un banquage/craque). L'appelant (UI) répète les
  /// appels avec un délai pour créer un effet de "réflexion" de l'IA,
  /// jusqu'à ce que la main passe à un autre joueur.
  void playAiTurnStep() {
    final engine = state!;
    final turn = engine.activeTurn!;

    if (turn.busted) {
      endBustedTurn();
      return;
    }

    if (turn.pendingRoll != null) {
      final strategy = _currentStrategy();
      final decline = strategy.decideDeclineFives(turn.pendingRoll!, turn);
      applyKeep(declineFivesCount: decline);
      return;
    }

    if (!turn.mustContinue) {
      final attempt = tryBank(turn, minimumRequired: engine.minimumForCurrentPlayer);
      if (attempt.success) {
        final strategy = _currentStrategy();
        final wantsToContinue = strategy.decideContinue(
          state: turn,
          minimumRequired: engine.minimumForCurrentPlayer,
          currentTotalScore: engine.currentPlayer.totalScore,
        );
        if (!wantsToContinue) {
          bank();
          return;
        }
      }
    }

    roll();
  }

  AiStrategy _currentStrategy() {
    final difficulty = _setup!.aiPlayers[state!.currentPlayerIndex]!;
    return aiStrategyFor(difficulty);
  }
}
