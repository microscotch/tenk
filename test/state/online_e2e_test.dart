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
        workingDirectory: 'server', environment: {'PORT': '$port', 'HOST': '127.0.0.1'});
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
