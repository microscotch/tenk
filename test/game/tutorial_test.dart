import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/dice_roll.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/tutorial.dart';

void main() {
  final random = ScriptedRandom(tutorialFaces);
  var engine = GameEngine.newGame(['Vous', 'Bot']).startTurn();

  TutorialStep step({bool introDone = true, int keep = 0}) =>
      tutorialStepFor(engine, introDone: introDone, selectedKeep: keep);

  test(
    'le scénario se joue de bout en bout sur le vrai moteur, un bot en face',
    () {
      expect(step(introDone: false), TutorialStep.intro);
      expect(step(), TutorialStep.rollFirst);

      engine = engine.roll(random: random);
      expect(step(), TutorialStep.rollAgain);
      // L'as est d'office, le 5 par défaut : 150 points, 3 dés à relancer.
      engine = engine.applyKeep(declineFivesCount: 0);
      expect(engine.activeTurn!.bankedScore, 150);
      expect(engine.activeTurn!.diceToRoll, 3);

      engine = engine.roll(random: random);
      expect(step(), TutorialStep.hotDice);
      engine = engine.applyKeep();
      expect(engine.activeTurn!.bankedScore, 450);
      expect(engine.activeTurn!.mustContinue, isTrue);

      engine = engine.roll(random: random);
      expect(engine.activeTurn!.pendingRoll!.faces, [5, 5, 2, 3, 6]);
      expect(step(keep: 2), TutorialStep.exchange);
      expect(step(keep: 1), TutorialStep.stop);
      random.assertConsumed();
    },
  );

  test('garder les deux 5 interdit de s\'arrêter (550), n\'en garder qu\'un le permet (500)', () {
    final both = engine.applyKeep(declineFivesCount: 0);
    expect(both.activeTurn!.bankedScore, 550);
    expect(both.bank().$2.success, isFalse, reason: 'finir en 50 : arrêt interdit');

    final one = engine.applyKeep(declineFivesCount: 1);
    expect(one.activeTurn!.bankedScore, 500);
    final (banked, attempt) = one.bank();
    expect(attempt.success, isTrue);
    expect(banked.players[0].totalScore, 500);
    expect(tutorialStepFor(banked, introDone: true, selectedKeep: 0), TutorialStep.outro);
  });
}
