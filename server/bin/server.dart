import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;

import '../src/limits.dart';
import '../src/room_manager.dart';
import '../src/server.dart';

/// Serveur des parties en ligne de Le 10000.
///
/// Réglages par variables d'environnement : `PORT` (8080), `HOST` (0.0.0.0),
/// `TRUST_PROXY=1` si le serveur n'est joignable que par un reverse proxy qui
/// pose `X-Forwarded-For` (à faire : le TLS, donc `wss://`, s'y termine).
Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  final trustProxy = Platform.environment['TRUST_PROXY'] == '1';

  final manager = RoomManager(config: const ServerConfig());
  final server = await shelf_io.serve(buildHandler(manager, trustProxy: trustProxy), host, port);
  final sweeper = Timer.periodic(const Duration(seconds: 30), (_) => manager.sweep());
  stdout.writeln('tenk_server à l\'écoute sur $host:${server.port} (proxy de confiance : $trustProxy)');

  Future<void> stop(ProcessSignal signal) async {
    stdout.writeln('arrêt ($signal)');
    sweeper.cancel();
    await server.close(force: true);
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(stop);
  ProcessSignal.sigterm.watch().listen(stop);
}
