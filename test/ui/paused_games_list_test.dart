import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/widgets/paused_games_list.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/scripted_game.dart';

void main() {
  late FakeGameSaveStore store;

  setUp(() {
    store = FakeGameSaveStore();
  });

  // Scaffold.body donne une hauteur bornée (comme la zone Expanded qui
  // héberge PausedGamesList en production, voir SetupScreen) : la liste
  // interne défile elle-même plutôt que de déborder.
  Widget wrap(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PausedGamesList()),
      ),
    );
  }

  testWidgets('affiche l\'alias et les avatars des joueurs de chaque partie en pause', (tester) async {
    await store.write(
      buildResumableSavedGame(seed: 1, alias: 'Facétieux Croupier', playerNames: const ['Marie Curie', 'Bob']),
    );

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
    await store.write(buildResumableSavedGame(seed: 2, alias: 'Dé Chanceux', playerNames: const ['A', 'B']));

    final container = ProviderContainer(overrides: [gameSaveStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dé Chanceux'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('swipe sans confirmation activée supprime directement la partie', (tester) async {
    await store.write(buildResumableSavedGame(seed: 3, alias: 'À Supprimer', playerNames: const ['A', 'B']));

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
    await store.write(buildResumableSavedGame(seed: 4, alias: 'À Confirmer', playerNames: const ['A', 'B']));

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
