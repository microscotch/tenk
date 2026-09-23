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

/// Où en est le rejeu : [turn] tours de joueur déjà joués, sur [count] que
/// compte la partie. Sert de valeur et de borne au curseur du rejeu.
class ReplayProgress {
  final int turn;
  final int count;

  const ReplayProgress({required this.turn, required this.count});
}

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

  /// Seed/config d'origine/journal d'actions de la partie en cours, pour
  /// dériver le journal de partie affiché à l'écran (voir
  /// `game_screen.dart`, `_seedLogFromHistory`) — mêmes valeurs que celles
  /// écrites dans le `.run`, exposées en lecture seule. Toutes nulles/vides
  /// hors partie persistée (ex: `debugLoadState` en test, ou mode rejeu).
  int? get seed => _seed;
  GameSetup? get originalSetup => _originalSetup;

  /// Journal complet (seed, config d'origine, toutes les actions) de la partie
  /// actuellement à l'écran, qu'elle soit jouée ou rejouée — de quoi en
  /// reconstruire la courbe des scores et les statistiques (voir
  /// `score_series.dart`, `game_statistics.dart`). Nul quand aucun journal
  /// n'existe (état chargé par `debugLoadState`).
  ///
  /// Un point d'entrée unique, pour ne jamais lire `seed`/`actions` à la
  /// main : en rejeu ils ne décrivent PAS la partie affichée (voir
  /// [startGameReplay], qui les vide), et les recoller à la main ferait
  /// tracer la courbe d'une autre partie.
  SavedGame? get gameRecord {
    if (_replaySource != null) return _replaySource;
    if (_seed == null || _originalSetup == null) return null;
    return _currentSavedGame();
  }

  /// Le run archivé dont le rejeu est en cours, tel que lu sur disque : seul
  /// endroit où son journal est entier, [GameRecordingHandoff] n'en
  /// transmettant que la fin, après le départage.
  SavedGame? _replaySource;

  /// Config réordonnée par le départage — celle qu'indexent
  /// `currentPlayerIndex` et consorts (voir [currentSeatRightHandedProvider]).
  GameSetup? get orderedSetup => _setup;
  List<GameAction> get actions => List.unmodifiable(_actions);

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
    _isReplay = false;
    _replaySource = null;
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
    _commit(
      GameEngine.newGame(setup.playerNames).startTurn(),
      [GameAction.startTurn(useFullHand: false, at: _enteredPlayAt)],
    );
  }

  /// Reprend une partie en pause : rejoue son journal d'actions (voir
  /// `lib/game/game_recording.dart`) pour reconstruire l'état exact où elle
  /// avait été laissée, puis continue de consommer le même flux aléatoire
  /// pour la suite.
  void resumeFromSave(SavedGame saved) {
    final replay = replayGame(saved.setup, saved.seed, saved.actions);
    assert(replay.engine != null, 'une sauvegarde ne devrait jamais être persistée avant la fin du départage');

    _setup = replay.orderedSetup;
    _isReplay = false;
    _replaySource = null;
    _originalSetup = saved.setup;
    _seed = saved.seed;
    _random = replay.random;
    _alias = saved.alias;
    _createdAt = saved.createdAt;
    _enteredPlayAt = saved.enteredPlayAt;
    _actions
      ..clear()
      ..addAll(saved.actions);
    // Borne l'interruption qui vient de s'achever : sans ce marqueur, le temps
    // passé hors du jeu compterait dans la durée active de la partie (voir
    // [activePlayingSecondsFor]). Posé APRÈS `_seed`, dont la persistance
    // dépend.
    _commit(replay.engine!, [GameAction.resume()]);
  }

  // Rejeu (spectateur) d'un run archivé : lecture seule, aucune écriture —
  // `_seed` n'est jamais posée sur ce chemin, donc `_commit` ne persiste
  // jamais rien.
  bool _isReplay = false;
  List<GameAction> _replayQueue = const [];
  Random? _replayRandom;

  /// Toutes les actions de la partie principale du rejeu (le départage n'en
  /// fait pas partie, on ne le rejoue pas), dont [_replayQueue] est la fin
  /// restant à appliquer.
  List<GameAction> _replayGameActions = const [];

  /// Début de chaque tour dans le journal du run rejoué (voir
  /// [replayTurnStarts]) ; vide sans run source, on ne peut alors pas
  /// naviguer.
  List<int> _replayTurnStarts = const [];

  /// Vrai depuis [startGameReplay] jusqu'à la partie suivante ([startGame],
  /// [resumeFromSave]) : le moteur exposé est alors celui d'un rejeu, que
  /// l'écran de jeu « vivant » resté empilé dessous ne doit pas prendre pour
  /// sa partie (voir `GameScreen`).
  bool get isReplay => _isReplay;
  bool get hasNextReplayAction => _replayQueue.isNotEmpty;

  /// Nombre d'actions du départage en tête du journal du run rejoué : la
  /// partie rejouée commence après.
  int get _replayDiceOffCount => _replaySource == null
      ? 0
      : _replaySource!.actions.length - _replayGameActions.length;

  /// Progression du rejeu en tours de joueur (voir `ReplayProgress`) : le tour
  /// à l'écran, sur le nombre de tours de la partie. Sans run source, ni
  /// progression ni navigation : zéro tour.
  ReplayProgress get replayProgress {
    if (_replayTurnStarts.isEmpty) return const ReplayProgress(turn: 0, count: 0);
    final consumed = _replayDiceOffCount + _replayGameActions.length - _replayQueue.length;
    final started = _replayTurnStarts.where((start) => start <= consumed).length;
    return ReplayProgress(
      turn: started.clamp(1, _replayTurnStarts.length),
      count: _replayTurnStarts.length,
    );
  }

  /// Amène le rejeu au début du tour [turn] (de 1 au nombre de tours), qu'il
  /// soit avant ou après le tour actuel : l'état exact en est reconstruit en
  /// rejouant le journal jusque-là, et le générateur de dés y reprend là où le
  /// journal l'a laissé — la suite du rejeu tombe donc sur les mêmes tirages
  /// que la partie jouée.
  void seekReplay(int turn) {
    final source = _replaySource;
    if (source == null || _replayTurnStarts.isEmpty) return;
    final target = _replayTurnStarts[(turn - 1).clamp(0, _replayTurnStarts.length - 1)];
    final replayed = replayGame(source.setup, source.seed, source.actions.sublist(0, target));
    _replayRandom = replayed.random;
    _replayQueue = _replayGameActions.sublist(target - _replayDiceOffCount);
    state = replayed.engine;
  }

  /// Les actions déjà appliquées du rejeu, départage compris : de quoi en
  /// reconstruire le journal de partie affiché (voir `GameScreen`).
  List<GameAction> get replayAppliedActions {
    final source = _replaySource;
    if (source == null) return const [];
    return source.actions.sublist(0, _replayDiceOffCount + _replayGameActions.length - _replayQueue.length);
  }

  /// La prochaine action du journal de rejeu qui change quelque chose à
  /// l'écran (une reprise de partie n'en est pas une, voir
  /// [applyNextReplayAction]) : de quoi montrer d'avance, sur la popup de
  /// reprise de main, le choix que le joueur va faire.
  GameAction? get nextReplayAction {
    for (final action in _replayQueue) {
      if (action.type != GameActionType.resume) return action;
    }
    return null;
  }

  /// Démarre le rejeu de la partie principale (voir [startReplay], qui le fait
  /// depuis un run archivé) : même principe que [startGame], mais sans seed
  /// donc sans aucune persistance.
  ///
  /// [source] est le run archivé rejoué, pour [gameRecord]. Les champs de la
  /// partie « vivante » sont vidés au passage : ils gardaient sinon la
  /// dernière partie jouée dans la session, que [gameRecord] aurait prise
  /// pour celle qu'on regarde.
  void startGameReplay(GameSetup orderedSetup, GameRecordingHandoff handoff, {SavedGame? source}) {
    _setup = orderedSetup;
    _isReplay = true;
    _replaySource = source;
    _seed = null;
    _originalSetup = null;
    _actions.clear();
    _replayRandom = handoff.random;
    _replayGameActions = List.unmodifiable(handoff.actions);
    _replayQueue = List.of(handoff.actions);
    // Un journal qui se rejoue mal n'empêche pas de regarder ce qui peut l'être :
    // seule la navigation par tour en fait les frais.
    List<int> starts = const [];
    if (source != null) {
      try {
        starts = replayTurnStarts(source.setup, source.seed, source.actions);
      } catch (_) {
        starts = const [];
      }
    }
    _replayTurnStarts = starts;
    state = GameEngine.newGame(orderedSetup.playerNames);
  }

  /// Démarre le rejeu de [saved], un run archivé, directement sur sa partie :
  /// le départage qui a fixé l'ordre de jeu n'est pas remis en scène, on n'en
  /// garde que le résultat (qui commence, et le générateur de dés dans l'état
  /// où il laisse la partie).
  void startReplay(SavedGame saved) {
    final diceOffCount = diceOffActionCount(saved.actions);
    final afterDiceOff = replayGame(saved.setup, saved.seed, saved.actions.sublist(0, diceOffCount));
    final orderedSetup = afterDiceOff.orderedSetup;
    if (orderedSetup == null) {
      throw StateError('le départage de ce run n\'est pas résolu : il n\'y a pas de partie à rejouer');
    }
    startGameReplay(
      orderedSetup,
      GameRecordingHandoff(
        seed: 0,
        random: afterDiceOff.random,
        originalSetup: saved.setup,
        alias: '',
        createdAt: saved.createdAt,
        actions: saved.actions.sublist(diceOffCount),
      ),
      source: saved,
    );
  }

  /// Applique la prochaine action du journal de rejeu, via le même dispatch
  /// que [replayGame] (voir [applyGameAction]), sans jamais persister.
  void applyNextReplayAction() {
    if (_replayQueue.isEmpty) return;
    final action = _replayQueue.removeAt(0);
    // Une reprise ne change rien à l'écran : la consommer sans y passer un
    // tic de temporisation, sinon le rejeu spectateur marquerait une pause
    // inexpliquée là où le joueur avait simplement fermé l'app.
    if (action.type == GameActionType.resume) {
      applyNextReplayAction();
      return;
    }
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

  void roll() => _commit(state!.roll(random: _random), [GameAction.roll()]);

  void applyKeep({int declineFivesCount = 0}) => _commit(
        state!.applyKeep(declineFivesCount: declineFivesCount),
        [GameAction.applyKeep(declineFivesCount: declineFivesCount)],
      );

  void endBustedTurn() {
    // Un craque remet toujours à 5 dés neufs : aucun choix de main possible.
    final ended = state!.endBustedTurn();
    _commit(
      ended.gameOver ? ended : ended.startTurn(),
      [
        GameAction.endBustedTurn(),
        if (!ended.gameOver) GameAction.startTurn(useFullHand: false),
      ],
    );
  }

  BankAttempt bank() {
    final (engine, attempt) = state!.bank();
    if (attempt.success) {
      _commit(engine, [GameAction.bank()]);
      if (!engine.gameOver && (engine.nextTurnDice >= 5 || engine.inheritedHandCannotBank)) {
        // Le joueur suivant n'a aucun choix de main à faire : soit il n'hérite
        // d'aucun dé (cas limite), soit la main héritée ne pourrait plus
        // banquer (voir [GameEngine.inheritedHandCannotBank]) et repartir à 5
        // dés neufs est sa seule suite jouable. Son tour démarre donc
        // directement, sans lui poser une question à une seule réponse.
        final useFullHand = engine.inheritedHandCannotBank;
        _commit(engine.startTurn(useFullHand: useFullHand), [GameAction.startTurn(useFullHand: useFullHand)]);
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
  void startTurn({required bool useFullHand}) => _commit(
        state!.startTurn(useFullHand: useFullHand),
        [GameAction.startTurn(useFullHand: useFullHand)],
      );

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
      applyKeep(declineFivesCount: previewAiDeclineFives(turn));
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
    if (engine.inheritedHandCannotBank) return false;
    return _currentStrategy().decideAcceptInheritedHand(
      diceCount: engine.nextTurnDice,
      extendedValues: engine.inheritedExtendedValues,
      inheritedScore: engine.inheritedScore,
      currentTotalScore: engine.currentPlayer.totalScore,
    );
  }

  /// Nombre de 5 que l'IA du joueur courant déclinerait sur le lancer en
  /// attente de [turn]. Même rôle que [previewAiAcceptInheritedHand] pour
  /// cette décision-ci : l'UI peut afficher à l'avance ce que
  /// [playAiTurnStep] appliquera — et par le MÊME calcul, appelé par les
  /// deux, pour que l'affiché et le joué ne puissent pas diverger.
  ///
  /// La stratégie raisonne sur le seul tour en cours : elle ignore le score
  /// déjà acquis par le joueur, et donc le plafond de 10000. On borne donc
  /// sa réponse ici, au seul endroit qui connaît les deux — exactement les
  /// mêmes bornes que celles proposées à un joueur humain (voir
  /// `_buildHumanControlRow`), pour que les deux jouent la même règle.
  int previewAiDeclineFives(TurnState turn) {
    final engine = state!;
    final analysis = turn.pendingRoll!;
    final fives = analysis.declinableFives?.diceCount ?? 0;
    final minKeep = minKeepableFives(analysis);
    final maxKeep = maxKeepableFives(
      turn,
      analysis,
      currentTotal: engine.currentPlayer.totalScore,
    );
    final wantedKeep = fives - _currentStrategy().decideDeclineFives(analysis, turn);
    final keep = wantedKeep.clamp(minKeep, maxKeep < minKeep ? minKeep : maxKeep);
    return fives - keep;
  }

  /// Prévisualise si l'IA du joueur courant choisirait de continuer à
  /// lancer plutôt que de s'arrêter sur [turn] (l'appelant garantit que
  /// s'arrêter y est déjà légal). Même rôle que [previewAiAcceptInheritedHand]
  /// pour cette autre décision.
  bool previewAiContinue(TurnState turn) {
    final player = state!.currentPlayer;
    return _currentStrategy().decideContinue(
      state: turn,
      minimumRequired: state!.minimumForCurrentPlayer,
      currentTotalScore: player.totalScore,
      // Ligne courante déjà tiretée : un nouveau craque la barrerait,
      // retombant sur le score précédent plutôt que de juste marquer un
      // second tiret (voir Player.applyBust).
      barLossIfBusted: player.hasTiret ? player.totalScore - player.previousScore : 0,
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

  /// Passe la partie à l'état [next] : journalise [actions] puis persiste (ou
  /// archive dans `over/` et retire de `in-progress/`, si la partie vient de se
  /// terminer) la sauvegarde correspondante. Sans seed (ex: [debugLoadState]
  /// en test), ne persiste rien : il n'y a pas de partie à persister.
  ///
  /// Le journal est complété AVANT d'assigner `state` : tout ce qui écoute le
  /// moteur (l'écran de jeu, qui lit le journal pour l'écran de fin dès que la
  /// partie est gagnée) s'exécute dans l'assignation, et verrait sinon un
  /// journal auquel manque le coup qu'il vient d'annoncer — une partie
  /// « inachevée » pour ses statistiques et son rejeu. Pour la même raison
  /// `state` reflète déjà [next] quand on décide de persister ou d'archiver,
  /// d'après `state!.gameOver`.
  void _commit(GameEngine next, List<GameAction> actions) {
    _actions.addAll(actions);
    state = next;
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
