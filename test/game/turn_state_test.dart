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

  group('tryBank', () {
    test('échoue sous le minimum requis', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 2, 3, 4, 6]));
      state = applyKeepDecision(state); // 100 points
      final attempt = tryBank(state, minimumRequired: 500);
      expect(attempt.success, isFalse);
      expect(attempt.reason, BankFailureReason.belowMinimum);
    });

    test('échoue si le score se termine par 50', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 5, 3, 4]));
      state = applyKeepDecision(state); // 100+100+50 = 250
      expect(state.bankedScore, 250);
      final attempt = tryBank(state, minimumRequired: 200);
      expect(attempt.success, isFalse);
      expect(attempt.reason, BankFailureReason.endsIn50);
    });

    test('échoue pendant un hot dice forcé', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 1, 1, 1]));
      state = applyKeepDecision(state); // quinte d'as, tout est gardé -> hot dice
      final attempt = tryBank(state, minimumRequired: 200);
      expect(attempt.success, isFalse);
      expect(attempt.reason, BankFailureReason.mustContinueHotDice);
    });

    test('succès si minimum atteint et score valide', () {
      var state = rollTurn(TurnState.initial(5), random: _QueueRandom([1, 1, 2, 3, 4]));
      state = applyKeepDecision(state); // 200
      final attempt = tryBank(state, minimumRequired: 200);
      expect(attempt.success, isTrue);
      expect(attempt.bankedPoints, 200);
    });
  });
}
