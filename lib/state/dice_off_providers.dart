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

  // Sérialise les écritures : deux rounds rapprochés (relance immédiate
  // d'une égalité) déclenchent chacun une persistance fire-and-forget, et sans
  // cette chaîne deux écritures concurrentes sur le même fichier `.tmp`
  // peuvent se marcher dessus (PathNotFoundException au renommage).
  Future<void> _persistChain = Future.value();

  @override
  DiceOffState? build() => null;

  int get humanPlayerCount => _setup.playerNames.length - _setup.aiPlayers.length;
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

  /// Reprend un départage interrompu avant d'être tranché : son journal est
  /// rejoué pour retrouver les rounds déjà joués et le générateur là où il
  /// s'était arrêté, puis le départage continue. C'est la même partie : même
  /// seed, même alias, même fichier.
  void resumeFromSave(SavedGame saved) {
    final replay = replayGame(saved.setup, saved.seed, saved.actions);
    assert(!replay.diceOff.isResolved, 'départage déjà tranché : c\'est la partie qu\'il faut reprendre');
    _setup = saved.setup;
    _seed = saved.seed;
    _random = replay.random;
    _alias = saved.alias;
    _createdAt = saved.createdAt;
    // La reprise borne l'interruption, comme pour une partie (voir
    // [GameActionType.resume]) : le temps passé hors de l'app ne compte pas.
    _actions
      ..clear()
      ..addAll(saved.actions)
      ..add(GameAction.resume());
    state = replay.diceOff;
    _enqueuePersist();
  }

  /// Vrai quand le départage de [saved] n'est pas tranché : c'est alors lui
  /// qu'il faut reprendre ([resumeFromSave]), la partie n'existant pas encore.
  static bool isUnfinished(SavedGame saved) =>
      !replayGame(saved.setup, saved.seed, saved.actions.sublist(0, diceOffActionCount(saved.actions)))
          .diceOff
          .isResolved;

  /// Joue un round : tous les joueurs encore en lice lancent leur dé en même
  /// temps, puis le round est tranché (vainqueur, ou relance des ex-aequo au
  /// plus bas au prochain appel).
  ///
  /// Un round commencé un joueur à la fois par une version antérieure (repris
  /// d'une vieille sauvegarde) se finit de la même façon, pour que son journal
  /// reste rejouable à l'identique.
  void rollRound() {
    var next = state!;
    if (next.rollsThisRound.isEmpty) {
      next = next.rollAll(random: _random);
      _actions.add(GameAction.diceOffRollAll());
    } else {
      while (!next.roundComplete) {
        final index = next.nextToRoll!;
        next = next.rollFor(index, random: _random);
        _actions.add(GameAction.diceOffRoll(index));
      }
    }
    next = next.resolveRound();
    _actions.add(GameAction.diceOffResolveRound());
    state = next;
    _enqueuePersist();
  }

  void _enqueuePersist() {
    // .catchError avale l'échec d'UNE persistance sans jamais laisser la
    // chaîne elle-même rejetée (sinon plus aucune écriture suivante ne
    // s'exécuterait : .then court-circuite sur une future rejetée).
    _persistChain = _persistChain.then((_) => _persist()).catchError((_) {});
  }

  /// La config telle que saisie, avant réordonnancement — pendant du
  /// `originalSetup` de [GameNotifier]. [buildOrderedSetup] exige un départage
  /// résolu, celle-ci est lisible dès [start].
  GameSetup get setup => _setup;

  /// Construit la configuration de partie finale, les joueurs étant
  /// réordonnés dans l'ordre de jeu tranché par le départage (voir
  /// `DiceOffState.playOrder`) : le vainqueur à l'index 0.
  GameSetup buildOrderedSetup() => _setup.reordered(state!.playOrder);

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
