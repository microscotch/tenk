import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/player_stats.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/player_edit_screen.dart';
import 'package:le10000/ui/screens/players_screen.dart';

import '../test_helpers/fake_player_store.dart';

void main() {
  late FakePlayerStore store;

  setUp(() => store = FakePlayerStore());

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [playerStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlayersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('une base vide le dit', (tester) async {
    await pump(tester);

    expect(find.text('Aucun joueur enregistré pour l\'instant.'), findsOneWidget);
  });

  testWidgets('les fiches sont listées avec leur nombre de parties', (tester) async {
    await store.write(PlayerProfile.create(name: 'Marie')
        .copyWith(stats: const PlayerStats(gamesPlayed: 3)));
    await store.write(PlayerProfile.create(name: 'Bob'));
    await pump(tester);

    expect(find.text('Marie'), findsOneWidget);
    expect(find.text('3 parties jouées'), findsOneWidget);
    expect(find.text('Aucune partie jouée'), findsOneWidget, reason: 'Bob n\'a pas encore joué');
  });

  testWidgets('le surnom prend la place du nom dans la liste', (tester) async {
    await store.write(PlayerProfile.create(name: 'Marie Curie', nickname: 'Mimi'));
    await pump(tester);

    expect(find.text('Mimi'), findsOneWidget);
    expect(find.text('Marie Curie'), findsNothing);
  });

  testWidgets('créer un joueur l\'ajoute à la base', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerEditScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Chloé');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final players = await store.list();
    expect(players.single.name, 'Chloé');
    expect(players.single.rightHanded, isTrue, reason: 'droitier par défaut');
    expect(find.text('Chloé'), findsOneWidget, reason: 'la liste doit s\'être rafraîchie');
  });

  testWidgets('un nom déjà pris est refusé, aux accents et à la casse près', (tester) async {
    await store.write(PlayerProfile.create(name: 'Rémi'));
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'remi');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Ce nom est déjà utilisé par un autre joueur.'), findsOneWidget);
    expect(find.byType(PlayerEditScreen), findsOneWidget, reason: 'on reste sur le formulaire');
    expect(await store.list(), hasLength(1), reason: 'rien n\'a été écrit');
  });

  testWidgets('un nom vide est refusé', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom est obligatoire.'), findsOneWidget);
    expect(await store.list(), isEmpty);
  });

  testWidgets('renommer conserve l\'ancien nom et les statistiques', (tester) async {
    await store.write(PlayerProfile.create(name: 'Marie')
        .copyWith(stats: const PlayerStats(gamesPlayed: 4, gamesWon: 2)));
    await pump(tester);

    await tester.tap(find.text('Marie'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nom'), 'Marie Curie');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final saved = (await store.list()).single;
    expect(saved.name, 'Marie Curie');
    expect(saved.formerNames, ['Marie'],
        reason: 'les archives ne connaissent que les noms : il faut garder l\'ancien');
    expect(saved.stats.gamesPlayed, 4, reason: 'l\'édition ne touche pas aux statistiques');
  });

  testWidgets('une fiche peut reprendre son propre nom sans se heurter à elle-même', (tester) async {
    await store.write(PlayerProfile.create(name: 'Marie', nickname: 'Mimi'));
    await pump(tester);

    await tester.tap(find.text('Mimi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Surnom (facultatif)'), 'Mumu');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final saved = (await store.list()).single;
    expect(saved.nickname, 'Mumu');
    expect(find.text('Ce nom est déjà utilisé par un autre joueur.'), findsNothing);
  });

  testWidgets('supprimer demande confirmation puis efface la fiche', (tester) async {
    await store.write(PlayerProfile.create(name: 'Bob'));
    await pump(tester);

    await tester.drag(find.text('Bob'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer ce joueur ?'), findsOneWidget);
    expect(find.textContaining('Les parties déjà jouées, elles, sont conservées'), findsOneWidget);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(await store.list(), isEmpty);
    expect(find.text('Bob'), findsNothing);
  });

  testWidgets('annuler la suppression garde la fiche', (tester) async {
    await store.write(PlayerProfile.create(name: 'Bob'));
    await pump(tester);

    await tester.drag(find.text('Bob'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(await store.list(), hasLength(1));
    expect(find.text('Bob'), findsOneWidget);
  });
}
