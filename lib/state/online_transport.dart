import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Un canal ouvert vers le serveur : du texte dans les deux sens.
abstract class OnlineChannel {
  /// Les messages reçus ; se termine quand la connexion se ferme (ou tombe).
  Stream<String> get incoming;

  void send(String message);

  Future<void> close();
}

/// Ouvre les canaux. Surchargeable en test (voir `onlineTransportProvider`).
abstract class OnlineTransport {
  /// Ouvre la connexion, ou lève si le serveur est injoignable.
  Future<OnlineChannel> connect(Uri url);
}

class WebSocketTransport implements OnlineTransport {
  const WebSocketTransport();

  @override
  Future<OnlineChannel> connect(Uri url) async {
    final channel = WebSocketChannel.connect(url);
    await channel.ready.timeout(const Duration(seconds: 10));
    return _WebSocketOnlineChannel(channel);
  }
}

class _WebSocketOnlineChannel implements OnlineChannel {
  final WebSocketChannel _channel;

  _WebSocketOnlineChannel(this._channel);

  @override
  Stream<String> get incoming => _channel.stream.where((d) => d is String).cast<String>();

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  Future<void> close() => _channel.sink.close();
}

/// De quoi revenir dans un salon : le jeton que le serveur a remis à ce joueur.
class OnlineCredentials {
  final String url;
  final String code;
  final String token;

  const OnlineCredentials({required this.url, required this.code, required this.token});
}

/// Garde les [OnlineCredentials] d'une session à l'autre, pour reprendre sa
/// place après une coupure ou un relancement de l'app.
abstract class OnlineCredentialsStore {
  Future<OnlineCredentials?> load();
  Future<void> save(OnlineCredentials credentials);
  Future<void> clear();
}

class SharedPreferencesCredentialsStore implements OnlineCredentialsStore {
  const SharedPreferencesCredentialsStore();

  static const _keyUrl = 'online.url';
  static const _keyCode = 'online.code';
  static const _keyToken = 'online.token';

  // Best-effort, comme les préférences : un disque ou un backend indisponible
  // ne doit jamais empêcher de jouer.
  @override
  Future<OnlineCredentials?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString(_keyUrl);
      final code = prefs.getString(_keyCode);
      final token = prefs.getString(_keyToken);
      if (url == null || code == null || token == null) return null;
      return OnlineCredentials(url: url, code: code, token: token);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(OnlineCredentials credentials) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUrl, credentials.url);
      await prefs.setString(_keyCode, credentials.code);
      await prefs.setString(_keyToken, credentials.token);
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUrl);
      await prefs.remove(_keyCode);
      await prefs.remove(_keyToken);
    } catch (_) {}
  }
}
