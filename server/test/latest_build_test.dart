import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../src/latest_build.dart';
import '../src/limits.dart';
import '../src/room_manager.dart';
import '../src/server.dart';

const _latest = '{"android": {"version": "1.0.0", "build": 95, "availableFrom": "2026-10-05T01:00:00Z"}}';

void main() {
  Future<Response> get(LatestBuildRelay? relay) async {
    final handler = buildHandler(RoomManager(config: const ServerConfig()), latestBuild: relay);
    return handler(Request('GET', Uri.parse('https://tenk.microscotch.net/latest-build')));
  }

  test('relaie le dernier fichier lu, en JSON et sans cache', () async {
    final relay = LatestBuildRelay(fetch: () async => _latest);
    await relay.refreshNow();

    final response = await get(relay);
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], 'application/json');
    expect(response.headers['cache-control'], 'no-store');
    expect(await response.readAsString(), _latest);
  });

  test('503 tant que rien n\'a été lu', () async {
    final relay = LatestBuildRelay(fetch: () async => null);
    await relay.refreshNow();
    expect((await get(relay)).statusCode, 503);
  });

  test('un incident garde la version précédente', () async {
    String? next = _latest;
    final relay = LatestBuildRelay(fetch: () async => next);
    await relay.refreshNow();

    for (final bad in [null, '<html>404</html>', '[]', '{"x": "${'a' * 20000}"}']) {
      next = bad;
      await relay.refreshNow();
      expect(relay.body, _latest, reason: '$bad');
    }
  });

  test('une lecture qui échoue ne casse rien', () async {
    final relay = LatestBuildRelay(fetch: () async => throw Exception('réseau'));
    await relay.refreshNow();
    expect(relay.body, isNull);
  });

  test('route absente sans relais', () async {
    expect((await get(null)).statusCode, 404);
  });
}
