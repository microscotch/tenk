import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/ai/ai_profiles.dart';
import '../game/ai/ai_strategy.dart';
import '../game/game_engine.dart';
import '../game/turn_result.dart';
import '../game/turn_state.dart';

/// Configuration d'une partie : les noms des joueurs, pour chacun
/// éventuellement une difficulté d'IA (absent d'index = joueur humain), et
/// l'ensemble des joueurs en "mode auto" (leurs actions se valident seules
/// après le délai réglé dans les préférences ; sinon un bouton explicite
/// attend toujours un clic manuel).
class GameSetup {
  final List<String> playerNames;
  final Map<int, AiDifficulty> aiPlayers;
  final Set<int> autoPlayers;

  const GameSetup({required this.playerNames, this.aiPlayers = const {}, this.autoPlayers = const {}});

  bool isAi(int index) => aiPlayers.containsKey(index);
  bool isAuto(int index) => autoPlayers.contains(index);
}

final gameProvider = NotifierProvider<GameNotifier, GameEngine?>(GameNotifier.new);

class GameNotifier extends Notifier<GameEngine?> {
  GameSetup? _setup;

  @override
  GameEngine? build() => null;

  bool isAiPlayer(int index) => _setup?.isAi(index) ?? false;

  /// Vrai si les actions du joueur [index] doivent se valider seules après
  /// le délai réglé dans les préférences (sinon elles attendent toujours un
  /// clic manuel sur le bouton, quel que soit ce délai).
  bool isAutoPlayer(int index) => _setup?.isAuto(index) ?? false;

  /// Nombre de joueurs humains dans la partie (les autres sont des bots IA).
  int get humanPlayerCount => (_setup?.playerNames.length ?? 0) - (_setup?.aiPlayers.length ?? 0);

  /// Vrai si passer la main au joueur [index] doit afficher l'écran "passez
  /// l'appareil" : c'est un humain, et il y a plus d'un joueur humain dans la
  /// partie (sinon l'appareil est déjà devant la bonne personne).
  bool shouldShowPassDevice(int index) => !isAiPlayer(index) && humanPlayerCount > 1;

  void startGame(GameSetup setup) {
    _setup = setup;
    state = GameEngine.newGame(setup.playerNames).startTurn();
  }

  /// Charge un état de partie déjà construit, sans passer par [startGame].
  /// Réservé aux tests, pour vérifier des scénarios (craque, victoire...)
  /// sans dépendre de vrais lancers de dés aléatoires.
  @visibleForTesting
  void debugLoadState(GameEngine engine, GameSetup setup) {
    _setup = setup;
    state = engine;
  }

  void roll() {
    state = state!.roll();
  }

  void applyKeep({int declineFivesCount = 0}) {
    state = state!.applyKeep(declineFivesCount: declineFivesCount);
  }

  void endBustedTurn() {
    // Un craque remet toujours à 5 dés neufs : aucun choix de main possible.
    final ended = state!.endBustedTurn();
    state = ended.gameOver ? ended : ended.startTurn();
  }

  BankAttempt bank() {
    final (engine, attempt) = state!.bank();
    if (attempt.success) {
      if (engine.gameOver) {
        state = engine;
      } else if (engine.nextTurnDice < 5) {
        // Le joueur suivant hérite de dés d'un tour précédent : on laisse
        // activeTurn à null en attendant son choix (cf. [startTurn]).
        state = engine;
      } else {
        state = engine.startTurn();
      }
    }
    return attempt;
  }

  /// À appeler quand le joueur courant doit choisir entre hériter des dés
  /// du tour précédent ou repartir avec une main pleine de 5 dés neufs
  /// (state.activeTurn est alors null, cf. [bank]).
  void startTurn({required bool useFullHand}) {
    state = state!.startTurn(useFullHand: useFullHand);
  }

  /// Joue une unique action du tour du joueur IA courant (un lancer, une
  /// décision de garde, ou un banquage/craque). L'appelant (UI) répète les
  /// appels avec un délai pour créer un effet de "réflexion" de l'IA,
  /// jusqu'à ce que la main passe à un autre joueur.
  void playAiTurnStep() {
    final engine = state!;

    if (engine.activeTurn == null) {
      startTurn(useFullHand: !previewAiAcceptInheritedHand());
      return;
    }

    final turn = engine.activeTurn!;

    if (turn.busted) {
      endBustedTurn();
      return;
    }

    if (turn.pendingRoll != null) {
      applyKeep(declineFivesCount: _currentStrategy().decideDeclineFives(turn.pendingRoll!, turn));
      return;
    }

    if (!turn.mustContinue) {
      final attempt = tryBank(turn, minimumRequired: engine.minimumForCurrentPlayer);
      if (attempt.success && !previewAiContinue(turn)) {
        bank();
        return;
      }
    }

    roll();
  }

  /// Prévisualise, sans rien modifier, si l'IA du joueur courant accepterait
  /// la main héritée en attente (score de base déjà au-delà de 10000, ou
  /// risque trop élevé pour son profil sinon). Utilisé à la fois par
  /// [playAiTurnStep] et par l'UI pour afficher un libellé de bouton explicite
  /// avant que la décision ne s'exécute.
  bool previewAiAcceptInheritedHand() {
    final engine = state!;
    if (engine.inheritedHandExceedsWinningScore) return false;
    return _currentStrategy().decideAcceptInheritedHand(
      diceCount: engine.nextTurnDice,
      extendedValues: engine.inheritedExtendedValues,
      inheritedScore: engine.inheritedScore,
      currentTotalScore: engine.currentPlayer.totalScore,
    );
  }

  /// Prévisualise si l'IA du joueur courant choisirait de continuer à
  /// lancer plutôt que de s'arrêter sur [turn] (l'appelant garantit que
  /// s'arrêter y est déjà légal). Même rôle que [previewAiAcceptInheritedHand]
  /// pour cette autre décision.
  bool previewAiContinue(TurnState turn) {
    return _currentStrategy().decideContinue(
      state: turn,
      minimumRequired: state!.minimumForCurrentPlayer,
      currentTotalScore: state!.currentPlayer.totalScore,
    );
  }

  AiStrategy _currentStrategy() {
    final difficulty = _setup!.aiPlayers[state!.currentPlayerIndex]!;
    return aiStrategyFor(difficulty);
  }
}
