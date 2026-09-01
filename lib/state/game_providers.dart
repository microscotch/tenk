import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/ai/ai_profiles.dart';
import '../game/ai/ai_strategy.dart';
import '../game/game_engine.dart';
import '../game/game_recording.dart';
import '../game/game_setup.dart';
import '../game/turn_result.dart';
import '../game/turn_state.dart';
import 'game_save_store.dart';

export '../game/game_setup.dart' show GameSetup;

final gameProvider = NotifierProvider<GameNotifier, GameEngine?>(GameNotifier.new);

class GameNotifier extends Notifier<GameEngine?> {
  /// Config courante, dans l'ordre de jeu réordonné (index 0 = vainqueur du
  /// départage) — sert aux lookups IA/auto par index de joueur courant.
  GameSetup? _setup;

  /// Config d'origine, telle que saisie avant le départage (non réordonnée)
  /// — c'est elle qui doit être persistée : `replayGame` réordonne lui-même
  /// une fois le départage rejoué, donc persister la version déjà réordonnée
  /// la ferait réordonner une seconde fois à la reprise.
  GameSetup? _originalSetup;

  int? _seed;
  Random? _random;
  String? _alias;
  DateTime? _createdAt;
  DateTime? _enteredPlayAt;
  final List<GameAction> _actions = [];

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

  /// Démarre la partie principale une fois le départage résolu. [handoff],
  /// quand fourni (partie réellement jouée, pas un test), transmet la
  /// seed/le générateur/le journal accumulés pendant le départage : voir
  /// [GameRecordingHandoff] pour pourquoi c'est la même instance de
  /// [Random], pas seulement la même seed, qui doit continuer d'être
  /// consommée.
  void startGame(GameSetup setup, {GameRecordingHandoff? handoff}) {
    _setup = setup;
    if (handoff != null) {
      _originalSetup = handoff.originalSetup;
      _seed = handoff.seed;
      _random = handoff.random;
      _alias = handoff.alias;
      _createdAt = handoff.createdAt;
      _actions
        ..clear()
        ..addAll(handoff.actions);
    }
    _enteredPlayAt = DateTime.now();
    final action = GameAction.startTurn(useFullHand: false, at: _enteredPlayAt);
    state = GameEngine.newGame(setup.playerNames).startTurn();
    _record(action);
  }

  /// Reprend une partie en pause : rejoue son journal d'actions (voir
  /// `lib/game/game_recording.dart`) pour reconstruire l'état exact où elle
  /// avait été laissée, puis continue de consommer le même flux aléatoire
  /// pour la suite.
  void resumeFromSave(SavedGame saved) {
    final replay = replayGame(saved.setup, saved.seed, saved.actions);
    assert(replay.engine != null, 'une sauvegarde ne devrait jamais être persistée avant la fin du départage');

    _setup = replay.rotatedSetup;
    _originalSetup = saved.setup;
    _seed = saved.seed;
    _random = replay.random;
    _alias = saved.alias;
    _createdAt = saved.createdAt;
    _enteredPlayAt = saved.enteredPlayAt;
    _actions
      ..clear()
      ..addAll(saved.actions);
    state = replay.engine;
  }

  // Rejeu (spectateur) d'un run archivé : lecture seule, aucune écriture —
  // `_seed` n'est jamais posée sur ce chemin, donc `_record`/la persistance
  // ne sont jamais impliqués.
  bool _isReplay = false;
  List<GameAction> _replayQueue = const [];
  Random? _replayRandom;

  bool get isReplay => _isReplay;
  bool get hasNextReplayAction => _replayQueue.isNotEmpty;

  /// Démarre le rejeu de la partie principale une fois le départage rejoué
  /// (voir `DiceOffNotifier.startReplay`/`replayHandoff`) : même principe que
  /// [startGame], mais sans seed donc sans aucune persistance.
  void startGameReplay(GameSetup rotatedSetup, GameRecordingHandoff handoff) {
    _setup = rotatedSetup;
    _isReplay = true;
    _replayRandom = handoff.random;
    _replayQueue = List.of(handoff.actions);
    state = GameEngine.newGame(rotatedSetup.playerNames);
  }

  /// Applique la prochaine action du journal de rejeu, via le même dispatch
  /// que [replayGame] (voir [applyGameAction]), sans jamais persister.
  void applyNextReplayAction() {
    if (_replayQueue.isEmpty) return;
    final action = _replayQueue.removeAt(0);
    state = applyGameAction(state!, action, _replayRandom!);
  }

  /// Charge un état de partie déjà construit, sans passer par [startGame].
  /// Réservé aux tests, pour vérifier des scénarios (craque, victoire...)
  /// sans dépendre de vrais lancers de dés aléatoires. N'active aucune
  /// persistance (pas de seed).
  @visibleForTesting
  void debugLoadState(GameEngine engine, GameSetup setup) {
    _setup = setup;
    state = engine;
  }

  void roll() {
    state = state!.roll(random: _random);
    _record(GameAction.roll());
  }

  void applyKeep({int declineFivesCount = 0}) {
    state = state!.applyKeep(declineFivesCount: declineFivesCount);
    _record(GameAction.applyKeep(declineFivesCount: declineFivesCount));
  }

  void endBustedTurn() {
    // Un craque remet toujours à 5 dés neufs : aucun choix de main possible.
    final ended = state!.endBustedTurn();
    state = ended.gameOver ? ended : ended.startTurn();
    _record(GameAction.endBustedTurn());
    if (!ended.gameOver) {
      _record(GameAction.startTurn(useFullHand: false));
    }
  }

  BankAttempt bank() {
    final (engine, attempt) = state!.bank();
    if (attempt.success) {
      // `state` DOIT déjà refléter `engine` avant `_record` : elle décide
      // persister-vs-supprimer d'après `state!.gameOver`, qui lirait sinon
      // encore l'ancien état (pré-banquage) et ne supprimerait jamais la
      // sauvegarde du coup qui fait gagner la partie.
      state = engine;
      _record(GameAction.bank());
      if (!engine.gameOver && engine.nextTurnDice >= 5) {
        // Aucun dé hérité pour le joueur suivant (cas limite) : pas de choix
        // de main à proposer, son tour démarre directement.
        state = engine.startTurn();
        _record(GameAction.startTurn(useFullHand: false));
      }
      // Sinon : gameOver (rien de plus à faire), ou le joueur suivant hérite
      // de dés d'un tour précédent — activeTurn reste à null en attendant
      // son choix (cf. [startTurn]).
    }
    return attempt;
  }

  /// À appeler quand le joueur courant doit choisir entre hériter des dés
  /// du tour précédent ou repartir avec une main pleine de 5 dés neufs
  /// (state.activeTurn est alors null, cf. [bank]).
  void startTurn({required bool useFullHand}) {
    state = state!.startTurn(useFullHand: useFullHand);
    _record(GameAction.startTurn(useFullHand: useFullHand));
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
      final attempt = tryBank(
        turn,
        minimumRequired: engine.minimumForCurrentPlayer,
        currentTotal: engine.currentPlayer.totalScore,
      );
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

  /// Chaîne chaque écriture/suppression sur la précédente : deux transitions
  /// rapprochées (ex: coups IA enchaînés) déclenchent chacune une
  /// persistance fire-and-forget, et sans cette sérialisation deux écritures
  /// concurrentes sur le même fichier `.tmp` peuvent se marcher dessus
  /// (`PathNotFoundException` au renommage, l'une ayant déjà consommé le
  /// fichier temporaire de l'autre).
  Future<void> _persistChain = Future.value();

  /// Journalise [action] puis persiste (ou archive dans `over/` et retire de
  /// `in-progress/`, si la partie vient de se terminer) la sauvegarde
  /// correspondante. Sans seed (ex: [debugLoadState] en test), ne fait
  /// rien : il n'y a pas de partie à persister.
  void _record(GameAction action) {
    _actions.add(action);
    if (_seed == null) return;
    // .catchError avale l'échec d'UNE persistance (ex: disque plein) sans
    // jamais laisser la chaîne elle-même rejetée — sinon, plus aucune
    // sauvegarde suivante ne s'exécuterait (.then court-circuite sur une
    // future rejetée).
    if (state!.gameOver) {
      _persistChain = _persistChain.then((_) => _archiveAndRemove()).catchError((_) {});
    } else {
      _persistChain = _persistChain.then((_) => _persist()).catchError((_) {});
    }
  }

  SavedGame _currentSavedGame() => SavedGame(
        seed: _seed!,
        setup: _originalSetup!,
        alias: _alias ?? '',
        createdAt: _createdAt ?? DateTime.now(),
        enteredPlayAt: _enteredPlayAt,
        durationSeconds: durationSecondsFor(_actions),
        actions: List.unmodifiable(_actions),
      );

  Future<void> _persist() async {
    await ref.read(gameSaveStoreProvider).write(_currentSavedGame());
  }

  /// Une partie terminée n'est plus "en pause" : son fichier passe de
  /// `in-progress/` à `over/` (archivage) au lieu d'être simplement effacé,
  /// pour rester rejouable depuis la zone "Runs terminés".
  Future<void> _archiveAndRemove() async {
    await ref.read(archivedGameSaveStoreProvider).write(_currentSavedGame());
    await ref.read(gameSaveStoreProvider).delete(_seed!);
  }
}
