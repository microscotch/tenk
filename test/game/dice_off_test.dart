import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/dice_off.dart';

/// Random de test qui rejoue une séquence de faces fixée à l'avance.
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
  test('sans égalité, le plus petit score gagne dès le premier round', () {
    var state = DiceOffState.start(3);
    final random = _QueueRandom([4, 2, 5]);

    state = state.rollFor(0, random: random);
    state = state.rollFor(1, random: random);
    state = state.rollFor(2, random: random);
    expect(state.roundComplete, isTrue);

    state = state.resolveRound();
    expect(state.isResolved, isTrue);
    expect(state.winnerIndex, 1); // a lancé 2, le plus petit
  });

  test('égalité sur le plus petit score : seuls les ex-aequo relancent', () {
    var state = DiceOffState.start(3);
    final random = _QueueRandom([3, 3, 5]);

    state = state.rollFor(0, random: random);
    state = state.rollFor(1, random: random);
    state = state.rollFor(2, random: random);
    state = state.resolveRound();

    expect(state.isResolved, isFalse);
    expect(state.activeIndices, [0, 1]); // joueur 2 (score 5) est éliminé
    expect(state.rollsThisRound, isEmpty); // nouveau round, personne n'a encore relancé
    expect(state.nextToRoll, 0);
  });

  test('le round de départage se répète jusqu\'à un vainqueur unique', () {
    var state = DiceOffState.start(3);
    final firstRound = _QueueRandom([3, 3, 5]);
    state = state.rollFor(0, random: firstRound);
    state = state.rollFor(1, random: firstRound);
    state = state.rollFor(2, random: firstRound);
    state = state.resolveRound();
    expect(state.activeIndices, [0, 1]);

    // Nouvelle égalité entre les deux restants.
    final secondRound = _QueueRandom([6, 6]);
    state = state.rollFor(0, random: secondRound);
    state = state.rollFor(1, random: secondRound);
    state = state.resolveRound();
    expect(state.isResolved, isFalse);
    expect(state.activeIndices, [0, 1]);

    // Cette fois, un score différent départage.
    final thirdRound = _QueueRandom([2, 4]);
    state = state.rollFor(0, random: thirdRound);
    state = state.rollFor(1, random: thirdRound);
    state = state.resolveRound();
    expect(state.isResolved, isTrue);
    expect(state.winnerIndex, 0);
    expect(state.roundHistory, hasLength(3));
  });

  test('nextToRoll est null une fois le départage résolu', () {
    var state = DiceOffState.start(3);
    final random = _QueueRandom([4, 2, 5]);
    state = state.rollFor(0, random: random);
    state = state.rollFor(1, random: random);
    state = state.rollFor(2, random: random);
    state = state.resolveRound();

    expect(state.isResolved, isTrue);
    expect(state.nextToRoll, isNull);
  });

  test('nextToRoll suit l\'ordre des indices actifs, pas l\'ordre de lancer', () {
    var state = DiceOffState.start(2);
    expect(state.nextToRoll, 0);
    state = state.rollFor(0, random: _QueueRandom([1]));
    expect(state.nextToRoll, 1);
    state = state.rollFor(1, random: _QueueRandom([2]));
    expect(state.nextToRoll, isNull);
    expect(state.roundComplete, isTrue);
  });

  group('lancer simultané', () {
    test('tous les joueurs en lice lancent d\'un coup, dans l\'ordre des sièges', () {
      final state = DiceOffState.start(3).rollAll(random: _QueueRandom([4, 2, 5]));

      expect(state.rollsThisRound, {0: 4, 1: 2, 2: 5});
      expect(state.roundComplete, isTrue);
      expect(state.resolveRound().winnerIndex, 1);
    });

    test('tire exactement les mêmes dés qu\'autant de lancers individuels', () {
      final together = DiceOffState.start(4).rollAll(random: Random(9));
      var oneByOne = DiceOffState.start(4);
      final random = Random(9);
      for (var i = 0; i < 4; i++) {
        oneByOne = oneByOne.rollFor(i, random: random);
      }
      expect(together.rollsThisRound, oneByOne.rollsThisRound);
    });

    test('à six joueurs aussi (au-delà des cinq dés d\'une main)', () {
      final state = DiceOffState.start(6).rollAll(random: _QueueRandom([6, 5, 4, 3, 2, 1]));
      expect(state.resolveRound().winnerIndex, 5);
    });

    test('après une égalité, seuls les ex-aequo au plus bas relancent', () {
      var state = DiceOffState.start(4).rollAll(random: _QueueRandom([3, 2, 2, 5])).resolveRound();
      expect(state.activeIndices, [1, 2]);

      state = state.rollAll(random: _QueueRandom([6, 1]));
      expect(state.rollsThisRound, {1: 6, 2: 1}, reason: 'les joueurs 0 et 3 ne relancent pas');
      expect(state.resolveRound().winnerIndex, 2);
    });
  });

  group('ordre de jeu', () {
    /// Joue des rounds simultanés successifs, un par liste de faces.
    DiceOffState play(int players, List<List<int>> rounds) {
      var state = DiceOffState.start(players);
      for (final faces in rounds) {
        state = state.rollAll(random: _QueueRandom(faces)).resolveRound();
      }
      expect(state.isResolved, isTrue);
      return state;
    }

    test('sans égalité : le vainqueur puis le sens de la liste', () {
      final state = play(5, [
        [4, 3, 2, 5, 6],
      ]);
      expect(state.reversesOrder, isFalse);
      expect(state.playOrder, [2, 3, 4, 0, 1]);
    });

    test('duel entre voisins gagné par le second : sens inversé (J3 J2 J1 J5 J4)', () {
      final state = play(5, [
        [4, 2, 2, 5, 6],
        [5, 1],
      ]);
      expect(state.reversesOrder, isTrue);
      expect(state.playOrder, [2, 1, 0, 4, 3]);
    });

    test('duel entre voisins gagné par le premier : sens de la liste', () {
      final state = play(5, [
        [4, 2, 2, 5, 6],
        [1, 5],
      ]);
      expect(state.reversesOrder, isFalse);
      expect(state.playOrder, [1, 2, 3, 4, 0]);
    });

    test('la table est circulaire : duel J5 contre J1 gagné par J1, sens inversé', () {
      final state = play(5, [
        [2, 4, 5, 6, 2],
        [1, 3],
      ]);
      expect(state.winnerIndex, 0);
      expect(state.reversesOrder, isTrue);
      expect(state.playOrder, [0, 4, 3, 2, 1]);
    });

    test('la table est circulaire : duel J5 contre J1 gagné par J5, sens de la liste', () {
      final state = play(5, [
        [2, 4, 5, 6, 2],
        [3, 1],
      ]);
      expect(state.winnerIndex, 4);
      expect(state.reversesOrder, isFalse);
      expect(state.playOrder, [4, 0, 1, 2, 3]);
    });

    test('duel entre non-voisins : sens de la liste', () {
      final state = play(5, [
        [2, 4, 2, 6, 5],
        [3, 1],
      ]);
      expect(state.winnerIndex, 2);
      expect(state.reversesOrder, isFalse);
      expect(state.playOrder, [2, 3, 4, 0, 1]);
    });

    test('égalité à trois tranchée d\'un coup : pas un duel, sens de la liste', () {
      final state = play(5, [
        [2, 2, 2, 6, 5],
        [4, 3, 1],
      ]);
      expect(state.winnerIndex, 2);
      expect(state.reversesOrder, isFalse);
    });

    test('c\'est le DERNIER round qui compte : duel final après une égalité à trois', () {
      final state = play(5, [
        [2, 2, 2, 6, 5],
        [4, 3, 3],
        [5, 2],
      ]);
      expect(state.winnerIndex, 2);
      expect(state.reversesOrder, isTrue, reason: 'J2 et J3 voisins, J3 second et vainqueur');
      expect(state.playOrder, [2, 1, 0, 4, 3]);
    });

    test('à deux joueurs, les deux sens donnent le même ordre : rien n\'est annoncé inversé', () {
      final secondWins = play(2, [[5, 1]]);
      final firstWins = play(2, [[1, 5]]);
      expect(secondWins.playOrder, [1, 0]);
      expect(firstWins.playOrder, [0, 1]);
      expect(secondWins.reversesOrder, isFalse);
      expect(firstWins.reversesOrder, isFalse);
    });

    test('un départage joué à l\'ancien format garde toujours le sens de la liste', () {
      var state = DiceOffState.start(5);
      final first = _QueueRandom([4, 2, 2, 5, 6]);
      for (var i = 0; i < 5; i++) {
        state = state.rollFor(i, random: first);
      }
      state = state.resolveRound();
      final second = _QueueRandom([5, 1]);
      state = state.rollFor(1, random: second).rollFor(2, random: second).resolveRound();

      expect(state.winnerIndex, 2);
      expect(state.reversesOrder, isFalse, reason: 'même duel qu\'en inversé, mais ancien journal');
      expect(state.playOrder, [2, 3, 4, 0, 1]);
    });
  });
}
