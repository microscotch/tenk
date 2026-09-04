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
        const CautiousAi()
            .decideContinue(state: state, minimumRequired: 200, currentTotalScore: 0, barLossIfBusted: 0),
        isFalse,
      );
    });

    test('équilibré s\'arrête', () {
      expect(
        const BalancedAi()
            .decideContinue(state: state, minimumRequired: 200, currentTotalScore: 0, barLossIfBusted: 0),
        isFalse,
      );
    });

    test('agressif continue', () {
      expect(
        const AggressiveAi()
            .decideContinue(state: state, minimumRequired: 200, currentTotalScore: 0, barLossIfBusted: 0),
        isTrue,
      );
    });
  });

  group('decideContinue : une ligne déjà tiretée resserre la marge de risque tolérée', () {
    // Même lancer/état que ci-dessus (50% de risque de craquer), sur lequel
    // l'agressif continue normalement (barLossIfBusted: 0). Un nouveau
    // craque coûterait ici bien plus qu'un tour perdu : la ligne courante
    // porte déjà un tiret, donc ce craque la barrerait, faisant retomber le
    // score total de bankedScore (500) de plus encore -- ce risque
    // supplémentaire doit suffire à faire renoncer même l'agressif.
    final state = TurnState(diceToRoll: 1, bankedScore: 500, extendedValues: const {3});

    test('agressif s\'arrête si le craque ferait aussi perdre 500 points déjà acquis', () {
      expect(
        const AggressiveAi()
            .decideContinue(state: state, minimumRequired: 200, currentTotalScore: 1000, barLossIfBusted: 500),
        isFalse,
      );
    });
  });

  group('decideDeclineFives', () {
    // Brelan d'as + un 3 junk + un 5 isolé déclinable : ne reste qu'1 dé
    // junk, donc un lot de relance de seulement 2 dés si on décline.
    final analysis = analyzeRoll([1, 1, 1, 3, 5]);
    final state = TurnState.initial(5);

    test('prudent ne rejette jamais de son propre chef, mais décline ici pour éviter un total en 50 (350)', () {
      expect(const CautiousAi().decideDeclineFives(analysis, state), 1);
    });

    test('équilibré décline quand même l\'unique 5 : le garder finirait à 350 (interdit de s\'arrêter sur un 50)',
        () {
      // Le lot de relance (2 dés) est trop petit pour que l'équilibré
      // décline de son propre chef -- mais garder ce 5 amènerait le score du
      // tour à 350, un total en 50 sur lequel s'arrêter est interdit,
      // forçant un lancer supplémentaire par ailleurs évitable. Éviter ce
      // piège prime sur la préférence "lot de relance trop petit".
      expect(const BalancedAi().decideDeclineFives(analysis, state), 1);
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

    test('aucun autre groupe obligatoire : agressif et équilibré gardent les deux 5 plutôt qu\'un seul (finirait à 50)',
        () {
      final analysis = analyzeRoll([5, 5, 2, 3, 4]); // pas de 1, pas de brelan
      expect(analysis.mandatoryGroups, isEmpty);
      // Décliner un des deux 5 (la préférence brute des deux profils) est
      // légal ici (il resterait l'autre 5 comme dé marquant obligatoire),
      // mais amènerait le score du tour à 50 pile -- interdit de s'arrêter
      // dessus. Garder les deux (100 points, strictement mieux) reste légal
      // et évite ce piège : les deux profils s'y rabattent.
      expect(const AggressiveAi().decideDeclineFives(analysis, state), 0);
      expect(const BalancedAi().decideDeclineFives(analysis, state), 0);
    });

    test('un seul 5 sans autre groupe obligatoire : impossible de le rejeter', () {
      final analysis = analyzeRoll([5, 2, 3, 4, 4]); // pas de 1, pas de brelan
      expect(analysis.mandatoryGroups, isEmpty);
      expect(const AggressiveAi().decideDeclineFives(analysis, state), 0);
      expect(const BalancedAi().decideDeclineFives(analysis, state), 0);
    });
  });

  group('decideDeclineFives évite un score de tour finissant par 50', () {
    // Même lancer que la préférence par défaut côté humain (voir
    // dice_display_test.dart) : garder l'unique 5 donnerait 150 (interdit de
    // s'arrêter dessus), le décliner donne 100, un total sur lequel
    // s'arrêter est légal.
    final analysis = analyzeRoll([1, 3, 4, 5, 6]);
    final state = TurnState.initial(5);

    test('même le prudent, qui ne décline jamais de son propre chef, décline ici pour éviter le 50', () {
      expect(const CautiousAi().decideDeclineFives(analysis, state), 1);
    });
  });
}
