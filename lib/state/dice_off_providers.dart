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
