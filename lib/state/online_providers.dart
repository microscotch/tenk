import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/dice_off.dart';
import '../game/game_recording.dart';
import '../game/online/protocol.dart';
import 'game_providers.dart';
import 'online_transport.dart';

export '../game/online/protocol.dart' show ErrorCode, RoomPhase, SeatInfo;

/// L'adresse du serveur des parties en ligne, fixée à la compilation :
/// `flutter build ... --dart-define=TENK_SERVER_URL=wss://…/ws`. Toujours
/// `wss://` en production (le TLS se termine sur le reverse proxy du serveur).
const String defaultServerUrl = String.fromEnvironment('TENK_SERVER_URL', defaultValue: 'ws://localhost:8080/ws');

/// Une build de release ne parle qu'à un serveur chiffré (`wss://`) : un `ws://`
/// oublié dans `--dart-define` enverrait pseudo, jeton et coups en clair. En
/// développement (debug, profile), un serveur local en `ws://` reste permis.
bool isAcceptableServerUrl(Uri url, {required bool release}) {
  if (url.host.isEmpty) return false;
  return release ? url.scheme == 'wss' : (url.scheme == 'wss' || url.scheme == 'ws');
}

final onlineServerUrlProvider = Provider<String>((ref) => defaultServerUrl);
final onlineTransportProvider = Provider<OnlineTransport>((ref) => const WebSocketTransport());
final onlineCredentialsStoreProvider = Provider<OnlineCredentialsStore>((ref) => const SharedPreferencesCredentialsStore());

/// Délai avant la n-ième tentative de reconnexion (à partir de 0) : 1 s, 2 s,
/// 4 s… plafonné à 15 s. Surchargeable pour les tests.
final onlineReconnectDelayProvider = Provider<Duration Function(int attempt)>((ref) {
  return (attempt) => Duration(seconds: (1 << attempt.clamp(0, 4)).clamp(1, 15));
});

enum OnlineStatus { offline, connecting, online }

/// Ce que l'écran sait de la session en ligne.
class OnlineState {
  final OnlineStatus status;
  final String? roomCode;

  /// Mon siège dans le salon (peut changer tant qu'on est au salon : l'hôte
  /// réordonne).
  final int? mySeat;
  final int hostSeat;
  final List<SeatInfo> seats;
  final RoomPhase? phase;

  /// Vrai dès que le serveur a envoyé le journal d'une partie commencée.
  final bool gameStarted;

  /// Le départage de cette partie, pour l'écran qui le montre.
  final DiceOffState? diceOff;

  /// La dernière erreur du serveur ; [errorSerial] change à chaque nouvelle
  /// erreur, même identique, pour que l'écran la réaffiche.
  final ErrorCode? error;
  final int errorSerial;

  /// Vrai quand [error] vient de ce que le serveur n'a pas pu être joint.
  final bool unreachable;

  const OnlineState({
    this.status = OnlineStatus.offline,
    this.roomCode,
    this.mySeat,
    this.hostSeat = 0,
    this.seats = const [],
    this.phase,
    this.gameStarted = false,
    this.diceOff,
    this.error,
    this.errorSerial = 0,
    this.unreachable = false,
  });

  bool get inRoom => roomCode != null;
  bool get isHost => mySeat != null && mySeat == hostSeat;

  OnlineState copyWith({
    OnlineStatus? status,
    String? roomCode,
    int? mySeat,
    int? hostSeat,
    List<SeatInfo>? seats,
    RoomPhase? phase,
    bool? gameStarted,
    DiceOffState? diceOff,
    ErrorCode? error,
    int? errorSerial,
    bool? unreachable,
  }) {
    return OnlineState(
      status: status ?? this.status,
      roomCode: roomCode ?? this.roomCode,
      mySeat: mySeat ?? this.mySeat,
      hostSeat: hostSeat ?? this.hostSeat,
      seats: seats ?? this.seats,
      phase: phase ?? this.phase,
      gameStarted: gameStarted ?? this.gameStarted,
      diceOff: diceOff ?? this.diceOff,
      error: error ?? this.error,
      errorSerial: errorSerial ?? this.errorSerial,
      unreachable: unreachable ?? this.unreachable,
    );
  }
}

final onlineSessionProvider = NotifierProvider<OnlineSession, OnlineState>(OnlineSession.new);

/// La session en ligne : la connexion au serveur, le salon, et le pont vers
/// [GameNotifier] une fois la partie commencée.
class OnlineSession extends Notifier<OnlineState> {
  OnlineChannel? _channel;
  StreamSubscription<String>? _subscription;
  Timer? _reconnectTimer;
  OnlineCredentials? _credentials;
  var _attempt = 0;

  /// Vrai quand la fermeture vient de nous (quitter le salon, changer de
  /// serveur) : on ne cherche alors pas à se reconnecter.
  var _closingOnPurpose = false;

  /// Un jeton reçu du serveur, en attente d'être associé à l'adresse utilisée.
  String? _pendingUrl;

  @override
  OnlineState build() {
    ref.onDispose(_teardown);
    return const OnlineState();
  }

  GameNotifier get _game => ref.read(gameProvider.notifier);

  /// Crée un salon et y entre.
  Future<void> create(String name) => _open(ClientMessage.create(name: name));

  /// Entre dans le salon [code].
  Future<void> join(String code, String name) => _open(ClientMessage.join(code: code.trim().toUpperCase(), name: name));

  /// Reprend sa place avec le jeton gardé d'une session précédente ; sans effet
  /// s'il n'y en a pas. À appeler au lancement de l'app.
  Future<bool> tryResume() async {
    final saved = await ref.read(onlineCredentialsStoreProvider).load();
    if (saved == null) return false;
    _credentials = saved;
    await _open(ClientMessage.rejoin(token: saved.token), url: saved.url);
    return true;
  }

  void reorder(List<int> order) => _send(ClientMessage.reorder(order));

  void start() => _send(ClientMessage.start());

  void play(GameActionType intent, Map<String, dynamic> params) => _send(ClientMessage.play(intent, params: params));

  /// Quitte le salon pour de bon : le siège est libéré (ou, en partie, laissé
  /// vide) et le jeton oublié.
  Future<void> leave() async {
    _send(ClientMessage.leave());
    _credentials = null;
    await ref.read(onlineCredentialsStoreProvider).clear();
    await _close();
    _game.endOnlineGame();
    state = const OnlineState();
  }

  Future<void> _open(ClientMessage first, {String? url}) async {
    await _close();
    _closingOnPurpose = false;
    _reconnectTimer?.cancel();
    final String target = url ?? ref.read(onlineServerUrlProvider);
    _pendingUrl = target;
    state = state.copyWith(status: OnlineStatus.connecting);
    final OnlineChannel channel;
    try {
      final uri = Uri.parse(target);
      if (!isAcceptableServerUrl(uri, release: kReleaseMode)) throw StateError('adresse de serveur refusée : $target');
      channel = await ref.read(onlineTransportProvider).connect(uri);
    } catch (_) {
      _fail(ErrorCode.roomNotFound, unreachable: true);
      _scheduleReconnect();
      return;
    }
    _channel = channel;
    _subscription = channel.incoming.listen(_onMessage, onDone: () => _onClosed(channel), onError: (Object _) => _onClosed(channel));
    state = state.copyWith(status: OnlineStatus.online);
    channel.send(jsonEncode(first.toJson()));
  }

  void _send(ClientMessage message) => _channel?.send(jsonEncode(message.toJson()));

  void _onMessage(String raw) {
    final ServerMessage message;
    try {
      message = ServerMessage.fromJson(jsonDecode(raw));
    } on FormatException {
      return _resync();
    }
    try {
      switch (message.type) {
        case ServerMessageType.joined:
          _onJoined(message);
        case ServerMessageType.room:
          state = state.copyWith(
            roomCode: message.roomCode,
            phase: message.phase,
            seats: message.seats,
            hostSeat: message.hostSeat,
          );
        case ServerMessageType.snapshot:
          _onSnapshot(message);
        case ServerMessageType.action:
          _onAction(message);
        case ServerMessageType.error:
          _onError(message.errorCode);
      }
    } on FormatException {
      _resync();
    }
  }

  void _onJoined(ServerMessage message) {
    _attempt = 0;
    final credentials = OnlineCredentials(url: _pendingUrl ?? ref.read(onlineServerUrlProvider), code: message.roomCode, token: message.token);
    _credentials = credentials;
    unawaited(ref.read(onlineCredentialsStoreProvider).save(credentials));
    state = state.copyWith(roomCode: message.roomCode, mySeat: message.seat);
  }

  void _onSnapshot(ServerMessage message) {
    final seat = state.mySeat;
    if (seat == null) return;
    final names = message.names;
    final actions = message.actions;
    _game.startOnlineGame(names: names, actions: actions, mySeat: seat, sendIntent: play);
    final diceOff = replayGame(GameSetup(playerNames: names), 0, actions.sublist(0, diceOffActionCount(actions))).diceOff;
    state = state.copyWith(gameStarted: true, diceOff: diceOff);
  }

  void _onAction(ServerMessage message) {
    if (!state.gameStarted) return;
    final expected = _game.onlineActionCount;
    if (message.seq < expected) return; // déjà appliquée (doublon après reconnexion)
    if (message.seq > expected) return _resync(); // un trou : on redemande tout
    try {
      _game.applyOnlineAction(message.action);
    } on StateError {
      _resync(); // le serveur et nous ne sommes plus d'accord : repartir de son journal
    }
  }

  void _onError(ErrorCode code) {
    if (code == ErrorCode.badToken) {
      _credentials = null;
      unawaited(ref.read(onlineCredentialsStoreProvider).clear());
    }
    _fail(code);
  }

  void _fail(ErrorCode code, {bool unreachable = false}) {
    state = state.copyWith(
      status: unreachable ? OnlineStatus.offline : null,
      error: code,
      errorSerial: state.errorSerial + 1,
      unreachable: unreachable,
    );
  }

  /// Repart du journal complet du serveur : on rouvre la connexion avec le
  /// jeton, ce qui provoque l'envoi d'un nouveau `snapshot`.
  void _resync() {
    final credentials = _credentials;
    if (credentials == null) return;
    unawaited(_open(ClientMessage.rejoin(token: credentials.token), url: credentials.url));
  }

  void _onClosed(OnlineChannel channel) {
    if (!identical(channel, _channel)) return;
    _channel = null;
    if (_closingOnPurpose) return;
    state = state.copyWith(status: OnlineStatus.offline);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final credentials = _credentials;
    if (credentials == null || state.phase == RoomPhase.over) return;
    _reconnectTimer?.cancel();
    final delay = ref.read(onlineReconnectDelayProvider)(_attempt++);
    _reconnectTimer = Timer(delay, () {
      unawaited(_open(ClientMessage.rejoin(token: credentials.token), url: credentials.url));
    });
  }

  Future<void> _close() async {
    _closingOnPurpose = true;
    await _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    await channel?.close();
  }

  void _teardown() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.close();
  }
}
