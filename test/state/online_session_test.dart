import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/online/protocol.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_providers.dart';
import 'package:le10000/state/player_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:le10000/state/online_providers.dart';
import 'package:le10000/state/online_transport.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/my_profile.dart';
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
  late FakeGameSaveStore inProgress;
  late FakeGameSaveStore archive;
  late FakePlayerStore players;
  late ProviderContainer container;

  ProviderContainer newContainer() {
    final c = ProviderContainer(overrides: [
      onlineTransportProvider.overrideWithValue(transport),
      onlineCredentialsStoreProvider.overrideWithValue(credentials),
      onlineServerUrlProvider.overrideWithValue('ws://test/ws'),
      onlineReconnectDelayProvider.overrideWithValue((_) => const Duration(milliseconds: 5)),
      gameSaveStoreProvider.overrideWithValue(inProgress),
      archivedGameSaveStoreProvider.overrideWithValue(archive),
      playerStoreProvider.overrideWithValue(players),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    transport = FakeTransport();
    credentials = FakeCredentialsStore();
    inProgress = FakeGameSaveStore();
    archive = FakeGameSaveStore();
    players = FakePlayerStore();
    SharedPreferences.setMockInitialValues({});
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

    test('rejoindre un salon où j\'ai déjà une place la reprend avec mon jeton, sans en prendre une seconde', () async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ABCDE', token: token);

      await session().join('abcde', 'Anna');

      expect(transport.current.lastSent!.type, ClientMessageType.rejoin);
      expect(transport.current.lastSent!.params['token'], token);
    });

    test('si cette place n\'existe plus, on entre normalement, sans afficher d\'erreur', () async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ABCDE', token: token);
      await session().join('abcde', 'Anna');
      final errors = online().errorSerial;

      transport.current.serverSends(ServerMessage.error(ErrorCode.badToken));
      await settle();

      expect(transport.current.lastSent!.type, ClientMessageType.join);
      expect(transport.current.lastSent!.params['code'], 'ABCDE');
      expect(transport.current.lastSent!.params['name'], 'Anna');
      expect(online().errorSerial, errors);
      expect(credentials.saved, isNull);
    });

    test('un jeton gardé pour un autre salon, ou un autre serveur, ne change rien', () async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ZZZZZ', token: token);
      await session().join('abcde', 'Anna');
      expect(transport.current.lastSent!.type, ClientMessageType.join);

      credentials.saved = const OnlineCredentials(url: 'wss://autre/ws', code: 'ABCDE', token: token);
      await session().join('abcde', 'Anna');
      expect(transport.current.lastSent!.type, ClientMessageType.join);
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
      expect(record.isOnline, isTrue);
      expect(replayGame(record.setup, 0, record.actions).engine, isNotNull);
      expect(replayGame(record.setup, record.seed, record.actions).engine, isNotNull,
          reason: 'la « seed » d\'un run en ligne n\'est qu\'un identifiant : elle ne change aucun dé');
    });

    test('en ligne, on ne passe jamais l\'appareil', () async {
      await joinedAndStarted(0, serverJournal());
      expect(game().shouldShowPassDevice(0), isFalse);
      expect(game().shouldShowPassDevice(1), isFalse);
    });
  });

  group('archivage d\'une partie en ligne terminée', () {
    /// La partie jouée jusqu'à son avant-dernière action, la dernière arrivant
    /// en direct du serveur.
    Future<List<GameAction>> playUntilLastAction(int seat) async {
      final full = fullJournal();
      await joinedAndStarted(seat, full.sublist(0, full.length - 1));
      expect(container.read(gameProvider)!.gameOver, isFalse);
      return full;
    }

    test('le dernier coup archive la partie, une seule fois, sans rien laisser en cours', () async {
      final full = await playUntilLastAction(1);
      expect(await archive.list(), isEmpty, reason: 'rien n\'est écrit avant la fin');

      transport.current.serverSends(ServerMessage.action(seq: full.length - 1, action: full.last));
      await settle();

      expect(container.read(gameProvider)!.gameOver, isTrue);
      final archived = (await archive.list()).single;
      expect(archived.isOnline, isTrue);
      expect(archived.onlineSeat, 1);
      expect(archived.setup.playerNames, names);
      expect(archived.actions, hasLength(full.length));
      expect(archived.alias, isNotEmpty);
      expect(archived.createdAt, full.first.at);
      expect(await inProgress.list(), isEmpty, reason: 'une partie en ligne n\'est jamais « en pause » sur l\'appareil');
    });

    test('le journal complet renvoyé ensuite par le serveur réécrit le même run, sans doublon', () async {
      final full = await playUntilLastAction(0);
      transport.current.serverSends(ServerMessage.action(seq: full.length - 1, action: full.last));
      await settle();
      final first = (await archive.list()).single;

      await transport.current.serverDrops();
      await settle();
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: full));
      await settle();

      final after = await archive.list();
      expect(after, hasLength(1));
      expect(after.single.seed, first.seed);
      expect(after.single.actions, hasLength(full.length));
    });

    test('une partie dont la fin n\'arrive qu\'avec le journal complet est archivée aussi', () async {
      await joinedAndStarted(0, fullJournal());

      expect(container.read(gameProvider)!.gameOver, isTrue);
      expect((await archive.list()).single.onlineSeat, 0);
    });

    test('quitter aussitôt la partie finie archive quand même tout le journal', () async {
      final full = await playUntilLastAction(0);

      // Le coup final, puis la sortie dans la foulée : l'écriture est encore en
      // attente quand le journal et la config sont vidés.
      game().applyOnlineAction(full.last);
      game().endOnlineGame();
      await settle();

      expect((await archive.list()).single.actions, hasLength(full.length));
    });

    test('le run archivé se rejoue jusqu\'au même classement final', () async {
      final full = await playUntilLastAction(0);
      transport.current.serverSends(ServerMessage.action(seq: full.length - 1, action: full.last));
      await settle();
      final played = container.read(gameProvider)!;
      final archived = (await archive.list()).single;

      game().startReplay(archived);
      expect(game().replayProgress.count, greaterThan(1), reason: 'le curseur de tours est disponible');
      while (game().hasNextReplayAction) {
        game().applyNextReplayAction();
      }

      final replayed = container.read(gameProvider)!;
      expect(replayed.gameOver, isTrue);
      expect(replayed.winnerIndex, played.winnerIndex);
      expect([for (final p in replayed.players) p.totalScore], [for (final p in played.players) p.totalScore]);
    });
  });

  group('sélection de 5 en cours', () {
    /// Un journal arrêté sur un lancer où garder plus ou moins de 5 est un vrai
    /// choix, et le siège du joueur qui a la main.
    (List<GameAction>, int seat) atFivesChoice() {
      for (var seed = 1; seed < 100; seed++) {
        final full = fullJournal(seed: seed);
        for (var end = 1; end <= full.length; end++) {
          if (full[end - 1].type != GameActionType.roll) continue;
          final replay = replayGame(setup, 0, full.sublist(0, end));
          final engine = replay.engine!;
          final turn = engine.activeTurn;
          final analysis = turn?.pendingRoll;
          if (turn == null || analysis == null || turn.busted) continue;
          if (maxKeepableFives(turn, analysis, currentTotal: engine.currentPlayer.totalScore) > minKeepableFives(analysis)) {
            return (full.sublist(0, end), replay.playOrder![engine.currentPlayerIndex]);
          }
        }
      }
      throw StateError('aucun choix de 5 trouvé');
    }

    test('celle de l\'autre joueur est retenue si elle date du lancer à l\'écran, ignorée sinon', () async {
      final (journal, current) = atFivesChoice();
      await joinedAndStarted(1 - current, journal);

      transport.current.serverSends(ServerMessage.selection(seq: journal.length - 1, declineFivesCount: 1));
      await settle();
      expect(container.read(onlineKeepSelectionProvider), isNull, reason: 'un lancer passé');

      transport.current.serverSends(ServerMessage.selection(seq: journal.length, declineFivesCount: 1));
      await settle();
      expect(container.read(onlineKeepSelectionProvider), (seq: journal.length, declineFivesCount: 1));
    });

    test('à mon tour, ma sélection part au serveur ; hors de mon tour, rien', () async {
      final (journal, current) = atFivesChoice();
      await joinedAndStarted(current, journal);
      game().shareKeepSelection(1);
      expect(transport.current.lastSent!.type, ClientMessageType.select);
      expect(transport.current.lastSent!.params['declineFivesCount'], 1);

      // Le même lancer, vu par l'autre joueur : ce n'est pas son tour.
      transport = FakeTransport();
      container = newContainer();
      await joinedAndStarted(1 - current, journal);
      final sent = transport.current.sent.length;
      game().shareKeepSelection(1);
      expect(transport.current.sent, hasLength(sent));
    });

    test('un serveur d\'avant, qui n\'annonce pas la fonction, ne reçoit jamais de sélection', () async {
      final (journal, current) = atFivesChoice();
      await session().join('abcde', names[current]);
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: current, features: const []));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: journal));
      await settle();

      game().shareKeepSelection(1);

      expect(transport.current.sent.where((m) => m.type == ClientMessageType.select), isEmpty);
    });

    test('un message d\'un type inconnu (serveur plus récent) est ignoré, sans tout redemander', () async {
      await joinedAndStarted(0, serverJournal());
      final connections = transport.channels.length;

      transport.current.serverSendsRaw({'v': onlineProtocolVersion, 'type': 'plusTard', 'params': {}});
      await settle();

      expect(transport.channels, hasLength(connections));
      expect(game().isOnline, isTrue);
    });

    test('un nouveau journal efface une sélection d\'avant', () async {
      final (journal, current) = atFivesChoice();
      await joinedAndStarted(1 - current, journal);
      transport.current.serverSends(ServerMessage.selection(seq: journal.length, declineFivesCount: 1));
      await settle();

      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: journal));
      await settle();

      expect(container.read(onlineKeepSelectionProvider), isNull);
    });
  });

  group('émotions', () {
    test('le serveur qui les relaie les active ; envoyer part au serveur', () async {
      await joinedAndStarted(0, serverJournal());
      expect(online().emotesEnabled, isTrue);

      session().sendEmote(Emote.mocking, phrase: 'stickyFive');

      final sent = transport.current.lastSent!;
      expect((sent.type, sent.params['emote'], sent.params['phrase']), (ClientMessageType.emote, 'mocking', 'stickyFive'));
    });

    test('un serveur d\'avant ne les relaie pas : rien n\'est envoyé', () async {
      await session().join('abcde', names[0]);
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: token, seat: 0, features: const []));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: serverJournal()));
      await settle();
      expect(online().emotesEnabled, isFalse);
      final count = transport.current.sent.length;

      session().sendEmote(Emote.joyful);

      expect(transport.current.sent, hasLength(count));
    });

    test('une émotion reçue est retenue, avec le siège de qui l\'envoie', () async {
      await joinedAndStarted(0, serverJournal());

      transport.current.serverSends(ServerMessage.emote(seat: 1, emote: Emote.devastated, phrase: 'argh'));
      await settle();

      final event = container.read(onlineEmotesProvider).single;
      expect((event.seat, event.emote, event.phrase), (1, Emote.devastated, 'argh'));
    });

    test('une émotion illisible (version plus récente) est ignorée, sans tout redemander', () async {
      await joinedAndStarted(0, serverJournal());
      final connections = transport.channels.length;

      transport.current.serverSendsRaw({'v': onlineProtocolVersion, 'type': 'emote', 'params': {'seat': 1, 'emote': 'furieux'}});
      await settle();

      expect(container.read(onlineEmotesProvider), isEmpty);
      expect(transport.channels, hasLength(connections));
    });

    test('elles restent après une reconnexion, mais pas d\'une partie à l\'autre', () async {
      await joinedAndStarted(0, serverJournal());
      transport.current.serverSends(ServerMessage.emote(seat: 1, emote: Emote.joyful));
      await settle();

      // Même partie, après une coupure : le journal revient, les émotions restent.
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: serverJournal()));
      await settle();
      expect(container.read(onlineEmotesProvider), hasLength(1));

      await session().leave();
      expect(container.read(onlineEmotesProvider), isEmpty);
    });
  });

  group('mon profil dans une partie en ligne', () {
    late PlayerProfile me;

    /// Mon profil (gaucher, surnommé), puis une session neuve qui le relit.
    Future<void> withMyProfile() async {
      me = PlayerProfile.create(name: 'Bob', nickname: 'Bobby', rightHanded: false);
      await seedMyProfile(players, me);
      container = newContainer();
      // Comme au lancement : la garde attend réglages et fiches relus.
      expect(await isMyProfileMissing(container), isFalse);
      await container.read(playersProvider.future);
    }

    test('ma fiche est rattachée à mon siège, jusque dans l\'archive', () async {
      await withMyProfile();
      final full = fullJournal();
      await joinedAndStarted(1, full);

      expect(game().originalSetup!.playerIdAt(1), me.id);
      expect(game().originalSetup!.playerIdAt(0), isNull, reason: 'l\'adversaire n\'est lié à aucune fiche');
      expect((await archive.list()).single.setup.playerIdAt(1), me.id);
    });

    test('à mon tour, les commandes suivent ma main', () async {
      await withMyProfile();
      await joinedAndStarted(1, serverJournal());
      final link = game().onlineLink!;
      final mine = container.read(gameProvider)!.currentPlayerIndex == link.myEngineIndex;

      // Ancien réglage d'appareil : droitier. Mon profil : gaucher. L'adversaire
      // n'a pas de fiche : il retombe sur le réglage par défaut, qui est le mien.
      expect(container.read(currentSeatRightHandedProvider), isFalse, reason: mine ? 'mon tour' : 'repli sur mon profil');
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

    test('une reconnexion automatique qui échoue ne s\'affiche pas en erreur, tentative après tentative', () async {
      await joinedAndStarted(0, serverJournal());
      final errors = online().errorSerial;
      transport.unreachable = true;

      await transport.current.serverDrops();
      await settle();
      await settle();

      expect(online().status, OnlineStatus.offline);
      expect(online().errorSerial, errors, reason: 'un « Serveur injoignable » par tentative s\'empilait à l\'écran');
    });

    test('en arrière-plan, aucune tentative ; au retour, reconnexion immédiate', () async {
      await joinedAndStarted(0, serverJournal());
      final connections = transport.channels.length;

      session().appPaused();
      await transport.current.serverDrops();
      await settle();
      await settle();
      expect(transport.channels, hasLength(connections), reason: 'le réseau est souvent coupé en arrière-plan');

      session().appResumed();
      await settle();
      expect(transport.channels, hasLength(connections + 1));
      expect(transport.current.sent.single.type, ClientMessageType.rejoin);
    });

    test('revenir au premier plan sans coupure ne rouvre rien', () async {
      await joinedAndStarted(0, serverJournal());
      final connections = transport.channels.length;

      session().appPaused();
      session().appResumed();
      await settle();

      expect(transport.channels, hasLength(connections));
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
