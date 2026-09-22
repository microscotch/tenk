import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/widgets/paused_games_list.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

void main() {
  late FakeGameSaveStore store;
  late FakePlayerStore players;

  setUp(() {
    store = FakeGameSaveStore();
    players = FakePlayerStore();
  });

  // Scaffold.body donne une hauteur bornée (comme la zone Expanded qui
  // héberge PausedGamesList en production, voir SetupScreen) : la liste
  // interne défile elle-même plutôt que de déborder.
  Widget wrap(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        // Fixé plutôt que laissé au défaut de l'environnement de test : le
        // format de date/heure en dépend.
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PausedGamesList()),
      ),
    );
  }

  testWidgets('affiche l\'alias, la date, les participants et l\'heure de chaque partie en pause',
      (tester) async {
    await store.write(buildResumableSavedGame(
      seed: 1,
      alias: 'Facétieux Croupier',
      playerNames: const ['Marie Curie', 'Bob'],
      createdAt: DateTime(2026, 3, 14, 9, 5),
    ));

    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(store),
      playerStoreProvider.overrideWithValue(players),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Facétieux Croupier'), findsOneWidget);
    expect(find.text('Marie Curie vs Bob'), findsOneWidget);
    expect(find.text('14 mars 2026'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
  });

  testWidgets('nomme les participants par leur surnom quand ils en ont un', (tester) async {
    final marie = PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi');
    await players.write(marie);
    await store.write(buildResumableSavedGame(
      seed: 5,
      alias: 'Partie liée',
      playerNames: const ['Marie Curie', 'Bob'],
      playerIds: {0: marie.id},
    ));

    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(store),
      playerStoreProvider.overrideWithValue(players),
    ]);
    addTearDown(container.dispose);
    await container.read(playersProvider.future);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Mimi vs Bob'), findsOneWidget);
    expect(find.textContaining('Marie Curie'), findsNothing);
  });

  testWidgets('aucune partie en pause : message discret plutôt qu\'une zone vide', (tester) async {
    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(store),
      playerStoreProvider.overrideWithValue(players),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Aucune partie en pause pour l\'instant.'), findsOneWidget);
  });

  testWidgets('tap sur une partie la reprend et ouvre GameScreen', (tester) async {
    await store.write(buildResumableSavedGame(seed: 2, alias: 'Dé Chanceux', playerNames: const ['A', 'B']));

    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(store),
      playerStoreProvider.overrideWithValue(players),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dé Chanceux'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('swipe sans confirmation activée supprime directement la partie', (tester) async {
    await store.write(buildResumableSavedGame(seed: 3, alias: 'À Supprimer', playerNames: const ['A', 'B']));

    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(store),
      playerStoreProvider.overrideWithValue(players),
    ]);
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

    final container = ProviderContainer(overrides: [
      gameSaveStoreProvider.overrideWithValue(store),
      playerStoreProvider.overrideWithValue(players),
    ]);
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
