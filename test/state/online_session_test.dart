import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/online/protocol.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/online_providers.dart';
import 'package:le10000/state/online_transport.dart';

import '../test_helpers/fake_online.dart';
import '../test_helpers/scripted_game.dart';

/// Le passage de témoin d'un rejeu, sur les actions de la partie principale de [full].
GameRecordingHandoff _handoffOf(List<GameAction> full) => GameRecordingHandoff(
      seed: 0,
      random: Random(0),
      originalSetup: const GameSetup(playerNames: ['Anna', 'Bob']),
      alias: '',
      createdAt: DateTime(2026),
      actions: full.sublist(diceOffActionCount(full)),
    );

void main() {
  const names = ['Anna', 'Bob'];
  const token = 'abcdef0123456789abcdef0123456789';

  late FakeTransport transport;
  late FakeCredentialsStore credentials;
  late ProviderContainer container;

  ProviderContainer newContainer() {
    final c = ProviderContainer(overrides: [
      onlineTransportProvider.overrideWithValue(transport),
      onlineCredentialsStoreProvider.overrideWithValue(credentials),
      onlineServerUrlProvider.overrideWithValue('ws://test/ws'),
      onlineReconnectDelayProvider.overrideWithValue((_) => const Duration(milliseconds: 5)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    transport = FakeTransport();
    credentials = FakeCredentialsStore();
    container = newContainer();
  });

  OnlineSession session() => container.read(onlineSessionProvider.notifier);
  OnlineState online() => container.read(onlineSessionProvider);
  GameNotifier game() => container.read(gameProvider.notifier);

  const setup = GameSetup(playerNames: names);

  /// Le journal complet d'une partie à deux, tel que le serveur l'aurait écrit
  /// (dés avec leurs faces), jusqu'à sa fin.
  List<GameAction> fullJournal({int seed = 5}) =>
      journalWithFaces(setup, seed, playScriptedGame(setup, seed).actions);

  /// Ce que le serveur envoie au départ : le départage et le premier tour.
  List<GameAction> serverJournal() {
    final full = fullJournal();
    return full.sublist(0, full.indexWhere((a) => a.type == GameActionType.startTurn) + 1);
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  /// Entre dans un salon en tant que [seat] et reçoit le journal.
  Future<void> joinedAndStarted(int seat, List<GameAction> journal) async {
    await session().join('abcde', names[seat]);
    transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: seat));
    transport.current.serverSends(ServerMessage.snapshot(names: names, actions: journal));
    await settle();
  }

  group('adresse du serveur', () {
    test('l\'adresse par défaut est celle de production, chiffrée : une release peut s\'en servir', () {
      final url = Uri.parse(defaultServerUrl);
      expect(url.scheme, 'wss');
      expect(url.host, 'tenk.microscotch.net');
      expect(url.path, '/ws');
      expect(isAcceptableServerUrl(url, release: true), isTrue);
    });

    test('une release n\'accepte que wss://, le développement accepte aussi ws://', () {
      expect(isAcceptableServerUrl(Uri.parse('wss://jeu.example/ws'), release: true), isTrue);
      expect(isAcceptableServerUrl(Uri.parse('ws://jeu.example/ws'), release: true), isFalse);
      expect(isAcceptableServerUrl(Uri.parse('ws://localhost:8080/ws'), release: false), isTrue);
      expect(isAcceptableServerUrl(Uri.parse('http://jeu.example/ws'), release: false), isFalse);
      expect(isAcceptableServerUrl(Uri.parse('wss:///ws'), release: true), isFalse, reason: 'pas d\'hôte');
    });
  });

  group('salon', () {
    test('créer envoie la demande, puis le serveur donne siège et jeton, qui sont gardés', () async {
      await session().create('Anna');
      expect(transport.urls.single.toString(), 'ws://test/ws');
      expect(transport.current.lastSent!.type, ClientMessageType.create);
      expect(online().status, OnlineStatus.online);

      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: 0));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.lobby,
        seats: const [SeatInfo(name: 'Anna', connected: true)],
        hostSeat: 0,
      ));
      await settle();

      expect(online().roomCode, 'ABCDE');
      expect(online().mySeat, 0);
      expect(online().isHost, isTrue);
      expect(online().seats.single.name, 'Anna');
      expect(credentials.saved!.token, token);
      expect(credentials.saved!.code, 'ABCDE');
      expect(credentials.saved!.url, 'ws://test/ws');
    });

    test('rejoindre normalise le code en majuscules', () async {
      await session().join(' abcde ', 'Bob');
      expect(transport.current.lastSent!.params['code'], 'ABCDE');
      expect(transport.current.lastSent!.type, ClientMessageType.join);
    });

    test('un serveur injoignable met hors ligne et signale l\'erreur', () async {
      transport.unreachable = true;
      await session().create('Anna');
      expect(online().status, OnlineStatus.offline);
      expect(online().error, isNotNull);
    });

    test('une erreur du serveur est exposée, et redonnée à chaque fois', () async {
      await session().join('ZZZZZ', 'Bob');
      transport.current.serverSends(ServerMessage.error(ErrorCode.roomNotFound));
      await settle();
      final first = online().errorSerial;
      transport.current.serverSends(ServerMessage.error(ErrorCode.roomNotFound));
      await settle();

      expect(online().error, ErrorCode.roomNotFound);
      expect(online().errorSerial, first + 1);
    });

    test('un jeton refusé par le serveur est oublié', () async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ABCDE', token: token);
      expect(await session().tryResume(), isTrue);
      expect(transport.current.lastSent!.type, ClientMessageType.rejoin);
      transport.current.serverSends(ServerMessage.error(ErrorCode.badToken));
      await settle();
      expect(credentials.saved, isNull);
    });

    test('sans jeton gardé, tryResume ne fait rien', () async {
      expect(await session().tryResume(), isFalse);
      expect(transport.channels, isEmpty);
    });

    test('quitter prévient le serveur, oublie le jeton et vide la partie', () async {
      await joinedAndStarted(0, serverJournal());
      expect(game().isOnline, isTrue);

      await session().leave();

      expect(transport.channels.first.sent.last.type, ClientMessageType.leave);
      expect(credentials.saved, isNull);
      expect(container.read(gameProvider), isNull);
      expect(game().isOnline, isFalse);
      expect(online().inRoom, isFalse);
    });
  });

  group('partie', () {
    test('le journal du serveur ouvre la partie, sans seed, et dit à qui c\'est de jouer', () async {
      final journal = serverJournal();
      await joinedAndStarted(0, journal);

      expect(online().gameStarted, isTrue);
      expect(online().diceOff!.isResolved, isTrue);
      final engine = container.read(gameProvider)!;
      expect(engine.activeTurn, isNotNull);
      expect(game().isOnline, isTrue);

      final firstToPlaySeat = game().onlineLink!.playOrder[engine.currentPlayerIndex];
      expect(game().isMyOnlineTurn, firstToPlaySeat == 0);
    });

    test('mon siège fait de moi le joueur d\'index correspondant à l\'ordre de jeu', () async {
      await joinedAndStarted(1, serverJournal());
      final link = game().onlineLink!;
      expect(link.myEngineIndex, link.playOrder.indexOf(1));
    });

    test('mes coups partent en demandes au serveur : rien ne bouge en local', () async {
      await joinedAndStarted(0, serverJournal());
      // Je me fais passer pour le joueur courant : c'est le serveur qui refuserait.
      final before = container.read(gameProvider);

      game().roll();
      game().applyKeep(declineFivesCount: 1);
      game().startTurn(useFullHand: true);
      game().endBustedTurn();

      final sent = transport.current.sent.where((m) => m.type == ClientMessageType.play).toList();
      expect(sent.map((m) => m.params['intent']), ['roll', 'applyKeep', 'startTurn', 'endBustedTurn']);
      expect(sent[1].params['declineFivesCount'], 1);
      expect(sent[2].params['useFullHand'], true);
      expect(identical(container.read(gameProvider), before), isTrue, reason: 'l\'état ne change que sur ordre du serveur');
    });

    test('une action du serveur s\'applique avec ses faces ; les dés sont ceux du serveur', () async {
      final full = fullJournal();
      // Le journal jusqu'au premier tour, puis le premier lancer arrive en direct.
      final rollIndex = full.indexWhere((a) => a.type == GameActionType.roll);
      await joinedAndStarted(0, full.sublist(0, rollIndex));

      transport.current.serverSends(ServerMessage.action(seq: rollIndex, action: full[rollIndex]));
      await settle();

      final turn = container.read(gameProvider)!.activeTurn!;
      expect(turn.pendingRoll!.faces, full[rollIndex].faces);
      expect(game().onlineActionCount, rollIndex + 1);
    });

    test('un doublon est ignoré', () async {
      final full = fullJournal();
      final rollIndex = full.indexWhere((a) => a.type == GameActionType.roll);
      await joinedAndStarted(0, full.sublist(0, rollIndex));
      final action = ServerMessage.action(seq: rollIndex, action: full[rollIndex]);

      transport.current.serverSends(action);
      transport.current.serverSends(action);
      await settle();

      expect(game().onlineActionCount, rollIndex + 1);
    });

    test('un trou dans les actions fait repartir du journal complet du serveur', () async {
      final full = fullJournal();
      final rollIndex = full.indexWhere((a) => a.type == GameActionType.roll);
      await joinedAndStarted(0, full.sublist(0, rollIndex));
      final connections = transport.channels.length;

      transport.current.serverSends(ServerMessage.action(seq: rollIndex + 3, action: full[rollIndex]));
      await settle();

      expect(transport.channels.length, connections + 1, reason: 'reconnexion');
      expect(transport.current.sent.first.type, ClientMessageType.rejoin);
      expect(transport.current.sent.first.params['token'], token);
    });

    test('la banque se juge en local mais c\'est le serveur qui banque', () async {
      // Un tour vierge : rien n'a été lancé, banquer échoue sans rien envoyer.
      await joinedAndStarted(0, serverJournal());
      final attempt = game().bank();
      expect(attempt.success, isFalse);
      expect(transport.current.sent.where((m) => m.params['intent'] == 'bank'), isEmpty);
    });

    test('s\'arrêter sur un lancer en attente envoie la garde puis la banque', () async {
      // Régression : l'état local ne bouge qu'à la réponse du serveur, et banquer
      // sur un lancer encore en attente levait — la banque ne partait jamais.
      final full = fullJournal();
      var keepIndex = -1;
      for (var i = 0; i < full.length - 1; i++) {
        if (full[i].type == GameActionType.applyKeep && full[i + 1].type == GameActionType.bank) {
          keepIndex = i;
          break;
        }
      }
      expect(keepIndex, greaterThan(0), reason: 'le script doit banquer au moins une fois juste après une garde');

      // Le journal s'arrête sur le lancer : la décision de garde est en attente.
      await joinedAndStarted(0, full.sublist(0, keepIndex));
      expect(container.read(gameProvider)!.activeTurn!.pendingRoll, isNotNull);

      final attempt = game().stopTurn(declineFivesCount: full[keepIndex].params['declineFivesCount'] as int);

      expect(attempt.success, isTrue);
      final sent = transport.current.sent.where((m) => m.type == ClientMessageType.play).map((m) => m.params['intent']);
      expect(sent, ['applyKeep', 'bank']);
    });

    test('le journal en ligne alimente les statistiques et la courbe (rejouable sans seed)', () async {
      await joinedAndStarted(0, serverJournal());
      final record = game().gameRecord!;
      expect(record.seed, 0);
      expect(replayGame(record.setup, record.seed, record.actions).engine, isNotNull);
    });

    test('en ligne, on ne passe jamais l\'appareil', () async {
      await joinedAndStarted(0, serverJournal());
      expect(game().shouldShowPassDevice(0), isFalse);
      expect(game().shouldShowPassDevice(1), isFalse);
    });
  });

  group('une partie locale n\'est jamais touchée par la session en ligne', () {
    const local = GameSetup(playerNames: ['Local1', 'Local2']);

    /// Une partie en ligne à l'écran, puis le joueur lance une partie locale.
    Future<List<GameAction>> onlineThenLocal() async {
      final full = fullJournal();
      final rollIndex = full.indexWhere((a) => a.type == GameActionType.roll);
      await joinedAndStarted(0, full.sublist(0, rollIndex));
      game().startGame(local);
      expect(game().isOnline, isFalse);
      return full;
    }

    test('une action du serveur ne s\'applique pas à la partie locale', () async {
      final full = await onlineThenLocal();
      final rollIndex = full.indexWhere((a) => a.type == GameActionType.roll);
      final engine = container.read(gameProvider);
      final journal = game().actions.length;

      // Même rang que le journal local : sans garde, l'action serait appliquée.
      transport.current.serverSends(ServerMessage.action(seq: game().onlineActionCount, action: full[rollIndex]));
      transport.current.serverSends(ServerMessage.action(seq: rollIndex + 5, action: full[rollIndex]));
      await settle();

      expect(identical(container.read(gameProvider), engine), isTrue);
      expect(game().actions.length, journal);
      expect(game().isOnline, isFalse);
      expect(transport.channels.length, 1, reason: 'aucune resynchronisation non demandée');
    });

    test('une reconnexion ne remplace pas la partie locale par le journal du serveur', () async {
      await onlineThenLocal();
      final engine = container.read(gameProvider);

      await transport.current.serverDrops();
      await settle();
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: serverJournal()));
      await settle();

      expect(identical(container.read(gameProvider), engine), isTrue);
      expect(game().isOnline, isFalse);
      expect([for (final p in container.read(gameProvider)!.players) p.name], local.playerNames);
    });

    test('quitter le salon ne vide pas la partie locale', () async {
      await onlineThenLocal();
      final engine = container.read(gameProvider);

      await session().leave();

      expect(identical(container.read(gameProvider), engine), isTrue);
      expect(game().hasLiveLocalGame, isTrue);
    });

    test('attendre dans le salon puis être lancé par l\'hôte prend bien la place : le joueur l\'a voulu', () async {
      game().startGame(local);
      await session().join('abcde', 'Bob');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: 1));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.lobby,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: serverJournal()));
      await settle();

      expect(game().isOnline, isTrue);
    });

    test('retrouver sa partie en ligne après une partie locale, à la demande', () async {
      final full = await onlineThenLocal();
      final rollIndex = full.indexWhere((a) => a.type == GameActionType.roll);

      final reopened = session().reopenGame();
      await settle();
      expect(transport.current.sent.single.type, ClientMessageType.rejoin);
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: full.sublist(0, rollIndex + 1)));

      expect(await reopened, isTrue);
      expect(game().isOnline, isTrue);
      expect(game().onlineActionCount, rollIndex + 1);
      expect(await session().reopenGame(), isTrue, reason: 'déjà en place : rien à refaire');
    });

    test('retrouver sa partie après un rejeu, dont le journal vide l\'ancien état', () async {
      final full = fullJournal();
      await joinedAndStarted(0, serverJournal());
      game().startGameReplay(setup, _handoffOf(full), source: null);
      expect(game().isReplay, isTrue);

      final reopened = session().reopenGame();
      await settle();
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: serverJournal()));

      expect(await reopened, isTrue);
      expect(game().isOnline, isTrue);
      expect(game().originalSetup, isNotNull);
    });
  });

  group('quitter, ou se déconnecter en gardant sa place', () {
    test('se déconnecter garde le jeton, vide la partie en ligne et ne cherche pas à se reconnecter', () async {
      await joinedAndStarted(0, serverJournal());

      await session().disconnect();
      await settle();

      expect(credentials.saved!.token, token, reason: 'la place est gardée');
      expect(game().isOnline, isFalse);
      expect(online().inRoom, isFalse);
      expect(transport.channels.length, 1, reason: 'aucune reconnexion');
      expect(transport.current.sent.any((m) => m.type == ClientMessageType.leave), isFalse, reason: 'le serveur garde le siège');
    });

    test('la place gardée se retrouve avec tryResume', () async {
      await joinedAndStarted(0, serverJournal());
      await session().disconnect();

      expect(await session().tryResume(), isTrue);
      expect(transport.channels.length, 2);
      expect(transport.current.sent.single.type, ClientMessageType.rejoin);
    });

    test('une partie finie efface le jeton : il n\'y a plus rien à retrouver', () async {
      await joinedAndStarted(0, serverJournal());
      expect(credentials.saved, isNotNull);

      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.over,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      await settle();

      expect(credentials.saved, isNull);
    });
  });

  group('reconnexion', () {
    test('une coupure remet hors ligne puis rouvre avec le jeton, sans nouvelle demande de salon', () async {
      await joinedAndStarted(0, serverJournal());
      final first = transport.current;

      await first.serverDrops();
      await settle();

      expect(transport.channels.length, 2);
      expect(transport.current.sent.single.type, ClientMessageType.rejoin);
      expect(transport.current.sent.single.params['token'], token);
      expect(online().status, OnlineStatus.online);
    });

    test('un retour avec un nouveau journal repart de zéro sans doubler les actions', () async {
      final journal = serverJournal();
      await joinedAndStarted(0, journal);
      await transport.current.serverDrops();
      await settle();

      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: journal));
      await settle();

      expect(game().onlineActionCount, journal.length);
    });

    test('quitter volontairement ne déclenche aucune reconnexion', () async {
      await joinedAndStarted(0, serverJournal());
      await session().leave();
      await settle();
      expect(transport.channels.length, 1);
    });

    test('une partie finie ne cherche plus à se reconnecter', () async {
      await joinedAndStarted(0, serverJournal());
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.over,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      await settle();

      await transport.current.serverDrops();
      await settle();
      expect(transport.channels.length, 1);
    });
  });
}
