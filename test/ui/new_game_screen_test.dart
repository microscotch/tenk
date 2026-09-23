import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/dice_off_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/dice_off_screen.dart';
import 'package:le10000/ui/screens/new_game_screen.dart';
import 'package:le10000/ui/screens/player_picker_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

/// L'écran compose la partie à partir de la base de joueurs : les humains se
/// choisissent dans une liste, les bots s'ajoutent d'un bouton. Plus aucune
/// saisie de nom libre.
void main() {
  late FakePlayerStore players;
  late FakeGameSaveStore paused;
  late FakeGameSaveStore archived;

  setUp(() {
    players = FakePlayerStore();
    paused = FakeGameSaveStore();
    archived = FakeGameSaveStore();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        playerStoreProvider.overrideWithValue(players),
        gameSaveStoreProvider.overrideWithValue(paused),
        archivedGameSaveStoreProvider.overrideWithValue(archived),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NewGameScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> addHuman(WidgetTester tester, String name) async {
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerPickerScreen), findsOneWidget);
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
  }

  testWidgets('l\'écran démarre vide quand il n\'y a aucune partie précédente', (tester) async {
    await pump(tester);

    expect(find.text('Joueurs (0)'), findsOneWidget);
  });

  testWidgets('un joueur choisi dans la base prend un siège', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie'));
    await pump(tester);

    await addHuman(tester, 'Marie');

    expect(find.text('Joueurs (1)'), findsOneWidget);
    expect(find.text('Marie'), findsOneWidget);
  });

  testWidgets('un joueur déjà assis ne peut pas être choisi une seconde fois', (tester) async {
    await players.write(PlayerProfile.create(name: 'Marie'));
    await pump(tester);
    await addHuman(tester, 'Marie');

    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    final tile = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(tile.onChanged, isNull, reason: 'on ne joue pas deux fois dans la même partie');
  });

  testWidgets('le bouton bot ajoute un adversaire, en auto par défaut', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(Icons.smart_toy));
    await tester.pumpAndSettle();

    expect(find.text('Joueurs (1)'), findsOneWidget);
    expect(find.text('Bot'), findsOneWidget);
    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.selected, isTrue, reason: 'rien ne justifie de cliquer à la place d\'un bot');
  });

  testWidgets('démarrer refuse en dessous de deux joueurs', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.smart_toy));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Commencer la partie'));
    await tester.pumpAndSettle();

    expect(find.text('Il faut au moins deux joueurs.'), findsOneWidget);
    expect(find.byType(DiceOffScreen), findsNothing);
  });

  testWidgets('démarrer construit une config qui relie chaque humain à sa fiche', (tester) async {
    final marie = PlayerProfile.create(name: 'Marie');
    await players.write(marie);
    final container = await pump(tester);
    await addHuman(tester, 'Marie');
    await tester.tap(find.byIcon(Icons.smart_toy));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Commencer la partie'));
    await tester.pumpAndSettle();

    expect(find.byType(DiceOffScreen), findsOneWidget);
    final setup = container.read(diceOffProvider.notifier).setup;
    expect(setup.playerNames, hasLength(2));
    expect(setup.playerIds.values, contains(marie.id),
        reason: 'c\'est ce lien qui rattachera la partie à sa fiche');
    expect(setup.aiPlayers.values, everyElement(AiDifficulty.prudent),
        reason: 'le réglage de difficulté a disparu : tous les bots sont prudents');
  });

  testWidgets('un joueur se déplace par sa poignée, et la partie suit ce nouvel ordre', (tester) async {
    final a = PlayerProfile.create(name: 'Anna');
    final b = PlayerProfile.create(name: 'Basile');
    final c = PlayerProfile.create(name: 'Céleste');
    for (final p in [a, b, c]) {
      await players.write(p);
    }
    await paused.write(buildResumableSavedGame(
      seed: 1,
      alias: 'Précédente',
      playerNames: const ['Anna', 'Basile', 'Céleste'],
      playerIds: {0: a.id, 1: b.id, 2: c.id},
    ));
    final container = await pump(tester);

    List<double> rowTops() => [
          for (final name in ['Anna', 'Basile', 'Céleste']) tester.getTopLeft(find.text(name)).dy,
        ];
    final before = rowTops();
    expect(before[0] < before[1] && before[1] < before[2], isTrue, reason: 'ordre repris de la dernière partie');

    // Anna glisse sous Céleste.
    final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.drag_handle).first));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, (before[2] - before[0] + 30) / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final after = rowTops();
    expect(after[1] < after[2] && after[2] < after[0], isTrue, reason: 'Basile, Céleste, puis Anna');

    await tester.tap(find.text('Commencer la partie'));
    await tester.pump();

    final setup = container.read(diceOffProvider.notifier).setup;
    expect(setup.playerNames, ['Basile', 'Céleste', 'Anna']);
    expect(setup.playerIds, {0: b.id, 1: c.id, 2: a.id}, reason: 'chaque fiche suit son joueur');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('un siège se retire', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.smart_toy));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Joueurs (0)'), findsOneWidget);
  });

  testWidgets('la composition de la partie précédente est reproposée', (tester) async {
    final marie = PlayerProfile.create(name: 'Marie');
    final bob = PlayerProfile.create(name: 'Bob');
    await players.write(marie);
    await players.write(bob);
    final base = buildResumableSavedGame(seed: 1, alias: 'Avant', playerNames: const ['Marie', 'Bob']);
    await archived.write(SavedGame(
      seed: base.seed,
      setup: GameSetup(playerNames: const ['Marie', 'Bob'], playerIds: {0: marie.id, 1: bob.id}),
      alias: base.alias,
      createdAt: base.createdAt,
      actions: base.actions,
    ));

    await pump(tester);

    expect(find.text('Joueurs (2)'), findsOneWidget);
    expect(find.text('Marie'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('un joueur supprimé depuis est simplement omis de la reproposition', (tester) async {
    final marie = PlayerProfile.create(name: 'Marie');
    await players.write(marie);
    final base = buildResumableSavedGame(seed: 1, alias: 'Avant', playerNames: const ['Marie', 'Parti']);
    await archived.write(SavedGame(
      seed: base.seed,
      setup: GameSetup(playerNames: const ['Marie', 'Parti'], playerIds: {0: marie.id, 1: 'id-disparu'}),
      alias: base.alias,
      createdAt: base.createdAt,
      actions: base.actions,
    ));

    await pump(tester);

    expect(find.text('Joueurs (0)'), findsOneWidget,
        reason: 'un seul rescapé, donc trop peu pour reproposer une partie');
  });
}
