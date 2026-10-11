import '../../lib/game/online/protocol.dart';
import '../src/room.dart';

/// Une connexion de test : ce que le serveur lui envoie est gardé pour être
/// vérifié.
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
