import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/dice_off.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/widgets/paused_games_list.dart';

/// Implémentation en mémoire de [GameSaveStore], sans aucune E/S disque
/// réelle : `flutter_test` (`testWidgets`) ne résout pas de façon fiable de
/// vraies opérations `dart:io` pendant les cycles de pompage — un souci
/// d'environnement de test, pas du code applicatif (déjà couvert contre de
/// vrais fichiers dans `test/state/game_save_store_test.dart`, hors
/// `testWidgets`). N'implémente que l'interface publique de [GameSaveStore].
class _FakeGameSaveStore implements GameSaveStore {
  final Map<int, SavedGame> _games = {};

  @override
  Future<Directory> Function() get rootDirectory => () => throw UnimplementedError();

  @override
  Future<bool> exists(int seed) async => _games.containsKey(seed);

  @override
  Future<List<SavedGame>> list() async => _games.values.toList();

  @override
  Future<SavedGame?> read(int seed) async => _games[seed];

  @override
  Future<void> write(SavedGame game) async => _games[game.seed] = game;

  @override
  Future<void> delete(int seed) async => _games.remove(seed);
}

/// Un journal d'actions réel (départage résolu + un tour entamé) pour une
/// sauvegarde authentiquement reprenable, plutôt qu'un simple objet vide.
SavedGame _buildValidSavedGame({required int seed, required String alias, required List<String> playerNames}) {
  final random = Random(seed);
  final actions = <GameAction>[];
  var diceOff = DiceOffState.start(playerNames.length);
  while (!diceOff.isResolved) {
    final idx = diceOff.nextToRoll;
    if (idx != null) {
      diceOff = diceOff.rollFor(idx, random: random);
      actions.add(GameAction.diceOffRoll(idx));
    } else {
      diceOff = diceOff.resolveRound();
      actions.add(GameAction.diceOffResolveRound());
    }
  }
  final setup = GameSetup(playerNames: playerNames);
  final rotated = setup.rotated(diceOff.winnerIndex!);
  var engine = GameEngine.newGame(rotated.playerNames).startTurn();
  actions.add(GameAction.startTurn(useFullHand: false));
  engine = engine.roll(random: random);
  actions.add(GameAction.roll());

  return SavedGame(seed: seed, setup: setup, alias: alias, createdAt: DateTime(2026, 1, 1), actions: actions);
}

void main() {
  late _FakeGameSaveStore store;

  setUp(() {
    store = _FakeGameSaveStore();
  });

  // Enveloppé dans un SingleChildScrollView comme en production
  // (SetupScreen) : PausedGamesList seul dans un Scaffold.body déborderait
  // verticalement dès que le contenu dépasse la hauteur de l'écran.
  Widget wrap(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: PausedGamesList())),
      ),
    );
  }

  testWidgets('affiche l\'alias et les avatars des joueurs de chaque partie en pause', (tester) async {
    await store.write(_buildValidSavedGame(seed: 1, alias: 'Facétieux Croupier', playerNames: ['Marie Curie', 'Bob']));

    final container = ProviderContainer(overrides: [gameSaveStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Facétieux Croupier'), findsOneWidget);
    expect(find.text('MC'), findsOneWidget); // initiales de "Marie Curie"
    expect(find.text('BB'), findsOneWidget); // initiales de "Bob"
  });

  testWidgets('aucune partie en pause : message discret plutôt qu\'une zone vide', (tester) async {
    final container = ProviderContainer(overrides: [gameSaveStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Aucune partie en pause pour l\'instant.'), findsOneWidget);
  });

  testWidgets('tap sur une partie la reprend et ouvre GameScreen', (tester) async {
    await store.write(_buildValidSavedGame(seed: 2, alias: 'Dé Chanceux', playerNames: ['A', 'B']));

    final container = ProviderContainer(overrides: [gameSaveStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dé Chanceux'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('swipe sans confirmation activée supprime directement la partie', (tester) async {
    await store.write(_buildValidSavedGame(seed: 3, alias: 'À Supprimer', playerNames: ['A', 'B']));

    final container = ProviderContainer(overrides: [gameSaveStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);
    container.read(settingsProvider.notifier).setConfirmBeforeDeleteGame(false);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('À Supprimer'), findsOneWidget);
    await tester.drag(find.text('À Supprimer'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('À Supprimer'), findsNothing);
    expect(await store.exists(3), isFalse);
  });

  testWidgets('swipe avec confirmation activée (par défaut) demande confirmation avant de supprimer', (tester) async {
    await store.write(_buildValidSavedGame(seed: 4, alias: 'À Confirmer', playerNames: ['A', 'B']));

    final container = ProviderContainer(overrides: [gameSaveStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.drag(find.text('À Confirmer'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette partie ?'), findsOneWidget);

    // Annuler : la partie reste.
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(await store.exists(4), isTrue);
    expect(find.text('À Confirmer'), findsOneWidget);
  });
}
