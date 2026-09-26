import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../lib/game/online/protocol.dart';
import '../../lib/game/online/room_link.dart';

/// Ce qu'il faut pour que les liens `https://<hôte>/j/<code>` ouvrent l'application
/// plutôt que le navigateur : les deux fichiers `.well-known` par lesquels iOS et
/// Android vérifient que le domaine autorise l'application, et la page que voit
/// celui qui n'a pas l'application.
class LinkConfig {
  /// `<équipe Apple>.<bundle id>`, tel que l'attend `apple-app-site-association`.
  final String iosAppId;
  final String androidPackage;

  /// Empreintes SHA-256 des certificats qui signent l'application Android :
  /// la clé d'envoi (les APK de la CI) et celle que Google Play utilise pour
  /// signer ce qu'il distribue. Sans aucune, `assetlinks.json` est absent et
  /// Android n'ouvre pas les liens dans l'application.
  final List<String> androidCertSha256;

  final String androidStoreUrl;
  final String iosStoreUrl;

  const LinkConfig({
    this.iosAppId = 'XXVG6J8PCR.net.microscotch.games.tenk',
    this.androidPackage = 'net.microscotch.games.tenk',
    this.androidCertSha256 = const [],
    this.androidStoreUrl = 'https://play.google.com/store/apps/details?id=net.microscotch.games.tenk',
    this.iosStoreUrl = 'https://apps.apple.com/app/id6807144484',
  });

  /// Lit la liste d'empreintes d'une variable d'environnement : séparées par des
  /// virgules, les espaces sont ignorés.
  static List<String> parseFingerprints(String? raw) =>
      [for (final part in (raw ?? '').split(',')) if (part.trim().isNotEmpty) part.trim().toUpperCase()];
}

const _jsonType = {'content-type': 'application/json'};

/// Les réponses qui relèvent des liens d'invitation, ou null si [request] n'en est
/// pas une (le routeur passe alors à la suite).
///
/// **Aucune de ces réponses n'interroge un salon** : la page d'un lien ne dit
/// pas si le code existe, sinon n'importe qui pourrait sonder les codes en
/// contournant les limites d'essais infructueux de [RoomManager].
Response? linkResponse(Request request, LinkConfig config) {
  final segments = request.url.pathSegments;
  if (segments.length == 2 && segments.first == '.well-known') {
    switch (segments.last) {
      case 'apple-app-site-association':
        return Response.ok(jsonEncode(_appleAppSiteAssociation(config)), headers: _jsonType);
      case 'assetlinks.json':
        if (config.androidCertSha256.isEmpty) return Response.notFound('not found');
        return Response.ok(jsonEncode(_assetLinks(config)), headers: _jsonType);
    }
    return null;
  }

  // `j/<code>`, avec ou sans `/` final.
  final parts = segments.where((s) => s.isNotEmpty).toList();
  if (parts.length == 2 && parts.first == roomLinkPathPrefix) {
    final code = parts.last.toUpperCase();
    if (!isValidRoomCode(code)) return Response.notFound('not found');
    return Response.ok(_landingPage(code, config), headers: _pageHeaders);
  }
  return null;
}

Map<String, Object?> _appleAppSiteAssociation(LinkConfig config) => {
      'applinks': {
        'details': [
          {
            'appIDs': [config.iosAppId],
            'components': [
              {'/': '/$roomLinkPathPrefix/*'},
            ],
          },
        ],
      },
    };

List<Object?> _assetLinks(LinkConfig config) => [
      {
        'relation': ['delegate_permission/common.handle_all_urls'],
        'target': {
          'namespace': 'android_app',
          'package_name': config.androidPackage,
          'sha256_cert_fingerprints': config.androidCertSha256,
        },
      },
    ];

/// Une page sans script ni ressource externe : elle ne fait que montrer le code
/// et les boutons des boutiques. Le code n'y entre qu'une fois validé (alphabet
/// du protocole), jamais tel que reçu.
const _pageHeaders = {
  'content-type': 'text/html; charset=utf-8',
  'cache-control': 'no-store',
  'referrer-policy': 'no-referrer',
  'x-content-type-options': 'nosniff',
  'content-security-policy': "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'",
};

String _landingPage(String code, LinkConfig config) => '''<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>TenK · Le 10000</title>
<style>
  body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
         background: #0b3d2e; color: #f5f0e1; font: 16px/1.5 system-ui, sans-serif; text-align: center; }
  main { padding: 24px; max-width: 420px; }
  h1 { margin: 0 0 8px; font-size: 1.4rem; }
  .code { margin: 16px 0; font-size: 2.6rem; font-weight: bold; letter-spacing: .3em; padding-left: .3em; }
  a.button { display: block; margin: 8px 0; padding: 12px; border-radius: 8px; background: #d9b44a; color: #1a1a1a;
             text-decoration: none; font-weight: 600; }
  p { margin: 8px 0; }
  small { opacity: .8; }
</style>
</head>
<body>
<main>
  <h1>Rejoins ma partie de Le 10000</h1>
  <p>Ouvre TenK, choisis « Jouer en ligne » puis saisis ce code :</p>
  <div class="code">$code</div>
  <a class="button" href="${config.iosStoreUrl}">App Store</a>
  <a class="button" href="${config.androidStoreUrl}">Google Play</a>
  <p><small>Join my online game of Le 10000: open TenK, choose “Play online” and enter this code.</small></p>
</main>
</body>
</html>
''';
