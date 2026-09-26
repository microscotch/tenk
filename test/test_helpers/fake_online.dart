import 'dart:async';
import 'dart:convert';

import 'package:le10000/game/online/protocol.dart';
import 'package:le10000/state/online_transport.dart';

/// Le serveur vu du client : ce que l'app envoie, et de quoi lui répondre.
class FakeChannel implements OnlineChannel {
  final _incoming = StreamController<String>();
  final List<ClientMessage> sent = [];
  bool closed = false;

  @override
  Stream<String> get incoming => _incoming.stream;

  @override
  void send(String message) => sent.add(ClientMessage.fromJson(jsonDecode(message)));

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }

  /// Le serveur envoie [message] au client.
  void serverSends(ServerMessage message) => _incoming.add(jsonEncode(message.toJson()));

  /// Le serveur (ou le réseau) coupe la connexion.
  Future<void> serverDrops() => _incoming.close();

  ClientMessage? get lastSent => sent.isEmpty ? null : sent.last;
}

class FakeTransport implements OnlineTransport {
  final List<FakeChannel> channels = [];
  final List<Uri> urls = [];

  /// Vrai : le serveur est injoignable.
  bool unreachable = false;

  FakeChannel get current => channels.last;

  @override
  Future<OnlineChannel> connect(Uri url) async {
    if (unreachable) throw StateError('injoignable');
    urls.add(url);
    final channel = FakeChannel();
    channels.add(channel);
    return channel;
  }
}

class FakeCredentialsStore implements OnlineCredentialsStore {
  OnlineCredentials? saved;

  @override
  Future<OnlineCredentials?> load() async => saved;

  @override
  Future<void> save(OnlineCredentials credentials) async => saved = credentials;

  @override
  Future<void> clear() async => saved = null;
}
