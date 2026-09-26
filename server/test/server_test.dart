import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../lib/game/game_recording.dart';
import '../../lib/game/online/protocol.dart';
import '../src/limits.dart';
import '../src/room_manager.dart';
import '../src/server.dart';

/// Un vrai client WebSocket qui range ce qu'il reçoit.
class Client {
  final WebSocketChannel channel;
  final List<ServerMessage> received = [];
  final _waiters = <Completer<void>>[];

  /// Se termine quand le serveur (ou nous) a fermé la socket.
  final Completer<void> closed = Completer<void>();

  Client(Uri uri) : channel = WebSocketChannel.connect(uri) {
    channel.stream.listen(
      (data) {
        received.add(ServerMessage.fromJson(jsonDecode(data as String)));
        for (final w in _waiters.toList()) {
          if (!w.isCompleted) w.complete();
        }
      },
      onDone: closed.complete,
    );
  }

  void send(ClientMessage m) => channel.sink.add(jsonEncode(m.toJson()));

  /// Attend le premier message qui vérifie [test] (déjà reçu ou à venir).
  Future<ServerMessage> waitFor(bool Function(ServerMessage) test, {String what = 'message'}) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    for (;;) {
      final hit = received.where(test);
      if (hit.isNotEmpty) return hit.first;
      final wait = Completer<void>();
      _waiters.add(wait);
      await wait.future.timeout(deadline.difference(DateTime.now()), onTimeout: () => throw TimeoutException(what));
    }
  }
}

void main() {
  late HttpServer server;
  late Uri uri;
  late RoomManager manager;

  setUp(() async {
    manager = RoomManager(authorityRandom: () => Random(11));
    server = await shelf_io.serve(buildHandler(manager), 'localhost', 0);
    uri = Uri.parse('ws://localhost:${server.port}/ws');
  });

  tearDown(() => server.close(force: true));

  test('/healthz répond, le reste est introuvable', () async {
    final client = HttpClient();
    final ok = await (await client.getUrl(Uri.parse('http://localhost:${server.port}/healthz'))).close();
    expect(ok.statusCode, 200);
    final missing = await (await client.getUrl(Uri.parse('http://localhost:${server.port}/nope'))).close();
    expect(missing.statusCode, 404);
    client.close();
  });

  test('deux joueurs, de la création du salon au premier lancer, par de vraies sockets', () async {
    final anna = Client(uri)..send(ClientMessage.create(name: 'Anna'));
    final code = (await anna.waitFor((m) => m.type == ServerMessageType.joined, what: 'joined')).roomCode;

    final bob = Client(uri)..send(ClientMessage.join(code: code, name: 'Bob'));
    await bob.waitFor((m) => m.type == ServerMessageType.joined, what: 'joined Bob');
    await anna.waitFor((m) => m.type == ServerMessageType.room && m.seats.length == 2, what: 'salon à deux');

    anna.send(ClientMessage.start());
    final snapshot = await bob.waitFor((m) => m.type == ServerMessageType.snapshot, what: 'snapshot');
    expect(snapshot.names, ['Anna', 'Bob']);
    await anna.waitFor((m) => m.type == ServerMessageType.snapshot, what: 'snapshot Anna');

    final current = manager.room(code)!.authority!.currentSeat!;
    (current == 0 ? anna : bob).send(ClientMessage.play(GameActionType.roll));
    for (final c in [anna, bob]) {
      final action = await c.waitFor((m) => m.type == ServerMessageType.action, what: 'action');
      expect(action.action.type, GameActionType.roll);
      expect(action.action.faces, hasLength(5));
    }

    await anna.channel.sink.close();
    await bob.channel.sink.close();
  });

  test('la fermeture d\'une socket marque le joueur déconnecté, son jeton le ramène à son siège', () async {
    final anna = Client(uri)..send(ClientMessage.create(name: 'Anna'));
    final code = (await anna.waitFor((m) => m.type == ServerMessageType.joined, what: 'joined')).roomCode;
    final bob = Client(uri)..send(ClientMessage.join(code: code, name: 'Bob'));
    final bobToken = (await bob.waitFor((m) => m.type == ServerMessageType.joined, what: 'joined Bob')).token;

    await bob.channel.sink.close();
    await anna.waitFor((m) => m.type == ServerMessageType.room && m.seats.length == 2 && !m.seats[1].connected,
        what: 'Bob déconnecté');

    final bobAgain = Client(uri)..send(ClientMessage.rejoin(token: bobToken));
    final back = await bobAgain.waitFor((m) => m.type == ServerMessageType.joined, what: 'retour');
    expect(back.seat, 1);
    await anna.waitFor((m) => m.type == ServerMessageType.room && m.seats.length == 2 && m.seats[1].connected,
        what: 'Bob reconnecté');
  });

  test('un message texte invalide reçoit une erreur, un message binaire ferme la connexion', () async {
    final client = Client(uri);
    client.channel.sink.add('pas du json');
    final error = await client.waitFor((m) => m.type == ServerMessageType.error, what: 'erreur');
    expect(error.errorCode, ErrorCode.badRequest);

    client.channel.sink.add([1, 2, 3]);
    await client.closed.future.timeout(const Duration(seconds: 5));
  });

  test('au-delà du plafond de connexions par adresse, la socket est refusée', () async {
    await server.close(force: true);
    manager = RoomManager(config: const ServerConfig(maxConnectionsPerIp: 1));
    server = await shelf_io.serve(buildHandler(manager), 'localhost', 0);
    final url = Uri.parse('ws://localhost:${server.port}/ws');

    final first = Client(url)..send(ClientMessage.create(name: 'A'));
    await first.waitFor((m) => m.type == ServerMessageType.joined, what: 'première connexion');

    final second = Client(url);
    await second.closed.future.timeout(const Duration(seconds: 5));
    expect(second.channel.closeCode, closeTryLater);
  });
}
