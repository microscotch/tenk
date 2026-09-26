import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/online/protocol.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/online_providers.dart';
import 'package:le10000/state/online_transport.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/online_dice_off_screen.dart';
import 'package:le10000/ui/screens/online_entry_screen.dart';
import 'package:le10000/ui/screens/online_room_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_online.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

const _token = 'abcdef0123456789abcdef0123456789';

/// Le journal de départ d'une partie à deux (départage et premier tour).
List<GameAction> _startedJournal() {
  const setup = GameSetup(playerNames: ['Anna', 'Bob']);
  final full = journalWithFaces(setup, 5, playScriptedGame(setup, 5).actions);
  return full.sublist(0, full.indexWhere((a) => a.type == GameActionType.startTurn) + 1);
}

void main() {
  late FakeTransport transport;
  late FakeCredentialsStore credentials;
  late ProviderContainer container;

  setUp(() {
    transport = FakeTransport();
    credentials = FakeCredentialsStore();
    container = ProviderContainer(overrides: [
      onlineTransportProvider.overrideWithValue(transport),
      onlineCredentialsStoreProvider.overrideWithValue(credentials),
      onlineServerUrlProvider.overrideWithValue('ws://test/ws'),
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      playerStoreProvider.overrideWithValue(FakePlayerStore()),
    ]);
    addTearDown(container.dispose);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String label) => tester
      .widget<ButtonStyleButton>(find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)))
      .onPressed != null;

  /// Le serveur répond à la création d'un salon : on y est l'hôte, seul.
  Future<void> serverOpensRoom(WidgetTester tester, {int seat = 0, List<String> names = const ['Anna']}) async {
    transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: seat));
    transport.current.serverSends(ServerMessage.room(
      code: 'ABCDE',
      phase: RoomPhase.lobby,
      seats: [for (final n in names) SeatInfo(name: n, connected: true)],
      hostSeat: 0,
    ));
    await tester.pumpAndSettle();
  }

  group('entrée', () {
    testWidgets('créer un salon demande un pseudo, puis envoie la demande', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      expect(enabled(tester, 'Créer un salon'), isFalse);

      await tester.enterText(find.widgetWithText(TextField, 'Votre pseudo'), 'Anna');
      await tester.pump();
      expect(enabled(tester, 'Créer un salon'), isTrue);

      await tester.tap(find.text('Créer un salon'));
      await tester.pumpAndSettle();

      expect(transport.current.lastSent!.type, ClientMessageType.create);
      expect(transport.current.lastSent!.params['name'], 'Anna');
    });

    testWidgets('rejoindre demande un code complet, envoyé en majuscules', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Votre pseudo'), 'Bob');
      await tester.enterText(find.widgetWithText(TextField, 'Code du salon'), 'abc');
      await tester.pump();
      expect(enabled(tester, 'Rejoindre'), isFalse);

      await tester.enterText(find.widgetWithText(TextField, 'Code du salon'), 'abcde');
      await tester.pump();
      await tester.tap(find.text('Rejoindre'));
      await tester.pumpAndSettle();

      expect(transport.current.lastSent!.type, ClientMessageType.join);
      expect(transport.current.lastSent!.params['code'], 'ABCDE');
    });

    testWidgets('une erreur du serveur s\'affiche ; un coup refusé ne dit rien', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Votre pseudo'), 'Bob');
      await tester.enterText(find.widgetWithText(TextField, 'Code du salon'), 'ZZZZZ');
      await tester.pump();
      await tester.tap(find.text('Rejoindre'));
      await tester.pumpAndSettle();

      transport.current.serverSends(ServerMessage.error(ErrorCode.illegalMove));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      transport.current.serverSends(ServerMessage.error(ErrorCode.roomNotFound));
      await tester.pumpAndSettle();
      expect(find.text('Aucun salon avec ce code.'), findsOneWidget);
    });

    testWidgets('un serveur injoignable le dit', (tester) async {
      transport.unreachable = true;
      await pump(tester, const OnlineEntryScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Votre pseudo'), 'Anna');
      await tester.pump();
      await tester.tap(find.text('Créer un salon'));
      await tester.pumpAndSettle();

      expect(find.text('Serveur injoignable.'), findsOneWidget);
    });

    testWidgets('le salon s\'ouvre dès que le serveur l\'a créé', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Votre pseudo'), 'Anna');
      await tester.pump();
      await tester.tap(find.text('Créer un salon'));
      await tester.pumpAndSettle();

      await serverOpensRoom(tester);

      expect(find.byType(OnlineRoomScreen), findsOneWidget);
      expect(find.text('ABCDE'), findsOneWidget);
    });

    testWidgets('ouvrir l\'entrée ne se connecte à rien : rien à faire tant qu\'on n\'a rien demandé', (tester) async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ABCDE', token: _token);
      await pump(tester, const OnlineEntryScreen());
      expect(transport.channels, isEmpty);
    });

    testWidgets('une place gardée se propose, et se retrouve d\'un tap', (tester) async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ABCDE', token: _token);
      await pump(tester, const OnlineEntryScreen());

      expect(find.text('Reprendre la partie en ligne'), findsOneWidget);
      await tester.tap(find.text('Reprendre la partie en ligne'));
      await tester.pumpAndSettle();

      expect(transport.current.lastSent!.type, ClientMessageType.rejoin);
      expect(transport.current.lastSent!.params['token'], _token);
    });

    testWidgets('sans place gardée, rien à reprendre', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      expect(find.text('Reprendre la partie en ligne'), findsNothing);
    });

    testWidgets('quitter une partie commencée garde sa place, comme le dit la fenêtre', (tester) async {
      await container.read(onlineSessionProvider.notifier).create('Anna');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: const ['Anna', 'Bob'], actions: _startedJournal()));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await pump(tester, const OnlineEntryScreen());

      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Quitter'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();

      expect(credentials.saved, isNotNull, reason: 'le jeton reste : la partie attend son retour');
      expect(transport.channels.first.sent.any((m) => m.type == ClientMessageType.leave), isFalse);
      expect(container.read(onlineSessionProvider).inRoom, isFalse);
      expect(find.text('Reprendre la partie en ligne'), findsOneWidget, reason: 'et on peut la retrouver');
    });

    testWidgets('une partie en cours se retrouve ou se quitte, sans en ouvrir une seconde', (tester) async {
      await container.read(onlineSessionProvider.notifier).create('Anna');
      await serverOpensRoom(tester);
      await pump(tester, const OnlineEntryScreen());

      expect(find.text('Reprendre la partie en ligne'), findsOneWidget);
      expect(find.text('Créer un salon'), findsNothing);

      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Quitter'));
      await tester.pumpAndSettle();
      // Fermer la connexion passe par des futures que le temps simulé du test
      // ne fait pas avancer : on laisse le vrai temps s'écouler.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();

      expect(transport.channels.first.sent.last.type, ClientMessageType.leave);
      expect(container.read(onlineSessionProvider).inRoom, isFalse);
      expect(find.text('Créer un salon'), findsOneWidget);
    });
  });

  group('salon', () {
    Future<void> inRoom(WidgetTester tester, {required int seat, required List<String> names}) async {
      await container.read(onlineSessionProvider.notifier).join('abcde', names[seat]);
      await pump(tester, const OnlineRoomScreen());
      await serverOpensRoom(tester, seat: seat, names: names);
    }

    testWidgets('l\'hôte ne peut lancer qu\'à deux joueurs connectés', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);
      expect(enabled(tester, 'Commencer la partie'), isFalse);
      expect(find.text('Il faut au moins 2 joueurs, tous connectés.'), findsOneWidget);

      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.lobby,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      await tester.pumpAndSettle();
      expect(enabled(tester, 'Commencer la partie'), isTrue);

      await tester.tap(find.text('Commencer la partie'));
      await tester.pumpAndSettle();
      expect(transport.current.lastSent!.type, ClientMessageType.start);
    });

    testWidgets('un joueur déconnecté empêche le lancement et se signale', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.lobby,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: false)],
        hostSeat: 0,
      ));
      await tester.pumpAndSettle();

      expect(enabled(tester, 'Commencer la partie'), isFalse);
      expect(find.text('Déconnecté'), findsOneWidget);
    });

    testWidgets('un invité attend l\'hôte : pas de bouton de lancement', (tester) async {
      await inRoom(tester, seat: 1, names: ['Anna', 'Bob']);

      expect(find.text('En attente du lancement par l\'hôte…'), findsOneWidget);
      expect(find.text('Commencer la partie'), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing, reason: 'seul l\'hôte règle l\'ordre');
    });

    testWidgets('l\'hôte voit une poignée par joueur', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna', 'Bob', 'Chloé']);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
      expect(find.text('Hôte'), findsOneWidget);
      expect(find.text('Joueurs (3/6)'), findsOneWidget);
    });

    testWidgets('le retour système quitte le salon', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(transport.current.sent.any((m) => m.type == ClientMessageType.leave), isTrue);
    });
  });

  group('tirage au sort', () {
    const names = ['Anna', 'Bob'];
    const setup = GameSetup(playerNames: names);

    List<GameAction> journal() =>
        journalWithFaces(setup, 5, playScriptedGame(setup, 5).actions);

    List<GameAction> start(List<GameAction> full) =>
        full.sublist(0, full.indexWhere((a) => a.type == GameActionType.startTurn) + 1);

    Future<void> gameStarted(WidgetTester tester, List<GameAction> actions) async {
      await container.read(onlineSessionProvider.notifier).join('abcde', 'Anna');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: actions));
      await tester.pump(const Duration(milliseconds: 20));
    }

    testWidgets('raconte le tirage puis mène à la partie', (tester) async {
      await gameStarted(tester, start(journal()));
      await pump(tester, const OnlineDiceOffScreen());

      // Les dés apparaissent, puis le résultat, puis le bouton.
      await tester.pump(OnlineDiceOffScreen.firstRollDelay + const Duration(milliseconds: 50));
      for (var i = 0; i < 6 && find.text('Jouer').evaluate().isEmpty; i++) {
        await tester.pump(OnlineDiceOffScreen.roundDelay + const Duration(milliseconds: 50));
      }
      expect(find.text('Jouer'), findsOneWidget);
      expect(find.textContaining('commence la partie'), findsOneWidget);

      await tester.tap(find.text('Jouer'));
      // Les dés de la partie s'animent sans fin : pas de pumpAndSettle. Une
      // image pour poser la route, une autre pour finir sa transition.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('un tap va droit au résultat', (tester) async {
      await gameStarted(tester, start(journal()));
      await pump(tester, const OnlineDiceOffScreen());

      await tester.tapAt(const Offset(20, 300));
      await tester.pump();
      expect(find.text('Jouer'), findsOneWidget);
    });

    testWidgets('une partie déjà entamée saute le tirage', (tester) async {
      final full = journal();
      final rollIndex = full.indexWhere((a) => a.type == GameActionType.roll);
      await gameStarted(tester, full.sublist(0, rollIndex + 2));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnlineDiceOffScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameScreen), findsOneWidget);
    });
  });
}
