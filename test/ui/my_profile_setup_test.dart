import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/online_providers.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/state/room_link_providers.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/route_observer.dart';
import 'package:le10000/ui/screens/my_profile_setup_screen.dart';
import 'package:le10000/ui/screens/tutorial_screen.dart';
import 'package:le10000/ui/screens/online_entry_screen.dart';
import 'package:le10000/ui/screens/player_edit_screen.dart';
import 'package:le10000/ui/screens/players_screen.dart';
import 'package:le10000/ui/screens/setup_screen.dart';
import 'package:le10000/ui/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_online.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/my_profile.dart';

/// Le profil de l'utilisateur : demandé au lancement quand il manque, jamais
/// sinon ; créé, ou choisi parmi les fiches existantes.
void main() {
  late FakePlayerStore players;
  late ProviderContainer container;

  setUp(() {
    players = FakePlayerStore();
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer newContainer() {
    final c = ProviderContainer(overrides: [
      playerStoreProvider.overrideWithValue(players),
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      onlineCredentialsStoreProvider.overrideWithValue(FakeCredentialsStore()),
      onlineTransportProvider.overrideWithValue(FakeTransport()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    container = newContainer();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [routeObserver],
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Le splash, écourté d'un toucher.
  Future<void> launch(WidgetTester tester) async {
    await pump(tester, const SplashScreen());
    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();
  }

  group('au lancement', () {
    testWidgets('au tout premier lancement, le splash mène au tutoriel, puis à la création du profil', (tester) async {
      await launch(tester);
      expect(find.byType(TutorialScreen), findsOneWidget);
      expect(find.byType(MyProfileSetupScreen), findsNothing);

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      expect(find.byType(MyProfileSetupScreen), findsOneWidget);
      expect(find.byType(TutorialScreen), findsNothing);
    });

    testWidgets('tutoriel déjà vu, sans profil : directement à la création', (tester) async {
      SharedPreferences.setMockInitialValues({'settings.tutorialSeen': true});
      await launch(tester);
      expect(find.byType(MyProfileSetupScreen), findsOneWidget);
      expect(find.byType(TutorialScreen), findsNothing);
    });

    testWidgets('un utilisateur d\'avant les profils (ancien nom) n\'a pas le tutoriel', (tester) async {
      SharedPreferences.setMockInitialValues({'settings.playerName': 'Laurent'});
      await launch(tester);
      expect(find.byType(MyProfileSetupScreen), findsOneWidget);
      expect(find.byType(TutorialScreen), findsNothing);
    });

    testWidgets('avec un profil, directement à l\'accueil', (tester) async {
      await seedMyProfile(players, PlayerProfile.create(name: 'Anna'));
      await launch(tester);
      expect(find.byType(SetupScreen), findsOneWidget);
      expect(find.byType(MyProfileSetupScreen), findsNothing);
    });
  });

  group('écran du profil', () {
    testWidgets('créer son profil, prérempli avec l\'ancien nom des réglages, mène à l\'accueil', (tester) async {
      SharedPreferences.setMockInitialValues({'settings.playerName': 'Laurent', 'settings.rightHanded': false});
      await pump(tester, const MyProfileSetupScreen());

      await tester.tap(find.text('Créer mon profil'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Laurent'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'Lolo');
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(find.byType(SetupScreen), findsOneWidget);
      final me = (await players.list()).single;
      expect(me.name, 'Laurent');
      expect(me.nickname, 'Lolo');
      expect(me.rightHanded, isFalse, reason: 'l\'ancienne latéralité des réglages');
      expect(container.read(settingsProvider).myProfileId, me.id);
    });

    testWidgets('choisir sa fiche parmi les joueurs : l\'ancien joueur principal en tête', (tester) async {
      final anna = PlayerProfile.create(name: 'Anna');
      final laurent = PlayerProfile.create(name: 'Laurent');
      await players.write(anna);
      await players.write(laurent);
      SharedPreferences.setMockInitialValues({'settings.playerName': 'laurent'});
      await pump(tester, const MyProfileSetupScreen());

      final tiles = find.byType(ListTile);
      expect(find.descendant(of: tiles.first, matching: find.text('Laurent')), findsOneWidget);

      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();

      expect(find.byType(SetupScreen), findsOneWidget);
      expect(container.read(settingsProvider).myProfileId, anna.id);
      expect(await players.list(), hasLength(2), reason: 'aucune fiche créée');
    });

    testWidgets('l\'ancien nom déjà porté par une fiche ne préremplit pas la création', (tester) async {
      await players.write(PlayerProfile.create(name: 'Laurent'));
      SharedPreferences.setMockInitialValues({'settings.playerName': 'Laurent'});
      await pump(tester, const MyProfileSetupScreen());

      await tester.tap(find.text('Créer mon profil'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Laurent'), findsNothing);
    });

    testWidgets('on n\'en sort pas sans profil', (tester) async {
      await pump(tester, const MyProfileSetupScreen());
      expect(find.byType(BackButton), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(MyProfileSetupScreen), findsOneWidget);
    });

    testWidgets('un lien d\'invitation reçu avant le profil ouvre le salon une fois le profil fait', (tester) async {
      await pump(tester, const MyProfileSetupScreen());
      container.read(pendingRoomCodeProvider.notifier).offer(Uri.parse('https://tenk.microscotch.net/j/abcde'));

      await tester.tap(find.text('Créer mon profil'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Anna');
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle();

      expect(find.byType(OnlineEntryScreen), findsOneWidget);
      expect(find.widgetWithText(TextField, 'ABCDE'), findsOneWidget);
      expect(find.text('Vous jouez sous le nom « Anna »'), findsOneWidget);
    });
  });

  testWidgets('mon profil doit pouvoir servir de pseudo en ligne', (tester) async {
    await pump(tester, const PlayerEditScreen(isMyProfile: true));
    await tester.enterText(find.byType(TextField).first, 'Anna');
    await tester.enterText(find.byType(TextField).at(1), 'Un surnom beaucoup trop long');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.textContaining('20 caractères au plus'), findsOneWidget);
    expect(await players.list(), isEmpty);
  });

  testWidgets('ma fiche est marquée « Moi » et ne se supprime pas d\'un glissement', (tester) async {
    final me = PlayerProfile.create(name: 'Anna');
    await seedMyProfile(players, me);
    await players.write(PlayerProfile.create(name: 'Bob'));
    await pump(tester, const PlayersScreen());

    expect(find.text('Moi'), findsOneWidget);
    expect(find.ancestor(of: find.text('Anna'), matching: find.byType(Dismissible)), findsNothing);
    expect(find.ancestor(of: find.text('Bob'), matching: find.byType(Dismissible)), findsOneWidget);
  });
}
