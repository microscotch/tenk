import 'dart:math';

import '../../lib/game/game_recording.dart';
import '../../lib/game/online/protocol.dart';
import 'authority.dart';
import 'limits.dart';

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

  Session(this.connection, this.ip, this.bucket);
}

class _Seat {
  String name;
  final String token;
  Session? session;
  DateTime? disconnectedAt;

  _Seat(this.name, this.token, this.session);

  bool get connected => session != null;
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

  /// Tire les jetons de reprise : doit être cryptographiquement sûr en production.
  final Random tokenRandom;

  /// Fabrique le générateur des dés d'une partie (une seed fixe dans les tests).
  final Random Function() authorityRandom;

  Room({
    required this.code,
    required this.now,
    required this.config,
    required this.tokenRandom,
    this.authorityRandom = Random.secure,
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
      if (_seats[i].token == token) return i;
    }
    return null;
  }

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
    _send(session, ServerMessage.joined(code: code, token: entry.token, seat: seat));
    _sendSnapshot(session);
    _refreshPhase();
    _broadcastRoom();
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
  void leave(Session session) {
    final seat = _seatOfSession(session);
    if (seat < 0) return;
    if (_phase == RoomPhase.lobby) {
      final left = _seats.removeAt(seat);
      if (identical(left, _host)) _host = _seats.isEmpty ? null : _seats.first;
      session.room = null;
      _touch();
      _renumber();
      _broadcastRoom();
    } else {
      // Une partie lancée ne peut pas perdre un joueur : le siège reste vide et
      // la partie attend (voir sweep).
      disconnected(session);
    }
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

  void _play(Session session, int seat, ClientMessage message) {
    final authority = _authority;
    if (_phase != RoomPhase.playing || authority == null) {
      return _send(session, ServerMessage.error(ErrorCode.illegalMove, 'la partie n\'est pas en cours'));
    }
    final firstSeq = authority.actions.length;
    final List<GameAction> produced;
    try {
      final params = Map<String, dynamic>.from(message.params)..remove('intent');
      produced = authority.play(seat, message.intent, params);
    } on IntentRejected catch (e) {
      return _send(session, ServerMessage.error(e.code, e.reason));
    }
    for (var i = 0; i < produced.length; i++) {
      _broadcast(ServerMessage.action(seq: firstSeq + i, action: produced[i]));
    }
    if (authority.isOver) {
      _phase = RoomPhase.over;
      _broadcastRoom();
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

    final idle = t.difference(_lastActivity);
    return _seats.isEmpty ||
        switch (_phase) {
          RoomPhase.lobby => idle > config.lobbyIdleTtl,
          RoomPhase.playing || RoomPhase.suspended => idle > config.gameIdleTtl,
          RoomPhase.over => idle > config.finishedTtl,
        };
  }

  /// La partie est suspendue tant qu'un joueur est absent depuis trop longtemps.
  void _refreshPhase() {
    if (_phase != RoomPhase.playing && _phase != RoomPhase.suspended) return;
    final t = now();
    final someoneGone = _seats.any((s) => s.disconnectedAt != null && t.difference(s.disconnectedAt!) > config.reconnectGrace);
    _phase = someoneGone ? RoomPhase.suspended : RoomPhase.playing;
  }

  void closeAll() {
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
      if (session != null) _send(session, ServerMessage.joined(code: code, token: _seats[i].token, seat: i));
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
        seats: [for (final s in _seats) SeatInfo(name: s.name, connected: s.connected)],
        hostSeat: hostSeat,
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
