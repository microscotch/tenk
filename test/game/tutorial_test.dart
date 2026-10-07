import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/tutorial.dart';
import 'package:le10000/game/turn_result.dart';
import 'package:le10000/game/turn_state.dart';

void main() {
  TutorialSession play(int steps) {
    var session = TutorialSession.start();
    for (var i = 0; i < steps; i++) {
      session = session.perform(session.current.action);
    }
    return session;
  }

  test('le scénario se joue en suivant l\'action attendue, étape par étape', () {
    var session = TutorialSession.start();
    for (var i = 0; i < tutorialSteps.length - 1; i++) {
      final before = session.step;
      session = session.perform(session.current.action);
      expect(session.step, before + 1, reason: 'étape $i');
    }
    expect(session.isLast, isTrue);
    expect(session.current.action, TutorialAction.finish);
  });

  test('une autre action que celle attendue ne fait rien', () {
    final session = TutorialSession.start();
    expect(session.perform(TutorialAction.stop), same(session));
    expect(session.perform(TutorialAction.roll), same(session));
  });

  test('premier lancer : l\'as est obligatoire, le 5 se garde, il reste 3 dés', () {
    final rolled = play(2); // intro, 1er lancer
    expect(rolled.turn.pendingRoll!.faces, [1, 5, 2, 3, 6]);
    final kept = play(3);
    expect(kept.turn.bankedScore, 150);
    expect(kept.turn.diceToRoll, 3);
  });

  test('le brelan de 3 fait des dés chauds : 450 points, 5 dés neufs obligatoires', () {
    final kept = play(5);
    expect(kept.turn.bankedScore, 450);
    expect(kept.turn.mustContinue, isTrue);
    expect(kept.turn.diceToRoll, 5);
  });

  test('le dernier lancer du tour porte la main à 700, et 650 n\'était pas permis', () {
    final kept = play(7);
    expect(kept.turn.bankedScore, 700);
    expect(kept.turn.mustContinue, isFalse);

    // Écarter le 5 laisserait 650 : s'y arrêter est interdit (fin en 50).
    final declined = applyKeepDecision(play(6).turn, declineFivesCount: 1);
    expect(declined.bankedScore, 650);
    final attempt = tryBank(declined, minimumRequired: 500, currentTotal: 0, isFinalRound: false);
    expect(attempt.reason, BankFailureReason.endsIn50);
  });

  test('s\'arrêter encaisse 700 et le tour suivant repart de zéro', () {
    final stopped = play(8);
    expect(stopped.total, 700);
    expect(stopped.turn.bankedScore, 0);
    expect(stopped.turn.diceToRoll, 5);
  });

  test('le dernier lancer ne rapporte rien : c\'est un craque, le total reste acquis', () {
    final busted = play(9);
    expect(busted.turn.busted, isTrue);
    expect(busted.total, 700);
    expect(busted.current.action, TutorialAction.finish);
  });
}
