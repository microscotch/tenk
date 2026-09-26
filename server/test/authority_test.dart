import 'dart:math';

import 'package:test/test.dart';

import '../../lib/game/game_engine.dart';
import '../../lib/game/game_recording.dart';
import '../../lib/game/game_setup.dart';
import '../../lib/game/online/protocol.dart';
import '../../lib/game/turn_state.dart';
import '../src/authority.dart';

/// Joue un coup légal et simple pour le joueur qui a la main : jamais de choix
/// de main risqué, garde minimale, banque dès que c'est permis.
void playOneMove(GameAuthority authority) {
  final seat = authority.currentSeat!;
  final engine = authority.engine!;
  final turn = engine.activeTurn;
  if (turn == null) {
    authority.play(seat, GameActionType.startTurn, {'useFullHand': true});
  } else if (turn.busted) {
    authority.play(seat, GameActionType.endBustedTurn, {});
  } else if (turn.pendingRoll != null) {
    final analysis = turn.pendingRoll!;
    final fives = analysis.declinableFives?.diceCount ?? 0;
    authority.play(seat, GameActionType.applyKeep, {'declineFivesCount': fives - minKeepableFives(analysis)});
  } else {
    try {
      authority.play(seat, GameActionType.bank, {});
    } on IntentRejected {
      authority.play(seat, GameActionType.roll, {});
    }
  }
}

GameEngine clientView(List<String> names, List<GameAction> actions) =>
    // Une seed sans rapport avec celle du serveur : un client n'en connaît aucune.
    replayGame(GameSetup(playerNames: names), 123456789, actions).engine!;

void main() {
  const names = ['Anna', 'Bob', 'Chloé'];

  GameAuthority newAuthority([int seed = 1]) => GameAuthority(names: names, random: Random(seed));

  test('le départage est tranché au démarrage et le premier tour part seul', () {
    final authority = newAuthority();
    final produced = authority.start();

    expect(produced.first.type, GameActionType.diceOffRollAll);
    expect(produced.first.faces, hasLength(names.length));
    expect(produced.last.type, GameActionType.startTurn);
    expect(authority.currentSeat, isNotNull);
    expect(authority.engine!.activeTurn, isNotNull);
    expect(authority.actions, produced);
  });

  test('un client qui rejoue le journal sans seed retrouve exactement l\'état du serveur', () {
    final authority = newAuthority(5);
    authority.start();
    var moves = 0;
    while (!authority.isOver && moves++ < 4000) {
      playOneMove(authority);
      final server = authority.engine!;
      final client = clientView(names, authority.actions);
      expect(client.currentPlayerIndex, server.currentPlayerIndex, reason: 'coup $moves');
      expect([for (final p in client.players) p.totalScore], [for (final p in server.players) p.totalScore]);
      expect(client.activeTurn?.pendingRoll?.faces, server.activeTurn?.pendingRoll?.faces, reason: 'dés au coup $moves');
    }
    expect(authority.isOver, isTrue, reason: 'la partie doit aller à son terme');
    expect(authority.currentSeat, isNull);
  });

  test('seul le joueur qui a la main peut jouer', () {
    final authority = newAuthority()..start();
    final other = (authority.currentSeat! + 1) % names.length;

    expect(
      () => authority.play(other, GameActionType.roll, {}),
      throwsA(isA<IntentRejected>().having((e) => e.code, 'code', ErrorCode.notYourTurn)),
    );
  });

  test('un coup refusé ne change rien au journal ni à l\'état', () {
    final authority = newAuthority()..start();
    final seat = authority.currentSeat!;
    final before = authority.actions.length;

    for (final (intent, params) in [
      (GameActionType.bank, <String, dynamic>{}), // rien lancé
      (GameActionType.applyKeep, {'declineFivesCount': 0}), // pas de lancer en attente
      (GameActionType.endBustedTurn, <String, dynamic>{}), // pas de craque
      (GameActionType.startTurn, {'useFullHand': true}), // le tour est déjà parti
      (GameActionType.diceOffRollAll, <String, dynamic>{}), // pas un coup de joueur
      (GameActionType.resume, <String, dynamic>{}),
    ]) {
      expect(() => authority.play(seat, intent, params), throwsA(isA<IntentRejected>()), reason: intent.name);
    }
    expect(authority.actions, hasLength(before));
  });

  test('on ne relance pas avant d\'avoir décidé de la garde', () {
    // Cherche une seed dont le premier lancer marque, pour avoir une décision en attente.
    for (var seed = 0; seed < 50; seed++) {
      final authority = newAuthority(seed)..start();
      authority.play(authority.currentSeat!, GameActionType.roll, {});
      if (authority.engine!.activeTurn!.busted) continue;
      expect(
        () => authority.play(authority.currentSeat!, GameActionType.roll, {}),
        throwsA(isA<IntentRejected>()),
      );
      return;
    }
    fail('aucune seed n\'a donné un lancer marquant');
  });

  test('un nombre de 5 à écarter hors des choix proposés est refusé', () {
    for (var seed = 0; seed < 200; seed++) {
      final authority = newAuthority(seed)..start();
      authority.play(authority.currentSeat!, GameActionType.roll, {});
      final turn = authority.engine!.activeTurn!;
      if (turn.busted) continue;
      expect(
        () => authority.play(authority.currentSeat!, GameActionType.applyKeep, {'declineFivesCount': 9}),
        throwsA(isA<IntentRejected>()),
      );
      expect(
        () => authority.play(authority.currentSeat!, GameActionType.applyKeep, {'declineFivesCount': -1}),
        throwsA(isA<IntentRejected>()),
      );
      return;
    }
    fail('aucune seed n\'a donné un lancer marquant');
  });

  test('les faces d\'un lancer viennent du serveur, jamais du client', () {
    final authority = newAuthority()..start();
    final produced = authority.play(authority.currentSeat!, GameActionType.roll, {'faces': [1, 1, 1, 1, 1]});
    expect(produced.first.faces, isNot([1, 1, 1, 1, 1]), reason: 'seed 1 ne donne pas cinq as');
    expect(produced.first.faces, hasLength(5));
  });

  test('deux parties de même seed jouent les mêmes dés, deux seeds différentes non', () {
    List<int> firstRoll(int seed) {
      final a = newAuthority(seed)..start();
      return a.play(a.currentSeat!, GameActionType.roll, {}).first.faces!;
    }

    expect(firstRoll(3), firstRoll(3));
    expect({for (var s = 0; s < 10; s++) firstRoll(s).join()}.length, greaterThan(1));
  });

  test('impossible de démarrer deux fois, ni de jouer avant le départ', () {
    final authority = newAuthority();
    expect(() => authority.play(0, GameActionType.roll, {}), throwsA(isA<IntentRejected>()));
    authority.start();
    expect(authority.start, throwsStateError);
  });
}
