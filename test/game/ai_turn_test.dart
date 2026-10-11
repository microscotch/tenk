import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/ai/ai_turn.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/game/turn_state.dart';

void main() {
  final prudent = aiStrategyFor(AiDifficulty.prudent);
  final fresh = GameEngine.newGame(['Bot', 'B']).startTurn();

  test('un tour qui n\'a pas commencé : démarrer, main neuve quand l\'héritage ne peut plus être encaissé', () {
    // B s'arrête avec 200 en laissant 2 dés : le bot, à 9900, les hérite —
    // 9900 + 200 dépasse déjà 10000.
    final engine = GameEngine.newGame(['B', 'Bot'])
        .startTurn()
        .copyWith(
          players: [Player(name: 'B', totalScore: 1000, hasEntered: true), Player(name: 'Bot', totalScore: 9900, hasEntered: true)],
          activeTurn: const TurnState(diceToRoll: 2, bankedScore: 200, hasRolledThisTurn: true),
        )
        .bank()
        .$1;
    expect(engine.activeTurn, isNull, reason: 'prémisse : le bot a le choix de reprendre la main');
    final move = nextAiMove(engine, prudent);
    expect(move.type, GameActionType.startTurn);
    expect(move.params['useFullHand'], isTrue);
  });

  test('un craque s\'acquitte', () {
    final engine = fresh.copyWith(
      activeTurn: TurnState(diceToRoll: 5, pendingRoll: analyzeRoll([2, 3, 4, 6, 2]), busted: true),
    );
    expect(nextAiMove(engine, prudent).type, GameActionType.endBustedTurn);
  });

  test('un lancer en attente se tranche, et le 10000 pile est imposé', () {
    final engine = fresh.copyWith(
      players: [Player(name: 'Bot', totalScore: 9850, hasEntered: true), Player(name: 'B')],
      activeTurn: TurnState(diceToRoll: 5, bankedScore: 100, pendingRoll: analyzeRoll([5, 5, 2, 3, 6]), hasRolledThisTurn: true),
    );
    final move = nextAiMove(engine, prudent);
    expect(move.type, GameActionType.applyKeep);
    expect(move.params['declineFivesCount'], 1, reason: '9850 + 100 + 50 = 10000 : un seul 5');
  });

  test('sans lancer en attente : relancer tant que s\'arrêter est interdit, s\'arrêter à 10000 pile', () {
    final below = fresh.copyWith(activeTurn: const TurnState(diceToRoll: 3, bankedScore: 150, hasRolledThisTurn: true));
    expect(nextAiMove(below, prudent).type, GameActionType.roll, reason: '150 < 500 pour entrer');

    final atTarget = fresh.copyWith(
      players: [Player(name: 'Bot', totalScore: 9500, hasEntered: true), Player(name: 'B')],
      activeTurn: const TurnState(diceToRoll: 4, bankedScore: 500, hasRolledThisTurn: true),
    );
    expect(nextAiMove(atTarget, prudent).type, GameActionType.bank);
  });
}
