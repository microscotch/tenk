import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';

import '../test_helpers/scripted_game.dart';

/// Laisse la chaîne de persistances fire-and-forget de GameNotifier
/// s'exécuter avant d'inspecter le disque : de vraies E/S dart:io prennent
/// plus qu'un simple tour de microtâches (`Duration.zero` ne suffit pas), et
/// un scénario qui déclenche beaucoup d'écritures chaînées (partie complète)
/// a besoin d'une marge plus généreuse qu'une seule transition.
Future<void> _flushMicrotasks({Duration duration = const Duration(milliseconds: 50)}) =>
    Future<void>.delayed(duration);

/// Sonde [condition] toutes les 20ms jusqu'à ce qu'elle soit vraie ou que
/// [timeout] soit écoulé ; renvoie le résultat final de [condition].
Future<bool> _waitUntil(Future<bool> Function() condition, {required Duration timeout}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  return condition();
}

void main() {
  late Directory tempDir;
  late Directory archiveTempDir;
  late GameSaveStore store;
  late GameSaveStore archiveStore;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tenk_game_providers_test_');
    archiveTempDir = await Directory.systemTemp.createTemp('tenk_game_providers_test_over_');
    store = GameSaveStore(rootDirectory: () async => tempDir);
    archiveStore = GameSaveStore(rootDirectory: () async => archiveTempDir);
    container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(store),
      archivedGameSaveStoreProvider.overrideWithValue(archiveStore),
    ]);
  });

  tearDown(() async {
    container.dispose();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    if (await archiveTempDir.exists()) await archiveTempDir.delete(recursive: true);
  });

  test('startGame avec un handoff persiste un fichier .run identifié par la seed', () async {
    final notifier = container.read(gameProvider.notifier);
    const setup = GameSetup(playerNames: ['A', 'B']);
    final handoff = GameRecordingHandoff(
      seed: 999,
      random: Random(999),
      originalSetup: setup,
      alias: 'Test Alias',
      createdAt: DateTime(2026, 1, 1),
      actions: const [],
    );

    notifier.startGame(setup, handoff: handoff);
    await _flushMicrotasks();

    expect(await store.exists(999), isTrue);
    final saved = await store.read(999);
    expect(saved!.alias, 'Test Alias');
    expect(saved.actions, hasLength(1)); // le startTurn initial
    expect(saved.setup.playerNames, ['A', 'B']); // config D'ORIGINE, pas réordonnée
  });

  test('startGame sans handoff (debugLoadState-style) ne persiste rien : pas de seed', () async {
    final notifier = container.read(gameProvider.notifier);
    notifier.startGame(const GameSetup(playerNames: ['A', 'B']));
    await _flushMicrotasks();

    expect(await store.list(), isEmpty);
  });

  test('une partie jouée jusqu\'à sa fin supprime le fichier de sauvegarde', () async {
    const seed = 20260901;
    // La règle qui refuse de banquer trop près de 10000 (voir
    // turn_state.dart, wouldMakeWinningImpossible) force davantage de
    // relances près de la cible, donc davantage de tours/écritures qu'avant
    // pour converger avec cette stratégie naïve "toujours banquer dès que
    // possible" : marge généreuse (guard + timeouts) pour absorber ça.
    // 2 joueurs plutôt que 3 : converge nettement plus vite vers une fin de
    // partie avec cette stratégie "jamais décliner, banquer dès que possible"
    // (moins de cycles de collision/barrage entre joueurs), ce qui limite le
    // nombre d'écritures réelles chaînées à attendre ci-dessous.
    const setup = GameSetup(playerNames: ['A', 'B']);
    final notifier = container.read(gameProvider.notifier);

    notifier.startGame(
      setup,
      handoff: GameRecordingHandoff(
        seed: seed,
        random: Random(seed),
        originalSetup: setup,
        alias: 'Fin de partie',
        createdAt: DateTime(2026, 1, 1),
        actions: const [],
      ),
    );
    await _flushMicrotasks();
    expect(await store.exists(seed), isTrue);

    // Même stratégie simple et toujours légale que dans
    // game_recording_test.dart : ne jamais décliner de 5, repartir à main
    // pleine, banquer dès que possible — jusqu'à la fin de partie.
    var guard = 0;
    while (!container.read(gameProvider)!.gameOver) {
      guard++;
      assert(guard < 20000);
      final engine = container.read(gameProvider)!;
      final turn = engine.activeTurn;
      if (turn == null) {
        notifier.startTurn(useFullHand: true);
      } else if (turn.busted) {
        notifier.endBustedTurn();
      } else if (turn.pendingRoll != null) {
        notifier.applyKeep();
      } else if (!turn.mustContinue && notifier.bank().success) {
        // bank() déjà appliqué par cet appel.
      } else {
        notifier.roll();
      }
    }
    // Une partie complète chaîne beaucoup d'écritures (une par transition) :
    // marge plus généreuse qu'une seule persistance pour les laisser toutes
    // s'exécuter dans l'ordre avant de vérifier l'état final sur disque.
    // Cette partie scriptée enchaîne des centaines de transitions sans
    // jamais attendre entre elles (contrairement à une vraie partie, où les
    // délais IA/auto espacent naturellement les écritures) : la chaîne de
    // persistance peut donc avoir des centaines d'écritures réelles encore à
    // vider. On sonde au lieu d'un délai fixe, pour rester rapide dans le
    // cas courant sans être fragile sur une machine plus lente.
    final removedFromInProgress =
        await _waitUntil(() async => !await store.exists(seed), timeout: const Duration(seconds: 90));
    expect(removedFromInProgress, isTrue, reason: 'une partie terminée n\'est plus "en pause"');

    final archived = await _waitUntil(() async => await archiveStore.exists(seed), timeout: const Duration(seconds: 5));
    expect(archived, isTrue, reason: 'elle doit être archivée dans over/, pas juste effacée');
    final savedInArchive = await archiveStore.read(seed);
    expect(savedInArchive!.actions.length, greaterThanOrEqualTo(guard));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('resumeFromSave reconstruit l\'état exact et permet de continuer sans planter', () async {
    final saved = buildResumableSavedGame(seed: 42, alias: 'Test', playerNames: const ['A', 'B']);
    final notifier = container.read(gameProvider.notifier);

    notifier.resumeFromSave(saved);

    final engine = container.read(gameProvider);
    expect(engine, isNotNull);
    expect(engine!.gameOver, isFalse);
    expect(engine.activeTurn, isNotNull);
    expect(engine.activeTurn!.pendingRoll, isNotNull, reason: 'un lancer avait été fait avant la sauvegarde');

    // Continuer à jouer après reprise ne doit pas planter (le générateur
    // repris doit être dans un état cohérent pour le moteur).
    notifier.applyKeep();
    await _flushMicrotasks();

    expect(await store.exists(42), isTrue);
  });
}
