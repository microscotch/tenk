import 'dart:math';

import 'dice_off.dart';
import 'game_engine.dart';
import 'game_setup.dart';

/// Ce que le départage transmet à la partie principale une fois résolu, pour
/// que la persistance/le rejeu restent un flux continu : la seed (identité
/// du fichier + point de départ du rejeu), le générateur DÉJÀ utilisé pour
/// le départage (la continuité de cette instance précise est ce qui compte
/// en jeu réel — copier juste la seed redémarrerait le flux aléatoire à
/// zéro ; le rejeu, lui, repart de [Random(seed)] et retombe sur le même
/// flux car il rejoue aussi les actions du départage), la config d'origine
/// (non réordonnée, nécessaire au rejeu), l'alias, la date de création, et
/// le journal d'actions déjà accumulé pendant le départage.
class GameRecordingHandoff {
  final int seed;
  final Random random;
  final GameSetup originalSetup;
  final String alias;
  final DateTime createdAt;
  final List<GameAction> actions;

  const GameRecordingHandoff({
    required this.seed,
    required this.random,
    required this.originalSetup,
    required this.alias,
    required this.createdAt,
    required this.actions,
  });
}

/// Chaque transition possible du départage puis de la partie, dans l'ordre
/// où elle peut survenir. Un journal de [GameAction] + la seed RNG qui les a
/// produites suffit à reconstruire un état identique : voir [replayGame].
enum GameActionType { diceOffRoll, diceOffResolveRound, startTurn, roll, applyKeep, endBustedTurn, bank }

/// Une transition journalisée : son type, l'instant où elle a eu lieu (pour
/// la durée de partie), et ses éventuels paramètres.
class GameAction {
  final GameActionType type;
  final DateTime at;
  final Map<String, dynamic> params;

  const GameAction({required this.type, required this.at, this.params = const {}});

  factory GameAction.diceOffRoll(int index, {DateTime? at}) =>
      GameAction(type: GameActionType.diceOffRoll, at: at ?? DateTime.now(), params: {'index': index});

  factory GameAction.diceOffResolveRound({DateTime? at}) =>
      GameAction(type: GameActionType.diceOffResolveRound, at: at ?? DateTime.now());

  factory GameAction.startTurn({required bool useFullHand, DateTime? at}) => GameAction(
        type: GameActionType.startTurn,
        at: at ?? DateTime.now(),
        params: {'useFullHand': useFullHand},
      );

  factory GameAction.roll({DateTime? at}) => GameAction(type: GameActionType.roll, at: at ?? DateTime.now());

  factory GameAction.applyKeep({required int declineFivesCount, DateTime? at}) => GameAction(
        type: GameActionType.applyKeep,
        at: at ?? DateTime.now(),
        params: {'declineFivesCount': declineFivesCount},
      );

  factory GameAction.endBustedTurn({DateTime? at}) =>
      GameAction(type: GameActionType.endBustedTurn, at: at ?? DateTime.now());

  factory GameAction.bank({DateTime? at}) => GameAction(type: GameActionType.bank, at: at ?? DateTime.now());

  Map<String, dynamic> toJson() => {'type': type.name, 'at': at.toIso8601String(), 'params': params};

  factory GameAction.fromJson(Map<String, dynamic> json) => GameAction(
        type: GameActionType.values.byName(json['type'] as String),
        at: DateTime.parse(json['at'] as String),
        params: Map<String, dynamic>.from(json['params'] as Map? ?? const {}),
      );
}

/// État reconstruit par [replayGame] : le départage (toujours présent, au
/// moins à son état initial), la partie principale (null tant que le
/// départage n'est pas encore résolu dans le journal), et la configuration
/// finale réordonnée (idem).
class ReplayResult {
  final DiceOffState diceOff;
  final GameEngine? engine;
  final GameSetup? rotatedSetup;

  /// Le générateur utilisé pour le rejeu, dans l'état où le journal l'a
  /// laissé : à réutiliser tel quel (pas un [Random] fraîchement re-seedé)
  /// pour que la partie puisse continuer après une reprise sans jamais
  /// répéter un tirage déjà consommé pendant le rejeu.
  final Random random;

  const ReplayResult({required this.diceOff, this.engine, this.rotatedSetup, required this.random});
}

/// Reconstruit l'état complet (départage puis partie) en rejouant [actions]
/// dans l'ordre depuis zéro, contre un [Random] re-seedé à l'identique avec
/// [seed] : la même seed, consommée dans le même ordre par les mêmes
/// transitions, reproduit exactement les mêmes tirages de dés.
///
/// [setup] est la configuration d'origine, telle que saisie avant le
/// départage (non réordonnée) : c'est elle qui sert de base pour calculer la
/// configuration finale une fois le vainqueur du départage connu.
ReplayResult replayGame(GameSetup setup, int seed, List<GameAction> actions) {
  final random = Random(seed);
  var diceOff = DiceOffState.start(setup.playerNames.length);
  GameSetup? rotatedSetup;
  GameEngine? engine;

  for (final action in actions) {
    switch (action.type) {
      case GameActionType.diceOffRoll:
        diceOff = diceOff.rollFor(action.params['index'] as int, random: random);
      case GameActionType.diceOffResolveRound:
        diceOff = diceOff.resolveRound();
        if (diceOff.isResolved) {
          rotatedSetup = setup.rotated(diceOff.winnerIndex!);
          engine = GameEngine.newGame(rotatedSetup.playerNames);
        }
      default:
        engine = applyGameAction(engine!, action, random);
    }
  }

  return ReplayResult(diceOff: diceOff, engine: engine, rotatedSetup: rotatedSetup, random: random);
}

/// Applique une seule action de la PARTIE PRINCIPALE (pas le départage) à
/// [engine] : le dispatch central réutilisé à la fois par [replayGame] (rejeu
/// complet d'un coup) et par le rejeu pas-à-pas temporisé (voir
/// `GameNotifier.applyNextReplayAction`), pour ne jamais faire diverger les
/// deux.
GameEngine applyGameAction(GameEngine engine, GameAction action, Random random) {
  switch (action.type) {
    case GameActionType.startTurn:
      return engine.startTurn(useFullHand: action.params['useFullHand'] as bool? ?? false);
    case GameActionType.roll:
      return engine.roll(random: random);
    case GameActionType.applyKeep:
      return engine.applyKeep(declineFivesCount: action.params['declineFivesCount'] as int? ?? 0);
    case GameActionType.endBustedTurn:
      return engine.endBustedTurn();
    case GameActionType.bank:
      final (next, _) = engine.bank();
      return next;
    case GameActionType.diceOffRoll:
    case GameActionType.diceOffResolveRound:
      throw ArgumentError('${action.type} concerne le départage, pas la partie principale');
  }
}

/// Somme des écarts entre actions consécutives : la durée d'une partie,
/// mise à jour après chaque transition (une longue pause réelle entre deux
/// actions compte donc en entier — pas de détection de pause/veille).
int durationSecondsFor(List<GameAction> actions) {
  var total = 0;
  for (var i = 1; i < actions.length; i++) {
    total += actions[i].at.difference(actions[i - 1].at).inSeconds;
  }
  return total;
}
