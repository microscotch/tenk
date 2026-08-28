import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/combination.dart';

void main() {
  group('dés isolés', () {
    test('un 1 isolé rapporte 100 points, mandatoire', () {
      final a = analyzeRoll([1, 2, 3, 4, 6]);
      expect(a.hasAnyScore, isTrue);
      expect(a.mandatoryGroups, hasLength(1));
      expect(a.mandatoryGroups.single.value, 1);
      expect(a.mandatoryGroups.single.points, 100);
      expect(a.junkDiceCount, 4); // 2,3,4,6
    });

    test('un 5 isolé rapporte 50 points et est déclinable', () {
      final a = analyzeRoll([5, 2, 3, 4, 4]);
      expect(a.mandatoryGroups, isEmpty);
      final fives = a.declinableFives!;
      expect(fives.points, 50);
      expect(fives.diceCount, 1);
      expect(a.canDeclineFives, isTrue); // 4 dés junk disponibles
    });

    test('deux 1 et deux 5 isolés', () {
      final a = analyzeRoll([1, 1, 5, 5, 2]);
      expect(a.mandatoryGroups.single.points, 200); // 2 x 100
      expect(a.declinableFives!.points, 100); // 2 x 50
      expect(a.junkDiceCount, 1);
    });

    test('aucun dé marquant = pas de score', () {
      final a = analyzeRoll([2, 3, 4, 6, 2]);
      expect(a.hasAnyScore, isFalse);
      expect(a.junkDiceCount, 5);
    });
  });

  group('rejet des 5 isolés', () {
    test('impossible de rejeter si aucun dé junk ne reste', () {
      // brelan de 1 + deux 5 : accounted = 5, junk = 0.
      final a = analyzeRoll([1, 1, 1, 5, 5]);
      expect(a.declinableFives, isNotNull);
      expect(a.canDeclineFives, isFalse);
    });
  });

  group('brelan', () {
    test('brelan générique = valeur x 100', () {
      final a = analyzeRoll([2, 2, 2, 3, 4]);
      final brelan = a.mandatoryGroups.firstWhere((g) => g.value == 2);
      expect(brelan.points, 200);
      expect(brelan.diceCount, 3);
    });

    test('brelan de 6 = 600', () {
      final a = analyzeRoll([6, 6, 6, 2, 3]);
      expect(a.mandatoryGroups.firstWhere((g) => g.value == 6).points, 600);
    });

    test('brelan d\'as = 1000 (exception)', () {
      final a = analyzeRoll([1, 1, 1, 2, 3]);
      expect(a.mandatoryGroups.single.points, 1000);
    });
  });

  group('carré', () {
    test('carré générique = valeur x 100 + 1000', () {
      final a = analyzeRoll([2, 2, 2, 2, 3]);
      expect(a.mandatoryGroups.single.points, 1200);
    });

    test('carré de 6 = 1600', () {
      final a = analyzeRoll([6, 6, 6, 6, 3]);
      expect(a.mandatoryGroups.single.points, 1600);
    });

    test('carré d\'as = 2000 (exception)', () {
      final a = analyzeRoll([1, 1, 1, 1, 3]);
      expect(a.mandatoryGroups.single.points, 2000);
    });
  });

  group('quinte', () {
    test('quinte générique = valeur x 1000', () {
      final a = analyzeRoll([2, 2, 2, 2, 2]);
      expect(a.mandatoryGroups.single.points, 2000);
    });

    test('quinte de 6 = 6000', () {
      final a = analyzeRoll([6, 6, 6, 6, 6]);
      expect(a.mandatoryGroups.single.points, 6000);
    });

    test('quinte d\'as = 10000 (exception, victoire immédiate)', () {
      final a = analyzeRoll([1, 1, 1, 1, 1]);
      expect(a.mandatoryGroups.single.points, 10000);
    });
  });

  group('suite', () {
    test('1-2-3-4-5 rapporte 500', () {
      final a = analyzeRoll([1, 2, 3, 4, 5]);
      expect(a.mandatoryGroups.single.isSuite, isTrue);
      expect(a.mandatoryGroups.single.points, 500);
      expect(a.mandatoryGroups.single.diceCount, 5);
    });

    test('2-3-4-5-6 rapporte 500', () {
      final a = analyzeRoll([2, 3, 4, 5, 6]);
      expect(a.mandatoryGroups.single.points, 500);
    });

    test('la suite ne compte que sur un lancer de 5 dés', () {
      // 4 dés ne peuvent jamais former la suite complète.
      final a = analyzeRoll([2, 3, 4, 5]);
      expect(a.mandatoryGroups.any((g) => g.isSuite), isFalse);
    });
  });

  group('règle d\'extension', () {
    test('un dé isolé de valeur déjà étendue rapporte 100', () {
      final a = analyzeRoll([2, 3, 4, 6], extendedValues: {2});
      final ext = a.mandatoryGroups.firstWhere((g) => g.value == 2);
      expect(ext.points, 100);
      expect(ext.diceCount, 1);
    });

    test('extension sur la valeur 5 : 100 au lieu de 50', () {
      final a = analyzeRoll([5, 2, 3, 4], extendedValues: {5});
      final fives = a.declinableFives!;
      expect(fives.points, 100);
    });

    test('sans extension, la valeur reste junk', () {
      final a = analyzeRoll([2, 3, 4, 6], extendedValues: {});
      expect(a.mandatoryGroups, isEmpty);
      expect(a.junkDiceCount, 4);
    });

    test('l\'extension fonctionne pour chaque valeur possible (2,3,4,6)', () {
      for (final v in [2, 3, 4, 6]) {
        final faces = [v, ...[1, 2, 3, 4, 6].where((f) => f != v).take(3)];
        final a = analyzeRoll(faces, extendedValues: {v});
        final ext = a.mandatoryGroups.firstWhere((g) => g.value == v);
        expect(ext.points, 100, reason: 'valeur $v');
        expect(ext.diceCount, 1, reason: 'valeur $v');
      }
    });

    test('plusieurs valeurs étendues simultanément sont chacune prises en compte '
        '(cas défensif : en jeu réel, une seule valeur peut être étendue à la fois '
        'puisqu\'un brelan/carré consomme déjà 3 ou 4 des 5 dés)', () {
      final a = analyzeRoll([2, 4, 3, 6, 1], extendedValues: {2, 4});
      final extTwo = a.mandatoryGroups.firstWhere((g) => g.value == 2);
      final extFour = a.mandatoryGroups.firstWhere((g) => g.value == 4);
      expect(extTwo.points, 100);
      expect(extFour.points, 100);
      // Le 1 reste mandatoire à sa valeur normale, le 3 et le 6 restent junk.
      final one = a.mandatoryGroups.firstWhere((g) => g.value == 1);
      expect(one.points, 100);
      expect(a.junkDiceCount, 2); // 3 et 6
    });
  });
}
