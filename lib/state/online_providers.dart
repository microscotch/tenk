import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/dice_off.dart';
import '../game/game_recording.dart';
import '../game/online/protocol.dart';
import 'game_providers.dart';
import 'online_transport.dart';
import 'settings_providers.dart';

export '../game/online/protocol.dart' show ErrorCode, RoomPhase, SeatInfo, Emote, emoteCooldown;

/// L'adresse du serveur des parties en ligne. Celle de production par défaut
/// (chiffrée : le TLS se termine sur le reverse proxy du serveur) ; pour jouer
/// contre un serveur local pendant le développement :
/// `flutter run -d linux --dart-define=TENK_SERVER_URL=ws://localhost:8080/ws`.
const String defaultServerUrl = String.fromEnvironment('TENK_SERVER_URL', defaultValue: 'wss://tenk.microscotch.net/ws');

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

  /// Vrai quand le serveur relaie les émotions (voir `emotesFeature`) : l'écran
  /// de jeu propose alors ses boutons d'émotion.
  final bool emotesEnabled;

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
    this.emotesEnabled = false,
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
    bool? emotesEnabled,
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
      emotesEnabled: emotesEnabled ?? this.emotesEnabled,
    );
  }
}

final onlineSessionProvider = NotifierProvider<OnlineSession, OnlineState>(OnlineSession.new);

/// Relie la session en ligne au cycle de vie de l'app (voir
/// [OnlineSession.appPaused] / [OnlineSession.appResumed]). Regardé par la
/// racine de l'app, pour toute sa durée.
final onlineLifecycleProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onStateChange: (lifecycle) {
      final session = ref.read(onlineSessionProvider.notifier);
      switch (lifecycle) {
        case AppLifecycleState.resumed:
          session.appResumed();
        case AppLifecycleState.paused:
        case AppLifecycleState.hidden:
          session.appPaused();
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          break;
      }
    },
  );
  ref.onDispose(listener.dispose);
});

/// Une émotion reçue pendant la partie en ligne : de qui (siège du salon),
/// laquelle, avec quelle phrase (nulle : l'émotion seule), et quand elle est
/// arrivée. [id] croît d'une émotion à la suivante.
class EmoteEvent {
  final int id;
  final int seat;
  final Emote emote;
  final String? phrase;
  final DateTime at;

  const EmoteEvent({required this.id, required this.seat, required this.emote, this.phrase, required this.at});
}

/// Les dernières émotions reçues dans la partie en ligne en cours (les plus
/// récentes en dernier, 50 au plus). L'écran de jeu en tire ses bulles et les
/// lignes de son Historique — et les y remet quand il se reconstruit, le journal
/// de la partie n'en gardant aucune trace.
final onlineEmotesProvider = NotifierProvider<OnlineEmotesNotifier, List<EmoteEvent>>(OnlineEmotesNotifier.new);

class OnlineEmotesNotifier extends Notifier<List<EmoteEvent>> {
  static const _kept = 50;
  var _nextId = 0;

  @override
  List<EmoteEvent> build() => const [];

  void add({required int seat, required Emote emote, String? phrase, DateTime? at}) {
    final event = EmoteEvent(id: _nextId++, seat: seat, emote: emote, phrase: phrase, at: at ?? DateTime.now());
    final next = [...state, event];
    state = next.length > _kept ? next.sublist(next.length - _kept) : next;
  }

  void clear() => state = const [];
}

/// La sélection de 5 en cours de l'autre joueur en ligne qui a la main, sur le
/// lancer qui attend sa décision : [seq] est le rang de la prochaine action du
/// journal, qui date la sélection. L'écran de jeu la suit (score de la main,
/// dés qui migrent) tant que ce rang est celui de sa partie ; nulle sinon.
typedef OnlineKeepSelection = ({int seq, int declineFivesCount});

final onlineKeepSelectionProvider =
    NotifierProvider<OnlineKeepSelectionNotifier, OnlineKeepSelection?>(OnlineKeepSelectionNotifier.new);

class OnlineKeepSelectionNotifier extends Notifier<OnlineKeepSelection?> {
  @override
  OnlineKeepSelection? build() => null;

  void set(OnlineKeepSelection selection) => state = selection;
  void clear() => state = null;
}

/// La place gardée dans une partie en ligne (jeton d'une session précédente ou
/// d'une déconnexion volontaire), pour proposer de la retrouver. Se relit dès
/// que la session entre dans un salon ou en sort.
final onlineSavedGameProvider = FutureProvider<OnlineCredentials?>((ref) {
  ref.watch(onlineSessionProvider.select((s) => s.roomCode));
  return ref.watch(onlineCredentialsStoreProvider).load();
});

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

  /// Les fonctions facultatives du serveur (voir `supportedFeatures`), apprises
  /// par `joined`.
  List<String> _serverFeatures = const [];

  /// Vrai quand le joueur vient de demander lui-même à retrouver sa partie en
  /// ligne : le journal qui arrive peut alors prendre la place d'une partie
  /// locale restée en mémoire. Sans cette demande, il ne la remplace jamais.
  var _takeover = false;
  Completer<bool>? _reopening;

  /// Vrai tant que l'app est en arrière-plan (partage du code, autre app) :
  /// le système y coupe souvent le réseau, et chaque tentative échouerait.
  /// On n'en fait donc aucune ; le retour au premier plan reconnecte aussitôt
  /// (voir [appResumed]).
  var _inBackground = false;

  @override
  OnlineState build() {
    ref.onDispose(_teardown);
    return const OnlineState();
  }

  GameNotifier get _game => ref.read(gameProvider.notifier);

  /// Crée un salon et y entre.
  Future<void> create(String name) {
    _joinIfBadToken = null;
    return _open(ClientMessage.create(name: name));
  }

  /// Entre dans le salon [code]. Si j'y ai déjà une place (app tuée puis
  /// rouverte par le lien d'invitation, par exemple), je la reprends avec mon
  /// jeton plutôt que d'en prendre une seconde — le serveur me verrait sinon
  /// comme un nouveau joueur, au pseudo suffixé (« Anna 2 »). Si ce jeton ne
  /// vaut plus rien (salon expiré, place libérée), on entre normalement.
  Future<void> join(String code, String name) async {
    final normalized = code.trim().toUpperCase();
    final saved = await ref.read(onlineCredentialsStoreProvider).load();
    if (!ref.mounted) return;
    if (saved != null && saved.code == normalized && saved.url == ref.read(onlineServerUrlProvider)) {
      _takeover = true;
      _credentials = saved;
      _joinIfBadToken = (code: normalized, name: name);
      return _open(ClientMessage.rejoin(token: saved.token), url: saved.url);
    }
    _joinIfBadToken = null;
    return _open(ClientMessage.join(code: normalized, name: name));
  }

  /// Un « rejoindre » tenté avec mon jeton gardé (voir [join]) : de quoi entrer
  /// normalement si le serveur ne reconnaît plus ce jeton.
  ({String code, String name})? _joinIfBadToken;

  /// Reprend sa place avec le jeton gardé d'une session précédente ; sans effet
  /// s'il n'y en a pas. À appeler au lancement de l'app.
  Future<bool> tryResume() async {
    final saved = await ref.read(onlineCredentialsStoreProvider).load();
    if (saved == null) return false;
    _takeover = true;
    _credentials = saved;
    await _open(ClientMessage.rejoin(token: saved.token), url: saved.url);
    return true;
  }

  void reorder(List<int> order) => _send(ClientMessage.reorder(order));

  void start() {
    _takeover = true;
    _send(ClientMessage.start());
  }

  void play(GameActionType intent, Map<String, dynamic> params) => _send(ClientMessage.play(intent, params: params));

  /// Envoie ma sélection de 5 en cours, pour que les autres la voient — si le
  /// serveur sait la relayer (un serveur d'avant la refuserait).
  void select(int declineFivesCount) {
    if (!_serverFeatures.contains(keepSelectionFeature)) return;
    _send(ClientMessage.select(declineFivesCount: declineFivesCount));
  }

  /// Envoie une émotion aux autres joueurs (et à moi : ma bulle apparaît quand
  /// le serveur la relaie, comme chez eux). Sans effet si le serveur ne relaie
  /// pas les émotions.
  void sendEmote(Emote emote, {String? phrase}) {
    if (!state.emotesEnabled) return;
    _send(ClientMessage.emote(emote, phrase: phrase));
  }

  /// Quitte le salon pour de bon : le siège est libéré (ou, en partie, laissé
  /// vide) et le jeton oublié. Pour partir d'une partie commencée en gardant sa
  /// place, c'est [disconnect].
  Future<void> leave() async {
    _send(ClientMessage.leave());
    _credentials = null;
    await ref.read(onlineCredentialsStoreProvider).clear();
    await _close();
    // Seulement la partie en ligne : une partie locale n'est pas la nôtre.
    if (_game.isOnline) _game.endOnlineGame();
    ref.read(onlineEmotesProvider.notifier).clear();
    state = const OnlineState();
  }

  /// Se déconnecte en GARDANT sa place : le jeton reste, la partie attend le
  /// retour du joueur (elle se suspend au bout de deux minutes) et il la
  /// retrouve depuis l'écran d'entrée.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _close();
    if (_game.isOnline) _game.endOnlineGame();
    state = const OnlineState();
  }

  /// Rouvre la partie en ligne dans le [GameNotifier] quand celui-ci a servi à
  /// autre chose depuis (une partie locale, un rejeu) : redemande le journal au
  /// serveur et rend vrai quand il est en place. Vrai tout de suite si la partie
  /// en ligne y est déjà.
  Future<bool> reopenGame() async {
    if (_game.isOnline) return true;
    if (_credentials == null) return false;
    _takeover = true;
    final done = _reopening = Completer<bool>();
    _resync();
    return done.future.timeout(const Duration(seconds: 10), onTimeout: () => false);
  }

  /// L'app passe en arrière-plan : plus de tentative de reconnexion d'ici son
  /// retour (voir `onlineLifecycleProvider`).
  void appPaused() {
    _inBackground = true;
    _reconnectTimer?.cancel();
  }

  /// L'app revient au premier plan : si la connexion est tombée entre-temps, on
  /// la rouvre tout de suite, sans attendre le délai croissant des tentatives.
  void appResumed() {
    if (!_inBackground) return;
    _inBackground = false;
    final credentials = _credentials;
    if (_channel != null || _closingOnPurpose || credentials == null || state.phase == RoomPhase.over) return;
    _attempt = 0;
    unawaited(_open(ClientMessage.rejoin(token: credentials.token), url: credentials.url, automatic: true));
  }

  /// Ouvre la connexion et envoie [first]. [automatic] : une reconnexion que le
  /// joueur n'a pas demandée — son échec ne s'affiche pas en erreur (une par
  /// tentative s'empilerait à l'écran), l'état « hors ligne » suffit au bandeau.
  Future<void> _open(ClientMessage first, {String? url, bool automatic = false}) async {
    await _close();
    // La session a pu disparaître pendant l'attente (app fermée, conteneur
    // détruit) : y écrire lèverait, et rien ne doit plus se rouvrir.
    if (!ref.mounted) return;
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
      if (!ref.mounted) return;
      if (automatic) {
        state = state.copyWith(status: OnlineStatus.offline);
      } else {
        _fail(ErrorCode.roomNotFound, unreachable: true);
      }
      _scheduleReconnect();
      return;
    }
    if (!ref.mounted) {
      unawaited(channel.close());
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
    } on UnknownServerMessage {
      return; // un serveur plus récent : ce message ne nous concerne pas
    } on FormatException {
      return _resync();
    }
    try {
      switch (message.type) {
        case ServerMessageType.joined:
          _onJoined(message);
        case ServerMessageType.room:
          // Partie finie : rien à retrouver, le jeton ne sert plus.
          if (message.phase == RoomPhase.over) {
            _credentials = null;
            unawaited(ref.read(onlineCredentialsStoreProvider).clear());
          }
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
        case ServerMessageType.selection:
          _onSelection(message);
        case ServerMessageType.emote:
          _onEmote(message);
      }
    } on FormatException {
      _resync();
    }
  }

  void _onJoined(ServerMessage message) {
    _attempt = 0;
    _joinIfBadToken = null;
    final credentials = OnlineCredentials(url: _pendingUrl ?? ref.read(onlineServerUrlProvider), code: message.roomCode, token: message.token);
    _credentials = credentials;
    _serverFeatures = message.features;
    state = state.copyWith(emotesEnabled: _serverFeatures.contains(emotesFeature));
    unawaited(ref.read(onlineCredentialsStoreProvider).save(credentials));
    state = state.copyWith(roomCode: message.roomCode, mySeat: message.seat);
  }

  void _onSnapshot(ServerMessage message) {
    final seat = state.mySeat;
    if (seat == null) return;
    // Une partie locale est en cours : le journal du serveur ne la remplace pas
    // de lui-même. Il le peut si le joueur attendait dans le salon (le départ
    // arrive alors que le salon est encore au repos), s'il l'a demandé, ou si
    // la partie en ligne est déjà celle de l'écran (reconnexion).
    final invited = state.phase == RoomPhase.lobby || _takeover;
    if (!_game.isOnline && _game.hasLiveLocalGame && !invited) return;
    _takeover = false;
    // Un journal neuf : une sélection gardée d'avant (autre partie, autre
    // lancer) n'a plus cours. Celle du lancer en attente, s'il y en a une, suit.
    ref.read(onlineKeepSelectionProvider.notifier).clear();
    // Les émotions d'une autre partie n'ont rien à faire dans celle-ci ; celles
    // de cette partie restent quand on y revient après une coupure.
    if (!state.gameStarted) ref.read(onlineEmotesProvider.notifier).clear();
    final names = message.names;
    final actions = message.actions;
    _game.startOnlineGame(
      names: names,
      actions: actions,
      mySeat: seat,
      sendIntent: play,
      myProfileId: ref.read(settingsProvider).myProfileId,
      sendSelection: select,
    );
    final diceOff = replayGame(GameSetup(playerNames: names), 0, actions.sublist(0, diceOffActionCount(actions))).diceOff;
    state = state.copyWith(gameStarted: true, diceOff: diceOff);
    _reopening?.complete(true);
    _reopening = null;
  }

  void _onAction(ServerMessage message) {
    // Seulement pour la partie en ligne de l'écran : jamais sur une partie
    // locale, dont le journal n'a rien à voir avec celui du serveur.
    if (!state.gameStarted || !_game.isOnline) return;
    final expected = _game.onlineActionCount;
    if (message.seq < expected) return; // déjà appliquée (doublon après reconnexion)
    if (message.seq > expected) return _resync(); // un trou : on redemande tout
    try {
      _game.applyOnlineAction(message.action);
    } on StateError {
      _resync(); // le serveur et nous ne sommes plus d'accord : repartir de son journal
    }
  }

  /// La sélection en cours de l'autre joueur qui a la main. Seulement si elle
  /// porte sur le lancer que montre l'écran : une sélection en retard (le coup
  /// est déjà arrivé) ou en avance (il nous manque des actions) est ignorée.
  void _onSelection(ServerMessage message) {
    if (!state.gameStarted || !_game.isOnline) return;
    final seq = message.seq;
    if (seq != _game.onlineActionCount) return;
    ref.read(onlineKeepSelectionProvider.notifier).set((seq: seq, declineFivesCount: message.declineFivesCount));
  }

  /// Une émotion relayée par le serveur, pour la partie à l'écran. Illisible
  /// (émotion ou phrase d'une version plus récente) : ignorée — une bulle ratée
  /// ne vaut pas de redemander tout le journal.
  void _onEmote(ServerMessage message) {
    if (!state.gameStarted || !_game.isOnline) return;
    final int seat;
    final Emote emote;
    final String? phrase;
    try {
      seat = message.seat;
      (emote, phrase) = message.emote;
    } on FormatException {
      return;
    }
    ref.read(onlineEmotesProvider.notifier).add(seat: seat, emote: emote, phrase: phrase);
  }

  void _onError(ErrorCode code) {
    if (code == ErrorCode.badToken) {
      _credentials = null;
      unawaited(ref.read(onlineCredentialsStoreProvider).clear());
      // Ma place d'avant n'existe plus : j'entre dans le salon comme demandé,
      // sans afficher d'erreur pour une place que je ne cherchais pas à reprendre.
      final join = _joinIfBadToken;
      if (join != null) {
        _joinIfBadToken = null;
        unawaited(_open(ClientMessage.join(code: join.code, name: join.name)));
        return;
      }
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
    unawaited(_open(ClientMessage.rejoin(token: credentials.token), url: credentials.url, automatic: true));
  }

  void _onClosed(OnlineChannel channel) {
    if (!identical(channel, _channel)) return;
    _channel = null;
    // Le flux est fini : son abonnement n'a plus rien à annuler, et attendre
    // cette annulation à la reconnexion suivante (voir [_close]) peut ne jamais
    // aboutir.
    _subscription = null;
    if (_closingOnPurpose) return;
    state = state.copyWith(status: OnlineStatus.offline);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final credentials = _credentials;
    if (credentials == null || state.phase == RoomPhase.over || _inBackground) return;
    _reconnectTimer?.cancel();
    final delay = ref.read(onlineReconnectDelayProvider)(_attempt++);
    _reconnectTimer = Timer(delay, () {
      unawaited(_open(ClientMessage.rejoin(token: credentials.token), url: credentials.url, automatic: true));
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
