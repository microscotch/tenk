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

  group('decideAcceptInheritedHand : accepte toujours à 0, sinon selon le risque du profil', () {
    test('à 0, tous les profils acceptent même une main très risquée (1 dé)', () {
      for (final ai in [const CautiousAi(), const BalancedAi(), const AggressiveAi()]) {
        expect(
          ai.decideAcceptInheritedHand(
            diceCount: 1,
            extendedValues: const {},
            inheritedScore: 300,
            currentTotalScore: 0,
          ),
          isTrue,
        );
      }
    });

    // 1 dé restant, valeur 3 déjà étendue -> 50% de risque de craquer :
    // situation intermédiaire qui différencie les trois profils (comme pour
    // decideContinue), cette fois à un score déjà entamé.
    test('à score non nul, prudent refuse une main à 50% de risque', () {
      expect(
        const CautiousAi().decideAcceptInheritedHand(
          diceCount: 1,
          extendedValues: const {3},
          inheritedScore: 300,
          currentTotalScore: 1000,
        ),
        isFalse,
      );
    });

    test('à score non nul, équilibré refuse une main à 50% de risque', () {
      expect(
        const BalancedAi().decideAcceptInheritedHand(
          diceCount: 1,
          extendedValues: const {3},
          inheritedScore: 300,
          currentTotalScore: 1000,
        ),
        isFalse,
      );
    });

    test('à score non nul, agressif accepte une main à 50% de risque', () {
      expect(
        const AggressiveAi().decideAcceptInheritedHand(
          diceCount: 1,
          extendedValues: const {3},
          inheritedScore: 300,
          currentTotalScore: 1000,
        ),
        isTrue,
      );
    });
  });

  group('decideDeclineFives : garde toujours au moins un dé marquant', () {
    final state = TurnState.initial(5);

    test('aucun autre groupe obligatoire : agressif garde un des deux 5', () {
      final analysis = analyzeRoll([5, 5, 2, 3, 4]); // pas de 1, pas de brelan
      expect(analysis.mandatoryGroups, isEmpty);
      expect(const AggressiveAi().decideDeclineFives(analysis, state), 1);
      expect(const BalancedAi().decideDeclineFives(analysis, state), 1);
    });

    test('un seul 5 sans autre groupe obligatoire : impossible de le rejeter', () {
      final analysis = analyzeRoll([5, 2, 3, 4, 4]); // pas de 1, pas de brelan
      expect(analysis.mandatoryGroups, isEmpty);
      expect(const AggressiveAi().decideDeclineFives(analysis, state), 0);
      expect(const BalancedAi().decideDeclineFives(analysis, state), 0);
    });
  });
}
