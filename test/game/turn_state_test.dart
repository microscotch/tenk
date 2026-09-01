import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/turn_result.dart';
import 'package:le10000/game/turn_state.dart';

/// Random de test qui rejoue une séquence de faces fixée à l'avance
/// (indépendamment de l'argument `max` passé par [rollDice]).
class _QueueRandom implements Random {
  final List<int> _faces; // valeurs 1..6 déjà décrémentées de 1
  var _i = 0;
  _QueueRandom(List<int> faces) : _faces = faces.map((f) => f - 1).toList();

  @override
  int nextInt(int max) => _faces[_i++];

  @override
  double nextDouble() => throw UnimplementedError();

  @override
  bool nextBool() => throw UnimplementedError();
}

void main() {
  group('rollTurn', () {
    test('un lancer scorant place une analyse en attente', () {
      final state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 2, 3, 4, 6]));
      expect(state.pendingRoll, isNotNull);
      expect(state.busted, isFalse);
    });

    test('un lancer sans dé marquant fait craquer le tour', () {
      final state = rollTurn(TurnState.initial(5), random: _QueueRandom([2, 3, 4, 6, 2]));
      expect(state.busted, isTrue);
      expect(state.pendingRoll!.hasAnyScore, isFalse);
    });
  });

  group('applyKeepDecision', () {
    test('les groupes obligatoires sont automatiquement conservés', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 2, 3, 4]));
      state = applyKeepDecision(state);
      expect(state.bankedScore, 200);
      expect(state.diceToRoll, 3); // 2, 3, 4 restent à relancer
      expect(state.pendingRoll, isNull);
      expect(state.mustContinue, isFalse);
    });

    test('les dés chauds forcent la poursuite du tour avec 5 dés neufs', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 1, 5, 5]));
      state = applyKeepDecision(state); // brelan d'as (1000) + deux 5 (100) = 1100, tout est gardé
      expect(state.bankedScore, 1100);
      expect(state.diceToRoll, 5);
      expect(state.mustContinue, isTrue);
    });

    test('rejeter un 5 isolé le relance avec les dés junk', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 1, 3, 5]));
      final analysis = state.pendingRoll!;
      expect(analysis.canDeclineFives, isTrue);
      state = applyKeepDecision(state, declineFivesCount: 1);
      expect(state.bankedScore, 1000); // seulement le brelan d'as, le 5 est relancé
      expect(state.diceToRoll, 2); // le 3 (junk) + le 5 rejeté
      expect(state.mustContinue, isFalse);
    });

    test('impossible de rejeter un 5 sans dé junk disponible', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 1, 5, 5]));
      expect(
        () => applyKeepDecision(state, declineFivesCount: 1),
        throwsA(isA<StateError>()),
      );
    });

    test('rejeter plus de 5 que disponible lève une erreur', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 1, 3, 5]));
      expect(
        () => applyKeepDecision(state, declineFivesCount: 5),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('impossible de rejeter le seul 5 d\'un lancer sans autre groupe obligatoire', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([5, 2, 3, 4, 4]));
      final analysis = state.pendingRoll!;
      expect(analysis.mandatoryGroups, isEmpty);
      expect(
        () => applyKeepDecision(state, declineFivesCount: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('impossible de rejeter tous les 5 d\'un lancer sans autre groupe obligatoire', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([5, 5, 2, 3, 4]));
      final analysis = state.pendingRoll!;
      expect(analysis.mandatoryGroups, isEmpty);
      expect(
        () => applyKeepDecision(state, declineFivesCount: 2),
        throwsA(isA<ArgumentError>()),
      );
      // Mais en garder au moins un reste possible.
      state = applyKeepDecision(state, declineFivesCount: 1);
      expect(state.bankedScore, 50);
    });

    test('un brelan banqué déclenche la règle d\'extension au lancer suivant', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([2, 2, 2, 3, 4]));
      state = applyKeepDecision(state);
      expect(state.extendedValues, contains(2));
      expect(state.diceToRoll, 2);

      state = rollTurn(state, random: _QueueRandom([2, 6]));
      final ext = state.pendingRoll!.mandatoryGroups.firstWhere((g) => g.value == 2);
      expect(ext.points, 100);
    });

    test('un carré banqué déclenche aussi la règle d\'extension au lancer suivant', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([4, 4, 4, 4, 2]));
      state = applyKeepDecision(state);
      expect(state.extendedValues, contains(4));
      expect(state.diceToRoll, 1);

      state = rollTurn(state, random: _QueueRandom([4]));
      final ext = state.pendingRoll!.mandatoryGroups.firstWhere((g) => g.value == 4);
      expect(ext.points, 100);
    });

    test('l\'extension issue d\'un carré s\'efface aussi dès les dés chauds', () {
      // Carré de 4 + un 1 : les 5 dés sont gardés d'un coup -> dés chauds.
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([4, 4, 4, 4, 1]));
      state = applyKeepDecision(state);
      expect(state.mustContinue, isTrue);
      expect(state.extendedValues, isEmpty);

      state = rollTurn(state, random: _QueueRandom([4, 4, 5, 3, 6]));
      final analysis = state.pendingRoll!;
      expect(analysis.mandatoryGroups, isEmpty); // pas de 4 étendu (juste une paire)
      expect(analysis.declinableFives, isNotNull); // le 5 reste isolé normal
    });

    test('l\'extension issue d\'une quinte s\'efface aussi dès les dés chauds '
        '(une quinte consomme toujours les 5 dés)', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([6, 6, 6, 6, 6]));
      state = applyKeepDecision(state);
      expect(state.bankedScore, 6000);
      expect(state.mustContinue, isTrue);
      expect(state.extendedValues, isEmpty);

      state = rollTurn(state, random: _QueueRandom([6, 1, 2, 3, 4]));
      final analysis = state.pendingRoll!;
      expect(analysis.mandatoryGroups.map((g) => g.value), [1]); // pas de 6 étendu
    });

    test('la règle d\'extension s\'efface dès que les dés chauds surviennent', () {
      // Brelan de 3 + un 1 + un 5 : les 5 dés sont gardés d'un coup -> dés
      // chauds. La règle d'extension ne doit pas survivre à ce reset.
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([3, 3, 3, 1, 5]));
      state = applyKeepDecision(state);
      expect(state.mustContinue, isTrue);
      expect(state.extendedValues, isEmpty);

      state = rollTurn(state, random: _QueueRandom([1, 3, 4, 5, 6]));
      final analysis = state.pendingRoll!;
      expect(analysis.mandatoryGroups.map((g) => g.value), [1]); // pas de 3 étendu
      expect(analysis.junkDiceCount, 3); // 3, 4 et 6 ne rapportent rien
    });
  });

  group('keptDiceThisTurn', () {
    test('s\'accumule au fil des lancers du tour', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 2, 3, 4]));
      state = applyKeepDecision(state); // garde les deux 1
      expect(state.keptDiceThisTurn.map((d) => d.value), [1, 1]);

      state = rollTurn(state, random: _QueueRandom([1, 5, 4]));
      state = applyKeepDecision(state); // garde le 1 et le 5, le 4 reste junk
      expect(state.keptDiceThisTurn.map((d) => d.value), [1, 1, 1, 5]);
    });

    test('un dé isolé étendu est marqué isExtended, une valeur normale non', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([2, 2, 2, 3, 4]));
      state = applyKeepDecision(state); // brelan de 2, pas encore d'extension
      expect(state.keptDiceThisTurn.every((d) => !d.isExtended), isTrue);

      state = rollTurn(state, random: _QueueRandom([2, 6]));
      state = applyKeepDecision(state); // le 2 isolé est maintenant étendu (100 pts)
      final extendedDie = state.keptDiceThisTurn.last;
      expect(extendedDie.value, 2);
      expect(extendedDie.points, 100);
      expect(extendedDie.isExtended, isTrue);
    });

    test('un 1 isolé n\'est jamais marqué comme étendu (sa valeur de 100 est normale)', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 2, 3, 4, 6]));
      state = applyKeepDecision(state);
      expect(state.keptDiceThisTurn.single.isExtended, isFalse);
    });

    test('est effacé par un reset de dés chauds : ne reflète que la main en cours', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 1, 3, 5]));
      state = applyKeepDecision(state, declineFivesCount: 1); // garde le brelan d'as, relance le 5
      expect(state.keptDiceThisTurn, hasLength(3));

      state = rollTurn(state, random: _QueueRandom([5, 5]));
      state = applyKeepDecision(state); // les 5 dés du tour sont maintenant tous gardés -> dés chauds
      expect(state.mustContinue, isTrue);
      expect(state.keptDiceThisTurn, isEmpty,
          reason: 'les dés chauds démarrent une nouvelle main : l\'affichage ne doit plus montrer les anciens dés');
    });
  });

  group('tryBank', () {
    test('échoue sous le minimum requis', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 2, 3, 4, 6]));
      state = applyKeepDecision(state); // 100 points
      final attempt = tryBank(state, minimumRequired: 500, currentTotal: 0);
      expect(attempt.success, isFalse);
      expect(attempt.reason, BankFailureReason.belowMinimum);
    });

    test('échoue si le score se termine par 50', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 5, 3, 4]));
      state = applyKeepDecision(state); // 100+100+50 = 250
      expect(state.bankedScore, 250);
      final attempt = tryBank(state, minimumRequired: 200, currentTotal: 0);
      expect(attempt.success, isFalse);
      expect(attempt.reason, BankFailureReason.endsIn50);
    });

    test('échoue pendant un hot dice forcé (qui n\'atteint pas exactement 10000)', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 2, 3, 4, 5]));
      state = applyKeepDecision(state); // suite, 500 points, tout est gardé -> hot dice
      expect(state.mustContinue, isTrue);
      final attempt = tryBank(state, minimumRequired: 200, currentTotal: 0);
      expect(attempt.success, isFalse);
      expect(attempt.reason, BankFailureReason.mustContinueHotDice);
    });

    test('réussit malgré un hot dice forcé si le total atteindrait exactement 10000 (quinte d\'as)', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 1, 1, 1]));
      state = applyKeepDecision(state); // quinte d'as, 10000 points, tout est gardé -> hot dice
      expect(state.mustContinue, isTrue);
      expect(state.bankedScore, 10000);
      // La victoire exacte prime sur l'obligation de continuer : les dés
      // chauds existent pour empêcher un arrêt "facile", pas la victoire.
      final attempt = tryBank(state, minimumRequired: 200, currentTotal: 0);
      expect(attempt.success, isTrue);
      expect(attempt.bankedPoints, 10000);
    });

    test('succès si minimum atteint et score valide', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 2, 3, 4]));
      state = applyKeepDecision(state); // 200
      final attempt = tryBank(state, minimumRequired: 200, currentTotal: 0);
      expect(attempt.success, isTrue);
      expect(attempt.bankedPoints, 200);
    });

    test('échoue si aucun lancer n\'a encore eu lieu ce tour, même avec un score hérité suffisant', () {
      // Simule un tour qui démarre sur une main héritée : le score hérité
      // dépasse déjà le minimum, mais aucun dé n'a été relancé cette fois-ci.
      const state = TurnState(diceToRoll: 3, bankedScore: 500);
      final attempt = tryBank(state, minimumRequired: 200, currentTotal: 0);
      expect(attempt.success, isFalse);
      expect(attempt.reason, BankFailureReason.notRolledYet);
    });

    test('échoue si banquer laisserait un total trop proche de 10000 pour rester atteignable', () {
      // 9700 + 200 = 9900 : au-dessus du minimum (200), ne finit pas par 50,
      // mais désormais aucun tour futur (toujours ≥200) ne pourrait plus
      // jamais retomber pile sur 10000 (9900+200 dépasserait).
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 2, 3, 4]));
      state = applyKeepDecision(state); // 200
      final attempt = tryBank(state, minimumRequired: 200, currentTotal: 9700);
      expect(attempt.success, isFalse);
      expect(attempt.reason, BankFailureReason.wouldMakeWinningImpossible);
    });

    test('succès à la limite exacte : 9600+200=9800 laisse tout juste un tour futur possible', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 2, 3, 4]));
      state = applyKeepDecision(state); // 200
      final attempt = tryBank(state, minimumRequired: 200, currentTotal: 9600);
      expect(attempt.success, isTrue);
      expect(attempt.bankedPoints, 200);
    });

    test('succès si banquer atteint exactement 10000 en partant de près de la cible', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 2, 3, 4]));
      state = applyKeepDecision(state); // 200
      final attempt = tryBank(state, minimumRequired: 200, currentTotal: 9800);
      expect(attempt.success, isTrue);
      expect(attempt.bankedPoints, 200);
    });
  });
}
