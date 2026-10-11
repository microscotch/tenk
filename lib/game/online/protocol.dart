import '../game_recording.dart';
import 'emotes.dart';

export 'emotes.dart';

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

/// Fonction facultative : un joueur qui quitte une partie en cours pour de bon
/// (`leave`) cède son siège à un bot du serveur, qui joue à sa place jusqu'à la
/// fin ([SeatInfo.bot]). Sans elle, quitter laisse le siège vide et la partie
/// attend.
const String seatBotsFeature = 'seatBots';

/// Fonction facultative : après le tirage au sort, seul le joueur qui commence
/// lance la partie (`begin`) ; les autres attendent que `room` l'annonce
/// ([ServerMessage.begun]).
const String startSignalFeature = 'startSignal';

/// Fonction facultative : la revanche, proposée à l'écran de fin d'une partie
/// en ligne (`rematch` dans les deux sens).
const String rematchFeature = 'rematch';

/// Les fonctions facultatives que ce serveur sait gérer, annoncées dans
/// `joined`. Client et serveur s'annoncent les leurs et n'envoient à l'autre que
/// ce qu'il a annoncé : un client ou un serveur d'avant, qui n'annonce rien, ne
/// reçoit jamais un message qu'il prendrait pour un journal abîmé. C'est ce qui
/// évite de changer [onlineProtocolVersion], qui couperait les anciens clients.
///
/// Deux listes distinctes, parce que le serveur se déploie avant l'app : il
/// peut annoncer une fonction que cette version de l'app ne sait pas encore
/// gérer, et l'app n'annonce ([clientFeatures]) que celles qu'elle gère.
const List<String> serverFeatures = [
  keepSelectionFeature,
  emotesFeature,
  emotes2Feature,
  seatBotsFeature,
  startSignalFeature,
  rematchFeature,
];

/// Les fonctions facultatives que l'app sait gérer, annoncées dans
/// `create`/`join`/`rejoin` (voir [serverFeatures]).
const List<String> clientFeatures = [
  keepSelectionFeature,
  emotesFeature,
  emotes2Feature,
  seatBotsFeature,
  startSignalFeature,
  rematchFeature,
];

const int _maxFeatures = 16;
const int _maxFeatureLength = 32;

enum ClientMessageType { create, join, rejoin, reorder, start, leave, play, select, emote, begin, rematch }

enum ServerMessageType { joined, room, action, snapshot, error, selection, emote, rematch }

/// Étape d'un salon. Pas de nouvelle valeur ici : un client d'avant ne saurait
/// pas la lire, et redemanderait tout en boucle (la revanche se joue donc dans
/// [over], par ses propres messages).
enum RoomPhase { lobby, playing, suspended, over }

/// La réponse d'un joueur à une revanche (voir [rematchFeature]) : la proposer
/// (la première proposition seule compte ; une suivante vaut acceptation),
/// l'accepter ou la refuser.
enum RematchAnswer { propose, accept, refuse }

/// Où en est une revanche, côté serveur : un vote en cours, une revanche
/// abandonnée (pas assez de joueurs l'acceptent : tout le monde rentre), ou
/// l'exclusion du joueur qui l'a refusée (ou n'a pas répondu à temps). Son
/// départ effectif, lui, s'annonce par `joined` puis `snapshot`.
enum RematchStatus { pending, cancelled, excluded }

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

  /// [features] : ce que ce client sait gérer (voir [clientFeatures]).
  factory ClientMessage.create({required String name, List<String> features = clientFeatures}) =>
      ClientMessage._(ClientMessageType.create, {'name': name, 'features': features});

  factory ClientMessage.join({required String code, required String name, List<String> features = clientFeatures}) =>
      ClientMessage._(ClientMessageType.join, {'code': code, 'name': name, 'features': features});

  factory ClientMessage.rejoin({required String token, List<String> features = clientFeatures}) =>
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

  /// Une émotion pour les autres joueurs, avec l'une de ses phrases ou seule
  /// (voir [emotesFeature]) : rien n'est joué.
  factory ClientMessage.emote(Emote emote, {String? phrase}) {
    assert(emote.accepts(phrase));
    return ClientMessage._(ClientMessageType.emote, {'emote': emote.name, 'phrase': ?phrase});
  }

  /// Le joueur qui commence, une fois le tirage au sort raconté, lance la partie
  /// pour tous (voir [startSignalFeature]).
  factory ClientMessage.begin() => const ClientMessage._(ClientMessageType.begin);

  /// Ma réponse à une revanche (voir [rematchFeature]).
  factory ClientMessage.rematch(RematchAnswer answer) =>
      ClientMessage._(ClientMessageType.rematch, {'answer': answer.name});

  /// La réponse d'un message `rematch`.
  RematchAnswer get rematchAnswer => RematchAnswer.values.byName(params['answer'] as String);

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
      case ClientMessageType.emote:
        final (emote, phrase) = _emote(raw);
        return ClientMessage.emote(emote, phrase: phrase);
      case ClientMessageType.begin:
        return ClientMessage.begin();
      case ClientMessageType.rematch:
        return ClientMessage.rematch(_enumByName(RematchAnswer.values, raw['answer'], 'answer'));
    }
  }
}

/// Un joueur d'un salon, tel que tous les clients le voient.
class SeatInfo {
  final String name;
  final bool connected;

  /// Vrai quand le joueur est parti pour de bon et qu'un bot du serveur joue à
  /// sa place (voir [seatBotsFeature]). Un siège de bot est aussi annoncé
  /// [connected] : un client d'avant, qui ignore ce champ, ne le montre donc pas
  /// comme absent.
  final bool bot;

  const SeatInfo({required this.name, required this.connected, this.bot = false});

  Map<String, dynamic> toJson() => {'name': name, 'connected': connected, if (bot) 'bot': true};

  factory SeatInfo.fromJson(Object? json) {
    final map = _map(json, 'seat');
    return SeatInfo(
      name: _string(map, 'name', min: 1, max: maxPlayerNameLength),
      connected: _bool(map, 'connected'),
      bot: map['bot'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SeatInfo && other.name == name && other.connected == connected && other.bot == bot;

  @override
  int get hashCode => Object.hash(name, connected, bot);
}

/// Ce que le serveur envoie aux clients.
class ServerMessage {
  final ServerMessageType type;
  final Map<String, dynamic> params;

  const ServerMessage._(this.type, this.params);

  /// Réponse à `create`/`join`/`rejoin` : le siège, le jeton qui permet d'y
  /// revenir, et les fonctions facultatives de ce serveur (voir [serverFeatures]).
  factory ServerMessage.joined({
    required String code,
    required String token,
    required int seat,
    List<String> features = serverFeatures,
  }) =>
      ServerMessage._(ServerMessageType.joined, {'code': code, 'token': token, 'seat': seat, 'features': features});

  /// L'état du salon, rediffusé à chaque arrivée, départ ou changement d'étape.
  /// [begun] : le joueur qui commence a lancé la partie (voir
  /// [startSignalFeature]) ; écrit seulement quand il est vrai.
  factory ServerMessage.room({
    required String code,
    required RoomPhase phase,
    required List<SeatInfo> seats,
    required int hostSeat,
    bool begun = false,
  }) =>
      ServerMessage._(ServerMessageType.room, {
        'code': code,
        'phase': phase.name,
        'seats': [for (final s in seats) s.toJson()],
        'hostSeat': hostSeat,
        if (begun) 'begun': true,
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

  /// L'émotion envoyée par le joueur du siège [seat] (voir [emotesFeature]).
  /// Hors du journal de la partie : ni rang, ni action, rien n'est rejoué.
  factory ServerMessage.emote({required int seat, required Emote emote, String? phrase}) =>
      ServerMessage._(ServerMessageType.emote, {'seat': seat, 'emote': emote.name, 'phrase': ?phrase});

  /// Où en est une revanche (voir [rematchFeature]) : [proposerSeat] l'a
  /// proposée ; [remainingMs], le temps qui reste pour répondre (une durée, pas
  /// une heure : les horloges des appareils ne sont pas celle du serveur) ;
  /// [answers], qui a déjà accepté (vrai) ou refusé (faux), par siège.
  factory ServerMessage.rematch({
    required RematchStatus status,
    int? proposerSeat,
    int? remainingMs,
    Map<int, bool> answers = const {},
  }) =>
      ServerMessage._(ServerMessageType.rematch, {
        'status': status.name,
        'proposerSeat': ?proposerSeat,
        'remainingMs': ?remainingMs,
        if (answers.isNotEmpty) 'answers': {for (final e in answers.entries) '${e.key}': e.value},
      });

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

  /// L'émotion d'un message `emote`, et sa phrase (nulle : l'émotion seule).
  /// Lève une [FormatException] pour une émotion ou une phrase inconnue.
  (Emote, String?) get emote => _emote(params);

  /// Le joueur qui commence a lancé la partie (`room`, voir [startSignalFeature]).
  bool get begun => params['begun'] == true;

  /// L'étape d'une revanche (`rematch`).
  RematchStatus get rematchStatus => _enumByName(RematchStatus.values, params['status'], 'status');

  /// Qui a proposé la revanche (`rematch`), s'il est dit.
  int? get proposerSeat => params.containsKey('proposerSeat') ? _int(params, 'proposerSeat', min: 0, max: maxOnlinePlayers - 1) : null;

  /// Le temps qui reste pour répondre à la revanche, s'il est dit.
  Duration? get remaining =>
      params.containsKey('remainingMs') ? Duration(milliseconds: _int(params, 'remainingMs', min: 0, max: 1 << 30)) : null;

  /// Les réponses déjà reçues à la revanche, par siège.
  Map<int, bool> get rematchAnswers {
    final raw = params['answers'];
    if (raw == null) return const {};
    if (raw is! Map || raw.length > maxOnlinePlayers) throw const FormatException('answers: objet attendu');
    final answers = <int, bool>{};
    for (final e in raw.entries) {
      final seat = int.tryParse('${e.key}');
      if (seat == null || seat < 0 || seat >= maxOnlinePlayers || e.value is! bool) {
        throw const FormatException('answers: siège → booléen attendu');
      }
      answers[seat] = e.value as bool;
    }
    return answers;
  }

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

/// Une émotion connue et, s'il y en a une, l'une de ses phrases.
(Emote, String?) _emote(Map<String, dynamic> map) {
  final emote = Emote.byName(map['emote']);
  if (emote == null) throw const FormatException('emote: émotion inconnue');
  final phrase = map['phrase'];
  if (phrase != null && (phrase is! String || !emote.accepts(phrase))) {
    throw const FormatException('phrase: phrase inconnue pour cette émotion');
  }
  return (emote, phrase as String?);
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
