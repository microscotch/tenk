import 'dart:math';

import 'package:le10000/game/dice_off.dart';
import 'package:le10000/game/dice_roll.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_save_store.dart';

/// Joue un départage complet au format actuel (tous les dés d'un round
/// ensemble) en journalisant ses actions dans [actions] ; [legacy] le joue à
/// l'ancien format (un joueur à la fois), pour les tests de compatibilité.
DiceOffState playDiceOff(int playerCount, Random random, List<GameAction> actions, {bool legacy = false}) {
  var diceOff = DiceOffState.start(playerCount);
  while (!diceOff.isResolved) {
    if (legacy) {
      final idx = diceOff.nextToRoll!;
      diceOff = diceOff.rollFor(idx, random: random);
      actions.add(GameAction.diceOffRoll(idx));
      if (!diceOff.roundComplete) continue;
    } else {
      diceOff = diceOff.rollAll(random: random);
      actions.add(GameAction.diceOffRollAll());
    }
    diceOff = diceOff.resolveRound();
    actions.add(GameAction.diceOffResolveRound());
  }
  return diceOff;
}

/// Rejoue le départage (à partir de [seed]) jusqu'à sa résolution, puis lance
/// un premier tour et un premier lancer : un journal d'actions minimal mais
/// authentique pour une sauvegarde "en cours de tour", reprenable.
///
/// [applyKeepAfterRoll] ajoute en plus la décision de garde par défaut (ne
/// décliner aucun 5) sur ce premier lancer — nécessaire dès qu'un test a
/// besoin que le journal de partie reconstruit contienne une entrée, le
/// lancer seul n'en produisant aucune. Le journal est rejoué pour vérifier
/// que ce lancer a bien de quoi être gardé pour cette [seed] : un craque
/// rendrait cette action illégale, autant échouer ici, franchement, que plus
/// loin dans un test au symptôme obscur.
({List<GameAction> actions, GameSetup orderedSetup}) buildResumableActionLog({
  required int seed,
  required List<String> playerNames,
  bool applyKeepAfterRoll = false,
}) {
  final random = Random(seed);
  final actions = <GameAction>[];
  final diceOff = playDiceOff(playerNames.length, random, actions);
  final setup = GameSetup(playerNames: playerNames);
  final ordered = setup.reordered(diceOff.playOrder);
  // Toujours légaux juste après le départage (tour frais, aucun lancer en
  // attente) : pas besoin de construire/faire progresser un GameEngine ici,
  // seule la SÉQUENCE d'actions compte pour un journal à rejouer plus tard.
  actions.add(GameAction.startTurn(useFullHand: false));
  actions.add(GameAction.roll());
  if (applyKeepAfterRoll) {
    final replayed = replayGame(setup, seed, actions).engine;
    assert(
      replayed?.activeTurn?.pendingRoll != null,
      'seed $seed : le premier lancer craque, aucune garde à appliquer',
    );
    actions.add(GameAction.applyKeep(declineFivesCount: 0));
  }
  return (actions: actions, orderedSetup: ordered);
}

/// Une [SavedGame] "en cours de tour" (départage résolu + un lancer déjà
/// fait), construite via [buildResumableActionLog].
SavedGame buildResumableSavedGame({
  required int seed,
  required String alias,
  required List<String> playerNames,
  DateTime? createdAt,
  bool applyKeepAfterRoll = false,
  Map<int, String> playerIds = const {},
}) {
  final log = buildResumableActionLog(
    seed: seed,
    playerNames: playerNames,
    applyKeepAfterRoll: applyKeepAfterRoll,
  );
  return SavedGame(
    seed: seed,
    setup: GameSetup(playerNames: playerNames, playerIds: playerIds),
    alias: alias,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    actions: log.actions,
  );
}

/// Joue une partie complète (départage + partie principale) depuis zéro,
/// avec des décisions volontairement simples et toujours légales (ne jamais
/// décliner de 5, repartir à 5 dés neufs à chaque choix de main, banquer dès
/// que possible), jusqu'à la fin de partie. Utile pour tester la
/// détermination seed → tirages, pas le réalisme des décisions.
({GameEngine engine, List<GameAction> actions}) playScriptedGame(GameSetup setup, int seed) {
  final random = Random(seed);
  final actions = <GameAction>[];

  final diceOff = playDiceOff(setup.playerNames.length, random, actions);
  final orderedSetup = setup.reordered(diceOff.playOrder);
  var engine = GameEngine.newGame(orderedSetup.playerNames);

  var guard = 0;
  while (!engine.gameOver) {
    guard++;
    assert(guard < 2000, 'la partie scriptée ne devrait pas prendre autant de tours');

    final turn = engine.activeTurn;
    if (turn == null) {
      engine = engine.startTurn(useFullHand: true);
      actions.add(GameAction.startTurn(useFullHand: true));
      continue;
    }
    if (turn.busted) {
      engine = engine.endBustedTurn();
      actions.add(GameAction.endBustedTurn());
      continue;
    }
    if (turn.pendingRoll != null) {
      engine = engine.applyKeep(declineFivesCount: 0);
      actions.add(GameAction.applyKeep(declineFivesCount: 0));
      continue;
    }
    if (!turn.mustContinue) {
      final attempt = tryBank(
        turn,
        minimumRequired: engine.minimumForCurrentPlayer,
        currentTotal: engine.currentPlayer.totalScore,
      );
      if (attempt.success) {
        final (next, _) = engine.bank();
        engine = next;
        actions.add(GameAction.bank());
        continue;
      }
    }
    engine = engine.roll(random: random);
    actions.add(GameAction.roll());
  }

  return (engine: engine, actions: actions);
}

/// Ce que fait un serveur en ligne : rejoue le journal d'une partie contre le
/// vrai générateur (seed) mais y écrit, sur chaque lancer, les faces obtenues.
List<GameAction> journalWithFaces(GameSetup setup, int seed, List<GameAction> actions) {
  final recorder = RecordingRandom(Random(seed));
  var diceOff = DiceOffState.start(setup.playerNames.length);
  GameEngine? engine;
  final out = <GameAction>[];
  for (final action in actions) {
    recorder.clear();
    switch (action.type) {
      case GameActionType.diceOffRollAll:
        diceOff = diceOff.rollAll(random: recorder);
        out.add(GameAction.diceOffRollAll(faces: recorder.faces, at: action.at));
      case GameActionType.diceOffResolveRound:
        diceOff = diceOff.resolveRound();
        if (diceOff.isResolved) {
          engine = GameEngine.newGame(setup.reordered(diceOff.playOrder).playerNames);
        }
        out.add(action);
      case GameActionType.roll:
        engine = engine!.roll(random: recorder);
        out.add(GameAction.roll(faces: recorder.faces, at: action.at));
      default:
        engine = applyGameAction(engine!, action, recorder);
        out.add(action);
    }
  }
  return out;
}
