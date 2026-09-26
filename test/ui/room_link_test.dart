import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/online_providers.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/state/room_link_providers.dart';
import 'package:le10000/ui/route_observer.dart';
import 'package:le10000/ui/screens/online_entry_screen.dart';
import 'package:le10000/ui/screens/setup_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_online.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

class _FakeLinkSource implements RoomLinkSource {
  final controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => controller.stream;
}

/// Les liens d'invitation ouvrent l'entrée en ligne sur le code du salon, sans
/// jamais rejoindre seuls.
void main() {
  late _FakeLinkSource source;
  late FakeTransport transport;
  late FakeGameSaveStore paused;
  late ProviderContainer container;

  setUp(() {
    source = _FakeLinkSource();
    transport = FakeTransport();
    paused = FakeGameSaveStore();
    container = ProviderContainer(overrides: [
      roomLinkSourceProvider.overrideWithValue(source),
      onlineTransportProvider.overrideWithValue(transport),
      onlineCredentialsStoreProvider.overrideWithValue(FakeCredentialsStore()),
      onlineServerUrlProvider.overrideWithValue('ws://test/ws'),
      gameSaveStoreProvider.overrideWithValue(paused),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      playerStoreProvider.overrideWithValue(FakePlayerStore()),
    ]);
    addTearDown(container.dispose);
    addTearDown(source.controller.close);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    // Comme Le10000App : l'écoute des liens commence avant l'accueil.
    container.read(roomLinkListenerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [routeObserver],
        home: const SetupScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> receive(WidgetTester tester, String url) async {
    source.controller.add(Uri.parse(url));
    await tester.pumpAndSettle();
  }

  String codeField(WidgetTester tester) => tester
      .widget<TextField>(find.widgetWithText(TextField, 'ABCDE'))
      .controller!
      .text;

  testWidgets('un lien reçu à l\'accueil ouvre l\'entrée sur le code, sans rejoindre', (tester) async {
    await pumpHome(tester);

    await receive(tester, 'https://tenk.microscotch.net/j/abcde');

    expect(find.byType(OnlineEntryScreen), findsOneWidget);
    expect(codeField(tester), 'ABCDE');
    expect(transport.channels, isEmpty, reason: 'aucune connexion : le joueur choisit son pseudo et rejoint lui-même');
  });

  testWidgets('le lien qui a lancé l\'application est ouvert dès l\'accueil', (tester) async {
    // Reçu avant que l'accueil n'existe (démarrage à froid).
    container.read(roomLinkListenerProvider);
    source.controller.add(Uri.parse('https://tenk.microscotch.net/j/K7M2P'));
    await tester.pump();

    await pumpHome(tester);

    expect(find.byType(OnlineEntryScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'K7M2P')).controller!.text, 'K7M2P');
  });

  testWidgets('le lien passe avant la proposition de reprise d\'une partie en pause', (tester) async {
    await paused.write(
      buildResumableSavedGame(seed: 7, alias: 'Facétieux Croupier', playerNames: const ['Marie', 'Bob']),
    );
    container.read(roomLinkListenerProvider);
    source.controller.add(Uri.parse('https://tenk.microscotch.net/j/ABCDE'));
    await tester.pump();

    await pumpHome(tester);

    expect(find.byType(OnlineEntryScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('un lien qui n\'est pas une invitation est ignoré', (tester) async {
    await pumpHome(tester);

    await receive(tester, 'https://example.com/j/ABCDE');
    await receive(tester, 'https://tenk.microscotch.net/j/ABCD');

    expect(find.byType(OnlineEntryScreen), findsNothing);
    expect(container.read(pendingRoomCodeProvider), isNull);
  });

  testWidgets('un lien reçu sous un autre écran attend le retour à l\'accueil', (tester) async {
    await pumpHome(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('en pleine partie'))));
    await tester.pumpAndSettle();

    await receive(tester, 'https://tenk.microscotch.net/j/ABCDE');
    expect(find.text('en pleine partie'), findsOneWidget, reason: 'l\'écran en cours n\'est pas recouvert');
    expect(find.byType(OnlineEntryScreen), findsNothing);

    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(OnlineEntryScreen), findsOneWidget);
    expect(codeField(tester), 'ABCDE');
  });

  testWidgets('un même lien ne s\'ouvre qu\'une fois', (tester) async {
    await pumpHome(tester);
    await receive(tester, 'https://tenk.microscotch.net/j/ABCDE');
    expect(container.read(pendingRoomCodeProvider), isNull);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(OnlineEntryScreen), findsNothing);
  });
}
