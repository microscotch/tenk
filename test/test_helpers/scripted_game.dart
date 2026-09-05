import 'dart:math';

import 'package:le10000/game/dice_off.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_save_store.dart';

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
({List<GameAction> actions, GameSetup rotatedSetup}) buildResumableActionLog({
  required int seed,
  required List<String> playerNames,
  bool applyKeepAfterRoll = false,
}) {
  final random = Random(seed);
  final actions = <GameAction>[];
  var diceOff = DiceOffState.start(playerNames.length);
  while (!diceOff.isResolved) {
    final idx = diceOff.nextToRoll;
    if (idx != null) {
      diceOff = diceOff.rollFor(idx, random: random);
      actions.add(GameAction.diceOffRoll(idx));
    } else {
      diceOff = diceOff.resolveRound();
      actions.add(GameAction.diceOffResolveRound());
    }
  }
  final setup = GameSetup(playerNames: playerNames);
  final rotated = setup.rotated(diceOff.winnerIndex!);
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
  return (actions: actions, rotatedSetup: rotated);
}

/// Une [SavedGame] "en cours de tour" (départage résolu + un lancer déjà
/// fait), construite via [buildResumableActionLog].
SavedGame buildResumableSavedGame({
  required int seed,
  required String alias,
  required List<String> playerNames,
  DateTime? createdAt,
  bool applyKeepAfterRoll = false,
}) {
  final log = buildResumableActionLog(
    seed: seed,
    playerNames: playerNames,
    applyKeepAfterRoll: applyKeepAfterRoll,
  );
  return SavedGame(
    seed: seed,
    setup: GameSetup(playerNames: playerNames),
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

  var diceOff = DiceOffState.start(setup.playerNames.length);
  while (!diceOff.isResolved) {
    final idx = diceOff.nextToRoll;
    if (idx != null) {
      diceOff = diceOff.rollFor(idx, random: random);
      actions.add(GameAction.diceOffRoll(idx));
    } else {
      diceOff = diceOff.resolveRound();
      actions.add(GameAction.diceOffResolveRound());
    }
  }

  final rotatedSetup = setup.rotated(diceOff.winnerIndex!);
  var engine = GameEngine.newGame(rotatedSetup.playerNames);

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
