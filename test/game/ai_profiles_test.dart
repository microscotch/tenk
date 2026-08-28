import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/combination.dart';
import 'package:le10000/game/turn_state.dart';

void main() {
  test('bustProbability(1, {}) = 4/6 (seuls 1 et 5 scorent)', () {
    expect(bustProbability(1, const {}), closeTo(4 / 6, 1e-9));
  });

  test('bustProbability(1, {3}) = 3/6 (extension : 1, 3 et 5 scorent)', () {
    expect(bustProbability(1, const {3}), closeTo(3 / 6, 1e-9));
  });

  group('decideContinue : plus le profil est agressif, plus il prend de risques', () {
    // 1 dé restant, valeur 3 déjà étendue -> 50% de risque de craquer :
    // situation intermédiaire qui différencie les trois profils.
    final state = TurnState(diceToRoll: 1, bankedScore: 500, extendedValues: const {3});

    test('prudent s\'arrête', () {
      expect(
        const CautiousAi().decideContinue(state: state, minimumRequired: 200, currentTotalScore: 0),
        isFalse,
      );
    });

    test('équilibré s\'arrête', () {
      expect(
        const BalancedAi().decideContinue(state: state, minimumRequired: 200, currentTotalScore: 0),
        isFalse,
      );
    });

    test('agressif continue', () {
      expect(
        const AggressiveAi().decideContinue(state: state, minimumRequired: 200, currentTotalScore: 0),
        isTrue,
      );
    });
  });

  group('decideDeclineFives', () {
    // Brelan d'as + un 3 junk + un 5 isolé déclinable : ne reste qu'1 dé
    // junk, donc un lot de relance de seulement 2 dés si on décline.
    final analysis = analyzeRoll([1, 1, 1, 3, 5]);
    final state = TurnState.initial(5);

    test('prudent ne rejette jamais', () {
      expect(const CautiousAi().decideDeclineFives(analysis, state), 0);
    });

    test('équilibré ne rejette pas si le lot de relance serait trop petit', () {
      expect(const BalancedAi().decideDeclineFives(analysis, state), 0);
    });

    test('agressif rejette systématiquement dès que possible', () {
      expect(const AggressiveAi().decideDeclineFives(analysis, state), 1);
    });
  });

  group('decideDeclineFives avec un grand lot de relance', () {
    final analysis = analyzeRoll([5, 5, 3, 3, 1]);
    final state = TurnState.initial(5);

    test('équilibré rejette si le lot de relance est suffisant', () {
      expect(const BalancedAi().decideDeclineFives(analysis, state), 2);
    });
  });
}
