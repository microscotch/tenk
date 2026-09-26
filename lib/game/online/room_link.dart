import 'protocol.dart';

/// Le domaine des liens d'invitation : celui du serveur de jeu, dont les
/// fichiers `.well-known` prouvent à iOS et à Android que l'application peut
/// ouvrir ces liens (voir `server/src/server.dart`).
const String roomLinkHost = 'tenk.microscotch.net';

/// Un lien d'invitation est `https://<hôte>/j/<code>`.
const String roomLinkPathPrefix = 'j';

/// Le lien qui invite à rejoindre le salon [code].
Uri roomLinkFor(String code) =>
    Uri(scheme: 'https', host: roomLinkHost, pathSegments: [roomLinkPathPrefix, code.toUpperCase()]);

/// Le code de salon porté par [link], ou null si ce n'est pas un lien
/// d'invitation : autre hôte, autre chemin, code mal formé. Un code en
/// minuscules est accepté (un lien retapé à la main), un `/` final et une
/// requête ou un fragment sont ignorés.
String? parseRoomLink(Uri link) {
  if (link.scheme != 'https' || link.host.toLowerCase() != roomLinkHost) return null;
  final segments = link.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 2 || segments.first != roomLinkPathPrefix) return null;
  final code = segments.last.toUpperCase();
  return isValidRoomCode(code) ? code : null;
}
