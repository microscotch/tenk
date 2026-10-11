import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';

import '../../lib/game/game_recording.dart';
import '../../lib/game/game_setup.dart';
import '../../lib/game/online/protocol.dart';
import '../src/limits.dart';
import '../src/room.dart';
import '../src/room_manager.dart';
import 'fake_connection.dart';
import 'fake_scheduler.dart';

/// Des dés choisis : [prefix] d'abord (faces de 1 à 6), puis toujours des as.
class _Dice implements Random {
  final List<int> prefix;
  var _i = 0;
  _Dice(this.prefix);

  @override
  int nextInt(int max) => _i < prefix.length ? prefix[_i++] - 1 : 0;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

void main() {
  late DateTime clock;
  late FakeScheduler scheduler;
  late RoomManager manager;
  late List<int> dicePrefix;

  /// Le scénario d'une partie de [count] joueurs : le tirage donne la main au
  /// siège 0, qui fait une quinte d'as (10000 pile) ; chaque autre joueur craque
  /// ensuite son dernier tour — la partie est finie.
  List<int> quickGame(int count) => [
        for (var i = 0; i < count; i++) 2 + i,
        1, 1, 1, 1, 1,
        for (var i = 1; i < count; i++) ...[2, 3, 4, 6, 2],
      ];

  setUp(() {
    clock = DateTime(2026, 10, 11, 12);
    scheduler = FakeScheduler(onAdvance: (d) => clock = clock.add(d));
    dicePrefix = quickGame(2);
    manager = RoomManager(
      config: const ServerConfig(),
      now: () => clock,
      secure: Random(99),
      authorityRandom: () => _Dice(dicePrefix),
      scheduler: scheduler,
    );
  });

  (FakeConnection, Session) open() {
    final connection = FakeConnection();
    return (connection, manager.connect(connection, '10.0.0.1')!);
  }

  void send(Session session, ClientMessage message) => manager.onMessage(session, jsonEncode(message.toJson()));

  /// Un salon de [count] joueurs ; [features] dit ce que chacun annonce (par
  /// défaut, tout ce que le serveur connaît).
  (String, List<(FakeConnection, Session)>) lobby(int count, {List<List<String>>? features}) {
    List<String> f(int i) => features?[i] ?? serverFeatures;
    final host = open();
    send(host.$2, ClientMessage.create(name: 'J1', features: f(0)));
    final code = host.$1.of(ServerMessageType.joined).last.roomCode;
    final players = [host];
    for (var i = 1; i < count; i++) {
      final p = open();
      send(p.$2, ClientMessage.join(code: code, name: 'J${i + 1}', features: f(i)));
      players.add(p);
    }
    return (code, players);
  }

  (String, List<(FakeConnection, Session)>) started(int count, {List<List<String>>? features}) {
    final (code, players) = lobby(count, features: features);
    send(players.first.$2, ClientMessage.start());
    return (code, players);
  }

  group('bot de siège', () {
    test('quitter une partie en cours : un bot reprend le siège, connecté, et l\'ancien jeton ne sert plus', () {
      final (code, players) = started(2);
      final token = players[1].$1.token;
      send(players[1].$2, ClientMessage.leave());

      final seats = players[0].$1.lastRoom.seats;
      expect(seats[1].bot, isTrue);
      expect(seats[1].connected, isTrue, reason: 'un client d\'avant ne doit pas le montrer absent');
      expect(manager.room(code)!.phase, RoomPhase.playing);

      final back = open();
      send(back.$2, ClientMessage.rejoin(token: token));
      expect(back.$1.lastError, ErrorCode.badToken);
    });

    test('le bot joue quand c\'est son tour, au rythme prévu, et la partie continue jusqu\'au bout', () {
      final (code, players) = started(2);
      final room = manager.room(code)!;
      final starter = room.authority!.currentSeat!;
      // Le premier joueur part avant même de jouer : son bot lance la partie.
      send(players[starter].$2, ClientMessage.leave());
      final other = players[1 - starter].$1;
      expect(other.lastRoom.begun, isTrue);
      expect(other.of(ServerMessageType.action), isEmpty, reason: 'le bot réfléchit avant de jouer');

      scheduler.elapse(const ServerConfig().botActionDelay);
      expect(other.of(ServerMessageType.action).first.action.type, GameActionType.roll);

      // Quinte d'as au premier lancer : le bot garde, et atteint 10000. À
      // l'autre joueur de jouer son dernier tour.
      scheduler.elapse(const Duration(seconds: 10));
      expect(room.authority!.engine!.players.first.totalScore, 10000);
      expect(room.authority!.currentSeat, 1 - starter);
      expect(scheduler.pendingCount, 0, reason: 'le bot attend son tour');

      final human = players[1 - starter].$2;
      send(human, ClientMessage.play(GameActionType.roll));
      send(human, ClientMessage.play(GameActionType.endBustedTurn));
      expect(room.authority!.isOver, isTrue);
      expect(other.lastRoom.phase, RoomPhase.over);
    });

    test('un bot ne suspend jamais la partie', () {
      final (code, players) = started(3);
      send(players[2].$2, ClientMessage.leave());
      clock = clock.add(const Duration(minutes: 5));
      manager.sweep();
      expect(manager.room(code)!.phase, RoomPhase.playing);
    });

    test('le dernier humain parti, le salon se ferme ; un joueur seulement déconnecté le retient', () {
      final (code, players) = started(3);
      manager.disconnect(players[0].$2);
      send(players[1].$2, ClientMessage.leave());
      send(players[2].$2, ClientMessage.leave());
      expect(manager.room(code), isNotNull, reason: 'J1, coupé, garde son siège et peut revenir');

      final back = open();
      send(back.$2, ClientMessage.rejoin(token: players[0].$1.token));
      send(back.$2, ClientMessage.leave());
      expect(manager.room(code), isNull);
      expect(players[1].$1.closed && players[2].$1.closed, isFalse, reason: 'partis d\'eux-mêmes, déjà détachés');
      expect(scheduler.pendingCount, 0, reason: 'les minuteries du salon sont annulées');
    });
  });

  group('signal de départ', () {
    test('seul le premier joueur lance la partie ; les autres l\'apprennent par `room`', () {
      final (code, players) = started(3);
      final starter = manager.room(code)!.authority!.startingSeat!;
      final other = (starter + 1) % 3;
      expect(players[other].$1.lastRoom.begun, isFalse);

      send(players[other].$2, ClientMessage.begin());
      expect(players[other].$1.lastError, ErrorCode.notYourTurn);

      send(players[starter].$2, ClientMessage.begin());
      for (final p in players) {
        expect(p.$1.lastRoom.begun, isTrue);
      }
    });

    test('un premier joueur d\'avant, qui ne dit pas `begin`, lance la partie par son premier coup', () {
      final (code, players) = started(2, features: [const [], const []]);
      final starter = manager.room(code)!.authority!.startingSeat!;
      send(players[starter].$2, ClientMessage.play(GameActionType.roll));
      expect(players[1 - starter].$1.lastRoom.begun, isTrue);
    });
  });

  group('revanche', () {
    /// Une partie finie, gagnée par le siège 0 (voir [quickGame]).
    (String, List<(FakeConnection, Session)>) finished({List<List<String>>? features, int count = 2}) {
      dicePrefix = quickGame(count);
      final (code, players) = started(count, features: features);
      final room = manager.room(code)!;
      expect(room.authority!.startingSeat, 0);
      send(players[0].$2, ClientMessage.play(GameActionType.roll));
      send(players[0].$2, ClientMessage.play(GameActionType.applyKeep, params: {'declineFivesCount': 0}));
      while (!room.authority!.isOver) {
        final seat = room.authority!.currentSeat!;
        send(players[seat].$2, ClientMessage.play(GameActionType.roll));
        send(players[seat].$2, ClientMessage.play(GameActionType.endBustedTurn));
      }
      expect(room.phase, RoomPhase.over);
      return (code, players);
    }

    test('acceptée par tous : même salon, joueurs dans l\'ordre précédent, le meilleur score commence, sans tirage', () {
      final (code, players) = finished(count: 3);
      final room = manager.room(code)!;
      final previousOrder = room.authority!.playOrder!;

      send(players[2].$2, ClientMessage.rematch(RematchAnswer.propose));
      final pending = players[0].$1.of(ServerMessageType.rematch).last;
      expect(pending.rematchStatus, RematchStatus.pending);
      expect(pending.proposerSeat, 2);
      expect(pending.remaining, const Duration(seconds: 60));

      send(players[0].$2, ClientMessage.rematch(RematchAnswer.accept));
      send(players[1].$2, ClientMessage.rematch(RematchAnswer.propose)); // vaut acceptation

      expect(room.phase, RoomPhase.playing);
      // J1 (siège 0) a gagné : il commence, puis l'ordre de jeu précédent.
      final start = previousOrder.indexOf(0);
      expect(room.names, [for (var k = 0; k < 3; k++) 'J${previousOrder[(start + k) % 3] + 1}']);
      for (final p in players) {
        final snapshot = p.$1.of(ServerMessageType.snapshot).last;
        expect(snapshot.actions.first.type, GameActionType.presetOrder);
        expect(p.$1.lastRoom.begun, isTrue);
        // `joined` (le nouveau siège) arrive avant le journal de la revanche.
        final joinedAt = p.$1.received.lastIndexWhere((m) => m.type == ServerMessageType.joined);
        final snapshotAt = p.$1.received.lastIndexWhere((m) => m.type == ServerMessageType.snapshot);
        expect(joinedAt, lessThan(snapshotAt));
      }
      final replayed = replayGame(GameSetup(playerNames: room.names), 0, players[0].$1.of(ServerMessageType.snapshot).last.actions);
      expect(replayed.engine!.players.map((p) => p.name), room.names);
    });

    test('un refus exclut son auteur ; à moins de deux, la revanche est abandonnée et le salon se ferme', () {
      final (code, players) = finished();
      send(players[0].$2, ClientMessage.rematch(RematchAnswer.propose));
      send(players[1].$2, ClientMessage.rematch(RematchAnswer.refuse));

      expect(players[1].$1.of(ServerMessageType.rematch).last.rematchStatus, RematchStatus.excluded);
      expect(players[0].$1.of(ServerMessageType.rematch).last.rematchStatus, RematchStatus.cancelled);
      expect(manager.room(code), isNull);
    });

    test('sans réponse au bout de 60 s, c\'est un refus : la revanche part sans lui', () {
      final (code, players) = finished(count: 3);
      send(players[0].$2, ClientMessage.rematch(RematchAnswer.propose));
      send(players[1].$2, ClientMessage.rematch(RematchAnswer.accept));
      final room = manager.room(code)!;
      expect(room.phase, RoomPhase.over, reason: 'J3 n\'a pas encore répondu');

      scheduler.elapse(const Duration(seconds: 60));
      expect(players[2].$1.of(ServerMessageType.rematch).last.rematchStatus, RematchStatus.excluded);
      expect(room.phase, RoomPhase.playing);
      expect(room.seatCount, 2);
    });

    test('un client d\'avant ne reçoit rien de la revanche, et compte comme un refus', () {
      final (code, players) = finished(count: 3, features: [serverFeatures, serverFeatures, const []]);
      send(players[0].$2, ClientMessage.rematch(RematchAnswer.propose));
      send(players[1].$2, ClientMessage.rematch(RematchAnswer.accept));

      final room = manager.room(code)!;
      expect(room.phase, RoomPhase.playing, reason: 'les deux qui pouvaient répondre l\'ont fait');
      expect(room.seatCount, 2);
      expect(players[2].$1.of(ServerMessageType.rematch), isEmpty);
    });

    test('impossible hors d\'une partie finie', () {
      final (_, players) = started(2);
      send(players[0].$2, ClientMessage.rematch(RematchAnswer.propose));
      expect(players[0].$1.lastError, ErrorCode.badRequest);
    });
  });

  group('émotions de la seconde série', () {
    test('telles quelles pour qui les connaît, rétrogradées pour les autres, rien pour une émotion inconnue d\'eux', () {
      final (_, players) = started(2, features: [serverFeatures, const [emotesFeature]]);

      send(players[0].$2, ClientMessage.emote(Emote.angry, phrase: 'lucky'));
      expect(players[0].$1.of(ServerMessageType.emote).last.emote, (Emote.angry, 'lucky'));
      expect(players[1].$1.of(ServerMessageType.emote).last.emote, (Emote.devastated, 'lucky'));

      clock = clock.add(emoteCooldown);
      send(players[0].$2, ClientMessage.emote(Emote.relieved, phrase: 'phew'));
      expect(players[0].$1.of(ServerMessageType.emote).last.emote, (Emote.relieved, 'phew'));
      expect(players[1].$1.of(ServerMessageType.emote), hasLength(1), reason: 'Soulagé lui est inconnu');
    });
  });
}
