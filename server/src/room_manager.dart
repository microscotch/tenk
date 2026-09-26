import 'dart:convert';
import 'dart:math';

import '../../lib/game/online/protocol.dart';
import 'limits.dart';
import 'room.dart';

/// Tous les salons du serveur, et la porte d'entrée de chaque message : limite
/// de débit, validation, puis aiguillage vers le bon salon.
class RoomManager {
  final ServerConfig config;
  final DateTime Function() now;
  final Random _secure;
  final Random Function() _authorityRandom;

  final Map<String, Room> _rooms = {};
  final Map<String, Room> _roomByToken = {};
  final Map<String, int> _connectionsByIp = {};
  final Map<String, TokenBucket> _failuresByIp = {};
  final Map<String, TokenBucket> _createsByIp = {};

  RoomManager({
    this.config = const ServerConfig(),
    DateTime Function()? now,
    Random? secure,
    Random Function()? authorityRandom,
  })  : now = now ?? DateTime.now,
        _secure = secure ?? Random.secure(),
        _authorityRandom = authorityRandom ?? Random.secure;

  int get roomCount => _rooms.length;
  Room? room(String code) => _rooms[code];

  /// Enregistre une nouvelle connexion, ou rend null si son adresse en a déjà trop.
  Session? connect(Connection connection, String ip) {
    final open = _connectionsByIp[ip] ?? 0;
    if (open >= config.maxConnectionsPerIp) return null;
    _connectionsByIp[ip] = open + 1;
    return Session(
      connection,
      ip,
      TokenBucket(ratePerSecond: config.messagesPerSecond, burst: config.messageBurst, now: now),
    );
  }

  void disconnect(Session session) {
    final open = _connectionsByIp[session.ip] ?? 1;
    if (open <= 1) {
      _connectionsByIp.remove(session.ip);
    } else {
      _connectionsByIp[session.ip] = open - 1;
    }
    session.room?.disconnected(session);
  }

  /// Traite un message brut reçu de [session]. Ne lève jamais : tout ce qui est
  /// douteux devient une réponse d'erreur (ou, pour un message trop gros, une
  /// fermeture).
  void onMessage(Session session, String raw) {
    if (utf8.encode(raw).length > config.maxMessageBytes) {
      session.connection.send(ServerMessage.error(ErrorCode.badRequest, 'message trop gros'));
      session.connection.close();
      return;
    }
    if (!session.bucket.tryTake()) {
      session.connection.send(ServerMessage.error(ErrorCode.rateLimited));
      return;
    }
    final ClientMessage message;
    try {
      message = ClientMessage.fromJson(jsonDecode(raw));
    } on UnsupportedVersion {
      session.connection.send(ServerMessage.error(ErrorCode.unsupportedVersion));
      return;
    } on FormatException catch (e) {
      session.connection.send(ServerMessage.error(ErrorCode.badRequest, e.message));
      return;
    }

    final room = session.room;
    if (room != null) return room.handle(session, message);

    switch (message.type) {
      case ClientMessageType.create:
        _create(session, message.params['name'] as String);
      case ClientMessageType.join:
        _join(session, message.params['code'] as String, message.params['name'] as String);
      case ClientMessageType.rejoin:
        _rejoin(session, message.params['token'] as String);
      case ClientMessageType.reorder:
      case ClientMessageType.start:
      case ClientMessageType.leave:
      case ClientMessageType.play:
        session.connection.send(ServerMessage.error(ErrorCode.badRequest, 'pas dans un salon'));
    }
  }

  void _create(Session session, String name) {
    final creates = _createsByIp.putIfAbsent(
      session.ip,
      () => TokenBucket(ratePerSecond: config.roomsCreatedPerMinute / 60, burst: config.roomsCreatedPerMinute, now: now),
    );
    if (!creates.tryTake() || _rooms.length >= config.maxRooms) {
      session.connection.send(ServerMessage.error(ErrorCode.rateLimited));
      return;
    }
    final room = Room(
      code: _newCode(),
      now: now,
      config: config,
      tokenRandom: _secure,
      authorityRandom: _authorityRandom,
    );
    _rooms[room.code] = room;
    _register(room, room.join(name, session).token);
  }

  void _join(Session session, String code, String name) {
    final room = _rooms[code];
    if (room == null) return _failed(session, ErrorCode.roomNotFound);
    try {
      _register(room, room.join(name, session).token);
    } on RoomRejected catch (e) {
      session.connection.send(ServerMessage.error(e.code));
    }
  }

  void _rejoin(Session session, String token) {
    final room = _roomByToken[token];
    final seat = room?.seatOf(token);
    if (room == null || seat == null) return _failed(session, ErrorCode.badToken);
    room.rejoin(seat, session);
  }

  void _register(Room room, String token) => _roomByToken[token] = room;

  /// Un essai raté (code ou jeton inconnu) coûte un jeton à l'adresse ; à sec,
  /// elle n'obtient plus qu'un « trop vite » — même pour un bon code.
  void _failed(Session session, ErrorCode code) {
    final bucket = _failuresByIp.putIfAbsent(
      session.ip,
      () => TokenBucket(ratePerSecond: config.joinFailuresPerMinute / 60, burst: config.joinFailuresPerMinute, now: now),
    );
    session.connection.send(ServerMessage.error(bucket.tryTake() ? code : ErrorCode.rateLimited));
  }

  /// Fait le ménage : suspend les parties dont un joueur manque, retire les
  /// salons oubliés. À appeler régulièrement (voir `bin/server.dart`).
  void sweep() {
    for (final entry in _rooms.entries.toList()) {
      if (entry.value.sweep()) {
        entry.value.closeAll();
        _rooms.remove(entry.key);
      }
    }
    _roomByToken.removeWhere((token, room) => !_rooms.containsKey(room.code) || room.seatOf(token) == null);
    // Les seaux d'adresses inactives ne servent plus à rien.
    if (_failuresByIp.length > 10000) _failuresByIp.clear();
    if (_createsByIp.length > 10000) _createsByIp.clear();
  }

  String _newCode() {
    for (;;) {
      final code = String.fromCharCodes(
        List.generate(roomCodeLength, (_) => roomCodeAlphabet.codeUnitAt(_secure.nextInt(roomCodeAlphabet.length))),
      );
      if (!_rooms.containsKey(code)) return code;
    }
  }
}
