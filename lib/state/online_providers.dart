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

export '../game/online/protocol.dart' show ErrorCode, RoomPhase, SeatInfo, Emote, emoteCooldown, emotesFor;

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

/// Un vote de revanche en cours (voir [rematchFeature]) : qui l'a proposée,
/// jusqu'à quand on peut répondre (heure de l'appareil, calculée à réception),
/// et qui a déjà répondu quoi, par siège.
class RematchView {
  final int proposerSeat;
  final DateTime deadline;
  final Map<int, bool> answers;

  const RematchView({required this.proposerSeat, required this.deadline, this.answers = const {}});
}

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

  /// Les fonctions facultatives annoncées par le serveur (voir [serverFeatures]).
  final List<String> serverFeatures;

  /// Le joueur qui commence a lancé la partie (voir [startSignalFeature]).
  final bool begun;

  /// Le vote de revanche en cours, s'il y en a un.
  final RematchView? rematch;

  /// Change à chaque nouvelle partie dans le même salon (une revanche) : l'écran
  /// de fin s'y reconnaît pour ouvrir la nouvelle partie.
  final int gameSerial;

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
    this.serverFeatures = const [],
    this.begun = false,
    this.rematch,
    this.gameSerial = 0,
  });

  bool get inRoom => roomCode != null;
  bool get isHost => mySeat != null && mySeat == hostSeat;

  bool get emotes2Enabled => serverFeatures.contains(emotes2Feature);
  bool get seatBotsEnabled => serverFeatures.contains(seatBotsFeature);
  bool get startSignalEnabled => serverFeatures.contains(startSignalFeature);
  bool get rematchEnabled => serverFeatures.contains(rematchFeature);

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
    List<String>? serverFeatures,
    bool? begun,
    RematchView? rematch,
    bool clearRematch = false,
    int? gameSerial,
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
      serverFeatures: serverFeatures ?? this.serverFeatures,
      begun: begun ?? this.begun,
      rematch: clearRematch ? null : (rematch ?? this.rematch),
      gameSerial: gameSerial ?? this.gameSerial,
    );
  }
}

final onlineSessionProvider = NotifierProvider<OnlineSession, OnlineState>(OnlineSession.new);

/// Ce qui renvoie un joueur à l'accueil depuis l'écran de fin d'une partie en
/// ligne : il a refusé la revanche (ou n'a pas répondu à temps), ou elle n'a
/// pas eu lieu, faute de joueurs.
enum OnlineNotice { rematchExcluded, rematchCancelled }

/// La dernière [OnlineNotice], avec un numéro qui change à chacune : la
/// session, elle, est déjà remise à zéro quand l'écran la lit.
final onlineNoticeProvider = NotifierProvider<OnlineNoticeNotifier, ({OnlineNotice notice, int serial})?>(
  OnlineNoticeNotifier.new,
);

class OnlineNoticeNotifier extends Notifier<({OnlineNotice notice, int serial})?> {
  @override
  ({OnlineNotice notice, int serial})? build() => null;

  void raise(OnlineNotice notice) => state = (notice: notice, serial: (state?.serial ?? 0) + 1);
}

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
final onlineSavedGameProvider = FutureProvider<OnlineCredentials?>((ref) async {
  ref.watch(onlineSessionProvider.select((s) => s.roomCode));
  // Une partie finie n'a plus de place à reprendre : son jeton est effacé à
  // l'annonce de la fin, sans qu'on puisse attendre le disque à ce moment-là.
  if (ref.watch(onlineSessionProvider.select((s) => s.phase)) == RoomPhase.over) return null;
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

  /// Les fonctions facultatives du serveur (voir [serverFeatures]), apprises
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

  /// Le joueur qui commence lance la partie pour tous (voir
  /// [startSignalFeature]) ; sans effet face à un serveur qui ne le connaît pas.
  void begin() {
    if (!state.startSignalEnabled) return;
    _send(ClientMessage.begin());
  }

  /// Propose une revanche (ou, si un vote est déjà en cours, l'accepte).
  void proposeRematch() {
    if (!state.rematchEnabled) return;
    _send(ClientMessage.rematch(RematchAnswer.propose));
  }

  /// Répond à la revanche proposée. La refuser, c'est quitter le salon : on
  /// rentre aussitôt, sans attendre que le serveur le confirme.
  Future<void> answerRematch({required bool accept}) async {
    if (!state.rematchEnabled) return;
    _send(ClientMessage.rematch(accept ? RematchAnswer.accept : RematchAnswer.refuse));
    if (!accept) await leave(tellServer: false);
  }

  /// Quitte la partie en ligne en cours, après confirmation du joueur : pour de
  /// bon quand le serveur fait reprendre le siège par un bot (voir
  /// [seatBotsFeature]) — la partie continue sans moi —, en gardant sa place
  /// sinon (voir [disconnect]) : la partie m'attendrait, il faut pouvoir y
  /// revenir.
  Future<void> leaveGame() => state.seatBotsEnabled ? leave() : disconnect();

  /// Quitte le salon pour de bon : le siège est libéré (en partie, repris par
  /// un bot du serveur, ou laissé vide par un serveur d'avant) et le jeton
  /// oublié. Pour partir d'une partie commencée en gardant sa place, c'est
  /// [disconnect]. [tellServer] : faux quand le serveur nous a déjà retirés du
  /// salon (revanche refusée ou abandonnée).
  Future<void> leave({bool tellServer = true}) async {
    if (tellServer) _send(ClientMessage.leave());
    _credentials = null;
    // La connexion cesse d'écouter tout de suite (rien de ce qui arriverait
    // encore ne doit repeupler l'état), mais l'état n'attend pas qu'elle soit
    // fermée. Il attend en revanche l'effacement du jeton : sa remise à zéro
    // fait relire [onlineSavedGameProvider], qui reproposerait sinon la place.
    final closing = _close();
    await ref.read(onlineCredentialsStoreProvider).clear();
    // Seulement la partie en ligne : une partie locale n'est pas la nôtre.
    if (_game.isOnline) _game.endOnlineGame();
    ref.read(onlineEmotesProvider.notifier).clear();
    state = const OnlineState();
    await closing;
  }

  /// Vrai quand la session est encore dans le salon d'une partie terminée :
  /// rien à y reprendre (voir [leaveFinishedGame]).
  bool get inFinishedGame => state.inRoom && state.phase == RoomPhase.over;

  /// Quitte le salon d'une partie terminée, s'il en reste un : de retour à
  /// l'accueil après une partie en ligne, la session y est encore (le serveur
  /// ne ferme pas le salon), et l'entrée en ligne proposait de « reprendre »
  /// une partie qui n'avait plus rien à montrer — un écran qui attendait sans
  /// fin. Sans effet hors de ce cas.
  Future<void> leaveFinishedGame() async {
    if (inFinishedGame) await leave();
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
    if (_channel != null || _closingOnPurpose || credentials == null || _finishedForGood) return;
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
        case ServerMessageType.rematch:
          _onRematch(message);
        case ServerMessageType.joined:
          _onJoined(message);
        case ServerMessageType.room:
          // Partie finie : rien à retrouver, le jeton ne sert plus — sauf quand
          // une revanche peut encore s'y jouer : il faut alors pouvoir revenir
          // dans le salon après une coupure.
          if (message.phase == RoomPhase.over && !state.rematchEnabled) {
            _credentials = null;
            unawaited(ref.read(onlineCredentialsStoreProvider).clear());
          }
          final seats = message.seats;
          state = state.copyWith(
            roomCode: message.roomCode,
            phase: message.phase,
            seats: seats,
            hostSeat: message.hostSeat,
            begun: message.begun,
          );
          if (_game.isOnline) _game.setOnlineBotSeats({for (var i = 0; i < seats.length; i++) if (seats[i].bot) i});
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
    state = state.copyWith(emotesEnabled: _serverFeatures.contains(emotesFeature), serverFeatures: _serverFeatures);
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
    final names = message.names;
    final actions = message.actions;
    // Une nouvelle partie dans le même salon (une revanche, qui ne se joue
    // qu'une fois la précédente finie) : son journal ne commence pas comme
    // celui de la partie à l'écran.
    final current = _game.isOnline && _game.actions.isNotEmpty ? _game.actions.first : null;
    final newGame = state.gameStarted &&
        state.phase == RoomPhase.over &&
        current != null &&
        actions.isNotEmpty &&
        (current.type != actions.first.type || current.at != actions.first.at);
    // Un journal neuf : une sélection gardée d'avant (autre partie, autre
    // lancer) n'a plus cours. Celle du lancer en attente, s'il y en a une, suit.
    ref.read(onlineKeepSelectionProvider.notifier).clear();
    // Les émotions d'une autre partie n'ont rien à faire dans celle-ci ; celles
    // de cette partie restent quand on y revient après une coupure.
    if (!state.gameStarted || newGame) ref.read(onlineEmotesProvider.notifier).clear();
    _game.startOnlineGame(
      names: names,
      actions: actions,
      mySeat: seat,
      sendIntent: play,
      myProfileId: ref.read(settingsProvider).myProfileId,
      sendSelection: select,
    );
    _game.setOnlineBotSeats({for (var i = 0; i < state.seats.length; i++) if (state.seats[i].bot) i});
    final diceOff = replayGame(GameSetup(playerNames: names), 0, actions.sublist(0, diceOffActionCount(actions))).diceOff;
    state = state.copyWith(
      gameStarted: true,
      diceOff: diceOff,
      clearRematch: newGame,
      gameSerial: newGame ? state.gameSerial + 1 : null,
    );
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

  /// Où en est la revanche. Illisible (une version plus récente) : ignoré —
  /// rien qui vaille de redemander tout le journal.
  void _onRematch(ServerMessage message) {
    final RematchStatus status;
    try {
      status = message.rematchStatus;
      switch (status) {
        case RematchStatus.pending:
          final proposer = message.proposerSeat;
          if (proposer == null) return;
          state = state.copyWith(
            rematch: RematchView(
              proposerSeat: proposer,
              deadline: DateTime.now().add(message.remaining ?? Duration.zero),
              answers: message.rematchAnswers,
            ),
          );
        case RematchStatus.excluded:
        case RematchStatus.cancelled:
          // Le serveur m'a déjà retiré du salon : je rentre.
          ref.read(onlineNoticeProvider.notifier).raise(
                status == RematchStatus.excluded ? OnlineNotice.rematchExcluded : OnlineNotice.rematchCancelled,
              );
          unawaited(leave(tellServer: false));
      }
    } on FormatException {
      return;
    }
  }

  /// Vrai quand le salon n'a plus rien à offrir après une coupure : une partie
  /// finie, sans revanche possible.
  bool get _finishedForGood => state.phase == RoomPhase.over && !state.rematchEnabled;

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
    if (credentials == null || _finishedForGood || _inBackground) return;
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
