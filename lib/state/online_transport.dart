import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
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

/// Le nom et la version d'OS tels qu'ils doivent apparaître dans le
/// User-Agent — jamais déduits de [Platform.operatingSystemVersion] : sur
/// Android, dart:io ne donne que la version du noyau Linux sous-jacent
/// ("Linux 5.15.78-android13-…"), pas la version Android ("14"), vérifiée
/// nulle part sur cette machine de dev (ARM64 sans appareil Android/iOS
/// branché) — [DeviceInfoPlugin] donne la vraie version système sur les deux
/// plateformes cibles (`AndroidDeviceInfo.version.release`,
/// `IosDeviceInfo.systemVersion`). Linux/macOS/Windows (desktop, jamais une
/// cible publiée — voir CLAUDE.md) gardent [Platform.operatingSystemVersion],
/// son format n'y posant pas ce problème.
Future<String> _platformAndVersion() async {
  final plugin = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final info = await plugin.androidInfo;
    return 'Android ${info.version.release}';
  }
  if (Platform.isIOS) {
    final info = await plugin.iosInfo;
    return 'iOS ${info.systemVersion}';
  }
  final name = Platform.isMacOS
      ? 'macOS'
      : Platform.isWindows
          ? 'Windows'
          : Platform.isLinux
              ? 'Linux'
              : Platform.operatingSystem;
  return '$name ${Platform.operatingSystemVersion}';
}

/// Le User-Agent envoyé par toute requête vers le serveur (WebSocket et
/// `/latest-build`) : `<nom>/<version>+<build> (<plateforme> <version OS>)`,
/// par ex. `TenK/1.0.0+95 (Android 14)` ou `TenK/1.0.0+95 (iOS 17.4.1)` — de
/// quoi filtrer ces routes sur le reverse proxy (voir CLAUDE.md) et
/// distinguer la plateforme/version qui se connecte. Toujours de la forme
/// `<nom>/…`, y compris en repli (`TenK/0`) : un filtre Apache `^TenK/` ne
/// doit jamais se mettre à tout refuser faute de ce `/`. Les deux sources
/// (`PackageInfo`, `DeviceInfoPlugin`) échouent indépendamment : un plugin
/// absent ne prive jamais l'autre de son information (pas de plugin sous
/// `flutter test`, voir `test/state/online_e2e_test.dart`, qui se connecte
/// pour de vrai sans surcharger `onlineTransportProvider` ; le serveur ne
/// doit jamais être bloqué par cet échec, comme les autres accès
/// best-effort du projet). Mis en cache seulement après un succès de
/// `PackageInfo` : une exception transitoire (le cas sous test) ne doit pas
/// figer le joueur sur un repli dégradé pour le reste du process.
String? _cachedUserAgent;

Future<String> tenkUserAgent() async {
  final cached = _cachedUserAgent;
  if (cached != null) return cached;

  String appAndVersion;
  var appInfoOk = true;
  try {
    final info = await PackageInfo.fromPlatform();
    appAndVersion = '${info.appName}/${info.version}+${info.buildNumber}';
  } catch (_) {
    appAndVersion = 'TenK/0';
    appInfoOk = false;
  }

  String? platform;
  try {
    platform = await _platformAndVersion();
  } catch (_) {
    platform = null;
  }

  final userAgent = platform == null ? appAndVersion : '$appAndVersion ($platform)';
  if (appInfoOk) _cachedUserAgent = userAgent;
  return userAgent;
}

class WebSocketTransport implements OnlineTransport {
  const WebSocketTransport();

  @override
  Future<OnlineChannel> connect(Uri url) async {
    // `WebSocket.userAgent` (dart:io) REMPLACE la valeur par défaut du
    // client HTTP interne PARTAGÉ de `WebSocket.connect` (son propre
    // singleton statique, jamais celui qu'on créerait nous-mêmes) — vérifié
    // à la main (`nc -l` + requête réelle) : une seule valeur arrive au
    // serveur. `headers: {'User-Agent': ...}` ou `customClient:` ont tous
    // deux été essayés et écartés :
    // - `headers` S'AJOUTE à la valeur par défaut plutôt que de la
    //   remplacer : le serveur recevrait `Dart/x (dart:io), TenK/…`, qui ne
    //   matche plus un filtre Apache `^TenK/`.
    // - `customClient` crée un NOUVEAU HttpClient, qui plante sous `flutter
    //   test` (test/state/online_e2e_test.dart, qui se connecte pour de
    //   vrai) : le mock HTTP du binding de test l'intercepte et ne sait pas
    //   servir un upgrade WebSocket — alors que le singleton par défaut
    //   d'IOWebSocketChannel.connect (sans customClient) y échappe.
    WebSocket.userAgent = await tenkUserAgent();
    final channel = IOWebSocketChannel.connect(url);
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
