import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/dice_off.dart';
import '../game/game_recording.dart';
import '../ui/alias_words.dart';
import 'game_providers.dart';
import 'game_save_store.dart';

final diceOffProvider = NotifierProvider<DiceOffNotifier, DiceOffState?>(DiceOffNotifier.new);

class DiceOffNotifier extends Notifier<DiceOffState?> {
  late GameSetup _setup;

  // Identité de la partie (seed/alias/dates) et journal d'actions, pour la
  // persistance : générés dès [start], transmis à [GameNotifier] une fois le
  // départage résolu (voir [handoff]). Voir lib/game/game_recording.dart
  // pour pourquoi c'est la MÊME instance de [Random] qui doit continuer
  // d'être consommée, pas seulement la même seed.
  late int _seed;
  late Random _random;
  late String _alias;
  late DateTime _createdAt;
  final List<GameAction> _actions = [];

  // Sérialise les écritures : deux lancers rapprochés (ex: départage 100%
  // IA/auto) déclenchent chacun une persistance fire-and-forget, et sans
  // cette chaîne deux écritures concurrentes sur le même fichier `.tmp`
  // peuvent se marcher dessus (PathNotFoundException au renommage).
  Future<void> _persistChain = Future.value();

  // Rejeu (spectateur) d'un run archivé : lecture seule, aucune écriture
  // (voir [startReplay]) — distinct de l'état de partie live ci-dessus.
  bool _isReplay = false;
  List<GameAction> _replayActions = const [];
  int _replayIndex = 0;

  @override
  DiceOffState? build() => null;

  int get humanPlayerCount => _setup.playerNames.length - _setup.aiPlayers.length;
  bool shouldShowPassDevice(int index) => !isAiPlayer(index) && humanPlayerCount > 1;
  bool isAiPlayer(int index) => _setup.isAi(index);
  bool isAutoPlayer(int index) => _setup.isAuto(index);
  String nameOf(int index) => _setup.playerNames[index];

  /// Vrai si tous les joueurs de la partie sont en mode auto : utilisé pour
  /// savoir si la transition vers l'écran de jeu, une fois l'ordre déterminé,
  /// peut se valider seule (aucun joueur non-auto à qui laisser la main).
  bool get allPlayersAreAuto {
    for (var i = 0; i < _setup.playerNames.length; i++) {
      if (!_setup.isAuto(i)) return false;
    }
    return true;
  }

  /// Démarre le départage d'une nouvelle partie : génère la seed RNG et
  /// l'alias qui l'identifieront pour toute sa durée (nom du fichier de
  /// sauvegarde, rejouabilité des tirages), et persiste un premier snapshot.
  void start(GameSetup setup) {
    _setup = setup;
    _seed = Random.secure().nextInt(1 << 32);
    _random = Random(_seed);
    _alias = randomGameAlias();
    _createdAt = DateTime.now();
    _actions.clear();
    state = DiceOffState.start(setup.playerNames.length);
    _enqueuePersist();
  }

  void rollForCurrent() {
    final s = state!;
    final idx = s.nextToRoll!;
    var next = s.rollFor(idx, random: _random);
    _actions.add(GameAction.diceOffRoll(idx));
    if (next.roundComplete) {
      next = next.resolveRound();
      _actions.add(GameAction.diceOffResolveRound());
    }
    state = next;
    _enqueuePersist();
  }

  bool get isReplay => _isReplay;

  /// Démarre le rejeu spectateur d'un run archivé, depuis le tout début
  /// (départage inclus) : aucune écriture disque (lecture seule), `_setup`
  /// est posée (pour [buildRotatedSetup]) mais [_seed]/[_random] "live" ne
  /// le sont pas — le générateur du rejeu est créé et consommé séparément
  /// via [applyNextDiceOffReplayAction].
  Random? _replayRandom;

  void startReplay(SavedGame saved) {
    _isReplay = true;
    _setup = saved.setup;
    _replayActions = saved.actions;
    _replayIndex = 0;
    _replayRandom = Random(saved.seed);
    state = DiceOffState.start(saved.setup.playerNames.length);
  }

  /// Applique la prochaine action du journal tant que le départage n'est pas
  /// résolu ; ne fait rien et renvoie false une fois résolu (le reste du
  /// journal concerne la partie principale, à consommer via
  /// `GameNotifier.applyNextReplayAction`).
  bool applyNextDiceOffReplayAction() {
    if (state!.isResolved) return false;
    final action = _replayActions[_replayIndex++];
    state = switch (action.type) {
      GameActionType.diceOffRoll => state!.rollFor(action.params['index'] as int, random: _replayRandom),
      GameActionType.diceOffResolveRound => state!.resolveRound(),
      _ => throw StateError('action de rejeu inattendue pendant le départage : ${action.type}'),
    };
    return true;
  }

  /// Une fois le départage résolu en mode rejeu : transmet le générateur
  /// (déjà avancé par [applyNextDiceOffReplayAction]) et le reste du journal
  /// à `GameNotifier.startGameReplay` pour continuer le rejeu de la partie
  /// principale sans jamais répéter un tirage déjà consommé.
  GameRecordingHandoff replayHandoff() => GameRecordingHandoff(
        seed: 0,
        random: _replayRandom!,
        originalSetup: _setup,
        alias: '',
        createdAt: DateTime.now(),
        actions: _replayActions.sublist(_replayIndex),
      );

  void _enqueuePersist() {
    // .catchError avale l'échec d'UNE persistance sans jamais laisser la
    // chaîne elle-même rejetée (sinon plus aucune écriture suivante ne
    // s'exécuterait : .then court-circuite sur une future rejetée).
    _persistChain = _persistChain.then((_) => _persist()).catchError((_) {});
  }

  /// Construit la configuration de partie finale, les joueurs étant
  /// réordonnés pour que le vainqueur du départage commence (index 0).
  GameSetup buildRotatedSetup() => _setup.rotated(state!.winnerIndex!);

  /// Transmet la seed/le générateur/le journal accumulés à la partie
  /// principale une fois le départage résolu.
  GameRecordingHandoff handoff() => GameRecordingHandoff(
        seed: _seed,
        random: _random,
        originalSetup: _setup,
        alias: _alias,
        createdAt: _createdAt,
        actions: List.unmodifiable(_actions),
      );

  Future<void> _persist() async {
    final store = ref.read(gameSaveStoreProvider);
    await store.write(SavedGame(
      seed: _seed,
      setup: _setup,
      alias: _alias,
      createdAt: _createdAt,
      durationSeconds: durationSecondsFor(_actions),
      actions: List.unmodifiable(_actions),
    ));
  }
}
