import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/online/protocol.dart';

ClientMessage roundTrip(ClientMessage m) => ClientMessage.fromJson(m.toJson());

void main() {
  group('messages du client', () {
    test('chaque message survit à un aller-retour JSON', () {
      expect(roundTrip(ClientMessage.create(name: 'Anna')).params, {'name': 'Anna'});
      expect(roundTrip(ClientMessage.join(code: 'ab3cd', name: 'Bob')).params, {'code': 'AB3CD', 'name': 'Bob'});
      expect(roundTrip(ClientMessage.rejoin(token: 'a' * 32)).params, {'token': 'a' * 32});
      expect(roundTrip(ClientMessage.reorder([1, 0, 2])).params, {'order': [1, 0, 2]});
      expect(roundTrip(ClientMessage.start()).type, ClientMessageType.start);
      expect(roundTrip(ClientMessage.leave()).type, ClientMessageType.leave);
      expect(roundTrip(ClientMessage.play(GameActionType.roll)).intent, GameActionType.roll);
      final keep = roundTrip(ClientMessage.play(GameActionType.applyKeep, params: {'declineFivesCount': 2}));
      expect(keep.params['declineFivesCount'], 2);
    });

    test('un pseudo est rogné, et refusé s\'il est vide, trop long ou contient un caractère de contrôle', () {
      expect(roundTrip(ClientMessage.create(name: '  Anna  ')).params['name'], 'Anna');
      for (final bad in ['', '   ', 'x' * (maxPlayerNameLength + 1), 'Ann\na', 'Ann\u0000a']) {
        expect(() => roundTrip(ClientMessage.create(name: bad)), throwsFormatException, reason: JsonName(bad).toString());
      }
    });

    test('un pseudo ne peut pas se cacher derrière des caractères invisibles ou un sens d\'écriture renversé', () {
      for (final bad in ['An\u200Bna', '\u202EAnna', 'Anna\u2066', 'An\uFEFFna', 'A\u2028nna', 'An\u200Fna']) {
        expect(() => roundTrip(ClientMessage.create(name: bad)), throwsFormatException, reason: bad.runes.toList().toString());
      }
      // Un BOM en bordure part avec les espaces : le pseudo gardé est le pseudo propre.
      expect(roundTrip(ClientMessage.create(name: '\uFEFFAnna')).params['name'], 'Anna');
      // Les lettres accentuées, les émojis et d'autres écritures restent permis.
      for (final ok in ['Chloé', 'Zoë', 'Åse', 'Мария', 'こんにちは', 'Bob 🎲']) {
        expect(roundTrip(ClientMessage.create(name: ok)).params['name'], ok);
      }
    });

    test('un code de salon mal formé est refusé', () {
      for (final bad in ['ABCD', 'ABCDEF', 'ABC0D', 'ABCIO', 'ab cd', '']) {
        expect(() => roundTrip(ClientMessage.join(code: bad, name: 'Bob')), throwsFormatException, reason: bad);
      }
    });

    test('le serveur ne laisse pas un client jouer le départage ou un lancer truqué', () {
      for (final intent in [GameActionType.diceOffRollAll, GameActionType.diceOffResolveRound, GameActionType.resume]) {
        expect(
          () => ClientMessage.fromJson({'v': onlineProtocolVersion, 'type': 'play', 'params': {'intent': intent.name}}),
          throwsFormatException,
          reason: intent.name,
        );
      }
      // Les faces d'un lancer sont ignorées : un client ne peut pas les imposer.
      final roll = ClientMessage.fromJson({
        'v': onlineProtocolVersion,
        'type': 'play',
        'params': {'intent': 'roll', 'faces': [1, 1, 1, 1, 1]},
      });
      expect(roll.params.containsKey('faces'), isFalse);
    });

    test('des paramètres hors bornes ou mal typés sont refusés', () {
      Object play(Map<String, dynamic> params) => {'v': onlineProtocolVersion, 'type': 'play', 'params': params};
      expect(() => ClientMessage.fromJson(play({'intent': 'applyKeep', 'declineFivesCount': 6})), throwsFormatException);
      expect(() => ClientMessage.fromJson(play({'intent': 'applyKeep', 'declineFivesCount': -1})), throwsFormatException);
      expect(() => ClientMessage.fromJson(play({'intent': 'applyKeep', 'declineFivesCount': '1'})), throwsFormatException);
      expect(() => ClientMessage.fromJson(play({'intent': 'startTurn', 'useFullHand': 1})), throwsFormatException);
      expect(() => ClientMessage.fromJson(play({'intent': 'nope'})), throwsFormatException);
      expect(() => roundTrip(ClientMessage.reorder([0])), throwsFormatException);
      expect(() => roundTrip(ClientMessage.reorder([0, 1, 2, 3, 4, 5, 6])), throwsFormatException);
      expect(() => ClientMessage.fromJson({'v': onlineProtocolVersion, 'type': 'reorder', 'params': {'order': ['a', 'b']}}),
          throwsFormatException);
    });

    test('un message qui n\'est pas un objet, sans type ou d\'une autre version est refusé', () {
      expect(() => ClientMessage.fromJson('start'), throwsFormatException);
      expect(() => ClientMessage.fromJson(null), throwsFormatException);
      expect(() => ClientMessage.fromJson({'v': onlineProtocolVersion}), throwsFormatException);
      expect(() => ClientMessage.fromJson({'v': onlineProtocolVersion, 'type': 'hack'}), throwsFormatException);
      expect(() => ClientMessage.fromJson({'v': 99, 'type': 'start'}), throwsA(isA<UnsupportedVersion>()));
    });
  });

  group('messages du serveur', () {
    ServerMessage roundTripServer(ServerMessage m) => ServerMessage.fromJson(m.toJson());

    test('joined, room, action, snapshot et error survivent à un aller-retour JSON', () {
      final joined = roundTripServer(ServerMessage.joined(code: 'ABCDE', token: 'a' * 32, seat: 2));
      expect((joined.roomCode, joined.token, joined.seat), ('ABCDE', 'a' * 32, 2));

      final room = roundTripServer(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: false)],
        hostSeat: 0,
      ));
      expect(room.phase, RoomPhase.playing);
      expect(room.seats, const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: false)]);
      expect(room.hostSeat, 0);

      final action = roundTripServer(ServerMessage.action(seq: 7, action: GameAction.roll(faces: [1, 2, 3])));
      expect(action.seq, 7);
      expect(action.action.faces, [1, 2, 3]);

      final snapshot = roundTripServer(ServerMessage.snapshot(
        names: ['Anna', 'Bob'],
        actions: [GameAction.diceOffRollAll(faces: [3, 4]), GameAction.diceOffResolveRound()],
      ));
      expect(snapshot.names, ['Anna', 'Bob']);
      expect(snapshot.actions.map((a) => a.type), [GameActionType.diceOffRollAll, GameActionType.diceOffResolveRound]);

      expect(roundTripServer(ServerMessage.error(ErrorCode.notYourTurn)).errorCode, ErrorCode.notYourTurn);
    });

    test('un client refuse ce qui ne suit pas le protocole', () {
      expect(() => ServerMessage.fromJson({'v': 99, 'type': 'room'}), throwsA(isA<UnsupportedVersion>()));
      expect(() => ServerMessage.fromJson({'v': onlineProtocolVersion, 'type': 'boom'}), throwsFormatException);
      final bad = ServerMessage.fromJson({
        'v': onlineProtocolVersion,
        'type': 'room',
        'params': {'code': 'AB', 'phase': 'nope', 'seats': 'x', 'hostSeat': 99},
      });
      expect(() => bad.roomCode, throwsFormatException);
      expect(() => bad.phase, throwsFormatException);
      expect(() => bad.seats, throwsFormatException);
      expect(() => bad.hostSeat, throwsFormatException);
    });
  });

  test('l\'alphabet des codes évite les caractères ambigus', () {
    for (final c in ['0', 'O', '1', 'I']) {
      expect(roomCodeAlphabet.contains(c), isFalse, reason: c);
    }
    expect(isValidRoomCode('ABCDE'), isTrue);
    expect(isValidRoomCode('abcde'), isFalse, reason: 'le serveur normalise en majuscules avant de valider');
  });
}

class JsonName {
  final String value;
  const JsonName(this.value);
  @override
  String toString() => 'pseudo ${value.replaceAll('\n', r'\n').replaceAll('\u0000', r'\0')}';
}
