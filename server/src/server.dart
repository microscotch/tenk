import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../lib/game/online/protocol.dart';
import 'room.dart';
import 'room_manager.dart';

/// Code de fermeture applicatif « réessayez plus tard » (les codes standards 1xxx
/// ne sont pas tous permis à l'émission ; 4000-4999 est réservé aux applications).
const int closeTryLater = 4013;

/// Une connexion WebSocket vue comme une [Connection].
class SocketConnection implements Connection {
  final WebSocketChannel _channel;
  var _closed = false;

  SocketConnection(this._channel);

  @override
  void send(ServerMessage message) {
    if (_closed) return;
    _channel.sink.add(jsonEncode(message.toJson()));
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _channel.sink.close();
  }
}

/// Les routes du serveur : `/ws` (les parties) et `/healthz` (supervision).
///
/// [trustProxy] : derrière un reverse proxy (TLS), l'adresse du client est la
/// dernière de `X-Forwarded-For`, celle que le proxy a lui-même constatée.
/// Ne l'activer que si le serveur n'est joignable QUE par ce proxy — sinon
/// n'importe qui pourrait choisir l'adresse qu'on lui attribue.
Handler buildHandler(RoomManager manager, {bool trustProxy = false}) {
  return (Request request) {
    switch (request.url.path) {
      case 'healthz':
        return Response.ok('ok');
      case 'ws':
        final ip = _clientIp(request, trustProxy);
        return webSocketHandler(
          (WebSocketChannel channel, String? _) => _serve(manager, channel, ip),
          pingInterval: const Duration(seconds: 30),
        )(request);
      default:
        return Response.notFound('not found');
    }
  };
}

void _serve(RoomManager manager, WebSocketChannel channel, String ip) {
  final connection = SocketConnection(channel);
  final session = manager.connect(connection, ip);
  if (session == null) {
    channel.sink.close(closeTryLater);
    return;
  }
  channel.stream.listen(
    (data) {
      if (data is String) {
        manager.onMessage(session, data);
      } else {
        connection.send(ServerMessage.error(ErrorCode.badRequest, 'messages texte uniquement'));
        connection.close();
      }
    },
    onDone: () => manager.disconnect(session),
    onError: (Object _) => manager.disconnect(session),
    cancelOnError: true,
  );
}

String _clientIp(Request request, bool trustProxy) {
  if (trustProxy) {
    final forwarded = request.headers['x-forwarded-for'];
    if (forwarded != null && forwarded.trim().isNotEmpty) return forwarded.split(',').last.trim();
  }
  final info = request.context['shelf.io.connection_info'];
  return info is HttpConnectionInfo ? info.remoteAddress.address : 'unknown';
}
