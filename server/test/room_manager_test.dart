import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';

import '../../lib/game/game_recording.dart';
import '../../lib/game/game_setup.dart';
import '../../lib/game/online/protocol.dart';
import '../src/limits.dart';
import '../src/room.dart';
import '../src/room_manager.dart';

class FakeConnection implements Connection {
  final List<ServerMessage> received = [];
  bool closed = false;

  @override
  void send(ServerMessage message) => received.add(message);

  @override
  void close() => closed = true;

  Iterable<ServerMessage> of(ServerMessageType type) => received.where((m) => m.type == type);
  ServerMessage get lastRoom => of(ServerMessageType.room).last;
  ErrorCode? get lastError => of(ServerMessageType.error).isEmpty ? null : of(ServerMessageType.error).last.errorCode;
  String get token => of(ServerMessageType.joined).last.token;
  int get seat => of(ServerMessageType.joined).last.seat;
}

void main() {
  late DateTime clock;
  late RoomManager manager;

  RoomManager newManager([ServerConfig config = const ServerConfig()]) => RoomManager(
        config: config,
        now: () => clock,
        secure: Random(99),
        authorityRandom: () => Random(7),
      );

  setUp(() {
    clock = DateTime(2026, 9, 26, 12);
    manager = newManager();
  });

  /// Une connexion ouverte sur le serveur.
  (FakeConnection, Session) open({String ip = '10.0.0.1'}) {
    final connection = FakeConnection();
    return (connection, manager.connect(connection, ip)!);
  }

  void send(Session session, ClientMessage message) => manager.onMessage(session, jsonEncode(message.toJson()));

  /// Un salon avec [count] joueurs connectés ; le premier est l'hôte.
  (String code, List<(FakeConnection, Session)> players) lobby(int count) {
    final host = open();
    send(host.$2, ClientMessage.create(name: 'J1'));
    final code = host.$1.of(ServerMessageType.joined).last.roomCode;
    final players = [host];
    for (var i = 2; i <= count; i++) {
      final p = open();
      send(p.$2, ClientMessage.join(code: code, name: 'J$i'));
      players.add(p);
    }
    return (code, players);
  }

  group('salon', () {
    test('créer donne un code valide, un jeton et le siège 0 (hôte)', () {
      final (code, players) = lobby(1);
      expect(isValidRoomCode(code), isTrue);
      expect(players.first.$1.seat, 0);
      expect(players.first.$1.token, hasLength(32));
      expect(players.first.$1.lastRoom.phase, RoomPhase.lobby);
      expect(players.first.$1.lastRoom.hostSeat, 0);
    });

    test('rejoindre par code (en minuscules aussi) rediffuse l\'état à tous', () {
      final (code, players) = lobby(1);
      final guest = open();
      send(guest.$2, ClientMessage.join(code: code.toLowerCase(), name: 'Bob'));

      expect(guest.$1.seat, 1);
      for (final p in [players.first.$1, guest.$1]) {
        expect(p.lastRoom.seats.map((s) => s.name), ['J1', 'Bob']);
      }
    });

    test('deux joueurs de même pseudo : le second est suffixé', () {
      final (code, players) = lobby(1);
      final guest = open();
      send(guest.$2, ClientMessage.join(code: code, name: 'j1'));
      expect(players.first.$1.lastRoom.seats.map((s) => s.name), ['J1', 'j1 2']);
    });

    test('un code inconnu est refusé', () {
      final guest = open();
      send(guest.$2, ClientMessage.join(code: 'ZZZZZ', name: 'Bob'));
      expect(guest.$1.lastError, ErrorCode.roomNotFound);
    });

    test('un septième joueur est refusé, comme tout arrivant après le départ', () {
      final (code, players) = lobby(6);
      final late = open();
      send(late.$2, ClientMessage.join(code: code, name: 'J7'));
      expect(late.$1.lastError, ErrorCode.roomFull);

      send(players.first.$2, ClientMessage.start());
      final after = open();
      send(after.$2, ClientMessage.join(code: code, name: 'Tard'));
      expect(after.$1.lastError, ErrorCode.gameStarted, reason: 'départ fait : partie commencée avant salon plein');
    });

    test('après le départ, un arrivant est refusé (partie commencée)', () {
      final (code, players) = lobby(2);
      send(players.first.$2, ClientMessage.start());
      final late = open();
      send(late.$2, ClientMessage.join(code: code, name: 'Tard'));
      expect(late.$1.lastError, ErrorCode.gameStarted);
    });

    test('seul l\'hôte règle l\'ordre et lance ; il faut deux joueurs', () {
      final (_, players) = lobby(1);
      send(players.first.$2, ClientMessage.start());
      expect(players.first.$1.lastError, ErrorCode.badRequest, reason: 'un seul joueur');

      final (_, duo) = lobby(2);
      send(duo[1].$2, ClientMessage.start());
      expect(duo[1].$1.lastError, ErrorCode.notHost);
      send(duo[1].$2, ClientMessage.reorder([1, 0]));
      expect(duo[1].$1.lastError, ErrorCode.notHost);
    });

    test('l\'hôte réordonne les sièges ; chacun apprend son nouveau numéro', () {
      final (_, players) = lobby(3);
      send(players[0].$2, ClientMessage.reorder([2, 0, 1]));

      expect(players[0].$1.lastRoom.seats.map((s) => s.name), ['J3', 'J1', 'J2']);
      expect([players[0].$1.seat, players[1].$1.seat, players[2].$1.seat], [1, 2, 0]);
    });

    test('un ordre qui n\'est pas une permutation est refusé', () {
      final (_, players) = lobby(3);
      for (final bad in [
        [0, 0, 1],
        [0, 1, 5],
        [0, 1],
      ]) {
        send(players[0].$2, ClientMessage.reorder(bad));
        expect(players[0].$1.lastError, ErrorCode.badRequest, reason: '$bad');
      }
    });

    test('partir d\'un salon non commencé libère le siège', () {
      final (_, players) = lobby(3);
      send(players[1].$2, ClientMessage.leave());
      expect(players[0].$1.lastRoom.seats.map((s) => s.name), ['J1', 'J3']);
      expect(players[2].$1.seat, 1);
    });
  });

  group('partie', () {
    (String, List<(FakeConnection, Session)>) started(int count) {
      final (code, players) = lobby(count);
      send(players.first.$2, ClientMessage.start());
      return (code, players);
    }

    test('le départ envoie à chacun le journal (départage et premier tour, avec faces)', () {
      final (_, players) = started(3);
      for (final p in players) {
        final snapshot = p.$1.of(ServerMessageType.snapshot).single;
        expect(snapshot.names, ['J1', 'J2', 'J3']);
        expect(snapshot.actions.first.type, GameActionType.diceOffRollAll);
        expect(snapshot.actions.first.faces, hasLength(3));
        expect(snapshot.actions.last.type, GameActionType.startTurn);
        expect(p.$1.lastRoom.phase, RoomPhase.playing);
      }
    });

    test('le joueur qui a la main lance : tous reçoivent la même action, numérotée à la suite', () {
      final (code, players) = started(3);
      final room = manager.room(code)!;
      final current = room.authority!.currentSeat!;
      final journalSize = room.authority!.actions.length;

      send(players[current].$2, ClientMessage.play(GameActionType.roll));

      for (final p in players) {
        final action = p.$1.of(ServerMessageType.action).first;
        expect(action.seq, journalSize);
        expect(action.action.type, GameActionType.roll);
        expect(action.action.faces, hasLength(5));
      }
    });

    test('un joueur hors tour est refusé et les autres ne voient rien', () {
      final (code, players) = started(3);
      final current = manager.room(code)!.authority!.currentSeat!;
      final other = (current + 1) % 3;

      send(players[other].$2, ClientMessage.play(GameActionType.roll));

      expect(players[other].$1.lastError, ErrorCode.notYourTurn);
      expect(players[current].$1.of(ServerMessageType.action), isEmpty);
    });

    test('un client qui rejoue les actions reçues (sans seed) suit la partie du serveur', () {
      final (code, players) = started(2);
      final room = manager.room(code)!;
      final seen = <GameAction>[...players[0].$1.of(ServerMessageType.snapshot).single.actions];
      for (var i = 0; i < 6 && !room.authority!.isOver; i++) {
        final seat = room.authority!.currentSeat!;
        final turn = room.authority!.engine!.activeTurn;
        final intent = turn == null
            ? ClientMessage.play(GameActionType.startTurn, params: {'useFullHand': true})
            : turn.busted
                ? ClientMessage.play(GameActionType.endBustedTurn)
                : turn.pendingRoll != null
                    ? ClientMessage.play(GameActionType.applyKeep, params: {'declineFivesCount': 0})
                    : ClientMessage.play(GameActionType.roll);
        send(players[seat].$2, intent);
      }
      seen
        ..clear()
        ..addAll(players[0].$1.of(ServerMessageType.snapshot).single.actions)
        ..addAll(players[0].$1.of(ServerMessageType.action).map((m) => m.action));

      final client = replayGame(const GameSetup(playerNames: ['J1', 'J2']), 31337, seen).engine!;
      expect(client.currentPlayerIndex, room.authority!.engine!.currentPlayerIndex);
      expect(client.activeTurn?.pendingRoll?.faces, room.authority!.engine!.activeTurn?.pendingRoll?.faces);
    });
  });

  group('reconnexion', () {
    test('un joueur coupé revient avec son jeton : même siège, journal renvoyé', () {
      final (code, players) = lobby(2);
      send(players[0].$2, ClientMessage.start());
      final token = players[1].$1.token;

      manager.disconnect(players[1].$2);
      expect(players[0].$1.lastRoom.seats[1].connected, isFalse);

      final back = open();
      send(back.$2, ClientMessage.rejoin(token: token));

      expect(back.$1.seat, 1);
      expect(back.$1.of(ServerMessageType.snapshot), hasLength(1));
      expect(players[0].$1.lastRoom.seats[1].connected, isTrue);
      expect(manager.room(code)!.phase, RoomPhase.playing);
    });

    test('un jeton inconnu est refusé', () {
      final guest = open();
      send(guest.$2, ClientMessage.rejoin(token: 'f' * 32));
      expect(guest.$1.lastError, ErrorCode.badToken);
    });

    test('se reconnecter depuis un autre appareil coupe l\'ancienne connexion', () {
      final (_, players) = lobby(2);
      final second = open();
      send(second.$2, ClientMessage.rejoin(token: players[1].$1.token));
      expect(players[1].$1.closed, isTrue);
      expect(second.$1.seat, 1);
    });

    test('au-delà du délai de grâce la partie est suspendue, puis reprend au retour', () {
      final (code, players) = lobby(2);
      send(players[0].$2, ClientMessage.start());
      final token = players[1].$1.token;
      manager.disconnect(players[1].$2);

      clock = clock.add(const Duration(minutes: 1));
      manager.sweep();
      expect(manager.room(code)!.phase, RoomPhase.playing);

      clock = clock.add(const Duration(minutes: 2));
      manager.sweep();
      expect(manager.room(code)!.phase, RoomPhase.suspended);
      expect(players[0].$1.lastRoom.phase, RoomPhase.suspended);

      final back = open();
      send(back.$2, ClientMessage.rejoin(token: token));
      expect(manager.room(code)!.phase, RoomPhase.playing);
    });

    test('dans un salon non commencé, un siège abandonné se libère après le délai', () {
      final (code, players) = lobby(3);
      manager.disconnect(players[2].$2);
      clock = clock.add(const Duration(minutes: 3));
      manager.sweep();
      expect(manager.room(code)!.seatCount, 2);
    });
  });

  group('ménage', () {
    test('un salon abandonné disparaît, fermant ses connexions', () {
      final (code, players) = lobby(2);
      clock = clock.add(const Duration(minutes: 31));
      manager.sweep();
      expect(manager.room(code), isNull);
      expect(manager.roomCount, 0);
      expect(players.every((p) => p.$1.closed), isTrue);
    });

    test('une partie en cours survit à une nuit, pas à deux jours', () {
      final (code, players) = lobby(2);
      send(players[0].$2, ClientMessage.start());
      clock = clock.add(const Duration(hours: 23));
      manager.sweep();
      expect(manager.room(code), isNotNull);
      clock = clock.add(const Duration(hours: 2));
      manager.sweep();
      expect(manager.room(code), isNull);
    });
  });

  group('limites', () {
    test('un message illisible, mal formé ou d\'une autre version reçoit une erreur, pas un plantage', () {
      final c = open();
      manager.onMessage(c.$2, 'pas du json');
      expect(c.$1.lastError, ErrorCode.badRequest);
      manager.onMessage(c.$2, '{"v":1,"type":"hack"}');
      expect(c.$1.lastError, ErrorCode.badRequest);
      manager.onMessage(c.$2, '{"v":42,"type":"start"}');
      expect(c.$1.lastError, ErrorCode.unsupportedVersion);
      manager.onMessage(c.$2, '[1,2]');
      expect(c.$1.lastError, ErrorCode.badRequest);
      expect(c.$1.closed, isFalse);
    });

    test('un message trop gros ferme la connexion', () {
      final c = open();
      manager.onMessage(c.$2, jsonEncode({'v': 1, 'type': 'create', 'params': {'name': 'x' * 5000}}));
      expect(c.$1.closed, isTrue);
    });

    test('une connexion qui inonde le serveur est freinée, puis repart avec le temps', () {
      final c = open();
      for (var i = 0; i < 25; i++) {
        manager.onMessage(c.$2, '{"v":1,"type":"leave"}');
      }
      expect(c.$1.of(ServerMessageType.error).where((m) => m.errorCode == ErrorCode.rateLimited), isNotEmpty);

      clock = clock.add(const Duration(seconds: 3));
      final before = c.$1.received.length;
      manager.onMessage(c.$2, '{"v":1,"type":"leave"}');
      expect(c.$1.received.skip(before).single.errorCode, ErrorCode.badRequest, reason: 'traité de nouveau');
    });

    test('deviner des codes de salon est limité par adresse', () {
      final c = open();
      final results = <ErrorCode>[];
      for (var i = 0; i < 12; i++) {
        clock = clock.add(const Duration(milliseconds: 100)); // un essai toutes les 100 ms : sous la limite de messages
        send(c.$2, ClientMessage.join(code: 'ZZZZ${'23456789'[i % 8]}', name: 'Bob'));
        results.add(c.$1.lastError!);
      }
      expect(results.take(10), everyElement(ErrorCode.roomNotFound));
      expect(results.skip(10), everyElement(ErrorCode.rateLimited));
    });

    test('créer des salons est limité par adresse', () {
      final results = <ServerMessageType>[];
      for (var i = 0; i < 7; i++) {
        final c = open();
        send(c.$2, ClientMessage.create(name: 'J$i'));
        results.add(c.$1.received.first.type);
      }
      expect(results.take(5), everyElement(ServerMessageType.joined));
      expect(results.skip(5), everyElement(ServerMessageType.error));
    });

    test('le nombre de connexions par adresse est plafonné', () {
      const config = ServerConfig(maxConnectionsPerIp: 2);
      final limited = newManager(config);
      expect(limited.connect(FakeConnection(), '1.1.1.1'), isNotNull);
      final second = limited.connect(FakeConnection(), '1.1.1.1');
      expect(limited.connect(FakeConnection(), '1.1.1.1'), isNull);
      expect(limited.connect(FakeConnection(), '2.2.2.2'), isNotNull, reason: 'une autre adresse n\'est pas touchée');

      limited.disconnect(second!);
      expect(limited.connect(FakeConnection(), '1.1.1.1'), isNotNull);
    });

    test('rouvrir des connexions en boucle ne redonne pas une rafale de messages', () {
      // Chaque connexion a son propre seau (rafale de 20) : sans seau commun à
      // l'adresse, dix connexions tour à tour enverraient 200 messages d'un coup.
      var limited = 0;
      for (var i = 0; i < 10; i++) {
        final c = open(ip: '9.9.9.9');
        for (var m = 0; m < 20; m++) {
          manager.onMessage(c.$2, '{"v":1,"type":"leave"}');
        }
        limited += c.$1.of(ServerMessageType.error).where((e) => e.errorCode == ErrorCode.rateLimited).length;
        manager.disconnect(c.$2);
      }
      expect(limited, greaterThan(0), reason: 'le seau de l\'adresse finit par se vider');
    });

    test('le rythme d\'ouverture des connexions d\'une adresse est limité, pas celui des autres', () {
      var refused = 0;
      for (var i = 0; i < 70; i++) {
        final connection = FakeConnection();
        final session = manager.connect(connection, '8.8.8.8');
        if (session == null) {
          refused++;
        } else {
          manager.disconnect(session);
        }
      }
      expect(refused, greaterThan(0));
      expect(manager.connect(FakeConnection(), '7.7.7.7'), isNotNull);

      clock = clock.add(const Duration(minutes: 1));
      expect(manager.connect(FakeConnection(), '8.8.8.8'), isNotNull, reason: 'le seau se remplit avec le temps');
    });

    test('le nombre total de salons est plafonné', () {
      final capped = newManager(const ServerConfig(maxRooms: 1, roomsCreatedPerMinute: 100));
      final a = FakeConnection();
      final b = FakeConnection();
      capped.onMessage(capped.connect(a, '1.1.1.1')!, jsonEncode(ClientMessage.create(name: 'A').toJson()));
      capped.onMessage(capped.connect(b, '2.2.2.2')!, jsonEncode(ClientMessage.create(name: 'B').toJson()));
      expect(a.received.first.type, ServerMessageType.joined);
      expect(b.lastError, ErrorCode.rateLimited);
    });
  });
}
