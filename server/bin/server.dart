import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;

import '../src/latest_build.dart';
import '../src/limits.dart';
import '../src/links.dart';
import '../src/room_manager.dart';
import '../src/server.dart';

/// Serveur des parties en ligne de Le 10000.
///
/// Réglages par variables d'environnement : `PORT` (8080), `HOST` (0.0.0.0),
/// `TRUST_PROXY=1` si le serveur n'est joignable que par un reverse proxy qui
/// pose `X-Forwarded-For` (à faire : le TLS, donc `wss://`, s'y termine), et
/// `TENK_ANDROID_CERT_SHA256` : les empreintes SHA-256 (séparées par des
/// virgules) des certificats qui signent l'application Android, pour que les
/// liens d'invitation l'ouvrent (voir `LinkConfig`). `TENK_LATEST_BUILDS_URL` :
/// où relire le dernier build de chaque store, relayé sur `/latest-build` (par
/// défaut, le `latest.json` de la branche `store-builds` ; vide : route coupée).
Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  final trustProxy = Platform.environment['TRUST_PROXY'] == '1';
  final links = LinkConfig(androidCertSha256: LinkConfig.parseFingerprints(Platform.environment['TENK_ANDROID_CERT_SHA256']));

  final latestSource = Platform.environment['TENK_LATEST_BUILDS_URL'] ?? defaultLatestBuildsSource;
  final latestBuild = latestSource.isEmpty ? null : (LatestBuildRelay.http(Uri.parse(latestSource))..start());

  final manager = RoomManager(config: const ServerConfig());
  final server = await shelf_io.serve(
    buildHandler(manager, trustProxy: trustProxy, links: links, latestBuild: latestBuild),
    host,
    port,
  );
  final sweeper = Timer.periodic(const Duration(seconds: 30), (_) => manager.sweep());
  stdout.writeln('tenk_server à l\'écoute sur $host:${server.port} (proxy de confiance : $trustProxy)');

  Future<void> stop(ProcessSignal signal) async {
    stdout.writeln('arrêt ($signal)');
    sweeper.cancel();
    latestBuild?.stop();
    await server.close(force: true);
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(stop);
  ProcessSignal.sigterm.watch().listen(stop);
}
