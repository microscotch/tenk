import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// Le fichier que la CI met à jour après chaque envoi réussi vers Google Play ou
/// TestFlight (voir `tool/publish_store_build.sh`).
const defaultLatestBuildsSource = 'https://raw.githubusercontent.com/microscotch/tenk/store-builds/latest.json';

/// Taille au-delà de laquelle le fichier n'est pas celui qu'on attend.
const _maxBodyBytes = 16 * 1024;

/// Relaie `latest.json` aux applications, sur `/latest-build` : c'est ce qui leur
/// fait proposer une mise à jour au lancement.
///
/// Le serveur ne connaît pas les builds lui-même (il n'est pas redéployé à chaque
/// build de l'application) : il relit le fichier de la CI toutes les [refresh] et
/// en garde la dernière version lisible. Les téléphones ne parlent ainsi qu'à ce
/// serveur, qui ne tient aucun journal — jamais à GitHub. Un incident de lecture
/// garde la version précédente ; tant qu'aucune n'a été lue, la route répond 503
/// et l'application ne propose rien.
class LatestBuildRelay {
  /// Rend le contenu du fichier, ou nul s'il n'a pas pu être lu.
  final Future<String?> Function() fetch;
  final Duration refresh;

  String? _body;
  Timer? _timer;

  LatestBuildRelay({required this.fetch, this.refresh = const Duration(minutes: 10)});

  /// Relit [source] par HTTP.
  factory LatestBuildRelay.http(Uri source, {Duration refresh = const Duration(minutes: 10)}) =>
      LatestBuildRelay(fetch: () => fetchText(source), refresh: refresh);

  /// La dernière version lisible, ou nul.
  String? get body => _body;

  /// Relit le fichier maintenant ; n'en retient qu'un objet JSON de taille raisonnable.
  Future<void> refreshNow() async {
    try {
      final body = await fetch();
      if (body == null || body.length > _maxBodyBytes) return;
      if (jsonDecode(body) is! Map) return;
      _body = body;
    } catch (_) {
      // Fichier illisible : on garde la version précédente.
    }
  }

  /// Lit le fichier tout de suite, puis toutes les [refresh].
  void start() {
    unawaited(refreshNow());
    _timer ??= Timer.periodic(refresh, (_) => refreshNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Response response() {
    final body = _body;
    if (body == null) return Response(HttpStatus.serviceUnavailable, body: 'pas encore lu');
    return Response.ok(body, headers: {'content-type': 'application/json', 'cache-control': 'no-store'});
  }
}

/// Le texte de [url], ou nul sur une erreur ou une réponse autre que 200.
Future<String?> fetchText(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final response = await (await client.getUrl(url)).close().timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    return await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
