import '../game_recording.dart';

/// Version du protocole des parties en ligne : le serveur refuse un client d'une
/// autre version plutôt que de deviner ce qu'il veut dire.
const int onlineProtocolVersion = 1;

const int minOnlinePlayers = 2;
const int maxOnlinePlayers = 6;
const int maxPlayerNameLength = 20;

/// Sans 0/O ni 1/I : un code se dicte à voix haute et se recopie à la main.
const String roomCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const int roomCodeLength = 5;

/// Les seules actions qu'un joueur peut demander : ce sont les coups d'un tour.
/// Tout le reste (départage, lancers) est décidé par le serveur.
const Set<GameActionType> playIntents = {
  GameActionType.startTurn,
  GameActionType.roll,
  GameActionType.applyKeep,
  GameActionType.bank,
  GameActionType.endBustedTurn,
};

/// Fonction facultative : le joueur qui a la main fait voir aux autres sa
/// sélection de 5 en cours (`select` → `selection`), avant de la valider.
const String keepSelectionFeature = 'keepSelection';

/// Les fonctions facultatives que cette version sait gérer. Client et serveur
/// s'annoncent les leurs (`create`/`join`/`rejoin`, puis `joined`) et n'envoient
/// à l'autre que ce qu'il a annoncé : un client ou un serveur d'avant, qui
/// n'annonce rien, ne reçoit jamais un message qu'il prendrait pour un journal
/// abîmé. C'est ce qui évite de changer [onlineProtocolVersion], qui couperait
/// les anciens clients.
const List<String> supportedFeatures = [keepSelectionFeature];

const int _maxFeatures = 16;
const int _maxFeatureLength = 32;

enum ClientMessageType { create, join, rejoin, reorder, start, leave, play, select }

enum ServerMessageType { joined, room, action, snapshot, error, selection }

/// Étape d'un salon.
enum RoomPhase { lobby, playing, suspended, over }

enum ErrorCode {
  badRequest,
  unsupportedVersion,
  roomNotFound,
  roomFull,
  gameStarted,
  notHost,
  notYourTurn,
  illegalMove,
  badToken,
  rateLimited,
}

/// Ce qu'un client envoie au serveur. Construit par les fabriques (côté
/// client) ou par [ClientMessage.fromJson] (côté serveur, qui ne fait confiance
/// à rien : chaque champ est vérifié et une entrée douteuse lève une
/// [FormatException]).
class ClientMessage {
  final ClientMessageType type;
  final Map<String, dynamic> params;

  const ClientMessage._(this.type, [this.params = const {}]);

  /// [features] : ce que ce client sait gérer (voir [supportedFeatures]).
  factory ClientMessage.create({required String name, List<String> features = supportedFeatures}) =>
      ClientMessage._(ClientMessageType.create, {'name': name, 'features': features});

  factory ClientMessage.join({required String code, required String name, List<String> features = supportedFeatures}) =>
      ClientMessage._(ClientMessageType.join, {'code': code, 'name': name, 'features': features});

  factory ClientMessage.rejoin({required String token, List<String> features = supportedFeatures}) =>
      ClientMessage._(ClientMessageType.rejoin, {'token': token, 'features': features});

  /// Nouvel ordre des sièges : `order[k]` est le siège actuel qui passe en position k.
  factory ClientMessage.reorder(List<int> order) => ClientMessage._(ClientMessageType.reorder, {'order': order});

  factory ClientMessage.start() => const ClientMessage._(ClientMessageType.start);

  factory ClientMessage.leave() => const ClientMessage._(ClientMessageType.leave);

  factory ClientMessage.play(GameActionType intent, {Map<String, dynamic> params = const {}}) {
    assert(playIntents.contains(intent));
    return ClientMessage._(ClientMessageType.play, {'intent': intent.name, ...params});
  }

  /// Ma sélection de 5 en cours, pour que les autres joueurs la voient : rien
  /// n'est joué (voir [keepSelectionFeature]). Même nombre que `applyKeep`.
  factory ClientMessage.select({required int declineFivesCount}) =>
      ClientMessage._(ClientMessageType.select, {'declineFivesCount': declineFivesCount});

  /// L'intention d'un message `play`.
  GameActionType get intent => GameActionType.values.byName(params['intent'] as String);

  /// Les fonctions annoncées par `create`/`join`/`rejoin` ; vide pour un client
  /// d'avant, qui n'en annonce aucune.
  List<String> get features => (params['features'] as List?)?.cast<String>() ?? const [];

  Map<String, dynamic> toJson() => {'v': onlineProtocolVersion, 'type': type.name, 'params': params};

  factory ClientMessage.fromJson(Object? json) {
    final map = _map(json, 'message');
    final version = map['v'];
    if (version != onlineProtocolVersion) throw UnsupportedVersion(version);
    final type = _enumByName(ClientMessageType.values, map['type'], 'type');
    final raw = _map(map['params'] ?? const <String, dynamic>{}, 'params');
    switch (type) {
      case ClientMessageType.create:
        return ClientMessage.create(name: _name(raw), features: _features(raw));
      case ClientMessageType.join:
        return ClientMessage.join(code: _code(raw), name: _name(raw), features: _features(raw));
      case ClientMessageType.rejoin:
        final token = _string(raw, 'token', min: 16, max: 128);
        return ClientMessage.rejoin(token: token, features: _features(raw));
      case ClientMessageType.reorder:
        final order = raw['order'];
        if (order is! List || order.length < minOnlinePlayers || order.length > maxOnlinePlayers) {
          throw const FormatException('order: liste de 2 à 6 sièges attendue');
        }
        if (order.any((e) => e is! int)) throw const FormatException('order: entiers attendus');
        return ClientMessage.reorder(order.cast<int>());
      case ClientMessageType.start:
        return ClientMessage.start();
      case ClientMessageType.leave:
        return ClientMessage.leave();
      case ClientMessageType.play:
        final intent = _enumByName(GameActionType.values, raw['intent'], 'intent');
        if (!playIntents.contains(intent)) throw FormatException('intent: $intent n\'est pas un coup jouable');
        return ClientMessage.play(intent, params: switch (intent) {
          GameActionType.applyKeep => {'declineFivesCount': _int(raw, 'declineFivesCount', min: 0, max: 5)},
          GameActionType.startTurn => {'useFullHand': _bool(raw, 'useFullHand')},
          _ => const {},
        });
      case ClientMessageType.select:
        return ClientMessage.select(declineFivesCount: _int(raw, 'declineFivesCount', min: 0, max: 5));
    }
  }
}

/// Un joueur d'un salon, tel que tous les clients le voient.
class SeatInfo {
  final String name;
  final bool connected;

  const SeatInfo({required this.name, required this.connected});

  Map<String, dynamic> toJson() => {'name': name, 'connected': connected};

  factory SeatInfo.fromJson(Object? json) {
    final map = _map(json, 'seat');
    return SeatInfo(name: _string(map, 'name', min: 1, max: maxPlayerNameLength), connected: _bool(map, 'connected'));
  }

  @override
  bool operator ==(Object other) => other is SeatInfo && other.name == name && other.connected == connected;

  @override
  int get hashCode => Object.hash(name, connected);
}

/// Ce que le serveur envoie aux clients.
class ServerMessage {
  final ServerMessageType type;
  final Map<String, dynamic> params;

  const ServerMessage._(this.type, this.params);

  /// Réponse à `create`/`join`/`rejoin` : le siège, le jeton qui permet d'y
  /// revenir, et les fonctions facultatives de ce serveur (voir [supportedFeatures]).
  factory ServerMessage.joined({
    required String code,
    required String token,
    required int seat,
    List<String> features = supportedFeatures,
  }) =>
      ServerMessage._(ServerMessageType.joined, {'code': code, 'token': token, 'seat': seat, 'features': features});

  /// L'état du salon, rediffusé à chaque arrivée, départ ou changement d'étape.
  factory ServerMessage.room({
    required String code,
    required RoomPhase phase,
    required List<SeatInfo> seats,
    required int hostSeat,
  }) =>
      ServerMessage._(ServerMessageType.room, {
        'code': code,
        'phase': phase.name,
        'seats': [for (final s in seats) s.toJson()],
        'hostSeat': hostSeat,
      });

  /// Une action de plus au journal : [seq] est son rang, pour repérer un trou.
  factory ServerMessage.action({required int seq, required GameAction action}) =>
      ServerMessage._(ServerMessageType.action, {'seq': seq, 'action': action.toJson()});

  /// Le journal entier (faces comprises), pour qu'un client qui se connecte ou
  /// se reconnecte reconstruise la partie avec `replayGame` — sans seed.
  factory ServerMessage.snapshot({required List<String> names, required List<GameAction> actions}) =>
      ServerMessage._(ServerMessageType.snapshot, {
        'names': names,
        'actions': [for (final a in actions) a.toJson()],
      });

  /// La sélection de 5 en cours du joueur qui a la main, sur le lancer qui
  /// attend sa décision : [seq] est le rang de la prochaine action du journal, ce
  /// qui date la sélection (une sélection d'un lancer passé est ignorée).
  factory ServerMessage.selection({required int seq, required int declineFivesCount}) =>
      ServerMessage._(ServerMessageType.selection, {'seq': seq, 'declineFivesCount': declineFivesCount});

  factory ServerMessage.error(ErrorCode code, [String message = '']) =>
      ServerMessage._(ServerMessageType.error, {'code': code.name, if (message.isNotEmpty) 'message': message});

  Map<String, dynamic> toJson() => {'v': onlineProtocolVersion, 'type': type.name, 'params': params};

  // Lecture typée, côté client (qui vérifie tout de même ce que le serveur lui dit).

  String get roomCode => _string(params, 'code', min: roomCodeLength, max: roomCodeLength);
  String get token => _string(params, 'token', min: 16, max: 128);
  int get seat => _int(params, 'seat', min: 0, max: maxOnlinePlayers - 1);
  int get hostSeat => _int(params, 'hostSeat', min: 0, max: maxOnlinePlayers - 1);
  int get seq => _int(params, 'seq', min: 0, max: 1 << 30);
  int get declineFivesCount => _int(params, 'declineFivesCount', min: 0, max: 5);

  /// Les fonctions annoncées par `joined` ; vide pour un serveur d'avant.
  List<String> get features => params.containsKey('features') ? _features(params) : const [];
  RoomPhase get phase => _enumByName(RoomPhase.values, params['phase'], 'phase');
  ErrorCode get errorCode => _enumByName(ErrorCode.values, params['code'], 'code');

  List<SeatInfo> get seats {
    final raw = params['seats'];
    if (raw is! List || raw.length > maxOnlinePlayers) throw const FormatException('seats: liste attendue');
    return [for (final s in raw) SeatInfo.fromJson(s)];
  }

  GameAction get action => GameAction.fromJson(_map(params['action'], 'action'));

  List<String> get names {
    final raw = params['names'];
    if (raw is! List || raw.length > maxOnlinePlayers || raw.any((e) => e is! String)) {
      throw const FormatException('names: liste de noms attendue');
    }
    return raw.cast<String>();
  }

  List<GameAction> get actions {
    final raw = params['actions'];
    if (raw is! List) throw const FormatException('actions: liste attendue');
    return [for (final a in raw) GameAction.fromJson(_map(a, 'action'))];
  }

  factory ServerMessage.fromJson(Object? json) {
    final map = _map(json, 'message');
    final version = map['v'];
    if (version != onlineProtocolVersion) throw UnsupportedVersion(version);
    final typeName = map['type'];
    final type = ServerMessageType.values.where((t) => t.name == typeName).firstOrNull;
    if (type == null) throw UnknownServerMessage(typeName);
    return ServerMessage._(type, _map(map['params'] ?? const <String, dynamic>{}, 'params'));
  }
}

/// Un type de message que cette version ne connaît pas : celui d'un serveur plus
/// récent, à ignorer — pas un journal abîmé, qui ferait tout redemander.
class UnknownServerMessage extends FormatException {
  UnknownServerMessage(Object? type) : super('type de message inconnu : $type');
}

/// Le message vient d'une autre version du protocole.
class UnsupportedVersion extends FormatException {
  UnsupportedVersion(Object? version) : super('version de protocole non prise en charge : $version');
}

/// Vrai si [code] est bien formé (le serveur le normalise en majuscules avant).
bool isValidRoomCode(String code) =>
    code.length == roomCodeLength && code.split('').every(roomCodeAlphabet.contains);

Map<String, dynamic> _map(Object? value, String what) {
  if (value is! Map) throw FormatException('$what: objet attendu');
  return Map<String, dynamic>.from(value);
}

T _enumByName<T extends Enum>(List<T> values, Object? name, String what) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('$what: valeur inconnue');
}

String _string(Map<String, dynamic> map, String key, {required int min, required int max}) {
  final value = map[key];
  if (value is! String || value.length < min || value.length > max) {
    throw FormatException('$key: texte de $min à $max caractères attendu');
  }
  return value;
}

int _int(Map<String, dynamic> map, String key, {required int min, required int max}) {
  final value = map[key];
  if (value is! int || value < min || value > max) throw FormatException('$key: entier de $min à $max attendu');
  return value;
}

/// Les fonctions annoncées : absentes, aucune ; sinon une liste courte de noms
/// courts. Un nom inconnu passe — c'est à qui le reçoit de l'ignorer.
List<String> _features(Map<String, dynamic> map) {
  final raw = map['features'];
  if (raw == null) return const [];
  if (raw is! List || raw.length > _maxFeatures) throw const FormatException('features: liste courte attendue');
  if (raw.any((f) => f is! String || f.isEmpty || f.length > _maxFeatureLength)) {
    throw const FormatException('features: noms courts attendus');
  }
  return raw.cast<String>();
}

bool _bool(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! bool) throw FormatException('$key: booléen attendu');
  return value;
}

/// Un pseudo : ni vide ni fait d'espaces, sans caractère de contrôle (il
/// s'affiche chez les autres joueurs), rogné.
String _name(Map<String, dynamic> map) {
  final name = _string(map, 'name', min: 1, max: maxPlayerNameLength * 2).trim();
  if (!isValidOnlineName(name)) throw const FormatException('name: pseudo invalide');
  return name;
}

/// Vrai si [name], une fois rogné, est un pseudo que le serveur accepte : la
/// règle même que le serveur applique, pour que l'app refuse d'avance (dans le
/// profil, sur l'écran « Jouer en ligne ») ce qu'il refuserait.
bool isValidOnlineName(String name) {
  final trimmed = name.trim();
  return trimmed.isNotEmpty && trimmed.length <= maxPlayerNameLength && !trimmed.runes.any(_isForbiddenInName);
}

/// Ce qui n'a rien à faire dans un pseudo : les caractères de contrôle, et ceux
/// qui ne se voient pas ou renversent le sens de l'écriture — de quoi faire
/// passer un joueur pour un autre (« Anna » et « An\u200Bna »), ou brouiller
/// la liste des joueurs de tout le salon.
bool _isForbiddenInName(int r) =>
    r < 0x20 ||
    (r >= 0x7f && r < 0xa0) ||
    (r >= 0x200b && r <= 0x200f) || // largeur nulle, marques de sens
    (r >= 0x202a && r <= 0x202e) || // enchâssements et forçage du sens
    (r >= 0x2060 && r <= 0x206f) || // joncteurs, isolats, formes invisibles
    r == 0xfeff || // BOM / espace insécable de largeur nulle
    r == 0x2028 || r == 0x2029; // séparateurs de ligne et de paragraphe

String _code(Map<String, dynamic> map) {
  final code = _string(map, 'code', min: roomCodeLength, max: roomCodeLength).toUpperCase();
  if (!isValidRoomCode(code)) throw const FormatException('code: code de salon invalide');
  return code;
}
