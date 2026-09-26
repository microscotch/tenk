import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../src/limits.dart';
import '../src/links.dart';
import '../src/room_manager.dart';
import '../src/server.dart';

const _fingerprint = '77:08:53:43:37:59:37:34:41:E3:E4:41:45:0B:9E:19:69:B0:24:85:93:37:84:29:56:CC:3E:92:66:80:79:EC';

void main() {
  Future<Response> get(String path, {LinkConfig links = const LinkConfig(androidCertSha256: [_fingerprint])}) {
    final handler = buildHandler(RoomManager(config: const ServerConfig()), links: links);
    return Future.value(handler(Request('GET', Uri.parse('https://tenk.microscotch.net$path'))));
  }

  group('apple-app-site-association', () {
    test('autorise l\'application sur /j/*, en JSON', () async {
      final response = await get('/.well-known/apple-app-site-association');
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'application/json');
      final json = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      final details = (json['applinks'] as Map)['details'] as List;
      expect((details.single as Map)['appIDs'], ['XXVG6J8PCR.net.microscotch.games.tenk']);
      expect((details.single as Map)['components'], [
        {'/': '/j/*'},
      ]);
    });

    test('est servi même sans empreinte Android', () async {
      final response = await get('/.well-known/apple-app-site-association', links: const LinkConfig());
      expect(response.statusCode, 200);
    });
  });

  group('assetlinks.json', () {
    test('donne le paquet et les empreintes configurées', () async {
      final response = await get('/.well-known/assetlinks.json');
      expect(response.statusCode, 200);
      final list = jsonDecode(await response.readAsString()) as List;
      final target = (list.single as Map)['target'] as Map;
      expect(target['namespace'], 'android_app');
      expect(target['package_name'], 'net.microscotch.games.tenk');
      expect(target['sha256_cert_fingerprints'], [_fingerprint]);
      expect((list.single as Map)['relation'], ['delegate_permission/common.handle_all_urls']);
    });

    test('est absent tant qu\'aucune empreinte n\'est configurée', () async {
      final response = await get('/.well-known/assetlinks.json', links: const LinkConfig());
      expect(response.statusCode, 404);
    });

    test('les empreintes d\'une variable d\'environnement se lisent séparées par des virgules', () {
      expect(LinkConfig.parseFingerprints(' aa:bb , CC:DD ,,'), ['AA:BB', 'CC:DD']);
      expect(LinkConfig.parseFingerprints(null), isEmpty);
      expect(LinkConfig.parseFingerprints(''), isEmpty);
    });
  });

  group('page d\'un lien d\'invitation', () {
    test('montre le code en majuscules et les boutiques, sans script', () async {
      final response = await get('/j/abcde');
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], startsWith('text/html'));
      final html = await response.readAsString();
      expect(html, contains('>ABCDE<'));
      expect(html, contains('apps.apple.com'));
      expect(html, contains('play.google.com'));
      expect(html, isNot(contains('<script')));
      expect(response.headers['content-security-policy'], contains("default-src 'none'"));
      expect(response.headers['cache-control'], 'no-store');
    });

    test('accepte un / final', () async {
      expect((await get('/j/ABCDE/')).statusCode, 200);
    });

    test('un code mal formé est refusé, sans jamais être recopié dans la page', () async {
      for (final path in ['/j/ABCD', '/j/ABCDEF', '/j/AB0DE', '/j/<script>', '/j/ABCDE%3Cb%3E']) {
        final response = await get(path);
        expect(response.statusCode, 404, reason: path);
        expect(await response.readAsString(), 'not found', reason: path);
      }
    });

    test('ne dit rien de l\'existence du salon : la même page pour tout code bien formé', () async {
      final a = await (await get('/j/ABCDE')).readAsString();
      final b = await (await get('/j/K7M2P')).readAsString();
      expect(a.replaceAll('ABCDE', 'CODE'), b.replaceAll('K7M2P', 'CODE'));
    });
  });

  test('les autres routes ne changent pas', () async {
    expect((await get('/healthz')).statusCode, 200);
    expect((await get('/inconnu')).statusCode, 404);
    expect((await get('/.well-known/autre')).statusCode, 404);
    expect((await get('/j')).statusCode, 404);
  });
}
