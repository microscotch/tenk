import 'dart:math';

import '../../lib/game/ai/ai_profiles.dart';
import '../../lib/game/ai/ai_turn.dart';
import '../../lib/game/game_recording.dart';
import '../../lib/game/online/protocol.dart';
import '../../lib/game/online/rematch.dart';
import 'authority.dart';
import 'limits.dart';
import 'scheduler.dart';

/// Le bout de tuyau vers un client : le serveur n'en sait pas plus (WebSocket
/// en production, un simple enregistreur dans les tests).
abstract class Connection {
  void send(ServerMessage message);
  void close();
}

/// Une connexion, et ce qu'elle est devenue dans un salon.
class Session {
  final Connection connection;
  final String ip;
  final TokenBucket bucket;
  Room? room;

  /// Les fonctions facultatives annoncées par ce client (voir
  /// `supportedFeatures`) : on ne lui envoie que les messages qu'il comprend.
  Set<String> features = const {};

  Session(this.connection, this.ip, this.bucket);

  bool get wantsKeepSelection => features.contains(keepSelectionFeature);
  bool get wantsEmotes => features.contains(emotesFeature);
  bool get wantsEmotes2 => features.contains(emotes2Feature);
  bool get wantsRematch => features.contains(rematchFeature);
}

class _Seat {
  String name;

  /// Le jeton de reprise du joueur ; effacé quand il part pour de bon (son
  /// siège ne se reprend plus).
  String? token;
  Session? session;
  DateTime? disconnectedAt;

  /// Le joueur est parti d'une partie en cours : un bot du serveur joue à sa
  /// place jusqu'à la fin (voir [seatBotsFeature]).
  bool bot = false;

  /// Le joueur est parti d'une partie finie (ou a refusé la revanche) : son
  /// siège ne compte plus, mais reste à sa place — les numéros de siège des
  /// émotions doivent continuer de correspondre au journal de la partie.
  bool left = false;

  _Seat(this.name, this.token, this.session);

  bool get connected => session != null;

  /// Un humain tient encore ce siège (connecté ou non).
  bool get human => !bot && !left;
}

/// Un vote de revanche en cours : qui l'a proposée, qui a répondu quoi, et la
/// minuterie qui le clôt.
class _RematchVote {
  final int proposer;
  final Map<int, bool> answers = {};
  final DateTime deadline;
  Cancellable? timer;

  _RematchVote(this.proposer, this.deadline);
}

/// Un salon : les joueurs, l'étape, et — une fois lancée — l'arbitre de la
/// partie. Ne connaît ni sockets ni horloge réelle : tout passe par
/// [Connection] et par [now].
class Room {
  final String code;
  final DateTime Function() now;
  final ServerConfig config;

  final List<_Seat> _seats = [];

  /// L'hôte : celui qui a créé le salon (ou, s'il part avant le départ, le
  /// premier des joueurs restants). Son rôle ne tient PAS à sa place autour de
  /// la table : il peut se glisser où il veut sans cesser d'être l'hôte.
  _Seat? _host;
  RoomPhase _phase = RoomPhase.lobby;
  GameAuthority? _authority;
  DateTime _lastActivity;

  /// L'heure de la dernière émotion relayée, par siège : une suivante qui
  /// arrive avant [emoteCooldown] est ignorée.
  final Map<int, DateTime> _lastEmoteAt = {};

  /// La dernière sélection de 5 du joueur qui a la main, pour la redonner à qui
  /// se reconnecte pendant qu'il hésite. Vidée à chaque coup joué.
  ({int seq, int declineFivesCount})? _selection;

  /// Tire les jetons de reprise : doit être cryptographiquement sûr en production.
  final Random tokenRandom;

  /// Fabrique le générateur des dés d'une partie (une seed fixe dans les tests).
  final Random Function() authorityRandom;

  /// Appelé quand le salon se ferme de lui-même (plus aucun humain, revanche
  /// abandonnée) : le gestionnaire l'oublie alors (voir `RoomManager`).
  void Function(Room room)? onClose;

  /// La partie a été lancée par son premier joueur (voir [startSignalFeature]).
  bool _begun = false;

  /// Le prochain coup programmé d'un bot de siège, s'il y en a un.
  Cancellable? _botTimer;

  _RematchVote? _vote;
  bool _closed = false;

  /// Programme les actions différées du salon (les coups d'un bot de siège, la
  /// fin d'un vote de revanche) : de vraies minuteries en production, une
  /// horloge que le test avance dans les tests.
  final Scheduler scheduler;

  Room({
    required this.code,
    required this.now,
    required this.config,
    required this.tokenRandom,
    this.authorityRandom = Random.secure,
    this.scheduler = const TimerScheduler(),
    this.onClose,
  }) : _lastActivity = now();

  RoomPhase get phase => _phase;
  int get seatCount => _seats.length;
  bool get isEmpty => _seats.isEmpty;
  GameAuthority? get authority => _authority;
  List<String> get names => [for (final s in _seats) s.name];

  /// Le siège de l'hôte : c'est lui qui règle l'ordre et lance la partie.
  int get hostSeat => _host == null ? 0 : _seats.indexOf(_host!);

  int? seatOf(String token) {
    for (var i = 0; i < _seats.length; i++) {
      if (_seats[i].token != null && _seats[i].token == token) return i;
    }
    return null;
  }

  /// Vrai quand la partie a commencé et que plus aucun humain n'y tient de
  /// siège (tous partis, remplacés par des bots ou sortis de la partie finie) :
  /// un salon que plus personne ne verra. Un joueur seulement déconnecté, qui
  /// garde son jeton, le retient encore.
  bool get isAbandoned => _authority != null && !_seats.any((s) => s.human && s.token != null);

  int _seatOfSession(Session session) => _seats.indexWhere((s) => s.session == session);

  /// Ajoute un joueur. Lève [RoomFull] ou [GameAlreadyStarted].
  ({int seat, String token}) join(String name, Session session) {
    if (_phase != RoomPhase.lobby) throw const RoomRejected(ErrorCode.gameStarted);
    if (_seats.length >= maxOnlinePlayers) throw const RoomRejected(ErrorCode.roomFull);
    final token = _newToken();
    final seat = _Seat(_uniqueName(name), token, session);
    _seats.add(seat);
    _host ??= seat;
    session.room = this;
    _touch();
    _send(session, ServerMessage.joined(code: code, token: token, seat: _seats.length - 1));
    _broadcastRoom();
    return (seat: _seats.length - 1, token: token);
  }

  /// Un joueur revient avec son jeton (coupure réseau, app relancée).
  void rejoin(int seat, Session session) {
    final entry = _seats[seat];
    final previous = entry.session;
    if (previous != null && previous != session) {
      previous.room = null;
      previous.connection.close();
    }
    entry.session = session;
    entry.disconnectedAt = null;
    session.room = this;
    _touch();
    _send(session, ServerMessage.joined(code: code, token: entry.token!, seat: seat));
    _sendSnapshot(session);
    final selection = _selection;
    if (selection != null && session.wantsKeepSelection && selection.seq == _authority?.actions.length) {
      _send(session, ServerMessage.selection(seq: selection.seq, declineFivesCount: selection.declineFivesCount));
    }
    if (_vote != null && session.wantsRematch) _send(session, _voteMessage());
    _refreshPhase();
    _broadcastRoom();
    _scheduleBot();
  }

  /// La connexion d'un joueur s'est coupée : son siège l'attend.
  void disconnected(Session session) {
    final seat = _seatOfSession(session);
    if (seat < 0) return;
    _seats[seat]
      ..session = null
      ..disconnectedAt = now();
    session.room = null;
    _touch();
    _broadcastRoom();
  }

  /// Le joueur part pour de bon.
  ///
  /// Dans le salon, son siège disparaît. Dans une partie en cours, un bot du
  /// serveur le reprend et joue à sa place jusqu'à la fin ([_convertToBot]) :
  /// les autres n'ont pas à attendre quelqu'un qui ne reviendra pas. Une app
  /// d'avant ne quitte jamais une partie en cours par `leave` (elle se
  /// déconnecte, et garde son siège) : ce changement ne la touche pas. Dans une
  /// partie finie, son siège ne compte plus (et vaut refus d'une revanche en
  /// cours).
  void leave(Session session) {
    final seat = _seatOfSession(session);
    if (seat < 0) return;
    switch (_phase) {
      case RoomPhase.lobby:
        final left = _seats.removeAt(seat);
        if (identical(left, _host)) _host = _seats.isEmpty ? null : _seats.first;
        session.room = null;
        _touch();
        _renumber();
        _broadcastRoom();
      case RoomPhase.playing:
      case RoomPhase.suspended:
        _convertToBot(seat);
      case RoomPhase.over:
        _detach(seat, left: true);
        if (_vote != null) {
          _vote!.answers[seat] = false;
          _resolveVoteIfComplete();
        } else {
          _broadcastRoom();
        }
    }
  }

  /// Un bot du serveur reprend le siège [seat] : son jeton est effacé (le
  /// siège ne se reprend plus), et il joue dès que c'est son tour.
  void _convertToBot(int seat) {
    final entry = _seats[seat];
    _detach(seat, left: false);
    entry
      ..bot = true
      ..disconnectedAt = null;
    if (_authority?.currentSeat == seat) _selection = null;
    // Le joueur qui devait lancer la partie s'en va : elle part sans lui.
    if (!_begun && _authority?.startingSeat == seat) _begun = true;
    if (isAbandoned) return _close();
    _refreshPhase();
    _broadcastRoom();
    _scheduleBot();
  }

  /// Retire le joueur du siège [seat] (sa connexion ne fait plus partie du
  /// salon, son jeton ne sert plus). [left] : son siège ne compte plus du tout.
  void _detach(int seat, {required bool left}) {
    final entry = _seats[seat];
    final session = entry.session;
    if (session != null) session.room = null;
    entry
      ..session = null
      ..token = null
      ..left = left;
    _touch();
  }

  void handle(Session session, ClientMessage message) {
    final seat = _seatOfSession(session);
    if (seat < 0) return;
    _touch();
    switch (message.type) {
      case ClientMessageType.reorder:
        _reorder(session, seat, (message.params['order'] as List).cast<int>());
      case ClientMessageType.start:
        _start(session, seat);
      case ClientMessageType.leave:
        leave(session);
      case ClientMessageType.play:
        _play(session, seat, message);
      case ClientMessageType.select:
        _select(session, seat, message.params['declineFivesCount'] as int);
      case ClientMessageType.emote:
        final (emote, phrase) = (Emote.byName(message.params['emote'])!, message.params['phrase'] as String?);
        _emote(seat, emote, phrase);
      case ClientMessageType.begin:
        _begin(session, seat);
      case ClientMessageType.rematch:
        _rematch(session, seat, message.rematchAnswer);
      case ClientMessageType.create:
      case ClientMessageType.join:
      case ClientMessageType.rejoin:
        _send(session, ServerMessage.error(ErrorCode.badRequest, 'déjà dans un salon'));
    }
  }

  void _reorder(Session session, int seat, List<int> order) {
    if (seat != hostSeat) return _send(session, ServerMessage.error(ErrorCode.notHost));
    if (_phase != RoomPhase.lobby) return _send(session, ServerMessage.error(ErrorCode.gameStarted));
    final valid = order.length == _seats.length && order.toSet().length == order.length && order.every((s) => s >= 0 && s < _seats.length);
    if (!valid) return _send(session, ServerMessage.error(ErrorCode.badRequest, 'ordre invalide'));
    final reordered = [for (final s in order) _seats[s]];
    _seats
      ..clear()
      ..addAll(reordered);
    _renumber();
    _broadcastRoom();
  }

  void _start(Session session, int seat) {
    if (seat != hostSeat) return _send(session, ServerMessage.error(ErrorCode.notHost));
    if (_phase != RoomPhase.lobby) return _send(session, ServerMessage.error(ErrorCode.gameStarted));
    if (_seats.length < minOnlinePlayers || _seats.any((s) => !s.connected)) {
      return _send(session, ServerMessage.error(ErrorCode.badRequest, 'il faut au moins 2 joueurs, tous connectés'));
    }
    final authority = GameAuthority(names: names, random: authorityRandom());
    authority.start();
    _authority = authority;
    _phase = RoomPhase.playing;
    for (final s in _seats) {
      _sendSnapshot(s.session!);
    }
    _broadcastRoom();
  }

  /// Le joueur qui commence lance la partie, une fois le tirage raconté (voir
  /// [startSignalFeature]) : les autres, qui l'attendaient, y entrent aussi.
  void _begin(Session session, int seat) {
    final authority = _authority;
    if (authority == null || _phase == RoomPhase.lobby) {
      return _send(session, ServerMessage.error(ErrorCode.illegalMove, 'la partie n\'a pas commencé'));
    }
    if (seat != authority.startingSeat) {
      return _send(session, ServerMessage.error(ErrorCode.notYourTurn, 'seul le premier joueur lance la partie'));
    }
    _markBegun();
  }

  void _markBegun() {
    if (_begun) return;
    _begun = true;
    _broadcastRoom();
    _scheduleBot();
  }

  void _play(Session session, int seat, ClientMessage message) {
    final params = Map<String, dynamic>.from(message.params)..remove('intent');
    final rejected = _applyPlay(seat, message.intent, params);
    if (rejected != null) _send(session, ServerMessage.error(rejected.code, rejected.reason));
  }

  /// Joue un coup pour le siège [seat] — le sien, ou celui de son bot — et le
  /// diffuse. Rend le refus de l'arbitre, sans rien diffuser, s'il y en a un.
  IntentRejected? _applyPlay(int seat, GameActionType intent, Map<String, dynamic> params) {
    final authority = _authority;
    if (_phase != RoomPhase.playing || authority == null) {
      return const IntentRejected(ErrorCode.illegalMove, 'la partie n\'est pas en cours');
    }
    final firstSeq = authority.actions.length;
    final List<GameAction> produced;
    try {
      produced = authority.play(seat, intent, params);
    } on IntentRejected catch (e) {
      return e;
    }
    _selection = null;
    for (var i = 0; i < produced.length; i++) {
      _broadcast(ServerMessage.action(seq: firstSeq + i, action: produced[i]));
    }
    // Un premier joueur d'avant ne dit pas `begin` : son premier coup lance la
    // partie pour tous.
    if (!_begun) {
      _begun = true;
      if (!authority.isOver) _broadcastRoom();
    }
    if (authority.isOver) {
      _phase = RoomPhase.over;
      _cancelBot();
      _broadcastRoom();
      return null;
    }
    _scheduleBot();
    return null;
  }

  /// Programme le prochain coup du bot qui a la main, s'il y en a un : la
  /// partie doit être en cours (pas suspendue) et lancée.
  void _scheduleBot() {
    if (_botTimer != null || _closed) return;
    final authority = _authority;
    if (authority == null || _phase != RoomPhase.playing || !_begun || authority.isOver) return;
    final seat = authority.currentSeat;
    if (seat == null || !_seats[seat].bot) return;
    var delay = config.botActionDelay;
    final turn = authority.engine?.activeTurn;
    // « Craqué ! » ne s'affiche chez les clients qu'une fois les dés immobilisés.
    if (turn != null && turn.busted && turn.pendingRoll != null) delay += config.botBustExtraDelay;
    _botTimer = scheduler.schedule(delay, () {
      _botTimer = null;
      _botStep();
    });
  }

  void _botStep() {
    final authority = _authority;
    if (authority == null || _phase != RoomPhase.playing || authority.isOver || _closed) return;
    final seat = authority.currentSeat;
    if (seat == null || !_seats[seat].bot) return;
    _touch();
    // Le même calcul que le bot local de l'app (voir `nextAiMove`), au niveau
    // prudent, celui de tous les bots.
    final move = nextAiMove(authority.engine!, aiStrategyFor(AiDifficulty.prudent));
    final rejected = _applyPlay(seat, move.type, Map<String, dynamic>.from(move.params));
    // Ne devrait jamais arriver (le calcul suit les mêmes règles que l'arbitre) :
    // la partie resterait bloquée sur ce bot, qu'on relance plutôt.
    if (rejected != null) _scheduleBot();
  }

  void _cancelBot() {
    _botTimer?.cancel();
    _botTimer = null;
  }

  /// Une réponse à la revanche (voir [rematchFeature]). Seulement dans une
  /// partie finie, d'un joueur qui la connaît.
  void _rematch(Session session, int seat, RematchAnswer answer) {
    if (_phase != RoomPhase.over || !session.wantsRematch || !_seats[seat].human) {
      return _send(session, ServerMessage.error(ErrorCode.badRequest, 'pas de revanche possible'));
    }
    var vote = _vote;
    if (vote == null) {
      if (answer != RematchAnswer.propose) return; // vote déjà clos : rien à faire
      vote = _vote = _RematchVote(seat, now().add(config.rematchWindow));
      vote.timer = scheduler.schedule(config.rematchWindow, _resolveVote);
    }
    // Une seconde proposition, pendant le vote, vaut acceptation.
    final accepts = answer != RematchAnswer.refuse;
    vote.answers[seat] = accepts;
    if (!accepts) {
      _send(session, ServerMessage.rematch(status: RematchStatus.excluded));
      _detach(seat, left: true);
    }
    _resolveVoteIfComplete();
  }

  /// Clôt le vote dès que tous ceux qui peuvent répondre l'ont fait ; sinon,
  /// rediffuse où il en est.
  void _resolveVoteIfComplete() {
    final vote = _vote;
    if (vote == null) return;
    final waiting = [
      for (var i = 0; i < _seats.length; i++)
        if (_seats[i].human && _seats[i].session != null && _seats[i].session!.wantsRematch && !vote.answers.containsKey(i)) i,
    ];
    if (waiting.isEmpty) return _resolveVote();
    _broadcastVote();
  }

  ServerMessage _voteMessage() {
    final vote = _vote!;
    final remaining = vote.deadline.difference(now());
    return ServerMessage.rematch(
      status: RematchStatus.pending,
      proposerSeat: vote.proposer,
      remainingMs: remaining.isNegative ? 0 : remaining.inMilliseconds,
      answers: vote.answers,
    );
  }

  void _broadcastVote() {
    final message = _voteMessage();
    for (final s in _seats) {
      final session = s.session;
      if (session != null && session.wantsRematch) _send(session, message);
    }
  }

  /// Le vote est clos (tous ont répondu, ou le temps est écoulé) : sans
  /// réponse, c'est un refus. À deux au moins, la revanche part avec ceux qui
  /// l'ont acceptée ; sinon, chacun rentre chez soi et le salon se ferme.
  void _resolveVote() {
    final vote = _vote;
    final authority = _authority;
    if (vote == null || authority == null || _closed) return;
    vote.timer?.cancel();
    _vote = null;
    final accepted = {
      for (var i = 0; i < _seats.length; i++)
        if (_seats[i].human && vote.answers[i] == true && _seats[i].session != null) i,
    };
    if (accepted.length < minOnlinePlayers) {
      for (final s in _seats) {
        final session = s.session;
        if (session != null && session.wantsRematch) _send(session, ServerMessage.rematch(status: RematchStatus.cancelled));
      }
      return _close();
    }
    for (var i = 0; i < _seats.length; i++) {
      if (accepted.contains(i) || !_seats[i].human) continue;
      final session = _seats[i].session;
      if (session != null && session.wantsRematch) _send(session, ServerMessage.rematch(status: RematchStatus.excluded));
      _detach(i, left: true);
    }
    final engine = authority.engine!;
    final previousOrder = authority.playOrder!;
    final order = rematchSeatOrder(
      previousPlayOrder: previousOrder,
      finalScoreBySeat: {for (var k = 0; k < previousOrder.length; k++) previousOrder[k]: engine.players[k].totalScore},
      remaining: accepted,
    );
    final seats = [for (final s in order) _seats[s]];
    _seats
      ..clear()
      ..addAll(seats);
    if (!_seats.contains(_host)) _host = _seats.first;
    _lastEmoteAt.clear();
    _selection = null;
    _cancelBot();
    _touch();
    _renumber();
    // L'ordre des sièges est déjà celui de la partie : pas de tirage.
    final rematch = GameAuthority(names: names, random: authorityRandom(), presetOrder: [for (var i = 0; i < _seats.length; i++) i]);
    rematch.start();
    _authority = rematch;
    _phase = RoomPhase.playing;
    _begun = true;
    for (final s in _seats) {
      final session = s.session;
      if (session != null) _sendSnapshot(session);
    }
    _broadcastRoom();
  }

  /// Le joueur qui a la main change sa sélection de 5 : rien n'est joué, on la
  /// fait seulement voir aux autres joueurs qui savent l'afficher. Refusée comme
  /// un coup (pas son tour, pas de lancer en attente, nombre non proposé).
  void _select(Session session, int seat, int declineFivesCount) {
    final authority = _authority;
    if (_phase != RoomPhase.playing || authority == null) {
      return _send(session, ServerMessage.error(ErrorCode.illegalMove, 'la partie n\'est pas en cours'));
    }
    try {
      authority.checkSelection(seat, declineFivesCount);
    } on IntentRejected catch (e) {
      return _send(session, ServerMessage.error(e.code, e.reason));
    }
    final seq = authority.actions.length;
    _selection = (seq: seq, declineFivesCount: declineFivesCount);
    final message = ServerMessage.selection(seq: seq, declineFivesCount: declineFivesCount);
    for (final s in _seats) {
      final other = s.session;
      if (other != null && other != session && other.wantsKeepSelection) _send(other, message);
    }
  }

  /// Le joueur du siège [seat] envoie une émotion : relayée à tous les joueurs
  /// qui savent l'afficher, lui compris (sa bulle apparaît au même moment que
  /// chez les autres). Rien n'est joué, rien n'entre au journal.
  ///
  /// Ignorée sans réponse avant le départ, ou si la précédente de ce siège date
  /// de moins de [emoteCooldown] : une erreur s'afficherait chez le joueur pour
  /// un simple bouton tapé trop vite.
  ///
  /// Un joueur dont l'app ne connaît que la première série (sans
  /// [emotes2Feature]) reçoit une version rétrogradée (voir [downgradeForV1]),
  /// ou rien pour une émotion qu'il ne saurait pas lire.
  void _emote(int seat, Emote emote, String? phrase) {
    if (_authority == null) return;
    final t = now();
    final last = _lastEmoteAt[seat];
    if (last != null && t.difference(last) < emoteCooldown) return;
    _lastEmoteAt[seat] = t;
    final message = ServerMessage.emote(seat: seat, emote: emote, phrase: phrase);
    final downgraded = downgradeForV1(emote, phrase);
    final v1Message = downgraded == null ? null : ServerMessage.emote(seat: seat, emote: downgraded.$1, phrase: downgraded.$2);
    for (final s in _seats) {
      final session = s.session;
      if (session == null || !session.wantsEmotes) continue;
      final forHim = session.wantsEmotes2 ? message : v1Message;
      if (forHim != null) _send(session, forHim);
    }
  }

  /// Appelé périodiquement : décide qui a trop attendu. Rend vrai si le salon
  /// doit disparaître.
  bool sweep() {
    final t = now();
    if (_phase == RoomPhase.lobby) {
      _seats.removeWhere((s) => s.disconnectedAt != null && t.difference(s.disconnectedAt!) > config.reconnectGrace);
      if (_host != null && !_seats.contains(_host)) _host = _seats.isEmpty ? null : _seats.first;
      _renumber();
    }
    final before = _phase;
    _refreshPhase();
    if (_phase != before) _broadcastRoom();
    _scheduleBot();

    final idle = t.difference(_lastActivity);
    return _seats.isEmpty ||
        switch (_phase) {
          RoomPhase.lobby => idle > config.lobbyIdleTtl,
          RoomPhase.playing || RoomPhase.suspended => idle > config.gameIdleTtl,
          RoomPhase.over => idle > config.finishedTtl,
        };
  }

  /// La partie est suspendue tant qu'un joueur est absent depuis trop longtemps
  /// (un bot, lui, ne s'absente jamais).
  void _refreshPhase() {
    if (_phase != RoomPhase.playing && _phase != RoomPhase.suspended) return;
    final t = now();
    final someoneGone =
        _seats.any((s) => s.human && s.disconnectedAt != null && t.difference(s.disconnectedAt!) > config.reconnectGrace);
    _phase = someoneGone ? RoomPhase.suspended : RoomPhase.playing;
  }

  /// Le salon se ferme de lui-même : plus d'humain, ou revanche abandonnée.
  void _close() {
    if (_closed) return;
    closeAll();
    onClose?.call(this);
  }

  void closeAll() {
    _closed = true;
    _cancelBot();
    _vote?.timer?.cancel();
    _vote = null;
    for (final s in _seats) {
      s.session?.room = null;
      s.session?.connection.close();
    }
    _seats.clear();
  }

  void _renumber() {
    // Rien à faire : les numéros de siège sont les positions dans la liste. Les
    // clients apprennent leur nouveau numéro par le message `joined` suivant.
    for (var i = 0; i < _seats.length; i++) {
      final session = _seats[i].session;
      final token = _seats[i].token;
      if (session != null && token != null) _send(session, ServerMessage.joined(code: code, token: token, seat: i));
    }
  }

  void _sendSnapshot(Session session) {
    final authority = _authority;
    if (authority == null) return;
    _send(session, ServerMessage.snapshot(names: authority.names, actions: authority.actions));
  }

  void _broadcastRoom() => _broadcast(ServerMessage.room(
        code: code,
        phase: _phase,
        // Un siège de bot est « connecté » : un client d'avant, qui ignore `bot`,
        // ne le montre pas comme absent.
        seats: [for (final s in _seats) SeatInfo(name: s.name, connected: s.connected || s.bot, bot: s.bot)],
        hostSeat: hostSeat,
        begun: _begun,
      ));

  void _broadcast(ServerMessage message) {
    for (final s in _seats) {
      final session = s.session;
      if (session != null) _send(session, message);
    }
  }

  void _send(Session session, ServerMessage message) => session.connection.send(message);

  void _touch() => _lastActivity = now();

  /// Deux joueurs ne portent pas le même pseudo dans un salon : le second est suffixé.
  String _uniqueName(String name) {
    final taken = {for (final s in _seats) s.name.toLowerCase()};
    if (!taken.contains(name.toLowerCase())) return name;
    for (var n = 2;; n++) {
      final suffix = ' $n';
      final candidate = '${name.substring(0, min(name.length, maxPlayerNameLength - suffix.length))}$suffix';
      if (!taken.contains(candidate.toLowerCase())) return candidate;
    }
  }

  String _newToken() => List.generate(32, (_) => tokenRandom.nextInt(16).toRadixString(16)).join();
}

/// Une jointure refusée, avec la raison à renvoyer au client.
class RoomRejected implements Exception {
  final ErrorCode code;
  const RoomRejected(this.code);
}
