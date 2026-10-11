import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/online_providers.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_online.dart';

/// Le vrai serveur (`server/bin/server.dart`, lancé en processus) et la vraie
/// couche client (WebSocket, `OnlineSession`, `GameNotifier`) : deux joueurs
/// créent un salon, jouent des coups, et l'un d'eux revient après une coupure.
/// C'est ce qui prouve que le protocole et les deux moteurs disent la même chose.
void main() {
  late Process server;
  late int port;

  setUpAll(() async {
    final pubGet = await Process.run('dart', ['pub', 'get'], workingDirectory: 'server');
    expect(pubGet.exitCode, 0, reason: '${pubGet.stderr}');

    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    port = probe.port;
    await probe.close();

    server = await Process.start('dart', ['run', 'bin/server.dart'],
        workingDirectory: 'server',
        // Un bot de siège qui ne réfléchit pas 1,5 s par coup : le test n'attend pas.
        environment: {'PORT': '$port', 'HOST': '127.0.0.1', 'TENK_LATEST_BUILDS_URL': '', 'TENK_BOT_DELAY_MS': '50'});
    final ready = Completer<void>();
    server.stdout.transform(utf8.decoder).listen((line) {
      if (line.contains('à l\'écoute') && !ready.isCompleted) ready.complete();
    });
    unawaited(server.stderr.drain<void>());
    await ready.future.timeout(const Duration(seconds: 60), onTimeout: () => throw StateError('le serveur n\'a pas démarré'));
  });

  tearDownAll(() => server.kill());

  ProviderContainer newClient(FakeCredentialsStore credentials) {
    final container = ProviderContainer(overrides: [
      onlineServerUrlProvider.overrideWithValue('ws://127.0.0.1:$port/ws'),
      onlineCredentialsStoreProvider.overrideWithValue(credentials),
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<void> until(bool Function() condition, String what) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) throw TimeoutException('attendu : $what');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Le coup simple et toujours légal du joueur qui a la main.
  void playOneMove(GameNotifier game) {
    final turn = game.state!.activeTurn;
    if (turn == null) {
      game.startTurn(useFullHand: true);
    } else if (turn.busted) {
      game.endBustedTurn();
    } else if (turn.pendingRoll != null) {
      final analysis = turn.pendingRoll!;
      final fives = analysis.declinableFives?.diceCount ?? 0;
      game.applyKeep(declineFivesCount: fives - minKeepableFives(analysis));
    } else if (!game.bank().success) {
      game.roll();
    }
  }

  test('deux joueurs jouent ensemble sur le vrai serveur, l\'un se coupe et revient', () async {
    final anna = newClient(FakeCredentialsStore());
    final bobCredentials = FakeCredentialsStore();
    final bob = newClient(bobCredentials);

    // Le salon.
    await anna.read(onlineSessionProvider.notifier).create('Anna');
    await until(() => anna.read(onlineSessionProvider).phase == RoomPhase.lobby, 'salon créé');
    final code = anna.read(onlineSessionProvider).roomCode!;
    await bob.read(onlineSessionProvider.notifier).join(code, 'Bob');
    await until(() => anna.read(onlineSessionProvider).seats.length == 2, 'Bob dans le salon');
    // Anna peut apprendre l'arrivée de Bob avant que Bob ne reçoive son siège :
    // deux connexions, deux rythmes (la suite pleine charge le montre).
    await until(() => bob.read(onlineSessionProvider).mySeat != null, 'siège reçu par Bob');
    expect(bob.read(onlineSessionProvider).mySeat, 1);

    // Le départ.
    anna.read(onlineSessionProvider.notifier).start();
    await until(
      () => anna.read(onlineSessionProvider).gameStarted && bob.read(onlineSessionProvider).gameStarted,
      'partie commencée chez les deux',
    );
    expect(anna.read(onlineSessionProvider).diceOff!.isResolved, isTrue);
    expect(bob.read(gameProvider.notifier).onlineLink!.playOrder, anna.read(gameProvider.notifier).onlineLink!.playOrder);

    // Des coups : chacun joue quand c'est à lui, l'autre voit les mêmes dés.
    final clients = [anna, bob];
    for (var move = 0; move < 40 && !(anna.read(gameProvider)?.gameOver ?? false); move++) {
      final mover = clients.firstWhere((c) => c.read(gameProvider.notifier).isMyOnlineTurn);
      final before = mover.read(gameProvider.notifier).onlineActionCount;
      playOneMove(mover.read(gameProvider.notifier));
      await until(
        () => clients.every((c) => c.read(gameProvider.notifier).onlineActionCount > before),
        'coup ${move + 1} reçu par les deux',
      );
      // Un joueur ne lance pas vingt fois par seconde : sans cette pause le test
      // dépasserait le débit toléré par connexion (et le serveur aurait raison).
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final a = anna.read(gameProvider)!;
      final b = bob.read(gameProvider)!;
      expect(a.currentPlayerIndex, b.currentPlayerIndex, reason: 'coup ${move + 1}');
      expect([for (final p in a.players) p.totalScore], [for (final p in b.players) p.totalScore]);
      expect(a.activeTurn?.pendingRoll?.faces, b.activeTurn?.pendingRoll?.faces, reason: 'mêmes dés');
    }
    expect(anna.read(gameProvider.notifier).onlineActionCount, bob.read(gameProvider.notifier).onlineActionCount);

    // Bob revient avec son jeton, depuis un client tout neuf.
    final bobBack = newClient(bobCredentials);
    expect(await bobBack.read(onlineSessionProvider.notifier).tryResume(), isTrue);
    await until(() => bobBack.read(onlineSessionProvider).gameStarted, 'journal renvoyé à Bob');
    await until(
      () => bobBack.read(gameProvider.notifier).onlineActionCount == anna.read(gameProvider.notifier).onlineActionCount,
      'Bob a rattrapé la partie',
    );
    expect(bobBack.read(onlineSessionProvider).mySeat, 1);
    expect(
      [for (final p in bobBack.read(gameProvider)!.players) p.totalScore],
      [for (final p in anna.read(gameProvider)!.players) p.totalScore],
    );
  }, timeout: const Timeout(Duration(seconds: 120)));

  test('seul le premier joueur lance la partie ; un joueur qui part est remplacé par un bot qui joue ses tours', () async {
    final anna = newClient(FakeCredentialsStore());
    final bob = newClient(FakeCredentialsStore());
    await anna.read(onlineSessionProvider.notifier).create('Anna');
    await until(() => anna.read(onlineSessionProvider).phase == RoomPhase.lobby, 'salon créé');
    await bob.read(onlineSessionProvider.notifier).join(anna.read(onlineSessionProvider).roomCode!, 'Bob');
    await until(() => bob.read(onlineSessionProvider).mySeat != null, 'siège reçu par Bob');
    anna.read(onlineSessionProvider.notifier).start();
    await until(
      () => anna.read(onlineSessionProvider).gameStarted && bob.read(onlineSessionProvider).gameStarted,
      'partie commencée chez les deux',
    );
    expect(anna.read(onlineSessionProvider).startSignalEnabled, isTrue);
    expect(anna.read(onlineSessionProvider).begun, isFalse);

    // Le signal de départ, du premier joueur seulement.
    final clients = [anna, bob];
    final starter = clients.firstWhere((c) => c.read(gameProvider.notifier).isMyOnlineTurn);
    final other = clients.firstWhere((c) => c != starter);
    starter.read(onlineSessionProvider.notifier).begin();
    await until(() => other.read(onlineSessionProvider).begun, 'départ annoncé à l\'autre joueur');

    // Bob part pour de bon : un bot du serveur reprend son siège.
    await bob.read(onlineSessionProvider.notifier).leaveGame();
    await until(() => anna.read(onlineSessionProvider).seats[1].bot, 'siège de Bob repris par un bot');
    final game = anna.read(gameProvider.notifier);
    final bobIndex = game.onlineLink!.playOrder.indexOf(1);
    expect(game.isOnlineBot(bobIndex), isTrue);

    // Anna joue ses tours ; le bot joue les siens, jusqu'à un tour complet de
    // bot (il a eu la main, puis l'a rendue).
    var botPlayed = false;
    for (var step = 0; step < 200 && !(anna.read(gameProvider)?.gameOver ?? false); step++) {
      final engine = anna.read(gameProvider)!;
      if (engine.currentPlayerIndex == bobIndex) {
        final before = game.onlineActionCount;
        await until(() => game.onlineActionCount > before, 'un coup du bot');
        botPlayed = true;
        continue;
      }
      if (botPlayed) break; // la main est revenue à Anna après le tour du bot
      final before = game.onlineActionCount;
      playOneMove(game);
      await until(() => game.onlineActionCount > before, 'coup d\'Anna reçu');
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    expect(botPlayed, isTrue);
    // Le journal reçu se rejoue à l'identique : le bot a joué des coups légaux.
    final replayed = replayGame(GameSetup(playerNames: game.originalSetup!.playerNames), 0, game.actions).engine!;
    expect([for (final p in replayed.players) p.totalScore], [for (final p in anna.read(gameProvider)!.players) p.totalScore]);
  }, timeout: const Timeout(Duration(seconds: 120)));

  test('l\'hôte dont l\'app a été tuée revient par le code : il reprend sa place, pas un « Anna 2 »', () async {
    final annaCredentials = FakeCredentialsStore();
    final anna = newClient(annaCredentials);
    final bob = newClient(FakeCredentialsStore());

    await anna.read(onlineSessionProvider.notifier).create('Anna');
    await until(() => anna.read(onlineSessionProvider).phase == RoomPhase.lobby, 'salon créé');
    final code = anna.read(onlineSessionProvider).roomCode!;
    await bob.read(onlineSessionProvider.notifier).join(code, 'Bob');
    await until(() => bob.read(onlineSessionProvider).seats.length == 2, 'Bob dans le salon');

    // L'app d'Anna est tuée : une app toute neuve, avec ce qu'elle avait gardé sur le disque.
    anna.dispose();
    final annaAgain = newClient(annaCredentials);
    await annaAgain.read(onlineSessionProvider.notifier).join(code, 'Anna');
    await until(() => annaAgain.read(onlineSessionProvider).seats.isNotEmpty, 'Anna de retour dans le salon');

    expect(annaAgain.read(onlineSessionProvider).mySeat, 0);
    expect(annaAgain.read(onlineSessionProvider).isHost, isTrue);
    expect(annaAgain.read(onlineSessionProvider).seats.map((s) => s.name), ['Anna', 'Bob']);
    await until(() => bob.read(onlineSessionProvider).seats.every((s) => s.connected), 'Bob voit Anna reconnectée');
    expect(bob.read(onlineSessionProvider).seats.map((s) => s.name), ['Anna', 'Bob']);
  });

  test('une émotion d\'Anna arrive chez Bob, et chez elle, avec son siège', () async {
    final anna = newClient(FakeCredentialsStore());
    final bob = newClient(FakeCredentialsStore());
    await anna.read(onlineSessionProvider.notifier).create('Anna');
    await until(() => anna.read(onlineSessionProvider).phase == RoomPhase.lobby, 'salon créé');
    final code = anna.read(onlineSessionProvider).roomCode!;
    await bob.read(onlineSessionProvider.notifier).join(code, 'Bob');
    await until(() => anna.read(onlineSessionProvider).seats.length == 2, 'Bob dans le salon');
    anna.read(onlineSessionProvider.notifier).start();
    await until(
      () => anna.read(onlineSessionProvider).gameStarted && bob.read(onlineSessionProvider).gameStarted,
      'partie commencée chez les deux',
    );
    expect(anna.read(onlineSessionProvider).emotesEnabled, isTrue, reason: 'le serveur annonce les émotions');

    anna.read(onlineSessionProvider.notifier).sendEmote(Emote.joyful, phrase: 'hello');
    await until(
      () => bob.read(onlineEmotesProvider).isNotEmpty && anna.read(onlineEmotesProvider).isNotEmpty,
      'émotion relayée aux deux',
    );

    for (final client in [anna, bob]) {
      final event = client.read(onlineEmotesProvider).single;
      expect((event.seat, event.emote, event.phrase), (0, Emote.joyful, 'hello'));
    }
  });

  test('un client qui essaie de jouer hors tour ne change rien pour personne', () async {
    final anna = newClient(FakeCredentialsStore());
    final bob = newClient(FakeCredentialsStore());
    await anna.read(onlineSessionProvider.notifier).create('Anna');
    await until(() => anna.read(onlineSessionProvider).phase == RoomPhase.lobby, 'salon');
    await bob.read(onlineSessionProvider.notifier).join(anna.read(onlineSessionProvider).roomCode!, 'Bob');
    await until(() => anna.read(onlineSessionProvider).seats.length == 2, 'Bob');
    anna.read(onlineSessionProvider.notifier).start();
    await until(() => anna.read(onlineSessionProvider).gameStarted && bob.read(onlineSessionProvider).gameStarted, 'départ');

    final waiting = [anna, bob].firstWhere((c) => !c.read(gameProvider.notifier).isMyOnlineTurn);
    final before = waiting.read(gameProvider.notifier).onlineActionCount;
    // Il envoie l'ordre de lancer à la main, comme un client modifié le ferait.
    waiting.read(onlineSessionProvider.notifier).play(GameActionType.roll, const {});
    await until(() => waiting.read(onlineSessionProvider).error == ErrorCode.notYourTurn, 'refus du serveur');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(waiting.read(gameProvider.notifier).onlineActionCount, before);
    expect([anna, bob].every((c) => c.read(gameProvider.notifier).onlineActionCount == before), isTrue);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
