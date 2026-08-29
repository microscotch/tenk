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
}
